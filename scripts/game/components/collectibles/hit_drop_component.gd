class_name HitDropComponent
extends Node

## Drops items when the attached entity takes damage.
## Connect to a HealthComponent's health_changed signal.

const FountainSpawnAnim = preload("res://scripts/game/components/animation/fountain_spawn_animation_component.gd")

@export var health_component: HealthComponent
@export var drop_scene: PackedScene
@export var drop_chance: float = 0.3  # 30% chance per hit
@export var min_drops: int = 1
@export var max_drops: int = 1
@export var spread_radius: float = 20.0
@export var cooldown: float = 0.0  # Minimum time between drops (0 = no cooldown)

@export_group("Fountain Animation")
@export var fountain_enabled: bool = true
@export var fountain_height: float = 40.0
@export var fountain_duration: float = 0.5

var _cooldown_timer: float = 0.0
var _previous_health: int = -1

func _ready() -> void:
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		_previous_health = health_component.current_health
	else:
		push_warning("HitDropComponent: health_component not set")

func _process(delta: float) -> void:
	if _cooldown_timer > 0:
		_cooldown_timer -= delta

func _on_health_changed(current: int, _max: int) -> void:
	"""Called when health changes. Only drops if health decreased (took damage)."""
	# Only trigger on damage (health decreased), not healing
	if _previous_health >= 0 and current >= _previous_health:
		_previous_health = current
		return

	_previous_health = current

	if not drop_scene:
		return

	# Check cooldown
	if _cooldown_timer > 0:
		return

	# Check drop chance (with passive bonus)
	var effective_drop_chance = drop_chance
	if SkillManager:
		effective_drop_chance = clampf(drop_chance + SkillManager.get_passive_float("drop_chance_bonus"), 0.0, 1.0)
	if randf() > effective_drop_chance:
		return

	# Reset cooldown
	_cooldown_timer = cooldown

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
	"""Spawn a single drop at the owner's position with fountain animation."""
	var drop = drop_scene.instantiate()

	# Start at owner position
	drop.global_position = owner.global_position

	# Add to scene
	get_tree().current_scene.add_child(drop)

	# Add fountain animation if enabled
	if fountain_enabled:
		var anim = FountainSpawnAnimationComponent.new()
		anim.launch_height = fountain_height
		anim.launch_duration = fountain_duration
		anim.spread_radius = spread_radius
		drop.add_child(anim)
	else:
		# No animation - just apply random offset directly
		var random_offset = Vector2(
			randf_range(-spread_radius, spread_radius),
			randf_range(-spread_radius, spread_radius)
		)
		drop.global_position += random_offset
