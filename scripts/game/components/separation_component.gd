class_name SeparationComponent
extends Node

## Calculates separation steering force to prevent entity clumping

@export var separation_radius: float = 50.0
@export var separation_strength: float = 1.0
@export var spatial_layer: String = "enemies"
@export var max_neighbors: int = 10
@export var enabled: bool = true

var _last_separation_vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Register with spatial grid
	if owner:
		SpatialGrid.register_entity(owner, spatial_layer)


func _exit_tree() -> void:
	# Unregister from spatial grid
	if owner:
		SpatialGrid.unregister_entity(owner, spatial_layer)


func _physics_process(_delta: float) -> void:
	# Update position in spatial grid
	if owner:
		SpatialGrid.update_entity_position(owner, spatial_layer)


## Get the separation steering vector
func get_separation_vector() -> Vector2:
	if not enabled or not owner:
		return Vector2.ZERO
	
	# Query nearby entities
	var nearby = SpatialGrid.query_nearby(
		owner.global_position,
		separation_radius,
		spatial_layer,
		owner  # Exclude self
	)
	
	if nearby.is_empty():
		_last_separation_vector = Vector2.ZERO
		return Vector2.ZERO
	
	# Limit neighbors for performance
	if nearby.size() > max_neighbors:
		nearby = nearby.slice(0, max_neighbors)
	
	# Calculate separation vector
	var separation = Vector2.ZERO
	var count = 0
	
	for neighbor in nearby:
		if not is_instance_valid(neighbor):
			continue
		
		var to_neighbor = owner.global_position - neighbor.global_position
		var distance = to_neighbor.length()
		
		if distance < 0.01:  # Avoid division by zero
			continue
		
		# Weight by inverse distance (closer = stronger push)
		var weight = 1.0 - (distance / separation_radius)
		separation += to_neighbor.normalized() * weight
		count += 1
	
	if count > 0:
		separation = separation / count  # Average
		separation = separation.normalized() * separation_strength
	
	_last_separation_vector = separation
	return separation


## Get the last calculated separation vector (for debugging)
func get_last_separation() -> Vector2:
	return _last_separation_vector


## Get count of nearby entities (for debugging)
func get_nearby_count() -> int:
	if not owner:
		return 0
	
	var nearby = SpatialGrid.query_nearby(
		owner.global_position,
		separation_radius,
		spatial_layer,
		owner
	)
	return nearby.size()
