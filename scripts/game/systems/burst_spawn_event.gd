class_name BurstSpawnEvent
extends SpawnEvent

## Spawns many enemies instantly at a specific time

@export var enemy_scene: PackedScene
@export var spawn_count: int = 10
@export var spawn_delay: float = 0.05  # Delay between each spawn (for performance)

var has_executed: bool = false
var spawned_count: int = 0
var next_spawn_time: float = 0.0

func execute(spawner: Node2D, elapsed_time: float) -> void:
	# Check if it's time to start the burst
	if not has_executed and elapsed_time >= trigger_time:
		has_executed = true
		next_spawn_time = elapsed_time
	
	# Spawn enemies with delay
	if has_executed and spawned_count < spawn_count:
		if elapsed_time >= next_spawn_time:
			spawner._spawn_enemy(enemy_scene)
			spawned_count += 1
			next_spawn_time = elapsed_time + spawn_delay

func is_active(elapsed_time: float) -> bool:
	return elapsed_time >= trigger_time and spawned_count < spawn_count

func reset() -> void:
	has_executed = false
	spawned_count = 0
	next_spawn_time = 0.0
