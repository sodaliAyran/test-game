class_name FacingIndicatorComponent
extends Node2D

## Visual indicator showing the player's facing direction.
## Draws an arc matching the sword attack range.
## Glows blue when the linked skill is off cooldown.

@export var facing: FacingComponent
@export var inner_radius: float = 20.0      ## Start distance from player center
@export var outer_radius: float = 55.0      ## End distance (sword reach)
@export var arc_angle: float = PI / 3       ## Arc span (60 degrees, narrower than sword)
@export var skill_id: String = "sword_slash" ## Skill to track cooldown for
@export_group("Cooldown Colors")
@export var color_idle: Color = Color(1, 1, 1, 0.08)           ## On cooldown fill
@export var outline_idle: Color = Color(1, 1, 1, 0.2)          ## On cooldown outline
@export var color_ready: Color = Color(0.3, 0.6, 1.0, 0.3)    ## Ready fill (blue)
@export var outline_ready: Color = Color(0.4, 0.7, 1.0, 0.7)  ## Ready outline (blue)
@export var transition_duration: float = 0.12
@export var color_fade_duration: float = 0.15                  ## Fade between ready/cooldown

var _current_angle: float = 0.0
var _tween: Tween
var _color_tween: Tween
var _cooldown: SkillCooldownComponent
var _fill_color: Color
var _outline_color: Color


func _ready() -> void:
	_fill_color = color_idle
	_outline_color = outline_idle
	if facing:
		facing.facing_changed.connect(_on_facing_changed)
		_current_angle = facing.facing_direction.angle()
	_try_connect_cooldown()
	SkillCooldownRegistry.skill_registered.connect(_on_skill_registered)
	queue_redraw()


func _try_connect_cooldown() -> void:
	var cooldown = SkillCooldownRegistry.get_cooldown(skill_id)
	if cooldown:
		_bind_cooldown(cooldown)


func _on_skill_registered(id: String, cooldown: SkillCooldownComponent) -> void:
	if id == skill_id:
		_bind_cooldown(cooldown)


func _bind_cooldown(cooldown: SkillCooldownComponent) -> void:
	if _cooldown:
		_cooldown.cooldown_ready.disconnect(_on_cooldown_ready)
		_cooldown.cooldown_started.disconnect(_on_cooldown_started)
	_cooldown = cooldown
	_cooldown.cooldown_ready.connect(_on_cooldown_ready)
	_cooldown.cooldown_started.connect(_on_cooldown_started)
	if _cooldown.is_ready:
		_set_colors(color_ready, outline_ready)
	else:
		_set_colors(color_idle, outline_idle)
	queue_redraw()


func _on_cooldown_ready() -> void:
	_fade_colors(color_ready, outline_ready)


func _on_cooldown_started() -> void:
	_fade_colors(color_idle, outline_idle)


func _fade_colors(target_fill: Color, target_outline: Color) -> void:
	if _color_tween:
		_color_tween.kill()
	_color_tween = create_tween().set_parallel(true)
	_color_tween.tween_method(_set_fill_color, _fill_color, target_fill, color_fade_duration)
	_color_tween.tween_method(_set_outline_color, _outline_color, target_outline, color_fade_duration)


func _set_colors(fill: Color, outline: Color) -> void:
	_fill_color = fill
	_outline_color = outline


func _set_fill_color(c: Color) -> void:
	_fill_color = c
	queue_redraw()


func _set_outline_color(c: Color) -> void:
	_outline_color = c
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

	draw_colored_polygon(points, _fill_color)

	# Draw outline arcs
	draw_arc(Vector2.ZERO, inner_radius, start_angle, end_angle, point_count, _outline_color, 1.0)
	draw_arc(Vector2.ZERO, outer_radius, start_angle, end_angle, point_count, _outline_color, 1.0)
	# Connect the sides
	var inner_start = Vector2.from_angle(start_angle) * inner_radius
	var outer_start = Vector2.from_angle(start_angle) * outer_radius
	var inner_end = Vector2.from_angle(end_angle) * inner_radius
	var outer_end = Vector2.from_angle(end_angle) * outer_radius
	draw_line(inner_start, outer_start, _outline_color, 1.0)
	draw_line(inner_end, outer_end, _outline_color, 1.0)
