extends NodeState

## Enemy hurt state that plays hurt animation then returns to previous state.

@export var hurt_animation: HurtStaggerAnimationComponent
@export var hurtbox: HurtboxComponent
@export var return_state: String = "Chase"

func _on_enter() -> void:
	if hurt_animation:
		hurt_animation.play()

func _on_process(_delta: float) -> void:
	pass

func _on_physics_process(_delta: float) -> void:
	pass

func _on_next_transitions() -> void:
	if hurt_animation and hurt_animation.is_finished():
		transition.emit(return_state)

func _on_exit() -> void:
	if hurt_animation:
		hurt_animation.stop()
