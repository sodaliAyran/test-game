class_name NemesisTraitData
extends Resource

## Base class for all nemesis traits
## Traits connect to signals and call arbiter when they want to trigger

@export var trait_name: String = "Unnamed Trait"
@export var priority: int = 50  # Higher = executes first
@export var can_execute_parallel: bool = false  # Can run alongside other traits

## Called when trait is added to NemesisComponent
## Traits should connect to signals here
func setup(owner: Node, arbiter: NemesisArbiter) -> void:
	pass

## Called when trait wants to execute
## Should be called from signal handlers
func execute(context: Dictionary) -> void:
	pass

## Called when trait is removed or owner is freed
## Disconnect signals here
func cleanup() -> void:
	pass
