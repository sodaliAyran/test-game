class_name KillTrackerComponent
extends Node

## Lightweight component that tracks when an entity dies
## and reports it to the GameStats manager

@export var health: HealthComponent

func _ready() -> void:
	if health:
		health.died.connect(_on_died)
	else:
		push_warning("KillTrackerComponent: health not set")

func _on_died() -> void:
	"""Called when the entity dies."""
	if GameStats:
		GameStats.increment_kills()
