class_name SkillData
extends Resource

## Defines a single skill in the skill tree

@export var skill_id: String = ""
@export var skill_name: String = ""
@export_multiline var description: String = ""
@export var icon_path: String = ""

## Stat modifiers (multiplicative, 1.0 = no change)
@export var damage_multiplier: float = 1.0
@export var attack_speed_multiplier: float = 1.0
@export var attack_size_multiplier: float = 1.0

## Multi-hit configuration
@export var multi_hit_count: int = 1
@export var attack_directions: Array[float] = [0.0]  # Angles in degrees

## Prerequisites
@export var required_skills: Array[String] = []


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
