class_name SkillData
extends Resource

## Defines a single skill in the skill tree

@export var skill_id: String = ""
@export var skill_name: String = ""
@export_multiline var description: String = ""
@export var icon_path: String = ""
@export var scene_path: String = ""

## Skill category for grouping/UI
@export_enum("melee", "ranged", "defensive", "passive", "utility") var category: String = "melee"

## Path tags for pseudo-random affinity (e.g., ["sword", "offense"])
@export var path_tags: Array[String] = []

## Maximum level this skill can reach
@export var max_level: int = 5

## Per-level data (index 0 = level 1, index 1 = level 2, etc.)
@export var levels: Array[SkillLevelData] = []

## Weight for appearing in offerings (higher = more likely base chance)
@export var base_weight: float = 1.0

## Prerequisites - skill_ids that must be unlocked (any level) before this appears
@export var required_skills: Array[String] = []

## Legacy stat modifiers (used when levels array is empty)
@export_group("Legacy Modifiers")
@export var damage_multiplier: float = 1.0
@export var attack_speed_multiplier: float = 1.0
@export var attack_size_multiplier: float = 1.0
@export var multi_hit_count: int = 1
@export var attack_directions: Array[float] = [0.0]


func _init(
	p_skill_id: String = "",
	p_skill_name: String = "",
	p_description: String = "",
	p_damage_mult: float = 1.0,
	p_attack_speed_mult: float = 1.0,
	p_attack_size_mult: float = 1.0,
	p_multi_hit: int = 1,
	p_directions: Array[float] = [0.0],
	p_required: Array[String] = []
) -> void:
	skill_id = p_skill_id
	skill_name = p_skill_name
	description = p_description
	damage_multiplier = p_damage_mult
	attack_speed_multiplier = p_attack_speed_mult
	attack_size_multiplier = p_attack_size_mult
	multi_hit_count = p_multi_hit
	attack_directions = p_directions if p_directions.size() > 0 else [0.0]
	required_skills = p_required


func has_prerequisites() -> bool:
	return required_skills.size() > 0


func get_level_data(level: int) -> SkillLevelData:
	var index = level - 1
	if index >= 0 and index < levels.size():
		return levels[index]
	return null


func get_modifier_summary() -> String:
	var parts: Array[String] = []

	if damage_multiplier != 1.0:
		var pct = int((damage_multiplier - 1.0) * 100)
		parts.append("%+d%% Damage" % pct)

	if attack_speed_multiplier != 1.0:
		var pct = int((attack_speed_multiplier - 1.0) * 100)
		parts.append("%+d%% Attack Speed" % pct)

	if attack_size_multiplier != 1.0:
		var pct = int((attack_size_multiplier - 1.0) * 100)
		parts.append("%+d%% Attack Size" % pct)

	if multi_hit_count > 1:
		parts.append("%d Hits" % multi_hit_count)

	return ", ".join(parts) if parts.size() > 0 else "No modifiers"


func get_level_modifier_summary(level: int) -> String:
	var ld = get_level_data(level)
	if not ld:
		return "No modifiers"

	var parts: Array[String] = []

	if ld.damage_bonus != 0.0:
		parts.append("%+d%% Damage" % int(ld.damage_bonus * 100))
	if ld.speed_bonus != 0.0:
		parts.append("%+d%% Attack Speed" % int(ld.speed_bonus * 100))
	if ld.size_bonus != 0.0:
		parts.append("%+d%% Attack Size" % int(ld.size_bonus * 100))
	if ld.cooldown_reduction != 0.0:
		parts.append("%+d%% Cooldown" % int(ld.cooldown_reduction * 100))
	if ld.health_bonus != 0:
		parts.append("+%d HP" % ld.health_bonus)
	if ld.magnet_radius_bonus != 0.0:
		parts.append("+%.0f Magnet Range" % ld.magnet_radius_bonus)
	if ld.drop_chance_bonus != 0.0:
		parts.append("+%d%% Drop Chance" % int(ld.drop_chance_bonus * 100))
	if ld.extra_drops != 0:
		parts.append("+%d Drops" % ld.extra_drops)
	if ld.stun_duration_bonus != 0.0:
		parts.append("+%.1fs Stun" % ld.stun_duration_bonus)
	if ld.down_duration_bonus != 0.0:
		parts.append("+%.1fs Down" % ld.down_duration_bonus)
	if ld.multi_hit_count > 0:
		parts.append("%d Hits" % ld.multi_hit_count)
	if ld.feature_flags.size() > 0:
		for flag in ld.feature_flags:
			parts.append(flag.replace("_", " ").capitalize())

	return ", ".join(parts) if parts.size() > 0 else "No modifiers"
