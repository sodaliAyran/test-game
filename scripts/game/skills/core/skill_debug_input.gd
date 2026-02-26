extends Node

## Debug helper to level up skills with number keys.
## Each press increases the skill by 1 level.

func _ready() -> void:
	print("SkillDebugInput: Press 1-8 to level skills, 0 to reset, 9 to max all")


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_1:
			_level_up_skill("sword_slash")
		KEY_2:
			_level_up_skill("punch")
		KEY_3:
			_level_up_skill("vitality")
		KEY_4:
			_level_up_skill("magnetism")
		KEY_5:
			_level_up_skill("looter")
		KEY_6:
			_level_up_skill("stunning_blows")
		KEY_7:
			_level_up_skill("heavy_hits")
		KEY_8:
			_level_up_skill("swift_cooldown")
		KEY_0:
			SkillManager.reset_skills()
			print("DEBUG: Reset all skills")
		KEY_9:
			SkillManager.debug_unlock_all("warrior")
			print("DEBUG: Maxed ALL skills")


func _level_up_skill(skill_id: String) -> void:
	var current = SkillManager.get_skill_level(skill_id)
	if SkillManager.acquire_skill(skill_id):
		print("DEBUG: %s -> level %d" % [skill_id, current + 1])
	else:
		var skill = SkillManager.find_skill_in_trees(skill_id)
		if skill and current >= skill.max_level:
			print("DEBUG: %s already at max level %d" % [skill_id, skill.max_level])
		else:
			print("DEBUG: Failed to level up %s" % skill_id)
