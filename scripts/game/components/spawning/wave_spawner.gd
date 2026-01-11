class_name WaveSpawner
extends Node2D

## Manages wave-based enemy spawning for arena/defense scenarios

signal wave_started(wave_number: int, enemy_count: int)
signal wave_completed(wave_number: int)
signal enemy_spawned(enemy: Node2D)
signal all_enemies_defeated()

@export var enemy_scene: PackedScene
@export var initial_enemy_count: int = 3
@export var enemies_per_wave_increase: int = 2
@export var wave_delay: float = 5.0
@export var spawn_interval: float = 0.5
@export var auto_start: bool = true

var current_wave: int = 0
var enemies_to_spawn: int = 0
var active_enemies: Array[Node2D] = []
var spawn_points: Array[Marker2D] = []
var is_spawning: bool = false

@onready var spawn_timer: Timer = Timer.new()
@onready var wave_delay_timer: Timer = Timer.new()


func _ready() -> void:
	# Setup timers
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_spawn_next_enemy)
	add_child(spawn_timer)
	
	wave_delay_timer.one_shot = true
	wave_delay_timer.timeout.connect(_start_next_wave)
	add_child(wave_delay_timer)
	
	# Collect spawn points from children
	_collect_spawn_points()
	
	if auto_start:
		call_deferred("_start_next_wave")


func _collect_spawn_points() -> void:
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
	
	if spawn_points.is_empty():
		push_warning("WaveSpawner: No spawn points found! Add Marker2D children.")


func _start_next_wave() -> void:
	if is_spawning:
		return
	
	current_wave += 1
	enemies_to_spawn = initial_enemy_count + (current_wave - 1) * enemies_per_wave_increase
	is_spawning = true
	
	emit_signal("wave_started", current_wave, enemies_to_spawn)
	
	# Start spawning enemies
	spawn_timer.start(spawn_interval)


func _spawn_next_enemy() -> void:
	if enemies_to_spawn <= 0:
		spawn_timer.stop()
		is_spawning = false
		return
	
	if enemy_scene == null:
		push_error("WaveSpawner: No enemy scene assigned!")
		spawn_timer.stop()
		is_spawning = false
		return
	
	if spawn_points.is_empty():
		push_error("WaveSpawner: No spawn points available!")
		spawn_timer.stop()
		is_spawning = false
		return
	
	# Pick random spawn point
	var spawn_point = spawn_points.pick_random()
	
	# Instantiate enemy
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_point.global_position
	
	# Add to scene tree (parent's parent to avoid being child of spawner)
	get_parent().add_child(enemy)
	
	# Track enemy
	active_enemies.append(enemy)
	
	# Connect to enemy death/removal
	if enemy.has_signal("tree_exiting"):
		enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))
	
	emit_signal("enemy_spawned", enemy)
	enemies_to_spawn -= 1


func _on_enemy_removed(enemy: Node2D) -> void:
	active_enemies.erase(enemy)
	
	# Check if wave is complete
	if active_enemies.is_empty() and not is_spawning:
		emit_signal("wave_completed", current_wave)
		emit_signal("all_enemies_defeated")
		
		# Start delay for next wave
		wave_delay_timer.start(wave_delay)


func get_current_wave() -> int:
	return current_wave


func get_active_enemy_count() -> int:
	return active_enemies.size()


func get_remaining_spawns() -> int:
	return enemies_to_spawn


func start_waves() -> void:
	if current_wave == 0:
		_start_next_wave()


func stop_waves() -> void:
	spawn_timer.stop()
	wave_delay_timer.stop()
	is_spawning = false


func reset() -> void:
	stop_waves()
	current_wave = 0
	enemies_to_spawn = 0
	
	# Clear active enemies
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
