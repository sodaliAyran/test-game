extends Node

## Circle Slot Manager - Arkham-style positioning system
## Manages attack slots in rings around targets (players)
## Autoload singleton that coordinates enemy positioning

signal slot_assigned(enemy: Node2D, ring: String)
signal slot_released(enemy: Node2D)
signal promoted_to_inner(enemy: Node2D)
signal moved_to_recovery(enemy: Node2D)

# Ring Configuration
@export var inner_ring_radius: float = 45.0
@export var outer_ring_radius: float = 90.0
@export var recovery_zone_radius: float = 120.0
@export var inner_slot_count: int = 6
@export var outer_slot_count: int = 12

# Orbit Configuration
@export var orbit_speed: float = 0.5  # Radians per second for slot rotation
@export var orbit_enabled: bool = true

# Internal slot data structures
class SlotData:
	var index: int
	var ring: String  # "inner" or "outer"
	var base_angle: float  # Base angle in radians
	var occupant: Node2D = null

	func is_occupied() -> bool:
		return occupant != null and is_instance_valid(occupant)

class TargetData:
	var target: Node2D
	var inner_slots: Array[SlotData] = []
	var outer_slots: Array[SlotData] = []
	var rotation_offset: float = 0.0  # Current orbit rotation
	var last_move_direction: Vector2 = Vector2.RIGHT

class EnemyAssignment:
	var enemy: Node2D
	var target: Node2D
	var slot: SlotData
	var priority_score: float = 0.0
	var wait_start_time: float = 0.0
	var is_in_recovery: bool = false

# State
var _targets: Dictionary = {}  # target instance_id -> TargetData
var _enemy_assignments: Dictionary = {}  # enemy instance_id -> EnemyAssignment
var _recovery_enemies: Dictionary = {}  # enemy instance_id -> target instance_id


func _ready() -> void:
	print("CircleSlotManager: Initialized (inner: %d slots @ %.0fpx, outer: %d slots @ %.0fpx)" % [
		inner_slot_count, inner_ring_radius,
		outer_slot_count, outer_ring_radius
	])


func _process(delta: float) -> void:
	if orbit_enabled:
		_update_orbit_rotations(delta)
	_process_promotions()
	_cleanup_invalid_assignments()


## Register a target (player) for slot management
func register_target(target: Node2D) -> void:
	if target == null:
		return

	var target_id = target.get_instance_id()
	if _targets.has(target_id):
		return  # Already registered

	var data = TargetData.new()
	data.target = target

	# Create inner ring slots
	for i in range(inner_slot_count):
		var slot = SlotData.new()
		slot.index = i
		slot.ring = "inner"
		slot.base_angle = (TAU / inner_slot_count) * i
		data.inner_slots.append(slot)

	# Create outer ring slots
	for i in range(outer_slot_count):
		var slot = SlotData.new()
		slot.index = i
		slot.ring = "outer"
		slot.base_angle = (TAU / outer_slot_count) * i
		data.outer_slots.append(slot)

	_targets[target_id] = data
	print("CircleSlotManager: Registered target %s" % target.name)


## Unregister a target
func unregister_target(target: Node2D) -> void:
	if target == null:
		return

	var target_id = target.get_instance_id()
	if not _targets.has(target_id):
		return

	# Release all slots for this target
	var data: TargetData = _targets[target_id]
	for slot in data.inner_slots:
		if slot.occupant:
			_release_slot_internal(slot.occupant)
	for slot in data.outer_slots:
		if slot.occupant:
			_release_slot_internal(slot.occupant)

	_targets.erase(target_id)
	print("CircleSlotManager: Unregistered target %s" % target.name)


## Request a slot for an enemy around a target
## Returns true if slot was assigned (inner or outer)
func request_slot(enemy: Node2D, target: Node2D, preferred_ring: String = "inner") -> bool:
	if enemy == null or target == null:
		return false

	var enemy_id = enemy.get_instance_id()
	var target_id = target.get_instance_id()

	# Check if enemy already has a slot
	if _enemy_assignments.has(enemy_id):
		return true  # Already assigned

	# Check if target is registered
	if not _targets.has(target_id):
		return false

	var data: TargetData = _targets[target_id]
	var assigned_slot: SlotData = null

	# Try preferred ring first, finding nearest empty slot to the enemy
	if preferred_ring == "inner":
		assigned_slot = _find_nearest_empty_slot(data.inner_slots, data, enemy.global_position)
		if assigned_slot == null:
			assigned_slot = _find_nearest_empty_slot(data.outer_slots, data, enemy.global_position)
	else:
		assigned_slot = _find_nearest_empty_slot(data.outer_slots, data, enemy.global_position)
		if assigned_slot == null:
			assigned_slot = _find_nearest_empty_slot(data.inner_slots, data, enemy.global_position)

	if assigned_slot == null:
		return false  # No slots available

	# Assign the slot
	assigned_slot.occupant = enemy

	var assignment = EnemyAssignment.new()
	assignment.enemy = enemy
	assignment.target = target
	assignment.slot = assigned_slot
	assignment.wait_start_time = Time.get_ticks_msec() / 1000.0
	assignment.priority_score = _calculate_priority(enemy, target)

	_enemy_assignments[enemy_id] = assignment

	slot_assigned.emit(enemy, assigned_slot.ring)
	return true


