extends Node

## Debug helper to unlock skills with number keys

func _ready() -> void:
	print("SkillDebugInput: Press 1-7 to unlock skills, 0 to reset")


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	
	var key_event = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	
	match key_event.keycode:
		KEY_1:
			SkillManager.unlock_skill("swift_strike")
			print("DEBUG: Unlocked Swift Strike (+20% attack speed)")
		KEY_2:
			SkillManager.unlock_skill("power_strike")
			print("DEBUG: Unlocked Power Strike (+30% damage)")
		KEY_3:
			SkillManager.unlock_skill("wide_slash")
			print("DEBUG: Unlocked Wide Slash (+40% attack size)")
		KEY_4:
			if SkillManager.unlock_skill("double_strike"):
				print("DEBUG: Unlocked Double Strike (2 hits)")
			else:
				print("DEBUG: Failed - Double Strike requires Swift Strike (press 1 first)")
		KEY_5:
			if SkillManager.unlock_skill("triple_strike"):
				print("DEBUG: Unlocked Triple Strike (3 hits)")
			else:
				print("DEBUG: Failed - Triple Strike requires Double Strike (press 4 first)")
		KEY_6:
			if SkillManager.unlock_skill("whirlwind_strike"):
				print("DEBUG: Unlocked Whirlwind Strike (4 hits)")
			else:
				print("DEBUG: Failed - Whirlwind Strike requires Triple Strike (press 5 first)")
		KEY_7:
			if SkillManager.unlock_skill("devastating_blow"):
				print("DEBUG: Unlocked Devastating Blow (+50% damage)")
			else:
				print("DEBUG: Failed - Devastating Blow requires Power Strike (press 2 first)")
		KEY_0:
			SkillManager.reset_skills()
			print("DEBUG: Reset all skills")
		KEY_9:
			SkillManager.debug_unlock_all("warrior")
			print("DEBUG: Unlocked ALL skills")
