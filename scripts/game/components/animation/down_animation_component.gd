class_name DownAnimationComponent
extends Node

signal down_started
signal down_finished

@export var sprite: Sprite2D
@export var down_duration: float = 3.0
@export var rotation_duration: float = 0.2
@export var down_rotation: float = PI / 2  # 90 degrees

var is_playing: bool = false
var _knockback_direction: Vector2 = Vector2.ZERO
var _original_rotation: float = 0.0
var _down_tween: Tween

func play(knockback_direction: Vector2 = Vector2.ZERO) -> void:
	"""Start the down animation with rotation based on knockback direction."""
	if is_playing:
		return

	_knockback_direction = knockback_direction
	is_playing = true

	if sprite:
		_original_rotation = sprite.rotation
		_animate_down()

func _animate_down() -> void:
	"""Animate sprite rotating to down position, waiting, then rotating back up."""
	if _down_tween and _down_tween.is_valid():
		_down_tween.kill()

	_down_tween = create_tween()

	# Determine rotation direction based on knockback and sprite facing
	var rotation_sign = _get_rotation_sign()
	var target_rotation = _original_rotation + (down_rotation * rotation_sign)

	# Rotate down
	_down_tween.tween_property(sprite, "rotation", target_rotation, rotation_duration)
	_down_tween.tween_callback(_on_down_reached)

	# Wait for down duration
	_down_tween.tween_interval(down_duration)

	# Rotate back up
	_down_tween.tween_property(sprite, "rotation", _original_rotation, rotation_duration)
	_down_tween.tween_callback(_on_animation_finished)

func _get_rotation_sign() -> float:
	"""Determine which way to rotate based on knockback direction and sprite facing."""
	# If knocked from the right (knockback goes left), fall face down (negative rotation)
	# If knocked from the left (knockback goes right), fall face up (positive rotation)
	if _knockback_direction.x > 0:
		return 1.0 if not sprite.flip_h else -1.0
	else:
		return -1.0 if not sprite.flip_h else 1.0

func _on_down_reached() -> void:
	down_started.emit()

func _on_animation_finished() -> void:
	is_playing = false
	down_finished.emit()

func stop() -> void:
	"""Stop animation and reset sprite."""
	if _down_tween and _down_tween.is_valid():
		_down_tween.kill()

	if sprite:
		sprite.rotation = _original_rotation

	is_playing = false

func is_finished() -> bool:
	"""Check if the animation has finished playing."""
	return not is_playing
