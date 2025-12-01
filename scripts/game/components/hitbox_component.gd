class_name HitboxComponent
extends Area2D

@export var damage: int = 10
@export var knockback: float = 0.0
@export var active: bool = false : set = set_active

signal hit(target)

func _ready() -> void:
	connect("area_entered", _on_area_entered)
	
func set_active(value: bool) -> void:
	active = value
	
func _on_area_entered(area: Area2D):
	if not active:
		return
	if area is not HurtboxComponent:
		return
	var hurtbox := area as HurtboxComponent
	hurtbox.receive_hit(damage, knockback)
