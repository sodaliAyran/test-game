class_name SkillOfferingService
extends RefCounted

## Generates weighted skill offerings for level-up choices.
## Uses pseudo-random path affinity to softly specialize.

const AFFINITY_BOOST: float = 1.5       ## Multiplier applied to affinity value per tag
const UPGRADE_WEIGHT_BONUS: float = 0.3  ## Extra weight for upgrading existing skills
const MIN_WEIGHT: float = 0.1            ## Floor weight so nothing is impossible


static func generate_offerings(count: int = 3, character_id: String = "player") -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var current_levels: Dictionary = SkillManager.get_character_skill_levels(character_id)
	var affinity: Dictionary = SkillManager.get_path_affinity(character_id)

	# Build candidate pool from all registered skill trees
	for tree_name in SkillManager.get_tree_names():
		var tree: SkillTree = SkillManager.get_skill_tree(tree_name)
		if not tree:
			continue

		for skill in tree.skills:
			var current_level: int = current_levels.get(skill.skill_id, 0)

			# Skip maxed skills
			if current_level >= skill.max_level:
				continue

			# Check prerequisites for new skills
			if current_level == 0 and not _prereqs_met(skill, current_levels):
				continue

			# Calculate weight
			var weight: float = skill.base_weight

			# Upgrade bonus for skills already owned
			if current_level > 0:
				weight += UPGRADE_WEIGHT_BONUS

			# Path affinity bonus
			for tag in skill.path_tags:
				weight += affinity.get(tag, 0.0) * AFFINITY_BOOST

			weight = maxf(weight, MIN_WEIGHT)

			candidates.append({
				"skill_data": skill,
				"target_level": current_level + 1,
				"weight": weight
			})

	# Weighted random selection without replacement
	var offerings: Array[Dictionary] = []
	for i in range(mini(count, candidates.size())):
		var selected = _weighted_pick(candidates)
		if selected.is_empty():
			break
		offerings.append(selected)
		candidates.erase(selected)

	return offerings


static func _prereqs_met(skill: SkillData, current_levels: Dictionary) -> bool:
	for required_id in skill.required_skills:
		if current_levels.get(required_id, 0) == 0:
			return false
	return true


static func _weighted_pick(candidates: Array[Dictionary]) -> Dictionary:
	if candidates.is_empty():
		return {}

	var total_weight: float = 0.0
	for c in candidates:
		total_weight += c.weight

	if total_weight <= 0.0:
		return candidates[0]

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for c in candidates:
		cumulative += c.weight
		if roll <= cumulative:
			return c

	return candidates.back()


