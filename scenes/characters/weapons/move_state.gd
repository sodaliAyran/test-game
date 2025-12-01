extends  NodeState

@export var animation: AnimationComponent
@export var movement: MovementComponent
@onready var player_input: PlayerInputComponent = %PlayerInputComponent

func _on_process(_delta : float) -> void:
	var direction = player_input.movement_direction
	movement.set_velocity(direction)

func _on_physics_process(_delta : float) -> void:
	pass


func _on_next_transitions() -> void:
	if not player_input.is_movement_input():
		transition.emit("Idle")


func _on_enter() -> void:
	pass


func _on_exit() -> void:
	movement.stop()
