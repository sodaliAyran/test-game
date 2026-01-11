extends NodeState

@export var spawn_animation: SpawnAnimationComponent

func _on_enter() -> void:
	if spawn_animation:
		spawn_animation.spawn_complete.connect(_on_spawn_complete)
		spawn_animation.play_spawn()
	else:
		push_error("SpawnState: spawn_animation not set")
		transition.emit("Idle")

func _on_exit() -> void:
	if spawn_animation and spawn_animation.spawn_complete.is_connected(_on_spawn_complete):
		spawn_animation.spawn_complete.disconnect(_on_spawn_complete)

func _on_spawn_complete() -> void:
	transition.emit("Idle")

func _on_process(_delta: float) -> void:
	pass

func _on_physics_process(_delta: float) -> void:
	pass

func _on_next_transitions() -> void:
	pass
