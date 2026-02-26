class_name SkillModifierComponent
extends Node

## Applies skill modifiers to weapon stats by querying SkillManager.
## Caches aggregated values with dirty flag for performance.
## Within a single skill: bonuses are additive across levels.
## Across different skills: multipliers are multiplicative.

@export var character_id: String = "player"

# Combat modifiers
var _cached_damage_multiplier: float = 1.0
var _cached_attack_speed_multiplier: float = 1.0
var _cached_attack_size_multiplier: float = 1.0
var _cached_multi_hit_count: int = 1
var _cached_attack_directions: Array[float] = [0.0]

# Passive modifiers (player-side)
var _cached_health_bonus: int = 0
var _cached_magnet_bonus: float = 0.0
var _cached_cooldown_reduction: float = 0.0

var _cache_dirty: bool = true


func _ready() -> void:
	if SkillManager:
		SkillManager.skill_changed.connect(_on_skills_changed)
		SkillManager.skills_reset.connect(_on_skills_reset)

	_update_cache()


func _on_skills_changed(_skill_id: String = "", _new_level: int = 0) -> void:
	_cache_dirty = true


func _on_skills_reset() -> void:
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


func get_health_bonus() -> int:
	if _cache_dirty:
		_update_cache()
	return _cached_health_bonus


func get_magnet_bonus() -> float:
	if _cache_dirty:
		_update_cache()
	return _cached_magnet_bonus


func get_cooldown_reduction() -> float:
	if _cache_dirty:
		_update_cache()
	return _cached_cooldown_reduction


func _update_cache() -> void:
	if not SkillManager:
		_reset_cache()
		return

	# Reset to defaults
	_cached_damage_multiplier = 1.0
	_cached_attack_speed_multiplier = 1.0
	_cached_attack_size_multiplier = 1.0
	_cached_multi_hit_count = 1
	_cached_attack_directions = [0.0]
	_cached_health_bonus = 0
	_cached_magnet_bonus = 0.0
	_cached_cooldown_reduction = 0.0

	var levels_dict: Dictionary = SkillManager.get_character_skill_levels(character_id)

	for skill_id in levels_dict:
		var skill_data: SkillData = SkillManager.find_skill_in_trees(skill_id)
		if not skill_data:
			continue

		var current_level: int = levels_dict[skill_id]

		if skill_data.levels.size() > 0:
			# New leveled system: sum bonuses additively within skill
			var skill_damage: float = 1.0
			var skill_speed: float = 1.0
			var skill_size: float = 1.0

			for i in range(mini(current_level, skill_data.levels.size())):
				var ld = skill_data.levels[i]
				skill_damage += ld.damage_bonus
				skill_speed += ld.speed_bonus
				skill_size += ld.size_bonus
				_cached_cooldown_reduction += ld.cooldown_reduction
				_cached_health_bonus += ld.health_bonus
				_cached_magnet_bonus += ld.magnet_radius_bonus

				# Multi-hit: use the latest non-zero override
				if ld.multi_hit_count > 0:
					_cached_multi_hit_count = ld.multi_hit_count
				if ld.attack_directions.size() > 0:
					_cached_attack_directions = ld.attack_directions.duplicate()

			# Multiply this skill's contribution into the aggregate
			_cached_damage_multiplier *= skill_damage
			_cached_attack_speed_multiplier *= skill_speed
			_cached_attack_size_multiplier *= skill_size
		else:
			# Legacy fallback: use flat multipliers from SkillData
			_cached_damage_multiplier *= skill_data.damage_multiplier
			_cached_attack_speed_multiplier *= skill_data.attack_speed_multiplier
			_cached_attack_size_multiplier *= skill_data.attack_size_multiplier
			if skill_data.multi_hit_count > _cached_multi_hit_count:
				_cached_multi_hit_count = skill_data.multi_hit_count
				_cached_attack_directions = skill_data.attack_directions.duplicate()

	# Clamp cooldown reduction to prevent negative cooldowns
	_cached_cooldown_reduction = clampf(_cached_cooldown_reduction, 0.0, 0.9)

	_cache_dirty = false


func _reset_cache() -> void:
	_cached_damage_multiplier = 1.0
	_cached_attack_speed_multiplier = 1.0
	_cached_attack_size_multiplier = 1.0
	_cached_multi_hit_count = 1
	_cached_attack_directions = [0.0]
	_cached_health_bonus = 0
	_cached_magnet_bonus = 0.0
	_cached_cooldown_reduction = 0.0
	_cache_dirty = false


func force_update() -> void:
	_cache_dirty = true
	_update_cache()
