class_name HealthComponent
extends Node

signal died
signal health_depleted  # Emitted when health reaches 0, before died
signal health_changed(current, max)

@export var max_health: int = 100
@export var skill_modifier: SkillModifierComponent  ## Optional - for player health bonus

var current_health: int
var _base_max_health: int


func _ready() -> void:
	_base_max_health = max_health
	current_health = get_effective_max_health()

	if skill_modifier and SkillManager:
		SkillManager.skill_changed.connect(_on_skill_changed)
		SkillManager.skills_reset.connect(_on_skills_reset)


func get_effective_max_health() -> int:
	if skill_modifier:
		return _base_max_health + skill_modifier.get_health_bonus()
	return _base_max_health


func _on_skill_changed(_skill_id: String = "", _new_level: int = 0) -> void:
	var old_max = _base_max_health + skill_modifier.get_health_bonus()
	# The cache may already be dirty, force update to get the new value
	skill_modifier.force_update()
	var new_max = get_effective_max_health()
	var diff = new_max - old_max
	if diff > 0:
		current_health = mini(current_health + diff, new_max)
	else:
		current_health = mini(current_health, new_max)
	health_changed.emit(current_health, new_max)


func _on_skills_reset() -> void:
	current_health = mini(current_health, get_effective_max_health())
	health_changed.emit(current_health, get_effective_max_health())


func take_damage(amount: int) -> void:
	var effective_max = get_effective_max_health()
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, effective_max)
	if current_health <= 0:
		health_depleted.emit()
		if not _has_knockbackable_handler():
			died.emit()


func _has_knockbackable_handler() -> bool:
	return owner.get_node_or_null("KnockbackableComponent") != null
