class_name HitboxComponent
extends Area2D

@export var base_damage: int = 10
@export var knockback: float = 0.0
@export var active: bool = false : set = set_active
@export_flags_2d_physics var hitbox_collision_layer: int = 4
@export_flags_2d_physics var hitbox_collision_mask: int = 32

var damage_multiplier: float = 1.0

signal hit(target)

func _ready() -> void:
	# Apply collision settings from exports
	collision_layer = hitbox_collision_layer
	collision_mask = hitbox_collision_mask
	
	connect("area_entered", _on_area_entered)
	
func set_active(value: bool) -> void:
	active = value


func set_damage_multiplier(multiplier: float) -> void:
	damage_multiplier = multiplier
	
func _on_area_entered(area: Area2D):
	if not active:
		print("Hitbox not active")
		return
	if area is not HurtboxComponent:
		return
	var hurtbox := area as HurtboxComponent
	var final_damage = int(base_damage * damage_multiplier)
	hurtbox.receive_hit(final_damage, knockback)
