class_name FacingIndicatorComponent
extends Node2D

## Visual indicator showing the player's facing direction.
## Draws an arc matching the sword attack range.

@export var facing: FacingComponent
@export var inner_radius: float = 20.0      ## Start distance from player center
@export var outer_radius: float = 55.0      ## End distance (sword reach)
@export var arc_angle: float = PI / 3       ## Arc span (60 degrees, narrower than sword)
@export var color: Color = Color(1, 1, 1, 0.15)
@export var outline_color: Color = Color(1, 1, 1, 0.4)
@export var transition_duration: float = 0.12

var _current_angle: float = 0.0
var _tween: Tween


func _ready() -> void:
	if facing:
		facing.facing_changed.connect(_on_facing_changed)
		_current_angle = facing.facing_direction.angle()
	queue_redraw()


func _on_facing_changed(new_direction: Vector2) -> void:
	var target_angle = new_direction.angle()

	# Find shortest rotation path
	var angle_diff = target_angle - _current_angle
	while angle_diff > PI:
		angle_diff -= TAU
	while angle_diff < -PI:
		angle_diff += TAU
	var final_angle = _current_angle + angle_diff

	# Animate to new angle
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_angle, _current_angle, final_angle, transition_duration)


func _set_angle(angle: float) -> void:
	_current_angle = angle
	queue_redraw()


func _draw() -> void:
	var start_angle = _current_angle - arc_angle / 2
	var end_angle = _current_angle + arc_angle / 2
	var point_count = 16

	# Build filled wedge polygon
	var points = PackedVector2Array()
	# Inner arc (near to far)
	for i in range(point_count + 1):
		var angle = start_angle + (end_angle - start_angle) * i / point_count
		points.append(Vector2.from_angle(angle) * inner_radius)
	# Outer arc (far to near, reversed for closed shape)
	for i in range(point_count, -1, -1):
		var angle = start_angle + (end_angle - start_angle) * i / point_count
		points.append(Vector2.from_angle(angle) * outer_radius)

	draw_colored_polygon(points, color)

	# Draw outline arcs
	draw_arc(Vector2.ZERO, inner_radius, start_angle, end_angle, point_count, outline_color, 1.0)
	draw_arc(Vector2.ZERO, outer_radius, start_angle, end_angle, point_count, outline_color, 1.0)
	# Connect the sides
	var inner_start = Vector2.from_angle(start_angle) * inner_radius
	var outer_start = Vector2.from_angle(start_angle) * outer_radius
	var inner_end = Vector2.from_angle(end_angle) * inner_radius
	var outer_end = Vector2.from_angle(end_angle) * outer_radius
	draw_line(inner_start, outer_start, outline_color, 1.0)
	draw_line(inner_end, outer_end, outline_color, 1.0)
