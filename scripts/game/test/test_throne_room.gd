extends Node2D

## Controller script for the throne room defense test scene

@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var wave_info_label: Label = $UI/WaveInfo


func _ready() -> void:
	# Connect to wave spawner signals
	if wave_spawner:
		wave_spawner.wave_started.connect(_on_wave_started)
		wave_spawner.wave_completed.connect(_on_wave_completed)
		wave_spawner.enemy_spawned.connect(_on_enemy_spawned)
		wave_spawner.all_enemies_defeated.connect(_on_all_enemies_defeated)
		
		_update_ui()


func _update_ui() -> void:
	if wave_spawner and wave_info_label:
		var wave_num = wave_spawner.get_current_wave()
		var enemy_count = wave_spawner.get_active_enemy_count()
		var remaining_spawns = wave_spawner.get_remaining_spawns()
		
		wave_info_label.text = "Wave: %d\nEnemies: %d" % [wave_num, enemy_count + remaining_spawns]


func _on_wave_started(wave_number: int, enemy_count: int) -> void:
	print("Wave %d started! Spawning %d enemies" % [wave_number, enemy_count])
	_update_ui()


func _on_wave_completed(wave_number: int) -> void:
	print("Wave %d completed!" % wave_number)
	_update_ui()


func _on_enemy_spawned(enemy: Node2D) -> void:
	# Add player to the "Player" group if not already
	var player = get_node_or_null("Warrior")
	if player and not player.is_in_group("Player"):
		player.add_to_group("Player")
	
	_update_ui()


func _on_all_enemies_defeated() -> void:
	print("All enemies defeated! Next wave incoming...")
	_update_ui()


func _process(_delta: float) -> void:
	# Update UI every frame to keep enemy count accurate
	_update_ui()
