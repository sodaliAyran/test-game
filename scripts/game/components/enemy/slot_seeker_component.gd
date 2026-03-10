class_name SlotSeekerComponent
extends Node

## Component that manages an enemy's interaction with the Circle Slot Manager
## Handles slot requests, releases, and provides target positions

signal slot_acquired(ring: String)
signal slot_lost()
signal promoted_to_inner()
signal entered_recovery()

@export var preferred_ring: String = "inner"  # "inner" or "outer"
@export var enemy_type_priority: float = 50.0  # Base priority for slot assignment

## Distance the player must move from the lock point before enemy repositions
@export var reposition_threshold: float = 50.0
## Distance tolerance for considering enemy "at" its slot
@export var arrival_distance: float = 8.0

var target: Node2D = null
var _wait_start_time: float = 0.0
var _slot_manager: Node = null

# Position locking - enemy stays put until player moves far enough
var _locked: bool = false
var _locked_position: Vector2 = Vector2.ZERO  # World position enemy locks to
var _lock_player_position: Vector2 = Vector2.ZERO  # Player position when lock was set


func _ready() -> void:
	# Get reference to CircleSlotManager autoload
	_slot_manager = get_node_or_null("/root/CircleSlotManager")

	# Connect to _slot_manager signals
	if _slot_manager:
		_slot_manager.promoted_to_inner.connect(_on_promoted_to_inner)
		_slot_manager.moved_to_recovery.connect(_on_moved_to_recovery)


func _exit_tree() -> void:
	release_current_slot()
	if _slot_manager:
		if _slot_manager.promoted_to_inner.is_connected(_on_promoted_to_inner):
			_slot_manager.promoted_to_inner.disconnect(_on_promoted_to_inner)
		if _slot_manager.moved_to_recovery.is_connected(_on_moved_to_recovery):
			_slot_manager.moved_to_recovery.disconnect(_on_moved_to_recovery)


## Request a slot around a target
## Returns true if slot was assigned
func request_slot_for_target(new_target: Node2D) -> bool:
	if new_target == null:
		return false

	target = new_target
	_wait_start_time = Time.get_ticks_msec() / 1000.0

	if _slot_manager:
		var success = _slot_manager.request_slot(owner, target, preferred_ring)
		if success:
			var ring = "inner" if _slot_manager.is_in_inner_ring(owner) else "outer"
			slot_acquired.emit(ring)
		return success

	return false


## Release current slot
func release_current_slot() -> void:
	if _slot_manager:
		_slot_manager.release_slot(owner)
	target = null
	_locked = false
	slot_lost.emit()


## Get the world position to move toward
## Returns locked position if enemy has arrived at slot and player hasn't moved far,
## otherwise returns the live slot position.
func get_target_position() -> Vector2:
	if _slot_manager:
		# Check if in recovery zone
		if _slot_manager.is_in_recovery(owner):
			_locked = false
			return _slot_manager.get_recovery_position(owner)

		# Check if has slot
		if _slot_manager.has_slot(owner):
			var live_slot_pos = _slot_manager.get_slot_position(owner)

			if _locked:
				# Check if player moved far enough to break the lock
				if target and is_instance_valid(target):
					var player_moved = target.global_position.distance_to(_lock_player_position)
					if player_moved > reposition_threshold:
						_locked = false
						return live_slot_pos
				return _locked_position
			else:
				# Not locked yet - check if we've arrived at the slot
				var distance_to_slot = owner.global_position.distance_to(live_slot_pos)
				if distance_to_slot <= arrival_distance:
					_lock_position(live_slot_pos)
					return _locked_position
				return live_slot_pos

	# Fallback to direct target position
	if target and is_instance_valid(target):
		return target.global_position

	return owner.global_position


## Lock the enemy to the current world position
func _lock_position(world_pos: Vector2) -> void:
	_locked = true
	_locked_position = world_pos
	if target and is_instance_valid(target):
		_lock_player_position = target.global_position


## Unlock position (e.g. when slot changes or enemy leaves engage)
func unlock_position() -> void:
	_locked = false


## Check if we're in the inner ring
func is_in_inner_ring() -> bool:
	if _slot_manager:
		return _slot_manager.is_in_inner_ring(owner)
	return false


## Check if we have any slot assigned
func has_slot() -> bool:
	if _slot_manager:
		return _slot_manager.has_slot(owner)
	return false


## Check if we're in recovery zone
func is_in_recovery() -> bool:
	if _slot_manager:
		return _slot_manager.is_in_recovery(owner)
	return false


## Move to recovery zone (call when enemy is downed)
func enter_recovery() -> void:
	if _slot_manager:
		_slot_manager.move_to_recovery(owner)


## Leave recovery zone and request new slot (call when enemy recovers)
func leave_recovery() -> bool:
	if _slot_manager and target:
		return _slot_manager.leave_recovery(owner, target)
	return false


## Get time spent waiting for slot
func get_wait_time() -> float:
	return (Time.get_ticks_msec() / 1000.0) - _wait_start_time


## Get current target reference
func get_target() -> Node2D:
	return target


func _on_promoted_to_inner(enemy: Node2D) -> void:
	if enemy == owner:
		_locked = false
		promoted_to_inner.emit()


func _on_moved_to_recovery(enemy: Node2D) -> void:
	if enemy == owner:
		entered_recovery.emit()
