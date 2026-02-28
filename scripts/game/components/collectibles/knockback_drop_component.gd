class_name KnockbackDropComponent
extends Node

## Bursts a large spray of coins when the enemy is stomped during stun.
## Connects to KnockbackableComponent.stomped signal.

const FountainSpawnAnim = preload("res://scripts/game/components/animation/fountain_spawn_animation_component.gd")

@export var knockbackable: Node  # KnockbackableComponent
@export var drop_scene: PackedScene  # coin.tscn
@export var drop_count: int = 15

@export_group("Spray Settings")
@export var spray_height: float = 60.0
@export var spray_duration: float = 0.6
@export var spread_radius: float = 40.0
@export var height_variance: float = 20.0
@export var duration_variance: float = 0.2


func _ready() -> void:
	if knockbackable:
		knockbackable.stomped.connect(_on_stomped)
	else:
		push_warning("KnockbackDropComponent: knockbackable not set")


func _on_stomped(_direction: Vector2) -> void:
	if not drop_scene:
		return

	for i in range(drop_count):
		_spawn_drop()


func _spawn_drop() -> void:
	var drop = drop_scene.instantiate()
	drop.global_position = owner.global_position
	get_tree().current_scene.add_child(drop)

	var anim = FountainSpawnAnim.new()
	anim.launch_height = spray_height
	anim.launch_duration = spray_duration
	anim.spread_radius = spread_radius
	anim.height_variance = height_variance
	anim.duration_variance = duration_variance
	drop.add_child(anim)
