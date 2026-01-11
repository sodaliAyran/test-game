class_name AutoAttackComponent
extends Node

## Handles automatic attack triggering with cooldown timer

@export var weapon: WeaponComponent
@export var skill_modifier: SkillModifierComponent
@export var attack_cooldown: float = 1.0
@export var auto_attack_enabled: bool = true

var _cooldown_timer: Timer
var _base_cooldown: float


func _ready() -> void:
	_base_cooldown = attack_cooldown
	_setup_cooldown_timer()


func _setup_cooldown_timer() -> void:
	var modified_cooldown = _base_cooldown
	
	# Apply attack speed multiplier from skills
	if skill_modifier:
		var speed_mult = skill_modifier.get_attack_speed_multiplier()
		if speed_mult > 0:
			modified_cooldown = _base_cooldown / speed_mult
	
	_cooldown_timer = Timer.new()
	_cooldown_timer.wait_time = modified_cooldown
	_cooldown_timer.one_shot = false
	_cooldown_timer.autostart = auto_attack_enabled
	_cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(_cooldown_timer)


func _on_cooldown_timeout() -> void:
	if weapon and auto_attack_enabled:
		weapon.trigger_attack()


func enable_auto_attack() -> void:
	auto_attack_enabled = true
	if _cooldown_timer and _cooldown_timer.is_stopped():
		_cooldown_timer.start()


func disable_auto_attack() -> void:
	auto_attack_enabled = false
	if _cooldown_timer:
		_cooldown_timer.stop()


func trigger_attack() -> void:
	"""Manually trigger an attack if cooldown is ready"""
	if weapon and _cooldown_timer.is_stopped():
		weapon.trigger_attack()
		_cooldown_timer.start()


func reset_cooldown() -> void:
	if _cooldown_timer:
		_cooldown_timer.stop()
		_cooldown_timer.start()


func update_attack_speed() -> void:
	"""Recalculate attack speed when skills change"""
	if not _cooldown_timer:
		return
	
	var modified_cooldown = _base_cooldown
	
	if skill_modifier:
		var speed_mult = skill_modifier.get_attack_speed_multiplier()
		if speed_mult > 0:
			modified_cooldown = _base_cooldown / speed_mult
	
	_cooldown_timer.wait_time = modified_cooldown
