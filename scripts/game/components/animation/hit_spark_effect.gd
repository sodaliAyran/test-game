class_name HitSparkEffect
extends Node2D

## A star/cross spark effect that scales up and fades out quickly.
## Spawned programmatically at hit positions and self-destructs.

@export var spark_color: Color = Color(1.0, 1.0, 0.9, 1.0)  # White with slight warmth
@export var line_length: float = 10.0
@export var line_width: float = 2.0
@export var duration: float = 0.18

func _ready() -> void:
	rotation = randf() * TAU  # Random rotation for variety
	scale = Vector2.ZERO

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), duration * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(queue_free)

func _draw() -> void:
	# Draw a 4-pointed star/cross
	for i in range(4):
		var angle = i * PI / 2.0
		var dir = Vector2.from_angle(angle)
		draw_line(-dir * 2.0, dir * line_length, spark_color, line_width)

	# Draw 4 diagonal shorter lines for extra flair
	for i in range(4):
		var angle = i * PI / 2.0 + PI / 4.0
		var dir = Vector2.from_angle(angle)
		draw_line(-dir * 1.5, dir * (line_length * 0.6), spark_color, line_width * 0.7)
