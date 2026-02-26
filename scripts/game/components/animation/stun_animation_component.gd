extends Node
class_name StunAnimationComponent

## Visual effect during stunned state - pulsing glow and optional wobble.

@export var sprite: Sprite2D
@export var stun_color: Color = Color(1.0, 0.8, 0.2, 1.0)  # Golden yellow
@export var pulse_speed: float = 0.3
@export var wobble_intensity: float = 2.0  # Degrees
@export var wobble_speed: float = 15.0

var is_playing: bool = false
var _tween: Tween
var _original_rotation: float = 0.0
var _duration: float = 0.0
var _elapsed: float = 0.0


func play(duration: float) -> void:
	if is_playing:
		return

	is_playing = true
	_duration = duration
	_elapsed = 0.0

	if sprite:
		_original_rotation = sprite.rotation
		_start_pulse_effect()


func stop() -> void:
	is_playing = false
	_elapsed = 0.0

	if _tween:
		_tween.kill()
		_tween = null

	if sprite:
		sprite.modulate = Color.WHITE
		sprite.rotation = _original_rotation


func is_finished() -> bool:
	return not is_playing or _elapsed >= _duration


func _process(delta: float) -> void:
	if not is_playing:
		return

	_elapsed += delta

	# Wobble effect
	if sprite and wobble_intensity > 0:
		sprite.rotation = _original_rotation + sin(_elapsed * wobble_speed) * deg_to_rad(wobble_intensity)

	if _elapsed >= _duration:
		stop()


func _start_pulse_effect() -> void:
	_tween = create_tween().set_loops()
	_tween.tween_property(sprite, "modulate", stun_color, pulse_speed)
	_tween.tween_property(sprite, "modulate", Color.WHITE, pulse_speed)
