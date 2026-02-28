extends Node

## Registry for skill cooldown components so HUD can track them.
## Bridges skill scene nodes and the HUD which are in different parts of the scene tree.

signal skill_registered(skill_id: String, cooldown: SkillCooldownComponent)
signal skill_unregistered(skill_id: String)

var _cooldowns: Dictionary = {}


func register(skill_id: String, cooldown: SkillCooldownComponent) -> void:
	_cooldowns[skill_id] = cooldown
	skill_registered.emit(skill_id, cooldown)


func unregister(skill_id: String) -> void:
	_cooldowns.erase(skill_id)
	skill_unregistered.emit(skill_id)


func get_cooldown(skill_id: String) -> SkillCooldownComponent:
	return _cooldowns.get(skill_id, null)


func get_all() -> Dictionary:
	return _cooldowns
