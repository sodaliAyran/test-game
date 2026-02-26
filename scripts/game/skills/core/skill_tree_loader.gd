extends Node

## Loads skill trees from code factories and caches them as .tres resources.
## Bump TREE_VERSION when skill definitions change to invalidate cache.

const TREE_VERSION := 1

const WARRIOR_SKILLS := [
	preload("res://scripts/game/skills/warrior/sword_slash_skill.gd"),
	preload("res://scripts/game/skills/warrior/punch_skill.gd"),
	preload("res://scripts/game/skills/warrior/vitality_skill.gd"),
	preload("res://scripts/game/skills/warrior/magnetism_skill.gd"),
	preload("res://scripts/game/skills/warrior/looter_skill.gd"),
	preload("res://scripts/game/skills/warrior/stunning_blows_skill.gd"),
	preload("res://scripts/game/skills/warrior/heavy_hits_skill.gd"),
	preload("res://scripts/game/skills/warrior/swift_cooldown_skill.gd"),
]


func _ready() -> void:
	var tree := _load_or_build("warrior", WARRIOR_SKILLS)
	SkillManager.register_skill_tree(tree)


func _load_or_build(tree_name: String, skill_scripts: Array) -> SkillTree:
	var cache_path := "user://cache/%s_skill_tree_v%d.tres" % [tree_name, TREE_VERSION]

	# Try loading cached version
	if FileAccess.file_exists(cache_path):
		var cached := load(cache_path) as SkillTree
		if cached and cached.skills.size() > 0:
			print("SkillTreeLoader: Loaded cached '%s' (%d skills)" % [tree_name, cached.skills.size()])
			return cached

	# Build from factories
	var tree := SkillTree.new()
	tree.tree_name = tree_name
	for skill_script in skill_scripts:
		tree.add_skill(skill_script.create())

	# Cache for next launch
	DirAccess.make_dir_recursive_absolute("user://cache")
	var err := ResourceSaver.save(tree, cache_path)
	if err == OK:
		print("SkillTreeLoader: Built and cached '%s' (%d skills)" % [tree_name, tree.skills.size()])
	else:
		print("SkillTreeLoader: Built '%s' (%d skills) [cache save failed: %d]" % [tree_name, tree.skills.size(), err])

	return tree
