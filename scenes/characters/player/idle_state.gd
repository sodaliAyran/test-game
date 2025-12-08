extends  NodeState

@export var movement: MovementComponent
@onready var player_input: PlayerInputComponent = %PlayerInputComponent

func _on_process(_delta : float) -> void:	
	if player_input.is_movement_input():
		transition.emit("Move")

func _on_physics_process(_delta : float) -> void:
	pass

func _on_next_transitions() -> void:
	pass

func _on_enter() -> void:
	pass


func _on_exit() -> void:
	pass
