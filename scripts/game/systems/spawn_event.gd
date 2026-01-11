class_name SpawnEvent
extends Resource

## Base class for spawn events in a timeline

@export var event_name: String = ""
@export var trigger_time: float = 0.0  # When this event starts (seconds)

## Override this in subclasses to implement event logic
func execute(spawner: Node2D, elapsed_time: float) -> void:
	pass

## Override to check if event is still active
func is_active(elapsed_time: float) -> bool:
	return false
