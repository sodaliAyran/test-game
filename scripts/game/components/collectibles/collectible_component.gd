class_name CollectibleComponent
extends Node2D

signal collected(collector)
signal collection_finished(collector)

@export var collectible_type: String = "coin"
@export var value: int = 1
@export var attraction_speed: float = 8.0  # Speed of magnetic pull
@export var collection_distance: float = 10.0  # Distance at which it's collected
@export var pickup_delay: float = 0.5  # Time before the item can be picked up

var is_attracted: bool = false
var is_collecting: bool = false
var is_pickupable: bool = false
var target_collector: Node2D = null

func _ready() -> void:
	# Register with spatial grid
	if SpatialGrid:
		SpatialGrid.register_entity(self, "collectibles")

	# Start pickup delay
	if pickup_delay > 0.0:
		is_pickupable = false
		get_tree().create_timer(pickup_delay).timeout.connect(func(): is_pickupable = true)
	else:
		is_pickupable = true

func _exit_tree() -> void:
	# Unregister from spatial grid
	if SpatialGrid:
		SpatialGrid.unregister_entity(self, "collectibles")

func _process(delta: float) -> void:
	if is_collecting:
		return
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
	if not is_pickupable:
		return
	if not is_attracted and not is_collecting:
		is_attracted = true
		target_collector = collector

func stop_attraction() -> void:
	"""Stop being attracted."""
	is_attracted = false
	target_collector = null

func _collect(collector_override: Node2D = null) -> void:
	"""Called when the collectible is collected."""
	if is_collecting or not is_pickupable:
		return
	is_collecting = true

	# Use override if provided (from direct area collision), otherwise use magnetic target
	var collector = collector_override if is_instance_valid(collector_override) else target_collector
	collected.emit(collector)

	# Stop attraction so the animation controls movement
	is_attracted = false

	# Unregister from spatial grid so it won't be queried again
	if SpatialGrid:
		SpatialGrid.unregister_entity(self, "collectibles")

	# Play collection animation if available, otherwise free immediately
	var anim = get_node_or_null("CollectAnimationComponent")
	if anim and anim.has_method("play") and is_instance_valid(collector):
		anim.play(collector, func(): collection_finished.emit(collector))
	else:
		collection_finished.emit(collector)
		queue_free()
