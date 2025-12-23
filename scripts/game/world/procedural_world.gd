extends Node2D

## Procedural world generator with chunk loading
## Generates infinite terrain using noise-based chunks

@export var player: Node2D  ## Reference to player for position tracking
@export var chunk_size: int = 16  ## Tiles per chunk (width and height)
@export var load_radius: int = 2  ## Load chunks within this radius
@export var unload_distance: int = 3  ## Unload chunks beyond this distance
@export_range(0.0, 1.0) var water_threshold: float = 0.15  ## Noise values below this = water
@export_range(0.001, 0.5) var noise_frequency: float = 0.05  ## Lower = smoother terrain
@export var tile_size: int = 16  ## Size of each tile in pixels
@export var terrain_grass: int = 0  ## Terrain ID for grass in TileSet
@export var terrain_water: int = 1  ## Terrain ID for water in TileSet

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

var chunk_manager: ChunkManager
var last_player_chunk: Vector2i = Vector2i(-999999, -999999)
var update_timer: Timer


func _ready() -> void:
	if not tile_map_layer:
		push_error("ProceduralWorld: TileMapLayer child node not found!")
		return
	
	_init_chunk_manager()
	_create_update_timer()
	_update_chunks()


func _init_chunk_manager() -> void:
	var config := {
		"chunk_size": chunk_size,
		"tile_size": tile_size,
		"water_threshold": water_threshold,
		"noise_frequency": noise_frequency,
		"load_radius": load_radius,
		"unload_distance": unload_distance
	}
	chunk_manager = ChunkManager.new(config)


func _create_update_timer() -> void:
	update_timer = Timer.new()
	update_timer.wait_time = 0.5  # Check every 0.5 seconds
	update_timer.one_shot = false
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)
	update_timer.start()


func _on_update_timer_timeout() -> void:
	_update_chunks()


func _update_chunks() -> void:
	var player_pos := player.global_position if player else Vector2.ZERO
	var result := chunk_manager.update_chunks(player_pos, last_player_chunk)
	
	if not result["changed"]:
		return
	
	last_player_chunk = result["current_chunk"]
	print("ProceduralWorld: Player in chunk ", last_player_chunk)
	
	# Load new chunks
	for chunk_coords in result["to_load"]:
		_load_chunk(chunk_coords)
	
	# Unload distant chunks
	for chunk_coords in result["to_unload"]:
		_unload_chunk(chunk_coords)
	
	print("ProceduralWorld: Active chunks: ", chunk_manager.get_active_chunk_count())


func _load_chunk(chunk_coords: Vector2i) -> void:
	print("  Loading chunk ", chunk_coords)
	
	# Generate chunk terrain data
	var chunk_data := chunk_manager.generator.generate_chunk(chunk_coords)
	
	# Apply terrain tiles using auto-tiling system
	if chunk_data["grass"].size() > 0:
		tile_map_layer.set_cells_terrain_connect(chunk_data["grass"], 0, terrain_grass)
	if chunk_data["water"].size() > 0:
		tile_map_layer.set_cells_terrain_connect(chunk_data["water"], 0, terrain_water)
	
	# Register chunk with manager
	var all_tiles: Array[Vector2i] = chunk_data["grass"] + chunk_data["water"]
	chunk_manager.register_chunk(chunk_coords, all_tiles)


func _unload_chunk(chunk_coords: Vector2i) -> void:
	print("  Unloading chunk ", chunk_coords)
	
	# Get all tile positions in this chunk
	var tiles := chunk_manager.get_chunk_tiles(chunk_coords)
	
	# Erase each tile
	for tile_pos in tiles:
		tile_map_layer.erase_cell(tile_pos)
	
	# Unregister chunk from manager
	chunk_manager.unregister_chunk(chunk_coords)


func get_stats() -> Dictionary:
	return {
		"active_chunks": chunk_manager.get_active_chunk_count(),
		"player_chunk": last_player_chunk
	}
