extends Node

## Singleton managing skill progression across the game

signal skill_changed(skill_id: String, new_level: int)
signal skills_reset()

var _skill_levels: Dictionary = {}    # character_id -> { skill_id: int }
var _skill_trees: Dictionary = {}     # tree_name -> SkillTree
var _path_affinity: Dictionary = {}   # character_id -> { tag: float }

# Passive cache for enemy components to query without exports
var _passive_cache: Dictionary = {}   # key -> value
var _passive_dirty: bool = true


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


## Get all registered tree names
func get_tree_names() -> Array[String]:
	var names: Array[String] = []
	for key in _skill_trees.keys():
		names.append(key)
	return names


## Acquire a skill (unlock at level 1 or level up by 1)
func acquire_skill(skill_id: String, character_id: String = "player") -> bool:
	var skill_data: SkillData = find_skill_in_trees(skill_id)
	if not skill_data:
		push_error("SkillManager: Unknown skill ID '%s'" % skill_id)
		return false

	if not _skill_levels.has(character_id):
		_skill_levels[character_id] = {}

	var levels: Dictionary = _skill_levels[character_id]
	var current_level: int = levels.get(skill_id, 0)

	# Check max level
	if current_level >= skill_data.max_level:
		push_warning("SkillManager: Skill '%s' already at max level %d" % [skill_id, skill_data.max_level])
		return false

	# Check prerequisites only for first acquisition
	if current_level == 0:
		for required_id in skill_data.required_skills:
			if levels.get(required_id, 0) == 0:
				push_error("SkillManager: Cannot acquire '%s' - requires '%s' first" % [skill_id, required_id])
				return false

	levels[skill_id] = current_level + 1
	_passive_dirty = true

	# Update path affinity
	_update_path_affinity(skill_data, character_id)

	skill_changed.emit(skill_id, current_level + 1)
	print("SkillManager: Skill '%s' now level %d for '%s'" % [skill_id, current_level + 1, character_id])
	return true


## Get the current level of a skill (0 = not owned)
func get_skill_level(skill_id: String, character_id: String = "player") -> int:
	if not _skill_levels.has(character_id):
		return 0
	return _skill_levels[character_id].get(skill_id, 0)


## Check if a skill is unlocked (level >= 1) - backward compatible
func is_skill_unlocked(skill_id: String, character_id: String = "player") -> bool:
	return get_skill_level(skill_id, character_id) > 0


## Check if any skill grants a specific feature flag at its current level
func has_feature(feature_flag: String, character_id: String = "player") -> bool:
	if not _skill_levels.has(character_id):
		return false

	var levels: Dictionary = _skill_levels[character_id]
	for sid in levels:
		var skill_data = find_skill_in_trees(sid)
		if not skill_data:
			continue
		var current_level: int = levels[sid]
		for i in range(mini(current_level, skill_data.levels.size())):
			if feature_flag in skill_data.levels[i].feature_flags:
				return true
	return false


## Get all active feature flags
func get_all_active_features(character_id: String = "player") -> Array[String]:
	var features: Array[String] = []
	if not _skill_levels.has(character_id):
		return features

	var levels: Dictionary = _skill_levels[character_id]
	for sid in levels:
		var skill_data = find_skill_in_trees(sid)
		if not skill_data:
			continue
		var current_level: int = levels[sid]
		for i in range(mini(current_level, skill_data.levels.size())):
			for flag in skill_data.levels[i].feature_flags:
				if flag not in features:
					features.append(flag)
	return features


## Get all unlocked skill IDs - backward compatible
func get_unlocked_skills(character_id: String = "player") -> Array[String]:
	var result: Array[String] = []
	if not _skill_levels.has(character_id):
		return result
	var levels: Dictionary = _skill_levels[character_id]
	for sid in levels:
		if levels[sid] > 0:
			result.append(sid)
	return result


## Get all unlocked SkillData objects - backward compatible
func get_unlocked_skill_data(character_id: String = "player") -> Array[SkillData]:
	var unlocked_ids = get_unlocked_skills(character_id)
	var result: Array[SkillData] = []
	for sid in unlocked_ids:
		var skill = find_skill_in_trees(sid)
		if skill:
			result.append(skill)
	return result


