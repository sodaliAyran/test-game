class_name KnockbackableComponent
extends Node

## Component that manages the "knockbackable" state when enemy health reaches zero.
## Triggers transition to Stunned state, which handles the knockback/recovery flow.
## Tracks enemy level — enemies level up each time they recover from being downed (stomped).

signal became_knockbackable
signal stomped(direction: Vector2)
signal recovered
signal leveled_up(new_level: int)

@export var health: HealthComponent
@export var state_machine: Node  # NodeStateMachine - for transitioning to Stunned state
@export var recovery_health_percent: float = 1.0

@export_group("Level Scaling")
@export var max_level: int = 15
@export var health_growth_rate: float = 0.35  ## Health increase per level (35% of base per level)

var is_knockbackable: bool = false
var current_level: int = 1
var _base_max_health: int


func _ready() -> void:
	if health:
		_base_max_health = health.max_health
		health.health_depleted.connect(_on_health_depleted)


func _on_health_depleted() -> void:
	if not is_knockbackable:
		is_knockbackable = true

		# Transition to Stunned state immediately
		if state_machine:
			state_machine.transition_to("Stunned")

		became_knockbackable.emit()


func get_scaled_max_health() -> int:
	return int(_base_max_health + _base_max_health * (current_level - 1) * health_growth_rate)


func recover(should_level_up: bool = false) -> void:
	is_knockbackable = false

	if should_level_up and current_level < max_level:
		current_level += 1
		leveled_up.emit(current_level)

	if health:
		var max_hp = get_scaled_max_health()
		health.max_health = max_hp
		health.current_health = int(max_hp * recovery_health_percent)
		health.health_changed.emit(health.current_health, max_hp)

	recovered.emit()
