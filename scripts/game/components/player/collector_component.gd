class_name CollectorComponent
extends Node2D

signal item_collected(collectible_type: String, value: int)

@export var collection_area: Area2D  # Area2D for instant collection on contact
@export var magnet_radius: float = 15.0  # Radius for magnetic attraction
@export var query_interval: float = 0.1  # How often to query spatial grid (seconds)

var query_timer: float = 0.0

func _ready() -> void:
	if collection_area:
		collection_area.area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	# Periodically query for nearby collectibles
	query_timer += delta
	if query_timer >= query_interval:
		query_timer = 0.0
		_query_nearby_collectibles()

func _query_nearby_collectibles() -> void:
	"""Query spatial grid for nearby collectibles and attract them."""
	if not SpatialGrid:
		return
	
	var nearby = SpatialGrid.query_nearby(global_position, magnet_radius, "collectibles")
	
	for collectible in nearby:
		if is_instance_valid(collectible) and collectible.has_method("start_attraction"):
			collectible.start_attraction(owner)

func _on_area_entered(area: Area2D) -> void:
	"""Called when a collectible enters the collection area."""
	# Check if the area belongs to a collectible
	var collectible = area.get_parent()
	if collectible and collectible.has_method("_collect"):
		# Get collectible info before it's freed
		var type = collectible.collectible_type if "collectible_type" in collectible else "unknown"
		var val = collectible.value if "value" in collectible else 1
		
		# Emit signal for game logic (UI updates, stats, etc.)
		item_collected.emit(type, val)
		
		# The collectible will handle its own cleanup
		collectible._collect()
