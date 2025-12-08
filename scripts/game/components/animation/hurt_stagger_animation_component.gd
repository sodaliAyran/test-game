class_name HurtStaggerAnimationComponent
extends Node

signal hurt_finished  # Emitted when the hurt animation completes

@export var sprite: Sprite2D
@export var flash_duration: float = 0.15  # Duration of the red flash
@export var rotation_back: float = 0.3  # How much to rotate back
@export var hurt_color: Color = Color.RED  # Color to flash

var is_playing: bool = false
var animation_time: float = 0.0
var original_rotation: float = 0.0
var original_modulate: Color = Color.WHITE
var total_duration: float = 0.15  # Total animation duration

func _ready() -> void:
	if sprite:
		original_modulate = sprite.modulate
		original_rotation = sprite.rotation

func play() -> void:
	"""Start the hurt animation."""
	if is_playing:
		return
	
	is_playing = true
	animation_time = 0.0
	if sprite:
		original_rotation = sprite.rotation
		original_modulate = sprite.modulate

func _process(delta: float) -> void:
	if not is_playing or not sprite:
		return
	
	animation_time += delta
	
	if animation_time >= total_duration:
		# Animation complete
		_reset_sprite()
		is_playing = false
		hurt_finished.emit()
		return
	
	var progress = animation_time / total_duration
	
	# Flash red for the first part, then fade back
	if animation_time < flash_duration:
		sprite.modulate = hurt_color
	else:
		var fade_progress = (animation_time - flash_duration) / (total_duration - flash_duration)
		sprite.modulate = hurt_color.lerp(original_modulate, fade_progress)
	
	# Rotate back slightly, then return to normal
	var rotation_direction = 1.0 if sprite.flip_h else -1.0
	if progress < 0.5:
		# First half: rotate back
		var rotate_progress = progress * 2.0  # 0 to 1
		sprite.rotation = original_rotation - (rotation_back * rotate_progress * rotation_direction)
	else:
		# Second half: return to normal
		var return_progress = (progress - 0.5) * 2.0  # 0 to 1
		sprite.rotation = original_rotation - (rotation_back * (1.0 - return_progress) * rotation_direction)

func stop() -> void:
	"""Stop the animation and reset."""
	_reset_sprite()
	is_playing = false
	animation_time = 0.0

func _reset_sprite() -> void:
	if sprite:
		sprite.rotation = original_rotation
		sprite.modulate = original_modulate

func is_finished() -> bool:
	"""Check if the animation has finished playing."""
	return not is_playing
