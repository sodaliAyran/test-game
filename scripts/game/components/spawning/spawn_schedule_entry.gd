class_name SpawnScheduleEntry
extends Resource

## Time in seconds from session start when this entry triggers
@export var time: float = 0.0
## The enemy scene to spawn
@export var enemy_scene: PackedScene
## How many enemies to spawn in this batch
@export var count: int = 1
## Delay between each spawn in the batch (0 = all at once)
@export var stagger: float = 0.0
