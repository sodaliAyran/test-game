extends Node

## Singleton managing skill progression across the game

signal skill_unlocked(skill_id: String)
signal skill_locked(skill_id: String)
signal skills_reset()

var _unlocked_skills: Dictionary = {}  # character_id -> Array[String]
var _skill_trees: Dictionary = {}  # tree_name -> SkillTree


func _ready() -> void:
	print("SkillManager: Initialized")


## Register a skill tree for use
func register_skill_tree(tree: SkillTree) -> void:
	if not tree:
		push_error("SkillManager: Cannot register null skill tree")
		return
	
	_skill_trees[tree.tree_name] = tree
	print("SkillManager: Registered skill tree '%s' with %d skills" % [tree.tree_name, tree.skills.size()])


## Get a registered skill tree by name
func get_skill_tree(tree_name: String) -> SkillTree:
	return _skill_trees.get(tree_name, null)


## Unlock a skill for a character
func unlock_skill(skill_id: String, character_id: String = "player") -> bool:
	if not _unlocked_skills.has(character_id):
		_unlocked_skills[character_id] = []
	
	var unlocked: Array = _unlocked_skills[character_id]
	
	if unlocked.has(skill_id):
		push_warning("SkillManager: Skill '%s' already unlocked for '%s'" % [skill_id, character_id])
		return false
	
	# Check prerequisites across all registered trees
	var skill_data: SkillData = _find_skill_in_trees(skill_id)
	if not skill_data:
		push_error("SkillManager: Unknown skill ID '%s'" % skill_id)
		return false
	
	# Verify prerequisites are met
	for required_id in skill_data.required_skills:
		if not unlocked.has(required_id):
			push_error("SkillManager: Cannot unlock '%s' - requires '%s' first" % [skill_id, required_id])
			return false
	
	unlocked.append(skill_id)
	skill_unlocked.emit(skill_id)
	print("SkillManager: Unlocked skill '%s' for '%s'" % [skill_id, character_id])
	return true


## Lock/remove a skill from a character
func lock_skill(skill_id: String, character_id: String = "player") -> bool:
	if not _unlocked_skills.has(character_id):
		return false
	
	var unlocked: Array = _unlocked_skills[character_id]
	var index = unlocked.find(skill_id)
	
	if index == -1:
		return false
	
	unlocked.remove_at(index)
	skill_locked.emit(skill_id)
	print("SkillManager: Locked skill '%s' for '%s'" % [skill_id, character_id])
	return true


## Check if a skill is unlocked
func is_skill_unlocked(skill_id: String, character_id: String = "player") -> bool:
	if not _unlocked_skills.has(character_id):
		return false
	return _unlocked_skills[character_id].has(skill_id)


## Get all unlocked skills for a character
func get_unlocked_skills(character_id: String = "player") -> Array[String]:
	if not _unlocked_skills.has(character_id):
		return []
	
	var result: Array[String] = []
	result.assign(_unlocked_skills[character_id])
	return result


## Get all unlocked SkillData objects for a character
func get_unlocked_skill_data(character_id: String = "player") -> Array[SkillData]:
	var unlocked_ids = get_unlocked_skills(character_id)
	var result: Array[SkillData] = []
	
	for skill_id in unlocked_ids:
		var skill = _find_skill_in_trees(skill_id)
		if skill:
			result.append(skill)
	
	return result


## Reset all skills for a character
func reset_skills(character_id: String = "player") -> void:
	_unlocked_skills[character_id] = []
	skills_reset.emit()
	print("SkillManager: Reset all skills for '%s'" % character_id)


## DEBUG: Unlock all skills in a tree
func debug_unlock_all(tree_name: String, character_id: String = "player") -> void:
	var tree = get_skill_tree(tree_name)
	if not tree:
		push_error("SkillManager: Unknown tree '%s'" % tree_name)
		return
	
	# Sort skills by prerequisites to unlock in correct order
	var sorted_skills = _topological_sort_skills(tree.skills)
	
	for skill in sorted_skills:
		unlock_skill(skill.skill_id, character_id)
	
	print("SkillManager: DEBUG - Unlocked all skills in '%s'" % tree_name)


## Find a skill across all registered trees
func _find_skill_in_trees(skill_id: String) -> SkillData:
	for tree in _skill_trees.values():
		var skill = tree.get_skill_by_id(skill_id)
		if skill:
			return skill
	return null


## Sort skills by prerequisites (topological sort)
func _topological_sort_skills(skills: Array[SkillData]) -> Array[SkillData]:
	var sorted: Array[SkillData] = []
	var visited: Dictionary = {}
	
	for skill in skills:
		_visit_skill(skill, skills, visited, sorted)
	
	return sorted


func _visit_skill(skill: SkillData, all_skills: Array[SkillData], visited: Dictionary, sorted: Array[SkillData]) -> void:
	if visited.has(skill.skill_id):
		return
	
	visited[skill.skill_id] = true
	
	# Visit prerequisites first
	for required_id in skill.required_skills:
		for other_skill in all_skills:
			if other_skill.skill_id == required_id:
				_visit_skill(other_skill, all_skills, visited, sorted)
				break
	
	sorted.append(skill)
