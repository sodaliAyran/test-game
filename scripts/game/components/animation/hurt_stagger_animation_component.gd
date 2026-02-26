class_name HurtStaggerAnimationComponent
extends Node

const HitSparkEffectScript = preload("res://scripts/game/components/animation/hit_spark_effect.gd")

signal hurt_finished  # Emitted when the hurt animation completes

@export var sprite: Sprite2D
@export var flash_duration: float = 0.15  # Duration of the white flash
@export var hurt_color: Color = Color(3.0, 3.0, 3.0, 1.0)  # Overbright white flash

var is_playing: bool = false
var animation_time: float = 0.0
var original_modulate: Color = Color.WHITE
var total_duration: float = 0.15  # Total animation duration

func _ready() -> void:
	if sprite:
		original_modulate = sprite.modulate

func play() -> void:
	"""Start the hurt animation."""
	if is_playing:
		return

	is_playing = true
	animation_time = 0.0
	if sprite:
		original_modulate = sprite.modulate
		_spawn_hit_spark()

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

	# Flash white for the first part, then fade back
	if animation_time < flash_duration:
		sprite.modulate = hurt_color
	else:
		var fade_progress = (animation_time - flash_duration) / (total_duration - flash_duration)
		sprite.modulate = hurt_color.lerp(original_modulate, fade_progress)

func stop() -> void:
	"""Stop the animation and reset."""
	_reset_sprite()
	is_playing = false
	animation_time = 0.0

func _reset_sprite() -> void:
	if sprite:
		sprite.modulate = original_modulate

func is_finished() -> bool:
	"""Check if the animation has finished playing."""
	return not is_playing

func _spawn_hit_spark() -> void:
	"""Spawn a star/cross spark effect at the sprite's position."""
	if not sprite:
		return
	var spark = HitSparkEffectScript.new()
	sprite.get_parent().add_child(spark)
	spark.global_position = sprite.global_position
