class_name CollectibleComponent
extends Node2D

signal collected(collector)

@export var collectible_type: String = "coin"
@export var value: int = 1
@export var attraction_speed: float = 8.0  # Speed of magnetic pull
@export var collection_distance: float = 10.0  # Distance at which it's collected

var is_attracted: bool = false
var target_collector: Node2D = null

func _ready() -> void:
	# Register with spatial grid
	if SpatialGrid:
		SpatialGrid.register_entity(self, "collectibles")

func _exit_tree() -> void:
	# Unregister from spatial grid
	if SpatialGrid:
		SpatialGrid.unregister_entity(self, "collectibles")

func _process(delta: float) -> void:
	if is_attracted and is_instance_valid(target_collector):
		# Move toward collector with magnetic attraction
		var direction = (target_collector.global_position - global_position)
		var distance = direction.length()
		
		# Check if close enough to collect
		if distance <= collection_distance:
			_collect()
			return
		
		# Smooth magnetic pull
		global_position = global_position.lerp(target_collector.global_position, attraction_speed * delta)
		
		# Update spatial grid position
		if SpatialGrid:
			SpatialGrid.update_entity_position(self, "collectibles")

func start_attraction(collector: Node2D) -> void:
	"""Start being attracted to a collector."""
	if not is_attracted:
		is_attracted = true
		target_collector = collector

func stop_attraction() -> void:
	"""Stop being attracted."""
	is_attracted = false
	target_collector = null

func _collect() -> void:
	"""Called when the collectible is collected."""
	collected.emit(target_collector)
	queue_free()
