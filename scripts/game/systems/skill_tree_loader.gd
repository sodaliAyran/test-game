extends Node

## Initializes the skill system by loading and registering skill trees

func _ready() -> void:
	# Wait for SkillManager to be ready
	await get_tree().process_frame
	
	# Load and register the warrior skill tree
	var warrior_tree = load("res://resources/skills/warrior_skill_tree.tres") as SkillTree
	
	if warrior_tree:
		SkillManager.register_skill_tree(warrior_tree)
		print("SkillTreeLoader: Registered warrior skill tree")
	else:
		push_error("SkillTreeLoader: Failed to load warrior skill tree")
