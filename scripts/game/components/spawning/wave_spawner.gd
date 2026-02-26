class_name WaveSpawner
extends Node2D

## Schedule-driven enemy spawner. Assign a SpawnSchedule resource to control
## what spawns, when, and how many. Reusable across any scene.

signal enemy_spawned(enemy: Node2D)
signal schedule_completed()

@export var schedule: SpawnSchedule
@export var auto_start: bool = true
## Maximum simultaneous enemies. Schedule pauses (not skips) when at cap.
@export var max_enemies: int = 18

var elapsed_time: float = 0.0
var is_running: bool = false
var active_enemies: Array[Node2D] = []
var spawn_points: Array[Marker2D] = []

var _sorted_entries: Array[SpawnScheduleEntry] = []
var _schedule_index: int = 0

# Stagger state for multi-count entries
var _stagger_entry: SpawnScheduleEntry = null
var _stagger_spawned: int = 0
var _stagger_timer: float = 0.0


func _ready() -> void:
	_collect_spawn_points()
	if schedule:
		_sorted_entries = schedule.get_sorted_entries()
	if auto_start:
		call_deferred("start")


func _process(delta: float) -> void:
	if not is_running:
		return
	elapsed_time += delta
	_process_stagger(delta)
	_process_schedule()


func _process_schedule() -> void:
	# Don't advance schedule while staggering a batch
	if _stagger_entry != null:
		return

	while _schedule_index < _sorted_entries.size():
		var entry := _sorted_entries[_schedule_index]
		if elapsed_time < entry.time:
			break

		if active_enemies.size() >= max_enemies:
			break

		if entry.count <= 1 or entry.stagger <= 0.0:
			for i in range(entry.count):
				_spawn_enemy(entry.enemy_scene)
			_schedule_index += 1
		else:
			_start_stagger(entry)
			_schedule_index += 1
			break

	if _schedule_index >= _sorted_entries.size() and _stagger_entry == null:
		if is_running:
			is_running = false
			schedule_completed.emit()


func _start_stagger(entry: SpawnScheduleEntry) -> void:
	_stagger_entry = entry
	_stagger_spawned = 1
	_stagger_timer = 0.0
	_spawn_enemy(entry.enemy_scene)


func _process_stagger(delta: float) -> void:
	if _stagger_entry == null:
		return
	_stagger_timer += delta
	while _stagger_timer >= _stagger_entry.stagger and _stagger_spawned < _stagger_entry.count:
		_stagger_timer -= _stagger_entry.stagger
		_spawn_enemy(_stagger_entry.enemy_scene)
		_stagger_spawned += 1
	if _stagger_spawned >= _stagger_entry.count:
		_stagger_entry = null


func _spawn_enemy(scene: PackedScene) -> void:
	if not scene or spawn_points.is_empty():
		return
	var spawn_point := spawn_points.pick_random() as Marker2D
	var enemy := scene.instantiate() as Node2D
	enemy.global_position = spawn_point.global_position
	get_parent().add_child(enemy)
	active_enemies.append(enemy)
	if enemy.has_signal("tree_exiting"):
		enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))
	enemy_spawned.emit(enemy)


func _on_enemy_removed(enemy: Node2D) -> void:
	active_enemies.erase(enemy)


func _collect_spawn_points() -> void:
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
	if spawn_points.is_empty():
		push_warning("WaveSpawner: No spawn points found! Add Marker2D children.")


# --- Public API ---

func start() -> void:
	if _sorted_entries.is_empty() and schedule:
		_sorted_entries = schedule.get_sorted_entries()
	is_running = true


func stop() -> void:
	is_running = false


func reset() -> void:
	stop()
	elapsed_time = 0.0
	_schedule_index = 0
	_stagger_entry = null
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()


func get_active_enemy_count() -> int:
	return active_enemies.size()


func get_elapsed_time() -> float:
	return elapsed_time
