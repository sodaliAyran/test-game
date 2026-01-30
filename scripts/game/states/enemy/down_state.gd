extends NodeState

## State where enemy is knocked down after taking damage.
## Enemy remains on the ground for a duration before getting back up.
## Can be triggered by any system via set_knockback_direction() + transition.emit("Down")

@export var down_animation: DownAnimationComponent
@export var hurtbox: HurtboxComponent
@export var health: HealthComponent

var knockback_direction: Vector2 = Vector2.ZERO

func set_knockback_direction(direction: Vector2) -> void:
	"""Called before transitioning to pass knockback direction for animation."""
	knockback_direction = direction

func _on_enter() -> void:
	_connect_health()

	if down_animation:
		down_animation.play(knockback_direction)

func _on_process(_delta: float) -> void:
	pass

func _on_physics_process(_delta: float) -> void:
	pass

func _on_next_transitions() -> void:
	if down_animation and down_animation.is_finished():
		if _should_flee():
			transition.emit("Flee")
		else:
			transition.emit("Chase")

func _on_exit() -> void:
	if down_animation:
		down_animation.stop()
	_disconnect_health()
	knockback_direction = Vector2.ZERO

func _connect_health() -> void:
	if health and not health.died.is_connected(_on_death):
		health.died.connect(_on_death)

func _on_death() -> void:
	transition.emit("Death")

func _disconnect_health() -> void:
	if health and health.died.is_connected(_on_death):
		health.died.disconnect(_on_death)

func _should_flee() -> bool:
	# Check NemesisComponent for CowardTrait's is_fleeing flag
	var nemesis = owner.get_node_or_null("NemesisComponent")
	if nemesis:
		for trait_data in nemesis.traits:
			if trait_data is CowardTrait:
				var data = trait_data._get_data(owner)
				return data.get("is_fleeing", false)
	return false
