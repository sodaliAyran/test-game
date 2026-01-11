class_name ContinuousSpawnEvent
extends SpawnEvent

## Spawns enemies at intervals during a time window

@export var end_time: float = 60.0  # When this event ends (seconds)
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0  # Time between spawns
@export var spawn_count_per_interval: int = 1  # Enemies per spawn

var next_spawn_time: float = 0.0
var is_initialized: bool = false

func execute(spawner: Node2D, elapsed_time: float) -> void:
	# Initialize on first execution
	if not is_initialized:
		next_spawn_time = trigger_time
		is_initialized = true
	
	# Check if it's time to spawn
	if elapsed_time >= next_spawn_time and elapsed_time <= end_time:
		# Spawn enemies
		for i in range(spawn_count_per_interval):
			spawner._spawn_enemy(enemy_scene)
		
		# Schedule next spawn
		next_spawn_time += spawn_interval

func is_active(elapsed_time: float) -> bool:
	return elapsed_time >= trigger_time and elapsed_time <= end_time

func reset() -> void:
	is_initialized = false
	next_spawn_time = 0.0
