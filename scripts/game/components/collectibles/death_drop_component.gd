class_name DropComponent
extends Node

@export var health_component: HealthComponent
@export var drop_scene: PackedScene  # Scene to drop (e.g., coin)
@export var drop_chance: float = 0.5  # 50% chance to drop
@export var min_drops: int = 1
@export var max_drops: int = 1
@export var spread_radius: float = 20.0  # Random spread when dropping

func _ready() -> void:
	if health_component:
		health_component.died.connect(_on_died)
	else:
		push_warning("DropComponent: health_component not set")

func _on_died() -> void:
	"""Called when the entity dies."""
	if not drop_scene:
		return
	
	# Check drop chance
	if randf() > drop_chance:
		return  # No drop this time
	
	# Determine how many to drop
	var drop_count = randi_range(min_drops, max_drops)
	
	# Spawn drops
	for i in range(drop_count):
		_spawn_drop()

func _spawn_drop() -> void:
	"""Spawn a single drop at the owner's position with random offset."""
	var drop = drop_scene.instantiate()
	
	# Random offset within spread radius
	var random_offset = Vector2(
		randf_range(-spread_radius, spread_radius),
		randf_range(-spread_radius, spread_radius)
	)
	
	drop.global_position = owner.global_position + random_offset
	
	# Add to scene
	get_tree().current_scene.add_child(drop)
