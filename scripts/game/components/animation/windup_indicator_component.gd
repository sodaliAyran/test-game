class_name WindupIndicatorComponent
extends Node2D

const LineShapeRendererScript = preload("res://scripts/game/components/animation/line_shape_renderer.gd")

## Visual indicator for attack wind-ups. Shows outer boundary and a growing
## inner shape that fills over the duration. Supports multiple shape renderers.
##
## Usage:
##   var indicator = WindupIndicatorComponent.new()
##   indicator.duration = 0.4
##   indicator.configure_circle(attack_radius)
##   get_tree().current_scene.add_child(indicator)
##   indicator.global_position = attack_position
##   indicator.start()
##   indicator.completed.connect(_on_windup_completed)

signal completed
signal cancelled

@export var duration: float = 0.4
@export var outer_color: Color = Color(1.0, 0.2, 0.2, 0.25)
@export var inner_color: Color = Color(1.0, 0.2, 0.2, 0.4)

var _shape_renderer: RefCounted
var _elapsed: float = 0.0
var _active: bool = false
var progress: float = 0.0


func _ready() -> void:
	top_level = true
	set_process(false)


func configure_circle(radius: float) -> void:
	_shape_renderer = CircleShapeRenderer.create(radius)


func configure_line(direction: Vector2, length: float, width: float = 8.0) -> void:
	_shape_renderer = LineShapeRendererScript.create(direction, length, width)


func start() -> void:
	if not _shape_renderer:
		push_warning("WindupIndicatorComponent: No shape renderer configured")
		completed.emit()
		queue_free()
		return

	_elapsed = 0.0
	progress = 0.0
	_active = true
	set_process(true)
	queue_redraw()


func cancel() -> void:
	if not _active:
		return
	_active = false
	set_process(false)
	cancelled.emit()
	queue_free()


func is_active() -> bool:
	return _active


func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta

	if _elapsed >= duration:
		progress = 1.0
		_active = false
		set_process(false)
		queue_redraw()
		completed.emit()
		queue_free()
		return

	# Ease-in: starts slow, speeds up (progress^2)
	var linear_progress = _elapsed / duration
	progress = ease(linear_progress, 2.0)
	queue_redraw()


func _draw() -> void:
	if _shape_renderer:
		_shape_renderer.draw(self, progress, outer_color, inner_color)
