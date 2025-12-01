extends  NodeState

@export var animation: AnimationComponent

func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	pass


func _on_next_transitions() -> void:
	if animation.is_finished("attack"):
		transition.emit("Idle")

func _on_enter() -> void:
	animation.play("attack")


func _on_exit() -> void:
	animation.stop_if("attack")
