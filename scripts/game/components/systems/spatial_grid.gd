extends Node

## Spatial Grid for efficient entity queries
## Autoload singleton that manages spatial partitioning using a grid-based hash

const CELL_SIZE: int = 64  # Grid cell size in pixels (tune based on separation radius)

# Dictionary structure: { layer_name: { cell_key: [entities] } }
var _grids: Dictionary = {}


func _ready() -> void:
	# Initialize default layer
	_grids["enemies"] = {}
	_grids["players"] = {}


## Register an entity in the spatial grid
func register_entity(entity: Node2D, layer: String = "enemies") -> void:
	if not entity:
		return
	
	# Ensure layer exists
	if not _grids.has(layer):
		_grids[layer] = {}
	
	var cell_key = _get_cell_key(entity.global_position)
	if not _grids[layer].has(cell_key):
		_grids[layer][cell_key] = []
	
	# Add entity if not already in cell
	if not _grids[layer][cell_key].has(entity):
		_grids[layer][cell_key].append(entity)


## Unregister an entity from the spatial grid
func unregister_entity(entity: Node2D, layer: String = "enemies") -> void:
	if not entity or not _grids.has(layer):
		return
	
	# Remove from all cells (in case position changed without update)
	for cell_key in _grids[layer].keys():
		var cell = _grids[layer][cell_key]
		if cell.has(entity):
			cell.erase(entity)
			# Clean up empty cells
			if cell.is_empty():
				_grids[layer].erase(cell_key)


## Update entity position in the grid (call when entity moves)
func update_entity_position(entity: Node2D, layer: String = "enemies") -> void:
	if not entity or not _grids.has(layer):
		return
	
	var new_cell_key = _get_cell_key(entity.global_position)
	
	# Check if entity is in the correct cell
	var found_in_correct_cell = false
	if _grids[layer].has(new_cell_key):
		found_in_correct_cell = _grids[layer][new_cell_key].has(entity)
	
	if found_in_correct_cell:
		return  # Already in correct cell
	
	# Remove from old cell and add to new cell
	unregister_entity(entity, layer)
	register_entity(entity, layer)


## Query entities within a radius of a position
func query_nearby(position: Vector2, radius: float, layer: String = "enemies", exclude: Node2D = null) -> Array[Node2D]:
	if not _grids.has(layer):
		return []
	
	var results: Array[Node2D] = []
	var radius_squared = radius * radius
	
	# Calculate which cells to check
	var min_cell = _get_cell_coords(position - Vector2(radius, radius))
	var max_cell = _get_cell_coords(position + Vector2(radius, radius))
	
	# Check all cells in range
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var cell_key = Vector2i(x, y)
			if not _grids[layer].has(cell_key):
				continue
			
			# Check each entity in the cell
			for entity in _grids[layer][cell_key]:
				if not is_instance_valid(entity) or entity == exclude:
					continue
				
				# Distance check (squared to avoid sqrt)
				var dist_squared = position.distance_squared_to(entity.global_position)
				if dist_squared <= radius_squared:
					results.append(entity)
	
	return results


## Get cell coordinates for a world position
func _get_cell_coords(position: Vector2) -> Vector2i:
	return Vector2i(
		floori(position.x / CELL_SIZE),
		floori(position.y / CELL_SIZE)
	)


## Get cell key for a world position
func _get_cell_key(position: Vector2) -> Vector2i:
	return _get_cell_coords(position)


## Debug: Get grid statistics
func get_stats(layer: String = "enemies") -> Dictionary:
	if not _grids.has(layer):
		return {"cells": 0, "entities": 0}
	
	var cell_count = _grids[layer].size()
	var entity_count = 0
	for cell in _grids[layer].values():
		entity_count += cell.size()
	
	return {
		"cells": cell_count,
		"entities": entity_count,
		"avg_per_cell": float(entity_count) / max(cell_count, 1)
	}
