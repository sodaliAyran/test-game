class_name SkillModifierComponent
extends Node

## Applies skill modifiers to weapon stats by querying SkillManager

@export var character_id: String = "player"

var _cached_damage_multiplier: float = 1.0
var _cached_attack_speed_multiplier: float = 1.0
var _cached_attack_size_multiplier: float = 1.0
var _cached_multi_hit_count: int = 1
var _cached_attack_directions: Array[float] = [0.0]
var _cache_dirty: bool = true


func _ready() -> void:
	# Connect to SkillManager signals to invalidate cache
	if SkillManager:
		SkillManager.skill_unlocked.connect(_on_skills_changed)
		SkillManager.skill_locked.connect(_on_skills_changed)
		SkillManager.skills_reset.connect(_on_skills_changed)
	
	_update_cache()


func _on_skills_changed(_skill_id: String = "") -> void:
	_cache_dirty = true


func get_damage_multiplier() -> float:
	if _cache_dirty:
		_update_cache()
	return _cached_damage_multiplier


func get_attack_speed_multiplier() -> float:
	if _cache_dirty:
		_update_cache()
	return _cached_attack_speed_multiplier


func get_attack_size_multiplier() -> float:
	if _cache_dirty:
		_update_cache()
	return _cached_attack_size_multiplier


func get_multi_hit_count() -> int:
	if _cache_dirty:
		_update_cache()
	return _cached_multi_hit_count


func get_attack_directions() -> Array[float]:
	if _cache_dirty:
		_update_cache()
	return _cached_attack_directions


func _update_cache() -> void:
	if not SkillManager:
		_reset_cache()
		return
	
	var skills = SkillManager.get_unlocked_skill_data(character_id)
	
	# Reset to defaults
	_cached_damage_multiplier = 1.0
	_cached_attack_speed_multiplier = 1.0
	_cached_attack_size_multiplier = 1.0
	_cached_multi_hit_count = 1
	_cached_attack_directions = [0.0]
	
	# Accumulate modifiers from all skills
	for skill in skills:
		_cached_damage_multiplier *= skill.damage_multiplier
		_cached_attack_speed_multiplier *= skill.attack_speed_multiplier
		_cached_attack_size_multiplier *= skill.attack_size_multiplier
		
		# For multi-hit, use the highest value
		if skill.multi_hit_count > _cached_multi_hit_count:
			_cached_multi_hit_count = skill.multi_hit_count
			_cached_attack_directions = skill.attack_directions.duplicate()
	
	_cache_dirty = false


func _reset_cache() -> void:
	_cached_damage_multiplier = 1.0
	_cached_attack_speed_multiplier = 1.0
	_cached_attack_size_multiplier = 1.0
	_cached_multi_hit_count = 1
	_cached_attack_directions = [0.0]
	_cache_dirty = false


func force_update() -> void:
	"""Force an immediate cache update"""
	_cache_dirty = true
	_update_cache()
