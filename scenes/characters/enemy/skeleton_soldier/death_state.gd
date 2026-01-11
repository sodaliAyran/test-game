extends NodeState

@export var collision_shapes: Array[CollisionShape2D]
@export var death_animation: DeathAnimationComponent

func _on_process(_delta : float) -> void:
	pass

func _on_physics_process(_delta : float) -> void:
	pass

func _on_next_transitions() -> void:
	pass

func _on_enter() -> void:
	owner.velocity = Vector2.ZERO
	
	for shape in collision_shapes:
		shape.disabled = true
	
	if death_animation:
		death_animation.play_death_animation()
	
func _on_exit() -> void:
	pass
