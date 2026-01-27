class_name APRequest
extends RefCounted

## Data class for Combat Director AP requests
## Bundles all parameters needed for an attack request

var enemy: Node2D
var action_type: String  # For logging/debugging (e.g., "dash_attack", "ranged_attack")
var cost: float          # AP cost for this action
var callback: Callable   # Called when request is approved
var priority: int        # Higher = processed first
var timestamp: float     # For FIFO ordering among same priority
var request_id: int      # Unique identifier for this request

static var _next_id: int = 0


static func create(p_enemy: Node2D, p_action: String, p_cost: float, p_callback: Callable, p_priority: int = 50) -> APRequest:
	var request = APRequest.new()
	request.enemy = p_enemy
	request.action_type = p_action
	request.cost = p_cost
	request.callback = p_callback
	request.priority = p_priority
	request.timestamp = Time.get_ticks_msec() / 1000.0
	request.request_id = _next_id
	_next_id += 1
	return request


func get_cost() -> float:
	return cost


func is_special() -> bool:
	# Special attacks cost 3+ AP
	return get_cost() >= 3.0


func is_valid() -> bool:
	# Request is valid if enemy still exists and is in tree
	return enemy != null and is_instance_valid(enemy) and enemy.is_inside_tree()
