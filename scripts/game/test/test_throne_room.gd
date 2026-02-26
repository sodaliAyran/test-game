extends Node2D

## Controller script for the throne room defense test scene

@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var wave_info_label: Label = $UI/WaveInfo


func _ready() -> void:
	if wave_spawner:
		wave_spawner.enemy_spawned.connect(_on_enemy_spawned)
		wave_spawner.schedule_completed.connect(_on_schedule_completed)
		_update_ui()


func _update_ui() -> void:
	if wave_spawner and wave_info_label:
		var elapsed: float = wave_spawner.get_elapsed_time()
		@warning_ignore("integer_division")
		var minutes: int = int(elapsed) / 60
		var seconds: int = int(elapsed) % 60
		var enemy_count: int = wave_spawner.get_active_enemy_count()
		wave_info_label.text = "Time: %d:%02d\nEnemies: %d" % [minutes, seconds, enemy_count]


func _on_enemy_spawned(_enemy: Node2D) -> void:
	var player = get_node_or_null("Warrior")
	if player and not player.is_in_group("Player"):
		player.add_to_group("Player")
	_update_ui()


func _on_schedule_completed() -> void:
	print("Spawn schedule completed!")
	_update_ui()


func _process(_delta: float) -> void:
	_update_ui()
