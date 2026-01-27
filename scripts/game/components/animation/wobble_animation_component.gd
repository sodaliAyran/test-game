class_name WobbleAnimationComponent
extends Node

@export var sprite: Sprite2D
@export var facing: FacingComponent
@export var frequency: float = 10.0
@export var amplitude: float = 200.0
@export var rotation_amplitude: float = 0.1
@export var scale_amplitude: Vector2 = Vector2(0.1, 0.1)

var time: float = 0.0
var original_scale: Vector2

func _ready() -> void:
	if sprite:
		original_scale = sprite.scale

func play(delta: float, movement_direction: Vector2 = Vector2.ZERO, target_position: Vector2 = Vector2.ZERO) -> void:
	time += delta
	var sine_val = sin(time * frequency)
	
	if sprite:
		_flip_sprite(target_position)
		_rotate_sprite(sine_val)
		_stretch_sprite(sine_val)
	
func _flip_sprite(target_position: Vector2) -> void:
	if target_position == Vector2.ZERO:
		return

	var owner_node = sprite.get_parent()
	if not owner_node:
		return

	var direction_to_target = target_position - owner_node.global_position
	if facing:
		facing.set_facing_from_direction(direction_to_target)
	else:
		# Fallback for backwards compatibility
		if direction_to_target.x < 0:
			sprite.flip_h = false
		elif direction_to_target.x > 0:
			sprite.flip_h = true

func _rotate_sprite(sine_val: float) -> void:
	var wobble_rotation = sine_val * rotation_amplitude
	sprite.rotation = wobble_rotation
	
func _stretch_sprite(sine_val: float) -> void:
		var stretch_factor = 1.0 - abs(sine_val)
		var new_scale = original_scale
		new_scale.x -= stretch_factor * scale_amplitude.x
		new_scale.y += stretch_factor * scale_amplitude.y
		sprite.scale = new_scale

func reset() -> void:
	if sprite:
		sprite.rotation = 0.0
		sprite.scale = original_scale
