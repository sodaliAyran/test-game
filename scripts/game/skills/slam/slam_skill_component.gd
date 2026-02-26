class_name SlamSkillComponent
extends Node

const WindupIndicatorComponentScript = preload("res://scripts/game/components/animation/windup_indicator_component.gd")

## Skill component wrapper for the Slam skill scene.
## Implements the generic skill interface (can_use, request_use, cancel_pending_request)
## for use with the Engage state pattern.

@export var weapon: WeaponComponent
@export var director_request: CombatDirectorRequestComponent
@export var cooldown: SkillCooldownComponent
@export var sense: EnemySenseComponent

@export var ap_cost: float = 1.0
@export var ap_priority: int = 50
@export var action_type: String = "basic_melee"

@export_group("Windup")
@export var windup_duration: float = 0.6
@export var windup_color: Color = Color.RED
@export var windup_sprite: Sprite2D
@export var ap_refund_ratio: float = 0.5

var _pending: bool = false
var _windup: WindupEffect
var _indicator: WindupIndicatorComponent
var _slam_position: Vector2
var _active: bool = false


func _ready() -> void:
	if director_request:
		director_request.action_approved.connect(_on_action_approved)
		director_request.action_denied.connect(_on_action_denied)
	if weapon:
		weapon.attack_ended.connect(_on_attack_ended)


func can_use() -> bool:
	if not _active:
		return false
	if _pending:
		return false
	if cooldown and not cooldown.is_ready:
		return false
	return true


func request_use(_context: Dictionary) -> bool:
	if not _active:
		return false
	if not director_request or not weapon:
		return false

	var request = APRequest.create(
		owner,  # The enemy root (berserker)
		action_type,
		ap_cost,
		Callable(),  # Handled via signal
		ap_priority
	)

	if director_request.request_action(request):
		_pending = true
		return true
	return false


## Call this to enable the skill (e.g. when entering Engage state)
func activate() -> void:
	_active = true


## Call this to disable the skill (e.g. when leaving Engage state)
func deactivate() -> void:
	_active = false


func is_winding_up() -> bool:
	return _windup != null and _windup.is_active()


func cancel_pending_request() -> void:
	if _windup and _windup.is_active():
		cancel_windup()
		return
	if _pending and director_request:
		director_request.cancel_pending_request()
		_pending = false


func _on_action_approved(_action: String) -> void:
	_pending = false

	# If no longer active (e.g. left engage state), reject the approved action
	if not _active:
		if director_request:
			director_request.complete_action()
		return

	# Capture the target's position at approval time so the slam doesn't track
	var target = sense.current_target if sense else null
	if target and is_instance_valid(target):
		_slam_position = target.global_position
	else:
		_slam_position = owner.global_position

	if windup_duration > 0.0:
		# Create circle indicator at attack position
		_create_indicator()

		# Create sprite color pulse effect
		if windup_sprite:
			_windup = WindupEffect.create(windup_sprite, windup_duration, windup_color)
			_windup.completed.connect(_on_windup_completed)
		else:
			# Use indicator completion if no sprite pulse
			if _indicator:
				_indicator.completed.connect(_on_windup_completed)
			else:
				_on_windup_completed()
	else:
		_on_windup_completed()


func _on_action_denied(_action: String, _reason: String) -> void:
	_pending = false


func _create_indicator() -> void:
	if not weapon or not weapon.hitbox_collision:
		return

	var shape = weapon.hitbox_collision.shape as CircleShape2D
	if not shape:
		return

	var radius = shape.radius

	# Apply size multiplier if available
	if weapon.skill_modifier:
		radius *= weapon.skill_modifier.get_attack_size_multiplier()

	_indicator = WindupIndicatorComponentScript.new()
	_indicator.duration = windup_duration
	_indicator.configure_circle(radius)
	get_tree().current_scene.add_child(_indicator)
	_indicator.global_position = _slam_position
	_indicator.start()


func _on_windup_completed() -> void:
	_windup = null
	_indicator = null
	if weapon:
		weapon.trigger_attack_at_position(_slam_position)
	if cooldown:
		cooldown.start_cooldown()


func cancel_windup() -> void:
	var was_active = (_windup and _windup.is_active()) or (_indicator and _indicator.is_active())

	if _windup and _windup.is_active():
		_windup.cancel()
		_windup = null
	if _indicator and _indicator.is_active():
		_indicator.cancel()
		_indicator = null

	if was_active:
		if director_request:
			director_request.complete_action()
		CombatDirector.refund_ap(ap_cost * ap_refund_ratio)


func _on_attack_ended() -> void:
	if director_request:
		director_request.complete_action()