## Release an enemy's slot
func release_slot(enemy: Node2D) -> void:
	_release_slot_internal(enemy)


func _release_slot_internal(enemy: Node2D) -> void:
	if enemy == null:
		return

	var enemy_id = enemy.get_instance_id()
	if not _enemy_assignments.has(enemy_id):
		# Check recovery zone
		_recovery_enemies.erase(enemy_id)
		return

	var assignment: EnemyAssignment = _enemy_assignments[enemy_id]
	if assignment.slot:
		assignment.slot.occupant = null

	_enemy_assignments.erase(enemy_id)
	slot_released.emit(enemy)


## Get world position of an enemy's assigned slot
func get_slot_position(enemy: Node2D) -> Vector2:
	if enemy == null:
		return Vector2.ZERO

	var enemy_id = enemy.get_instance_id()

	# Check if in recovery zone
	if _recovery_enemies.has(enemy_id):
		return get_recovery_position(enemy)

	if not _enemy_assignments.has(enemy_id):
		return Vector2.ZERO

	var assignment: EnemyAssignment = _enemy_assignments[enemy_id]
	if not assignment.target or not is_instance_valid(assignment.target):
		return Vector2.ZERO

	var target_id = assignment.target.get_instance_id()
	if not _targets.has(target_id):
		return Vector2.ZERO

	var data: TargetData = _targets[target_id]
	var slot = assignment.slot

	# Calculate position based on ring and rotation
	var radius = inner_ring_radius if slot.ring == "inner" else outer_ring_radius
	var angle = slot.base_angle + data.rotation_offset
	var offset = Vector2(cos(angle), sin(angle)) * radius

	return assignment.target.global_position + offset


## Check if enemy has a slot assigned
func has_slot(enemy: Node2D) -> bool:
	if enemy == null:
		return false
	return _enemy_assignments.has(enemy.get_instance_id())


## Check if enemy is in inner ring
func is_in_inner_ring(enemy: Node2D) -> bool:
	if enemy == null:
		return false
	var enemy_id = enemy.get_instance_id()
	if not _enemy_assignments.has(enemy_id):
		return false
	var assignment: EnemyAssignment = _enemy_assignments[enemy_id]
	return assignment.slot != null and assignment.slot.ring == "inner"


## Move enemy to recovery zone (called when enemy is downed)
func move_to_recovery(enemy: Node2D) -> void:
	if enemy == null:
		return

	var enemy_id = enemy.get_instance_id()

	# Get target before releasing slot
	var target: Node2D = null
	if _enemy_assignments.has(enemy_id):
		var assignment: EnemyAssignment = _enemy_assignments[enemy_id]
		target = assignment.target

	# Release current slot
	release_slot(enemy)

	# Add to recovery zone
	if target:
		_recovery_enemies[enemy_id] = target.get_instance_id()
		moved_to_recovery.emit(enemy)


## Get position in recovery zone for an enemy
func get_recovery_position(enemy: Node2D) -> Vector2:
	if enemy == null:
		return Vector2.ZERO

	var enemy_id = enemy.get_instance_id()
	if not _recovery_enemies.has(enemy_id):
		return Vector2.ZERO

	var target_id = _recovery_enemies[enemy_id]
	if not _targets.has(target_id):
		return Vector2.ZERO

	var data: TargetData = _targets[target_id]
	if not data.target or not is_instance_valid(data.target):
		return Vector2.ZERO

	# Calculate recovery position - spread enemies around recovery zone
	# Use enemy instance id to get consistent angle
	var angle = fmod(float(enemy_id) * 0.618033988749, 1.0) * TAU  # Golden ratio for distribution
	var offset = Vector2(cos(angle), sin(angle)) * recovery_zone_radius

	return data.target.global_position + offset


## Check if enemy is in recovery zone
func is_in_recovery(enemy: Node2D) -> bool:
	if enemy == null:
		return false
	return _recovery_enemies.has(enemy.get_instance_id())


