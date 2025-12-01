class_name HealthComponent
extends Node

signal died
signal health_changed(current, max)

@export var max_health: int = 100
var current_health = max_health

func take_damage(amount: int) -> void:
	current_health = max(current_health - amount, 0)
	emit_signal("health_changed", current_health, max_health)
	if current_health <= 0:
		emit_signal("died")
