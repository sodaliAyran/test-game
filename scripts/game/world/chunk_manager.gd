class_name ChunkManager
extends RefCounted

## Manages chunk lifecycle (loading, unloading, tracking)

var generator: ChunkGenerator
var active_chunks: Dictionary = {}  # Vector2i -> Array[Vector2i] (chunk coords -> tile positions)
var chunk_size: int
var tile_size: int
var load_radius: int
var unload_distance: int


func _init(config: Dictionary) -> void:
	chunk_size = config.get("chunk_size", 16)
	tile_size = config.get("tile_size", 16)
	load_radius = config.get("load_radius", 2)
	unload_distance = config.get("unload_distance", 3)
	
	generator = ChunkGenerator.new(config)


func update_chunks(player_pos: Vector2, last_chunk: Vector2i) -> Dictionary:
	var current_chunk := world_to_chunk_coords(player_pos)
	
	# Only update if player changed chunks
	if current_chunk == last_chunk:
		return {
			"to_load": [],
			"to_unload": [],
			"current_chunk": current_chunk,
			"changed": false
		}
	
	# Determine which chunks should be loaded
	var desired_chunks: Dictionary = {}
	for x in range(-load_radius, load_radius + 1):
		for y in range(-load_radius, load_radius + 1):
			var chunk_coords := current_chunk + Vector2i(x, y)
			desired_chunks[chunk_coords] = true
	
	# Find chunks to load (desired but not active)
	var to_load: Array[Vector2i] = []
	for chunk_coords in desired_chunks.keys():
		if not active_chunks.has(chunk_coords):
			to_load.append(chunk_coords)
	
	# Find chunks to unload (active but too far)
	var to_unload: Array[Vector2i] = []
	for chunk_coords in active_chunks.keys():
		var distance := chunk_distance(chunk_coords, current_chunk)
		if distance > unload_distance:
			to_unload.append(chunk_coords)
	
	return {
		"to_load": to_load,
		"to_unload": to_unload,
		"current_chunk": current_chunk,
		"changed": true
	}


func register_chunk(chunk_coords: Vector2i, tiles: Array[Vector2i]) -> void:
	active_chunks[chunk_coords] = tiles


func unregister_chunk(chunk_coords: Vector2i) -> void:
	active_chunks.erase(chunk_coords)


func get_chunk_tiles(chunk_coords: Vector2i) -> Array[Vector2i]:
	if active_chunks.has(chunk_coords):
		return active_chunks[chunk_coords]
	return []


func world_to_chunk_coords(world_pos: Vector2) -> Vector2i:
	var chunk_pixel_size := chunk_size * tile_size
	return Vector2i(
		floori(world_pos.x / chunk_pixel_size),
		floori(world_pos.y / chunk_pixel_size)
	)


func chunk_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


func get_active_chunk_count() -> int:
	return active_chunks.size()


func get_active_chunk_coords() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for coord in active_chunks.keys():
		coords.append(coord)
	return coords
