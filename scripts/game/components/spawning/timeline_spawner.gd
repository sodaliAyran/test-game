class_name TimelineSpawner
extends Node2D

## Executes a scripted spawn timeline with precise control over spawn events

signal enemy_spawned(enemy: Node2D, event_name: String)
signal event_started(event_name: String, trigger_time: float)
signal event_completed(event_name: String)
signal timeline_started()
signal timeline_completed()

@export var spawn_timeline: SpawnTimeline
@export var auto_start: bool = true
@export var loop_timeline: bool = false
@export var debug_mode: bool = false

var elapsed_time: float = 0.0
var is_running: bool = false
var active_events: Array[SpawnEvent] = []
var completed_events: Array[SpawnEvent] = []
var spawn_points: Array[Marker2D] = []
var active_enemies: Array[Node2D] = []

func _ready() -> void:
	_collect_spawn_points()
	
	if auto_start:
		call_deferred("start_timeline")

func _collect_spawn_points() -> void:
	"""Collect all Marker2D children as spawn points."""
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
	
	if spawn_points.is_empty():
		push_warning("TimelineSpawner: No spawn points found! Add Marker2D children.")

func _process(delta: float) -> void:
	if not is_running or not spawn_timeline:
		return
	
	elapsed_time += delta
	
	# Process all events
	_process_events()
	
	# Check if timeline is complete
	if _is_timeline_complete():
		_on_timeline_complete()

func _process_events() -> void:
	"""Process all spawn events based on elapsed time."""
	if not spawn_timeline:
		return
	
	for event in spawn_timeline.spawn_events:
		# Check if event should start
		if not active_events.has(event) and not completed_events.has(event):
			if elapsed_time >= event.trigger_time:
				_start_event(event)
		
		# Execute active events
		if active_events.has(event):
			event.execute(self, elapsed_time)
			
			# Check if event is no longer active
			if not event.is_active(elapsed_time):
				_complete_event(event)

func _start_event(event: SpawnEvent) -> void:
	"""Mark an event as started."""
	active_events.append(event)
	event_started.emit(event.event_name, event.trigger_time)
	
	if debug_mode:
		print("TimelineSpawner: Event started - %s at %.1fs" % [event.event_name, elapsed_time])

func _complete_event(event: SpawnEvent) -> void:
	"""Mark an event as completed."""
	active_events.erase(event)
	completed_events.append(event)
	event_completed.emit(event.event_name)
	
	if debug_mode:
		print("TimelineSpawner: Event completed - %s at %.1fs" % [event.event_name, elapsed_time])

func _is_timeline_complete() -> bool:
	"""Check if the timeline has finished."""
	if not spawn_timeline:
		return true
	
	# If timeline has a duration, check if we've exceeded it
	if spawn_timeline.timeline_duration > 0.0 and elapsed_time >= spawn_timeline.timeline_duration:
		return active_events.is_empty()
	
	# Otherwise, check if all events are completed
	return completed_events.size() == spawn_timeline.spawn_events.size() and active_events.is_empty()

func _on_timeline_complete() -> void:
	"""Called when the timeline completes."""
	timeline_completed.emit()
	
	if debug_mode:
		print("TimelineSpawner: Timeline completed at %.1fs" % elapsed_time)
	
	if loop_timeline:
		restart_timeline()
	else:
		stop_timeline()

func _spawn_enemy(enemy_scene: PackedScene) -> void:
	"""Spawn an enemy at a random spawn point."""
	if not enemy_scene:
		push_error("TimelineSpawner: No enemy scene provided!")
		return
	
	if spawn_points.is_empty():
		push_error("TimelineSpawner: No spawn points available!")
		return
	
	# Pick random spawn point
	var spawn_point = spawn_points.pick_random()
	
	# Instantiate enemy
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_point.global_position
	
	# Add to scene tree (parent to avoid being child of spawner)
	get_parent().add_child(enemy)
	
	# Track enemy
	active_enemies.append(enemy)
	
	# Connect to enemy removal
	if enemy.has_signal("tree_exiting"):
		enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))
	
	# Emit signal
	var event_name = _get_current_event_name()
	enemy_spawned.emit(enemy, event_name)
	
	if debug_mode:
		print("TimelineSpawner: Spawned enemy at %.1fs" % elapsed_time)

func _get_current_event_name() -> String:
	"""Get the name of the currently active event."""
	if not active_events.is_empty():
		return active_events[0].event_name
	return "Unknown"

func _on_enemy_removed(enemy: Node2D) -> void:
	"""Called when an enemy is removed from the scene."""
	active_enemies.erase(enemy)

## Public API

func start_timeline() -> void:
	"""Start or resume the timeline."""
	if not spawn_timeline:
		push_error("TimelineSpawner: No spawn timeline assigned!")
		return
	
	is_running = true
	timeline_started.emit()
	
	if debug_mode:
		print("TimelineSpawner: Timeline started - %s" % spawn_timeline.timeline_name)

func stop_timeline() -> void:
	"""Stop the timeline."""
	is_running = false

func pause_timeline() -> void:
	"""Pause the timeline."""
	is_running = false

func resume_timeline() -> void:
	"""Resume the timeline."""
	is_running = true

func restart_timeline() -> void:
	"""Restart the timeline from the beginning."""
	elapsed_time = 0.0
	active_events.clear()
	completed_events.clear()
	
	# Reset all events
	if spawn_timeline:
		spawn_timeline.reset_all_events()
	
	is_running = true
	timeline_started.emit()
	
	if debug_mode:
		print("TimelineSpawner: Timeline restarted")

func get_elapsed_time() -> float:
	"""Get the current elapsed time."""
	return elapsed_time

func get_active_enemy_count() -> int:
	"""Get the number of active enemies."""
	return active_enemies.size()

func is_timeline_running() -> bool:
	"""Check if the timeline is currently running."""
	return is_running
