class_name EnemyDrops
extends Node

## Macro component bundling drop-on-hit and drop-on-knockback behavior.
## Contains: HitDropComponent, KnockbackDropComponent.
##
## Set the external exports (health, knockbackable, drop_scene) in the inspector.

@export var health: HealthComponent
@export var knockbackable: Node  # KnockbackableComponent
@export var drop_scene: PackedScene

@onready var hit_drop: HitDropComponent = $HitDropComponent
@onready var knockback_drop: KnockbackDropComponent = $KnockbackDropComponent


func _ready() -> void:
	if health:
		hit_drop.health_component = health
	else:
		push_warning("EnemyDrops: health not set")

	if knockbackable:
		knockback_drop.knockbackable = knockbackable
	else:
		push_warning("EnemyDrops: knockbackable not set")

	if drop_scene:
		hit_drop.drop_scene = drop_scene
		knockback_drop.drop_scene = drop_scene
	else:
		push_warning("EnemyDrops: drop_scene not set")
