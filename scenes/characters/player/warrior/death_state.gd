extends NodeState

## Player death state - triggered when health reaches zero

@export var death_animation: DeathAnimationComponent
@export var collision_shapes: Array[CollisionShape2D] = []

signal player_died()


func _on_process(_delta: float) -> void:
	pass


func _on_physics_process(_delta: float) -> void:
	pass


func _on_next_transitions() -> void:
	# Death is final - no transitions out
	pass


func _on_enter() -> void:
	# Disable collision
	for shape in collision_shapes:
		if shape:
			shape.disabled = true
	
	# Play death animation
	if death_animation:
		death_animation.play_death_animation()
	
	# Emit signal for game over UI (future implementation)
	emit_signal("player_died")
	
	# Stop all movement
	if owner is CharacterBody2D:
		owner.velocity = Vector2.ZERO


func _on_exit() -> void:
	# Death state is not exited
	pass
