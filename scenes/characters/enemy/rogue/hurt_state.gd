extends NodeState

@export var hurt_animation: HurtStaggerAnimationComponent

func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	pass


func _on_next_transitions() -> void:
	if hurt_animation and hurt_animation.is_finished():
		# Check if enemy should be fleeing (CowardTrait sets this)
		if _should_flee():
			transition.emit("Flee")
		else:
			transition.emit("Idle")

func _on_enter() -> void:
	if hurt_animation:
		hurt_animation.play()


func _on_exit() -> void:
	if hurt_animation:
		hurt_animation.stop()

func _should_flee() -> bool:
	# Check NemesisComponent for CowardTrait's is_fleeing flag
	var nemesis = owner.get_node_or_null("NemesisComponent")
	if nemesis:
		for trait_data in nemesis.traits:
			if trait_data is CowardTrait:
				var data = trait_data._get_data(owner)
				return data.get("is_fleeing", false)
	return false
