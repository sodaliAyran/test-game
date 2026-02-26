extends Node2D
class_name StunBarComponent

## Grey bar above enemy head showing remaining stun time.
## Bar shrinks from right to left as stun expires.

@export var bar_width: float = 20.0
@export var bar_height: float = 3.0
@export var bar_offset: Vector2 = Vector2(0, -32)  # Above enemy head
@export var bar_color: Color = Color(0.5, 0.5, 0.5, 1.0)  # Grey
@export var background_color: Color = Color(0.2, 0.2, 0.2, 0.8)  # Dark grey

var _progress: float = 0.0  # 0 = full, 1 = empty
var _visible: bool = false


func _ready() -> void:
	visible = false


func show_bar(_duration: float) -> void:
	_progress = 0.0
	_visible = true
	visible = true
	queue_redraw()


func hide_bar() -> void:
	_visible = false
	visible = false


func update_progress(progress: float) -> void:
	_progress = clamp(progress, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if not _visible:
		return

	var pos = bar_offset - Vector2(bar_width / 2.0, 0)

	# Background (full bar)
	draw_rect(Rect2(pos, Vector2(bar_width, bar_height)), background_color)

	# Foreground (remaining time - shrinks left to right)
	var remaining_width = bar_width * (1.0 - _progress)
	if remaining_width > 0:
		draw_rect(Rect2(pos, Vector2(remaining_width, bar_height)), bar_color)