class_name DeathAnimationComponent
extends Node

@export var sprite: Sprite2D
@export var body: Node2D

func play_death_animation() -> void:
	if not body or not sprite:
		return
		
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.BLACK, 0.15)
	tween.tween_property(body, "scale", Vector2(1.2, 0.8), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(body, "scale", Vector2(0, 0), 0.4).set_delay(0.1).set_ease(Tween.EASE_IN)
	
	tween.tween_callback(body.queue_free)
