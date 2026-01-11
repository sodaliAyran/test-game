class_name SpawnTimeline
extends Resource

## Container for all spawn events in a timeline

@export var timeline_name: String = "Default Timeline"
@export var spawn_events: Array[SpawnEvent] = []
@export var timeline_duration: float = 0.0  # 0 = infinite, auto-calculated if not set

func _init() -> void:
	# Auto-calculate timeline duration if not set
	if timeline_duration == 0.0 and not spawn_events.is_empty():
		_calculate_duration()

func _calculate_duration() -> void:
	var max_time: float = 0.0
	for event in spawn_events:
		if event is ContinuousSpawnEvent:
			max_time = max(max_time, event.end_time)
		elif event is BurstSpawnEvent:
			max_time = max(max_time, event.trigger_time)
		else:
			max_time = max(max_time, event.trigger_time)
	timeline_duration = max_time

func get_sorted_events() -> Array[SpawnEvent]:
	"""Returns events sorted by trigger time."""
	var sorted = spawn_events.duplicate()
	sorted.sort_custom(func(a, b): return a.trigger_time < b.trigger_time)
	return sorted

func reset_all_events() -> void:
	"""Reset all events to their initial state."""
	for event in spawn_events:
		if event.has_method("reset"):
			event.reset()
