class_name FacingComponent
extends Node

## Component that tracks and manages a character's facing direction.
## Handles sprite flipping and provides utility methods for position queries.

signal facing_changed(new_direction: Vector2)

@export var sprite: Sprite2D

## The direction the character is currently facing (normalized, horizontal only)
var facing_direction: Vector2 = Vector2.RIGHT

## Updates facing direction based on movement input.
## Only updates on horizontal movement to preserve facing when moving vertically.
func set_facing_from_direction(direction: Vector2) -> void:
	if direction.x == 0:
		return

	var new_facing = Vector2(sign(direction.x), 0)
	if new_facing != facing_direction:
		facing_direction = new_facing
		_update_sprite()
		facing_changed.emit(facing_direction)

## Directly set the facing direction (1 for right, -1 for left)
func set_facing(horizontal_direction: float) -> void:
	if horizontal_direction == 0:
		return

	var new_facing = Vector2(sign(horizontal_direction), 0)
	if new_facing != facing_direction:
		facing_direction = new_facing
		_update_sprite()
		facing_changed.emit(facing_direction)

## Returns the world position behind this character
func get_back_position(offset: float = 50.0) -> Vector2:
	return owner.global_position - facing_direction * offset

## Returns the world position in front of this character
func get_front_position(offset: float = 50.0) -> Vector2:
	return owner.global_position + facing_direction * offset

## Returns true if the given world position is behind this character
func is_position_behind(pos: Vector2) -> bool:
	var to_pos = (pos - owner.global_position).normalized()
	return to_pos.dot(facing_direction) < 0

## Returns true if the given world position is in front of this character
func is_position_in_front(pos: Vector2) -> bool:
	var to_pos = (pos - owner.global_position).normalized()
	return to_pos.dot(facing_direction) > 0

## Returns true if currently facing right
func is_facing_right() -> bool:
	return facing_direction.x > 0

## Returns true if currently facing left
func is_facing_left() -> bool:
	return facing_direction.x < 0

func _update_sprite() -> void:
	if sprite:
		# flip_h = true means facing right in this project's convention
		sprite.flip_h = facing_direction.x > 0
