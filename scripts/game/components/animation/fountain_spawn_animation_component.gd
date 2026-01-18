class_name FountainSpawnAnimationComponent
extends Node

## Animates the parent node in a fountain arc when spawned.
## Add to collectibles or other items that should arc out when dropped.

@export var enabled: bool = true
@export var launch_height: float = 40.0  # Peak height of the arc
@export var launch_duration: float = 0.5  # Time to complete the arc
@export var spread_radius: float = 20.0  # Horizontal distance to travel
@export var height_variance: float = 10.0  # Random variation in height
@export var duration_variance: float = 0.1  # Random variation in duration

var _start_position: Vector2
var _target_offset: Vector2
var _arc_height: float
var _tween: Tween

func _ready() -> void:
	if not enabled:
		return
	_start_animation()

func _start_animation() -> void:
	var parent = get_parent()
	if not parent or not parent is Node2D:
		return

	_start_position = parent.global_position

	# Random horizontal offset for landing
	_target_offset = Vector2(
		randf_range(-spread_radius, spread_radius),
		randf_range(-spread_radius * 0.3, spread_radius * 0.3)
	)

	# Randomize height and duration
	_arc_height = launch_height + randf_range(-height_variance, height_variance)
	var duration = launch_duration + randf_range(-duration_variance, duration_variance)

	# Create tween for the arc animation
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_LINEAR)

	# Use a method to calculate parabolic position each frame
	_tween.tween_method(_update_arc_position, 0.0, 1.0, duration)
	_tween.tween_callback(_on_animation_finished)

func _update_arc_position(t: float) -> void:
	var parent = get_parent() as Node2D
	if not parent:
		return

	# Horizontal: linear interpolation
	var x = _start_position.x + _target_offset.x * t

	# Vertical: parabolic arc (goes up then down)
	# Formula: y = start_y - height * 4t(1-t) + offset_y * t
	# The 4t(1-t) term creates a parabola peaking at t=0.5
	var arc = _arc_height * 4.0 * t * (1.0 - t)
	var y = _start_position.y - arc + _target_offset.y * t

	parent.global_position = Vector2(x, y)

func _on_animation_finished() -> void:
	# Animation complete - item is now at rest
	pass
