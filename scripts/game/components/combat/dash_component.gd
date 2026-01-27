class_name DashComponent
extends Node

## Handles dash movement with invincibility frames.
## Can be used by both players and enemies.
## Use CombatDirectorRequestComponent for AP token integration.

@export var character_body: CharacterBody2D
@export var hurtbox: HurtboxComponent
@export var movement: MovementComponent
@export var skill_modifier: SkillModifierComponent
@export var director_request: CombatDirectorRequestComponent  ## Optional: for AP-gated dashing

@export_group("Dash Settings")
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var cooldown: float = 1.0
@export var invincible_during_dash: bool = true

@export_group("AP Integration")
@export var ap_cost: float = 2.5  ## AP cost for this dash ability
@export var ap_priority: int = 60  ## Priority for AP requests
@export var action_label: String = "dash_attack"  ## Label for debugging/logging

signal dash_started(direction: Vector2)
signal dash_ended
signal cooldown_finished

var _is_dashing: bool = false
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_timer: Timer
var _cooldown_timer: Timer
var _original_invincible: bool = false
var _pending_dash_direction: Vector2 = Vector2.ZERO


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


func _physics_process(_delta: float) -> void:
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
	var has_pending = director_request and director_request.has_pending_request()
	return not _is_dashing and _cooldown_timer.is_stopped() and not has_pending


func request_dash(direction: Vector2) -> bool:
	"""Request a dash. If director_request component exists, requests AP first.
	Use this method for enemies that need AP tokens.
	Returns true if request was accepted (queued or executed)."""
	if not can_dash():
		return false

	if direction == Vector2.ZERO:
		return false

	# If no director component, execute dash immediately
	if not director_request:
		return dash(direction)

	# Store direction for when AP is approved
	_pending_dash_direction = direction.normalized()

	# Create AP request with this skill's cost
	var request = APRequest.create(
		character_body,  # The entity requesting
		action_label,    # Label for logging
		ap_cost,         # Cost defined by this skill
		Callable(self, "_execute_approved_dash"),
		ap_priority
	)

	# Request AP through director component
	return director_request.request_action(request)


func dash(direction: Vector2) -> bool:
	"""Start a dash in the given direction immediately (no AP check).
	Use this for player abilities or when AP was already approved.
	Returns true if dash started."""
	if _is_dashing or not _cooldown_timer.is_stopped():
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


func _execute_approved_dash() -> void:
	"""Called when CombatDirector approves the dash request"""
	dash(_pending_dash_direction)
	_pending_dash_direction = Vector2.ZERO


func _on_dash_timeout() -> void:
	_end_dash()


func _end_dash() -> void:
	_is_dashing = false
	_dash_direction = Vector2.ZERO

	# Restore original invincibility state
	if hurtbox and invincible_during_dash:
		hurtbox.invincible = _original_invincible

	# Notify CombatDirector that attack completed
	if director_request:
		director_request.complete_action()

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


func cancel_pending_request() -> void:
	"""Cancel any pending AP request"""
	if director_request:
		director_request.cancel_pending_request()
	_pending_dash_direction = Vector2.ZERO
