class_name ChunkGenerator
extends RefCounted

var noise: FastNoiseLite
var chunk_size: int
var tile_size: int
var water_threshold: float


func _init(config: Dictionary) -> void:
	chunk_size = config.get("chunk_size", 16)
	tile_size = config.get("tile_size", 16)
	water_threshold = config.get("water_threshold", 0.2)
	
	_init_noise(config)


func _init_noise(config: Dictionary) -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = config.get("noise_frequency", 0.05)
	noise.seed = randi()  # Random seed each time


func generate_chunk(chunk_coords: Vector2i) -> Dictionary:
	var water_tiles: Array[Vector2i] = []
	var grass_tiles: Array[Vector2i] = []
	
	# Calculate world offset for this chunk
	var chunk_offset := chunk_coords * chunk_size
	
	# Generate each tile in the chunk
	for y in range(chunk_size):
		for x in range(chunk_size):
			var tile_pos := chunk_offset + Vector2i(x, y)
			
			# Sample noise at world position
			var world_x := tile_pos.x * tile_size
			var world_y := tile_pos.y * tile_size
			var noise_value := noise.get_noise_2d(world_x, world_y)
			
			# Convert noise (-1 to 1) to normalized (0 to 1)
			var normalized := (noise_value + 1.0) / 2.0
			
			# Determine terrain type
			if normalized < water_threshold:
				water_tiles.append(tile_pos)
			else:
				grass_tiles.append(tile_pos)
	
	return {"water": water_tiles, "grass": grass_tiles}
