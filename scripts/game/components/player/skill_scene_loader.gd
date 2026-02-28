class_name SkillSceneLoader
extends Node

## Dynamically instantiates skill scenes when skills are acquired.
## Listens to SkillManager.skill_changed and adds skill scene nodes
## as children of the parent entity (e.g., Warrior).

## Skills to auto-unlock at game start (instantiated immediately)
@export var starting_skills: Array[String] = []

var _instantiated_skills: Dictionary = {}  # skill_id -> Node


func _ready() -> void:
	SkillManager.skill_changed.connect(_on_skill_changed)
	SkillManager.skills_reset.connect(_on_skills_reset)

	# Defer startup to ensure the full scene tree is ready
	await get_tree().process_frame

	# Auto-unlock starting skills
	for skill_id in starting_skills:
		SkillManager.acquire_skill(skill_id)

	# Load scenes for any already-unlocked skills
	for skill_id in SkillManager.get_unlocked_skills():
		_try_instantiate(skill_id)


func _on_skill_changed(skill_id: String, new_level: int) -> void:
	if new_level == 1:
		_try_instantiate(skill_id)


func _on_skills_reset() -> void:
	for skill_id in _instantiated_skills.keys():
		var node: Node = _instantiated_skills[skill_id]
		if is_instance_valid(node):
			node.queue_free()
	_instantiated_skills.clear()


func _try_instantiate(skill_id: String) -> void:
	if _instantiated_skills.has(skill_id):
		return

	var skill_data: SkillData = SkillManager.find_skill_in_trees(skill_id)
	if not skill_data or skill_data.scene_path.is_empty():
		return

	if not ResourceLoader.exists(skill_data.scene_path):
		push_warning("SkillSceneLoader: Scene not found: %s" % skill_data.scene_path)
		return

	var scene: PackedScene = load(skill_data.scene_path)
	var instance: Node = scene.instantiate()
	get_parent().add_child(instance)
	_instantiated_skills[skill_id] = instance
