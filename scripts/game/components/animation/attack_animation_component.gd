class_name AttackAnimationComponent
extends Node

signal attack_hit  # Emitted when the attack should deal damage
signal attack_finished  # Emitted when the animation completes

@export var sprite: Sprite2D
@export var windup_duration: float = 0.3  # Time to wind up
@export var strike_duration: float = 0.15  # Time to strike forward
@export var recovery_duration: float = 0.2  # Time to return to normal
@export var windup_rotation: float = -0.4  # Rotation during windup (negative = twist back)
@export var strike_rotation: float = 0.3  # Rotation during strike (positive = twist forward)

var is_playing: bool = false
var animation_time: float = 0.0
var original_rotation: float = 0.0
var original_modulate: Color = Color.WHITE

enum AnimationPhase {
	WINDUP,
	STRIKE,
	RECOVERY,
	IDLE
}

var current_phase: AnimationPhase = AnimationPhase.IDLE

func _ready() -> void:
	if sprite:
		original_rotation = sprite.rotation

func play() -> void:
	"""Start the attack animation."""
	if is_playing:
		return
	
	is_playing = true
	animation_time = 0.0
	current_phase = AnimationPhase.WINDUP
	if sprite:
		original_rotation = sprite.rotation
		original_modulate = sprite.modulate

func _process(delta: float) -> void:
	if not is_playing or not sprite:
		return
	
	animation_time += delta
	
	match current_phase:
		AnimationPhase.WINDUP:
			_process_windup()
		AnimationPhase.STRIKE:
			_process_strike()
		AnimationPhase.RECOVERY:
			_process_recovery()

func _process_windup() -> void:
	var progress = animation_time / windup_duration
	
	if progress >= 1.0:
		# Move to strike phase
		current_phase = AnimationPhase.STRIKE
		animation_time = 0.0
		return
	
	# Ease out for smooth windup
	var eased_progress = ease(progress, -0.5)  # Ease out
	var rotation_direction = 1.0 if sprite.flip_h else -1.0
	sprite.rotation = original_rotation + (windup_rotation * eased_progress * rotation_direction)

func _process_strike() -> void:
	var progress = animation_time / strike_duration
	
	if progress >= 1.0:
		# Move to recovery phase
		current_phase = AnimationPhase.RECOVERY
		animation_time = 0.0
		attack_hit.emit()  # Emit damage signal at end of strike
		return
	
	# Ease in for fast strike
	var eased_progress = ease(progress, 2.0)  # Ease in (fast)
	var rotation_range = windup_rotation - strike_rotation
	var rotation_direction = 1.0 if sprite.flip_h else -1.0
	sprite.rotation = original_rotation + (windup_rotation - (rotation_range * eased_progress)) * rotation_direction
	
	# Flash white during strike
	var flash_intensity = eased_progress * 0.7
	sprite.modulate = original_modulate.lerp(Color.YELLOW, flash_intensity)

func _process_recovery() -> void:
	var progress = animation_time / recovery_duration
	
	if progress >= 1.0:
		# Animation complete
		sprite.rotation = original_rotation
		sprite.modulate = original_modulate
		is_playing = false
		current_phase = AnimationPhase.IDLE
		attack_finished.emit()
		return
	
	# Ease out for smooth recovery
	var eased_progress = ease(progress, -0.5)  # Ease out
	var rotation_direction = 1.0 if not sprite.flip_h else -1.0
	sprite.rotation = original_rotation + (strike_rotation - (strike_rotation * eased_progress)) * rotation_direction
	
	# Fade out the white flash
	var flash_intensity = (1.0 - eased_progress) * 0.7  # Fade from 70% to 0%
	sprite.modulate = original_modulate.lerp(Color.WHITE, flash_intensity)

func stop() -> void:
	"""Stop the animation and reset."""
	is_playing = false
	current_phase = AnimationPhase.IDLE
	animation_time = 0.0
	if sprite:
		sprite.rotation = original_rotation
		sprite.modulate = original_modulate
