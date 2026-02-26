class_name HurtFlashAnimationComponent
extends Node

## Component that flashes a sprite red when entity takes damage
## Lightweight and performant using modulate property

signal flash_complete()

@export var sprite: Sprite2D
@export var flash_color: Color = Color.WHITE
@export var flash_duration: float = 0.1
@export var num_flashes: int = 1

var original_modulate: Color
var is_flashing: bool = false
var flash_timer: float = 0.0
var current_flash: int = 0


func _ready() -> void:
	if sprite:
		original_modulate = sprite.modulate


func play() -> void:
	"""Start the flash animation."""
	if not sprite:
		push_warning("HurtFlashAnimationComponent: sprite not set")
		return
	
	# Don't restart if already flashing (prevents color getting stuck)
	if is_flashing:
		return
	
	is_flashing = true
	flash_timer = 0.0
	current_flash = 0
	original_modulate = sprite.modulate


func _process(delta: float) -> void:
	if not is_flashing:
		return
	
	flash_timer += delta
	
	# Calculate progress within current flash cycle
	var cycle_duration = flash_duration * 2  # Flash on + flash off
	var progress = fmod(flash_timer, cycle_duration) / cycle_duration
	
	# Alternate between flash color and original
	if progress < 0.5:
		# Flash on (first half of cycle)
		var flash_progress = progress * 2.0
		sprite.modulate = original_modulate.lerp(flash_color, flash_progress)
	else:
		# Flash off (second half of cycle)
		var fade_progress = (progress - 0.5) * 2.0
		sprite.modulate = flash_color.lerp(original_modulate, fade_progress)
	
	# Check if all flashes complete
	if flash_timer >= cycle_duration * num_flashes:
		_finish_flash()


func _finish_flash() -> void:
	"""Complete the flash animation and restore original color."""
	is_flashing = false
	if sprite:
		sprite.modulate = original_modulate
	emit_signal("flash_complete")


func stop() -> void:
	"""Stop the flash animation immediately."""
	if is_flashing:
		_finish_flash()
