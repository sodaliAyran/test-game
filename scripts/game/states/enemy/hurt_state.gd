extends NodeState

## Enemy hurt state that plays hurt animation then transitions to Down state.
## Captures knockback direction to pass to the Down state.

@export var hurt_animation: HurtStaggerAnimationComponent
@export var hurtbox: HurtboxComponent

var _last_knockback_direction: Vector2 = Vector2.ZERO

func _on_enter() -> void:
	_last_knockback_direction = Vector2.ZERO
	_connect_hurtbox()
	if hurt_animation:
		hurt_animation.play()

func _on_process(_delta: float) -> void:
	pass

func _on_physics_process(_delta: float) -> void:
	pass

func _on_next_transitions() -> void:
	if hurt_animation and hurt_animation.is_finished():
		# Pass knockback direction to Down state before transitioning
		var down_state = get_parent().get_node_or_null("Down")
		if down_state and down_state.has_method("set_knockback_direction"):
			down_state.set_knockback_direction(_last_knockback_direction)
		transition.emit("Down")

func _on_exit() -> void:
	if hurt_animation:
		hurt_animation.stop()
	_disconnect_hurtbox()

func _connect_hurtbox() -> void:
	if hurtbox and not hurtbox.knocked.is_connected(_on_knocked):
		hurtbox.knocked.connect(_on_knocked)

func _on_knocked(direction: Vector2, _force: float) -> void:
	_last_knockback_direction = direction

func _disconnect_hurtbox() -> void:
	if hurtbox and hurtbox.knocked.is_connected(_on_knocked):
		hurtbox.knocked.disconnect(_on_knocked)
