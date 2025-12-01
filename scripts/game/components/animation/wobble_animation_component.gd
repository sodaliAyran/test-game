class_name WobbleAnimationComponent
extends Node

@export var sprite: Sprite2D
@export var frequency: float = 10.0
@export var amplitude: float = 200.0
@export var rotation_amplitude: float = 0.1
@export var scale_amplitude: Vector2 = Vector2(0.1, 0.1)

var time: float = 0.0
var original_scale: Vector2

func _ready() -> void:
	if sprite:
		original_scale = sprite.scale

func get_wobble_offset(delta: float) -> float:
	time += delta
	var sine_val = sin(time * frequency)
	
	if sprite:
		sprite.rotation = sine_val * rotation_amplitude
		
		var cos_val = cos(time * frequency * 2.0)

		var stretch_factor = 1.0 - abs(sine_val)
		var new_scale = original_scale
		new_scale.x -= stretch_factor * scale_amplitude.x
		new_scale.y += stretch_factor * scale_amplitude.y
		sprite.scale = new_scale

	return sine_val * amplitude
