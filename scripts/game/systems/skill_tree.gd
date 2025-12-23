class_name SkillTree
extends Resource

## Container for all skills in a skill tree

@export var tree_name: String = ""
@export var skills: Array[SkillData] = []


func _init(p_tree_name: String = "") -> void:
	tree_name = p_tree_name


func add_skill(skill: SkillData) -> void:
	if not skills.has(skill):
		skills.append(skill)


func get_skill_by_id(skill_id: String) -> SkillData:
	for skill in skills:
		if skill.skill_id == skill_id:
			return skill
	return null


func validate_prerequisites(unlocked_skill_ids: Array[String]) -> bool:
	"""Validate that all prerequisites are met for unlocked skills"""
	for skill_id in unlocked_skill_ids:
		var skill = get_skill_by_id(skill_id)
		if not skill:
			push_warning("SkillTree: Unknown skill ID '%s'" % skill_id)
			return false
		
		for required_id in skill.required_skills:
			if not unlocked_skill_ids.has(required_id):
				push_warning("SkillTree: Skill '%s' requires '%s' but it's not unlocked" % [skill_id, required_id])
				return false
	
	return true


func get_all_skill_ids() -> Array[String]:
	var ids: Array[String] = []
	for skill in skills:
		ids.append(skill.skill_id)
	return ids
