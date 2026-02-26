class_name DeathDropComponent
extends Node

## Drops items when the attached entity dies.
## Connect to a HealthComponent's died signal.

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
	
	# Check drop chance (with passive bonus)
	var effective_drop_chance = drop_chance
	if SkillManager:
		effective_drop_chance = clampf(drop_chance + SkillManager.get_passive_float("drop_chance_bonus"), 0.0, 1.0)
	if randf() > effective_drop_chance:
		return  # No drop this time

	# Determine how many to drop (with passive bonus)
	var effective_max_drops = max_drops
	if SkillManager:
		effective_max_drops += SkillManager.get_passive_int("extra_drops")
	var drop_count = _weighted_drop_count(min_drops, effective_max_drops)
	
	# Spawn drops
	for i in range(drop_count):
		_spawn_drop()

func _weighted_drop_count(min_count: int, max_count: int) -> int:
	"""Weighted random drop count - lower counts are much more likely.
	Weights: 1 = 70%, 2 = 20%, 3+ = 10% (split evenly among higher values)."""
	if min_count >= max_count:
		return min_count
	var roll = randf()
	if roll < 0.7:
		return min_count
	elif roll < 0.9:
		return mini(min_count + 1, max_count)
	else:
		return max_count

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
