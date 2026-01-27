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

var target: Node2D = null
var _wait_start_time: float = 0.0
var _slot_manager: Node = null


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
	slot_lost.emit()


## Get the world position to move toward
## Returns slot position if available, otherwise returns target position directly
func get_target_position() -> Vector2:
	if _slot_manager:
		# Check if in recovery zone
		if _slot_manager.is_in_recovery(owner):
			return _slot_manager.get_recovery_position(owner)

		# Check if has slot
		if _slot_manager.has_slot(owner):
			return _slot_manager.get_slot_position(owner)

	# Fallback to direct target position
	if target and is_instance_valid(target):
		return target.global_position

	return owner.global_position


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
		promoted_to_inner.emit()


func _on_moved_to_recovery(enemy: Node2D) -> void:
	if enemy == owner:
		entered_recovery.emit()
