class_name TraitRequest
extends RefCounted

## Communication object between traits and arbiter

var nemesis_trait  # NemesisTraitData - untyped to avoid circular dependency
var priority: int
var can_execute_parallel: bool
var context: Dictionary

func _init(p_trait = null, p_priority: int = 0, p_parallel: bool = false, p_context: Dictionary = {}) -> void:
	nemesis_trait = p_trait
	priority = p_priority
	can_execute_parallel = p_parallel
	context = p_context
