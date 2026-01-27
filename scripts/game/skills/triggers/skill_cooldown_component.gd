class_name SkillCooldownComponent
extends Node

## Manages skill/weapon cooldown state separately from attack execution.
## Can be shared by multiple trigger systems or used standalone.

signal cooldown_ready
signal cooldown_started

@export var cooldown_time: float = 2.5
@export var skill_modifier: SkillModifierComponent

var is_ready: bool = true
var _timer: Timer
var _base_cooldown: float


func _ready() -> void:
	_base_cooldown = cooldown_time
	_setup_timer()

	# Listen for skill changes to update cooldown
	if skill_modifier:
		if SkillManager:
			SkillManager.skill_unlocked.connect(_on_skills_changed)
			SkillManager.skill_locked.connect(_on_skills_changed)
			SkillManager.skills_reset.connect(_on_skills_changed)


func _setup_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = _get_modified_cooldown()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)


func start_cooldown() -> void:
	is_ready = false
	_timer.wait_time = _get_modified_cooldown()
	_timer.start()
	cooldown_started.emit()


func _on_timer_timeout() -> void:
	is_ready = true
	cooldown_ready.emit()


func _get_modified_cooldown() -> float:
	if skill_modifier:
		var speed_mult = skill_modifier.get_attack_speed_multiplier()
		if speed_mult > 0:
			return _base_cooldown / speed_mult
	return _base_cooldown


func _on_skills_changed(_skill_id: String = "") -> void:
	# Update timer wait time if currently on cooldown
	if _timer and not _timer.is_stopped():
		var remaining_ratio = _timer.time_left / _timer.wait_time
		_timer.wait_time = _get_modified_cooldown()
		# Adjust remaining time proportionally
		_timer.start(_timer.wait_time * remaining_ratio)


func get_cooldown_progress() -> float:
	"""Returns 0.0 to 1.0 representing cooldown completion (1.0 = ready)"""
	if is_ready:
		return 1.0
	if _timer.is_stopped():
		return 1.0
	return 1.0 - (_timer.time_left / _timer.wait_time)


func reset_cooldown() -> void:
	"""Immediately make the weapon ready"""
	_timer.stop()
	is_ready = true
	cooldown_ready.emit()
