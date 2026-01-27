extends CharacterBody2D

## Warrior player character

@onready var facing: FacingComponent = $FacingComponent


func _ready() -> void:
	# Register with CircleSlotManager so enemies can position around us
	var slot_manager = get_node_or_null("/root/CircleSlotManager")
	if slot_manager:
		slot_manager.register_target(self)


func _exit_tree() -> void:
	# Unregister from CircleSlotManager
	var slot_manager = get_node_or_null("/root/CircleSlotManager")
	if slot_manager:
		slot_manager.unregister_target(self)