## Get the skill levels dictionary for a character
func get_character_skill_levels(character_id: String = "player") -> Dictionary:
	return _skill_levels.get(character_id, {})


## Get path affinity for a character
func get_path_affinity(character_id: String = "player") -> Dictionary:
	return _path_affinity.get(character_id, {})


## Reset all skills for a character
func reset_skills(character_id: String = "player") -> void:
	_skill_levels[character_id] = {}
	_path_affinity[character_id] = {}
	_passive_dirty = true
	skills_reset.emit()
	print("SkillManager: Reset all skills for '%s'" % character_id)


## Backward-compatible unlock (acquires at level 1)
func unlock_skill(skill_id: String, character_id: String = "player") -> bool:
	if is_skill_unlocked(skill_id, character_id):
		push_warning("SkillManager: Skill '%s' already unlocked for '%s'" % [skill_id, character_id])
		return false
	return acquire_skill(skill_id, character_id)


# --- Passive cache for enemy components ---

## Get a passive float bonus by key (used by enemy components)
func get_passive_float(key: String, character_id: String = "player") -> float:
	if _passive_dirty:
		_rebuild_passive_cache(character_id)
	return _passive_cache.get(key, 0.0)


## Get a passive int bonus by key (used by enemy components)
func get_passive_int(key: String, character_id: String = "player") -> int:
	if _passive_dirty:
		_rebuild_passive_cache(character_id)
	return int(_passive_cache.get(key, 0))


func _rebuild_passive_cache(character_id: String) -> void:
	_passive_cache.clear()
	var drop_chance_bonus: float = 0.0
	var extra_drops: int = 0
	var stun_duration_bonus: float = 0.0
	var down_duration_bonus: float = 0.0

	if _skill_levels.has(character_id):
		var levels: Dictionary = _skill_levels[character_id]
		for sid in levels:
			var skill_data = find_skill_in_trees(sid)
			if not skill_data:
				continue
			var current_level: int = levels[sid]
			for i in range(mini(current_level, skill_data.levels.size())):
				var ld: SkillLevelData = skill_data.levels[i]
				drop_chance_bonus += ld.drop_chance_bonus
				extra_drops += ld.extra_drops
				stun_duration_bonus += ld.stun_duration_bonus
				down_duration_bonus += ld.down_duration_bonus

	_passive_cache["drop_chance_bonus"] = drop_chance_bonus
	_passive_cache["extra_drops"] = extra_drops
	_passive_cache["stun_duration_bonus"] = stun_duration_bonus
	_passive_cache["down_duration_bonus"] = down_duration_bonus
	_passive_dirty = false


# --- Internal helpers ---

## Find a skill across all registered trees
func find_skill_in_trees(skill_id: String) -> SkillData:
	for tree in _skill_trees.values():
		var skill = tree.get_skill_by_id(skill_id)
		if skill:
			return skill
	return null


func _update_path_affinity(skill_data: SkillData, character_id: String) -> void:
	if not _path_affinity.has(character_id):
		_path_affinity[character_id] = {}

	var affinity: Dictionary = _path_affinity[character_id]
	for tag in skill_data.path_tags:
		affinity[tag] = affinity.get(tag, 0.0) + 0.2


## DEBUG: Unlock all skills in a tree to max level
func debug_unlock_all(tree_name: String, character_id: String = "player") -> void:
	var tree = get_skill_tree(tree_name)
	if not tree:
		push_error("SkillManager: Unknown tree '%s'" % tree_name)
		return

	var sorted_skills = _topological_sort_skills(tree.skills)

	for skill in sorted_skills:
		for lvl in range(skill.max_level):
			acquire_skill(skill.skill_id, character_id)

	print("SkillManager: DEBUG - Maxed all skills in '%s'" % tree_name)


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

	for required_id in skill.required_skills:
		for other_skill in all_skills:
			if other_skill.skill_id == required_id:
				_visit_skill(other_skill, all_skills, visited, sorted)
				break

	sorted.append(skill)