## Leave recovery zone and request a new slot (called when enemy recovers)
func leave_recovery(enemy: Node2D, target: Node2D) -> bool:
	if enemy == null:
		return false

	var enemy_id = enemy.get_instance_id()
	_recovery_enemies.erase(enemy_id)

	# Request slot from outer ring (fair queue position)
	return request_slot(enemy, target, "outer")


## Update target's last movement direction (for orbit alignment)
func update_target_direction(target: Node2D, direction: Vector2) -> void:
	if target == null or direction == Vector2.ZERO:
		return

	var target_id = target.get_instance_id()
	if _targets.has(target_id):
		var data: TargetData = _targets[target_id]
		data.last_move_direction = direction.normalized()


## Find first empty slot in array
func _find_empty_slot(slots: Array[SlotData]) -> SlotData:
	for slot in slots:
		if not slot.is_occupied():
			return slot
	return null


## Find nearest empty slot to enemy position
func _find_nearest_empty_slot(slots: Array[SlotData], target_data: TargetData, enemy_pos: Vector2) -> SlotData:
	var best_slot: SlotData = null
	var best_distance: float = INF

	for slot in slots:
		if slot.is_occupied():
			continue

		# Calculate slot world position
		var radius = inner_ring_radius if slot.ring == "inner" else outer_ring_radius
		var angle = slot.base_angle + target_data.rotation_offset
		var slot_pos = target_data.target.global_position + Vector2(cos(angle), sin(angle)) * radius

		var distance = enemy_pos.distance_squared_to(slot_pos)
		if distance < best_distance:
			best_distance = distance
			best_slot = slot

	return best_slot


## Calculate priority score for an enemy
func _calculate_priority(enemy: Node2D, target: Node2D) -> float:
	var score = 50.0  # Base priority

	# Distance factor - closer enemies get higher priority
	var distance = enemy.global_position.distance_to(target.global_position)
	score += max(0, 100 - distance) * 0.5

	# Could add enemy type priority here via groups or properties
	if enemy.is_in_group("berserker"):
		score += 20  # Berserkers are more aggressive
	elif enemy.is_in_group("ranged"):
		score -= 10  # Ranged prefer outer ring

	return score


## Update orbit rotations based on target movement
func _update_orbit_rotations(delta: float) -> void:
	for target_id in _targets:
		var data: TargetData = _targets[target_id]
		if data.target and is_instance_valid(data.target):
			# Slowly rotate slots in direction of movement
			var target_angle = data.last_move_direction.angle()
			var angle_diff = wrapf(target_angle - data.rotation_offset, -PI, PI)
			data.rotation_offset += angle_diff * orbit_speed * delta


## Process promotions from outer to inner ring
func _process_promotions() -> void:
	for target_id in _targets:
		var data: TargetData = _targets[target_id]

		# Check for empty inner slots
		var empty_inner = _find_empty_slot(data.inner_slots)
		if empty_inner == null:
			continue

		# Find highest priority enemy in outer ring for this target
		var best_assignment: EnemyAssignment = null
		var best_score: float = -1.0

		for enemy_id in _enemy_assignments:
			var assignment: EnemyAssignment = _enemy_assignments[enemy_id]
			if assignment.target != data.target:
				continue
			if assignment.slot == null or assignment.slot.ring != "outer":
				continue

			# Skip enemies that prefer the outer ring (e.g. ranged mages)
			var slot_seeker = assignment.enemy.get_node_or_null("SlotSeekerComponent")
			if slot_seeker and slot_seeker.preferred_ring == "outer":
				continue

			# Calculate score with wait time bonus
			var wait_time = (Time.get_ticks_msec() / 1000.0) - assignment.wait_start_time
			var score = assignment.priority_score + wait_time * 10  # 10 priority per second waiting

			if score > best_score:
				best_score = score
				best_assignment = assignment

		if best_assignment:
			# Promote to inner ring
			best_assignment.slot.occupant = null
			best_assignment.slot = empty_inner
			empty_inner.occupant = best_assignment.enemy
			promoted_to_inner.emit(best_assignment.enemy)


## Clean up assignments for enemies that no longer exist
func _cleanup_invalid_assignments() -> void:
	var to_remove: Array[int] = []

	for enemy_id in _enemy_assignments:
		var assignment: EnemyAssignment = _enemy_assignments[enemy_id]
		if not assignment.enemy or not is_instance_valid(assignment.enemy) or not assignment.enemy.is_inside_tree():
			if assignment.slot:
				assignment.slot.occupant = null
			to_remove.append(enemy_id)

	for enemy_id in to_remove:
		_enemy_assignments.erase(enemy_id)

	# Also clean recovery zone
	var recovery_to_remove: Array[int] = []
	for enemy_id in _recovery_enemies:
		# Can't easily check validity without reference, rely on explicit calls
		pass
