class_name WorldConfig
extends Resource

## World generation configuration resource
## Can be saved as .tres file and edited in inspector

# ==================== CHUNK CONFIGURATION ====================

## Size of each chunk in tiles (width and height)
@export var chunk_size: int = 20

## Size of each tile in pixels
@export var tile_size: int = 16

## Calculated chunk size in pixels
var chunk_pixel_size: int:
	get:
		return chunk_size * tile_size


# ==================== CHUNK STREAMING ====================

## Load chunks within this radius of the player (in chunks)
@export_range(1, 10) var load_radius: int = 3

## Unload chunks beyond this distance from player (in chunks)
@export_range(1, 20) var unload_distance: int = 5

## How often to check for chunk updates (seconds)
@export_range(0.1, 2.0) var update_interval: float = 0.5


# ==================== TERRAIN GENERATION ====================

## Terrain set index in the TileSet
@export var terrain_set: int = 0

## Terrain IDs (NOTE: new_tile_set corrected to terrain_0=Grass, terrain_1=Water)
@export var terrain_grass: int = 0
@export var terrain_water: int = 1

## Noise threshold for water generation (0.0 to 1.0)
## Values below this = water, above = grass
@export_range(0.0, 1.0) var water_threshold: float = 0.15

## Noise generation settings
@export_range(0.001, 0.5) var noise_frequency: float = 0.05  ## Lower = smoother terrain
@export_range(1, 8) var noise_octaves: int = 3                ## Detail layers
@export_range(0.0, 1.0) var noise_gain: float = 0.5           ## Amplitude of each octave


# ==================== TILESET CONFIGURATION ====================

## Source ID for the main tileset in TileMap
@export var tileset_source_id: int = 3
