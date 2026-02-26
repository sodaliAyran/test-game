class_name DashWindupEffect
extends RefCounted

## Dash-specific windup visual: darkens + squeezes sprite.
## Usage: var effect = DashWindupEffect.create(sprite, body, direction, distance, duration)
## Connect to effect.completed to know when windup finishes.
## Call effect.cancel() to abort early (e.g., enemy got hit).

signal completed
signal cancelled

var _squeeze_tween: Tween
var _finish_tween: Tween
var _sprite: Sprite2D
var _original_modulate: Color
var _original_scale: Vector2
var _active: bool = false


static func create(sprite: Sprite2D, _body: CharacterBody2D, _direction: Vector2, _distance: float, duration: float) -> DashWindupEffect:
	var effect = DashWindupEffect.new()
	effect._start(sprite, duration)
	return effect


func _start(sprite: Sprite2D, duration: float) -> void:
	if not sprite or not is_instance_valid(sprite):
		completed.emit()
		return

	_sprite = sprite
	_original_modulate = sprite.modulate
	_original_scale = sprite.scale
	_active = true

	# Darken + Squeeze on sprite
	_squeeze_tween = sprite.create_tween()
	_squeeze_tween.set_parallel(true)

	# Darken to black
	_squeeze_tween.tween_property(sprite, "modulate", Color.BLACK, duration * 0.6)

	# Squeeze horizontally
	var squeeze_scale = Vector2(_original_scale.x * 0.6, _original_scale.y * 1.1)
	_squeeze_tween.tween_property(sprite, "scale", squeeze_scale, duration * 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Finish timer
	_finish_tween = sprite.create_tween()
	_finish_tween.tween_callback(_on_completed).set_delay(duration)


func _on_completed() -> void:
	if not _active:
		return
	_cleanup()
	completed.emit()


func cancel() -> void:
	if not _active:
		return
	_cleanup()
	cancelled.emit()


func is_active() -> bool:
	return _active


func _cleanup() -> void:
	_active = false

	if _squeeze_tween and _squeeze_tween.is_valid():
		_squeeze_tween.kill()
	if _finish_tween and _finish_tween.is_valid():
		_finish_tween.kill()

	if _sprite and is_instance_valid(_sprite):
		_sprite.modulate = _original_modulate
		_sprite.scale = _original_scale