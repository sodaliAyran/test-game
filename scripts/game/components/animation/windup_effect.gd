class_name WindupEffect
extends RefCounted

## Reusable windup visual effect that pulses a sprite's color.
## Usage: var effect = WindupEffect.create(sprite, 0.4, Color.RED)
## Connect to effect.completed to know when windup finishes.
## Call effect.cancel() to abort early (e.g., enemy got hit).

signal completed
signal cancelled

var _tween: Tween
var _sprite: Sprite2D
var _original_modulate: Color
var _active: bool = false


static func create(sprite: Sprite2D, duration: float, color: Color = Color.RED) -> WindupEffect:
	var effect = WindupEffect.new()
	effect._start(sprite, duration, color)
	return effect


func _start(sprite: Sprite2D, duration: float, color: Color) -> void:
	if not sprite or not is_instance_valid(sprite):
		completed.emit()
		return

	_sprite = sprite
	_original_modulate = sprite.modulate
	_active = true

	# Create a tween on the sprite's scene tree
	_tween = sprite.create_tween()
	_tween.set_loops()

	# Pulse: original -> color -> original per cycle (0.3s per cycle)
	var cycle_time = 0.15
	_tween.tween_property(sprite, "modulate", color, cycle_time)
	_tween.tween_property(sprite, "modulate", _original_modulate, cycle_time)

	# Finish timer — use a second tween to call _on_completed after duration
	var finish_tween = sprite.create_tween()
	finish_tween.tween_callback(_on_completed).set_delay(duration)


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
	if _tween and _tween.is_valid():
		_tween.kill()
	if _sprite and is_instance_valid(_sprite):
		_sprite.modulate = _original_modulate
