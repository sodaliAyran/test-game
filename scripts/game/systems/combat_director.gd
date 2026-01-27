extends Node

## Combat Director - Global AP token bucket system
## Controls when enemies can perform attacks via Action Point management
## Autoload singleton that coordinates enemy attack pacing

signal ap_changed(current: float, max_capacity: float)
signal attack_approved(enemy: Node2D, action_type: String)
signal attack_denied(enemy: Node2D, reason: String)

# Token Bucket Configuration
@export var max_ap: float = 10.0
@export var ap_refill_rate: float = 2.0  # AP per second
@export var initial_ap: float = 5.0

# Action Costs - can be extended as needed
const ACTION_COSTS = {
	"basic_melee": 1.0,
	"heavy_melee": 2.0,
	"dash_attack": 2.5,
	"special_attack": 3.0,
	"ranged_attack": 1.5,
	"ultimate": 5.0,
	"recovery": 4.0,  # For reviving downed heroes
}

# Concurrency Limits
@export var max_concurrent_attacks: int = 3
@export var max_concurrent_specials: int = 1

# State
var current_ap: float = 0.0
var _pending_requests: Array[APRequest] = []
var _active_attacks: Dictionary = {}  # enemy instance_id -> action_type
var _active_special_count: int = 0


func _ready() -> void:
	current_ap = initial_ap
	print("CombatDirector: Initialized with %.1f/%.1f AP" % [current_ap, max_ap])


func _process(delta: float) -> void:
	_refill_ap(delta)
	_process_pending_requests()


## Request AP for an attack action
## Returns true if request was queued, false if rejected immediately
func request_ap(request: APRequest) -> bool:
	if request == null or not request.is_valid():
		return false

	# Check if enemy already has a pending request
	for pending in _pending_requests:
		if pending.enemy == request.enemy:
			# Already has a pending request, reject
			attack_denied.emit(request.enemy, "already_pending")
			return false

	# Check if enemy is already attacking
	var enemy_id = request.enemy.get_instance_id()
	if _active_attacks.has(enemy_id):
		attack_denied.emit(request.enemy, "already_attacking")
		return false

	# Queue the request
	_pending_requests.append(request)
	_sort_requests()
	return true


## Cancel a pending request for an enemy
func cancel_request(enemy: Node2D) -> void:
	if enemy == null:
		return

	for i in range(_pending_requests.size() - 1, -1, -1):
		if _pending_requests[i].enemy == enemy:
			_pending_requests.remove_at(i)
			break


## Notify director that an attack has completed
func complete_attack(enemy: Node2D) -> void:
	if enemy == null:
		return

	var enemy_id = enemy.get_instance_id()
	if _active_attacks.has(enemy_id):
		var action_type = _active_attacks[enemy_id]
		var cost = get_action_cost(action_type)

		# Decrement special count if it was a special attack
		if cost >= 3.0:
			_active_special_count = max(0, _active_special_count - 1)

		_active_attacks.erase(enemy_id)


## Get current AP level
func get_current_ap() -> float:
	return current_ap


## Get max AP capacity
func get_max_ap() -> float:
	return max_ap


## Get action cost by type
static func get_action_cost(action_type: String) -> float:
	return ACTION_COSTS.get(action_type, 1.0)


## Check if an action type is considered "special" (high cost)
static func is_special_action(action_type: String) -> bool:
	return get_action_cost(action_type) >= 3.0


## Scale capacity and refill rate (for difficulty progression)
func scale_parameters(capacity_mult: float, refill_mult: float) -> void:
	max_ap *= capacity_mult
	ap_refill_rate *= refill_mult
	print("CombatDirector: Scaled to %.1f max AP, %.1f/sec refill" % [max_ap, ap_refill_rate])


## Get number of active attacks
func get_active_attack_count() -> int:
	return _active_attacks.size()


## Get number of pending requests
func get_pending_request_count() -> int:
	return _pending_requests.size()


## Refill AP over time
func _refill_ap(delta: float) -> void:
	var old_ap = current_ap
	current_ap = min(current_ap + ap_refill_rate * delta, max_ap)

	if current_ap != old_ap:
		ap_changed.emit(current_ap, max_ap)


## Process queued requests in priority order
func _process_pending_requests() -> void:
	# Clean up invalid requests first
	_cleanup_invalid_requests()

	# Process requests in order (already sorted by priority)
	var i = 0
	while i < _pending_requests.size():
		var request = _pending_requests[i]

		if _can_approve_request(request):
			_approve_request(request)
			_pending_requests.remove_at(i)
			# Don't increment i, array shifted
		else:
			i += 1


## Check if a request can be approved
func _can_approve_request(request: APRequest) -> bool:
	if not request.is_valid():
		return false

	var cost = request.get_cost()

	# Check AP availability
	if current_ap < cost:
		return false

	# Check concurrent attack limit
	if _active_attacks.size() >= max_concurrent_attacks:
		return false

	# Check concurrent special limit
	if request.is_special() and _active_special_count >= max_concurrent_specials:
		return false

	return true


## Approve a request and deduct AP
func _approve_request(request: APRequest) -> void:
	var cost = request.get_cost()
	var enemy_id = request.enemy.get_instance_id()

	# Deduct AP
	current_ap -= cost
	ap_changed.emit(current_ap, max_ap)

	# Track active attack
	_active_attacks[enemy_id] = request.action_type

	# Track special count
	if request.is_special():
		_active_special_count += 1

	# Emit signal
	attack_approved.emit(request.enemy, request.action_type)

	# Call the callback
	if request.callback.is_valid():
		request.callback.call()


## Sort requests by priority (higher first), then by timestamp (earlier first)
func _sort_requests() -> void:
	_pending_requests.sort_custom(func(a: APRequest, b: APRequest) -> bool:
		if a.priority != b.priority:
			return a.priority > b.priority  # Higher priority first
		return a.timestamp < b.timestamp  # Earlier timestamp first (FIFO)
	)


## Remove invalid requests (enemy died, left tree, etc.)
func _cleanup_invalid_requests() -> void:
	for i in range(_pending_requests.size() - 1, -1, -1):
		if not _pending_requests[i].is_valid():
			attack_denied.emit(_pending_requests[i].enemy, "invalid")
			_pending_requests.remove_at(i)


## Clean up active attacks for enemies that no longer exist
func _cleanup_active_attacks() -> void:
	var to_remove: Array[int] = []
	for enemy_id in _active_attacks:
		# Check if enemy still exists - this is tricky without a reference
		# We'll rely on complete_attack being called properly
		pass
