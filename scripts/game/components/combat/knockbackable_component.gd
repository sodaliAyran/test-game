class_name KnockbackableComponent
extends Node

## Component that manages the "knockbackable" state when enemy health reaches zero.
## Triggers transition to Stunned state, which handles the knockback/recovery flow.

signal became_knockbackable
signal recovered

@export var health: HealthComponent
@export var state_machine: Node  # NodeStateMachine - for transitioning to Stunned state
@export var recovery_health_percent: float = 1.0

var is_knockbackable: bool = false


func _ready() -> void:
	if health:
		health.health_depleted.connect(_on_health_depleted)


func _on_health_depleted() -> void:
	if not is_knockbackable:
		is_knockbackable = true

		# Transition to Stunned state immediately
		if state_machine:
			state_machine.transition_to("Stunned")

		became_knockbackable.emit()


func recover() -> void:
	is_knockbackable = false
	if health:
		var max_hp = health.max_health
		health.current_health = int(max_hp * recovery_health_percent)
		health.health_changed.emit(health.current_health, max_hp)
	recovered.emit()
