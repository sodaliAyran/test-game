class_name DashComponent
extends Node

## Handles dash movement with invincibility frames.
## Can be used by both players and enemies.

@export var character_body: CharacterBody2D
@export var hurtbox: HurtboxComponent
@export var movement: MovementComponent
@export var skill_modifier: SkillModifierComponent

@export_group("Dash Settings")
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var cooldown: float = 1.0
@export var invincible_during_dash: bool = true

signal dash_started(direction: Vector2)
signal dash_ended
signal cooldown_finished

var _is_dashing: bool = false
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_timer: Timer
var _cooldown_timer: Timer
var _original_invincible: bool = false


func _ready() -> void:
	_setup_timers()


func _setup_timers() -> void:
	_dash_timer = Timer.new()
	_dash_timer.wait_time = dash_duration
	_dash_timer.one_shot = true
	_dash_timer.timeout.connect(_on_dash_timeout)
	add_child(_dash_timer)

	_cooldown_timer = Timer.new()
	_cooldown_timer.wait_time = cooldown
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(_cooldown_timer)


func _physics_process(delta: float) -> void:
	if not _is_dashing:
		return

	if character_body:
		# Apply dash velocity directly
		character_body.velocity = _dash_direction * _get_modified_speed()
		character_body.move_and_slide()


func _get_modified_speed() -> float:
	var speed = dash_speed
	# Could apply skill modifiers here in the future
	return speed


func _get_modified_duration() -> float:
	var duration = dash_duration
	# Could apply skill modifiers here in the future
	return duration


func _get_modified_cooldown() -> float:
	var cd = cooldown
	if skill_modifier:
		var speed_mult = skill_modifier.get_attack_speed_multiplier()
		if speed_mult > 0:
			cd = cooldown / speed_mult
	return cd


func can_dash() -> bool:
	return not _is_dashing and _cooldown_timer.is_stopped()


func dash(direction: Vector2) -> bool:
	"""Start a dash in the given direction. Returns true if dash started."""
	if not can_dash():
		return false

	if direction == Vector2.ZERO:
		return false

	_dash_direction = direction.normalized()
	_is_dashing = true

	# Store original invincibility and enable it during dash
	if hurtbox and invincible_during_dash:
		_original_invincible = hurtbox.invincible
		hurtbox.invincible = true

	# Stop normal movement during dash
	if movement:
		movement.stop()

	# Update timer duration with modifiers
	_dash_timer.wait_time = _get_modified_duration()
	_dash_timer.start()

	dash_started.emit(_dash_direction)
	return true


func _on_dash_timeout() -> void:
	_end_dash()


func _end_dash() -> void:
	_is_dashing = false
	_dash_direction = Vector2.ZERO

	# Restore original invincibility state
	if hurtbox and invincible_during_dash:
		hurtbox.invincible = _original_invincible

	# Start cooldown with modifiers
	_cooldown_timer.wait_time = _get_modified_cooldown()
	_cooldown_timer.start()

	dash_ended.emit()


func _on_cooldown_timeout() -> void:
	cooldown_finished.emit()


func is_dashing() -> bool:
	return _is_dashing


func get_dash_direction() -> Vector2:
	return _dash_direction


func get_cooldown_remaining() -> float:
	return _cooldown_timer.time_left


func force_end_dash() -> void:
	"""Force the dash to end immediately"""
	if _is_dashing:
		_dash_timer.stop()
		_end_dash()
