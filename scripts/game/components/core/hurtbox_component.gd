class_name HurtboxComponent
extends Area2D

@export var health_component: Node = null
@export var invincible: bool = false
@export var knockback_multiplier: float = 1.0

signal hurt(amount)
signal knocked(direction, force)

func receive_hit(damage: int, knockback: float, hit_origin: Vector2 = Vector2.ZERO) ->  void:
	if invincible:
		return

	if health_component:
		health_component.take_damage(damage)
	emit_signal("hurt", damage)

	if knockback > 0 and owner is CharacterBody2D:
		var dir = (global_position - hit_origin).normalized()
		emit_signal("knocked", dir, knockback * knockback_multiplier)
		
