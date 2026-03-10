class_name WeaponOrbitComponent
extends Node

## Positions a weapon node in an orbit around the parent, following a FacingComponent's direction.
## Smoothly tweens between angles using shortest-rotation-path logic.

@export var target: Node2D                       ## The weapon node to reposition
@export var facing: FacingComponent              ## The facing component to follow
@export var weapon_facing: FacingComponent       ## The weapon's own facing component (for sprite flip)
@export var orbit_radius: float = 20.0
@export var vertical_extra: float = 5.0          ## Extra distance added when facing up/down
@export var transition_duration: float = 0.12

var is_attack_animating: bool = false
var _current_angle: float = 0.0
var _tween: Tween


func _ready() -> void:
	if facing:
		facing.facing_changed.connect(_on_facing_changed)
		_current_angle = facing.facing_direction.angle()
		_apply_position()


func _on_facing_changed(new_direction: Vector2) -> void:
	if weapon_facing:
		weapon_facing.set_facing_from_direction(new_direction)

	var target_angle = new_direction.angle()

	# Shortest rotation path
	var angle_diff = target_angle - _current_angle
	while angle_diff > PI:
		angle_diff -= TAU
	while angle_diff < -PI:
		angle_diff += TAU
	var final_angle = _current_angle + angle_diff

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_angle, _current_angle, final_angle, transition_duration)


func _set_angle(angle: float) -> void:
	_current_angle = angle
	_apply_position()


func get_rest_transform() -> Dictionary:
	var vertical_factor = abs(sin(_current_angle))
	var radius = orbit_radius + vertical_extra * vertical_factor
	var offset = Vector2.from_angle(_current_angle) * radius
	return {
		"position": offset,
		"rotation": _current_angle,
		"scale_x": -1.0 if cos(_current_angle) > 0 else 1.0,
		"scale_y": -1.0 if cos(_current_angle) < 0 else 1.0,
	}


func _apply_position() -> void:
	if not target or is_attack_animating:
		return
	# Stretch the orbit vertically based on how much we're facing up/down
	var vertical_factor = abs(sin(_current_angle))  # 0 at left/right, 1 at top/bottom
	var radius = orbit_radius + vertical_extra * vertical_factor
	var offset = Vector2.from_angle(_current_angle) * radius
	target.position = offset
	target.rotation = _current_angle
	# Flip horizontally when facing right so the blade edge faces outward
	target.scale.x = -1.0 if cos(_current_angle) > 0 else 1.0
	# Flip vertically when facing left so the handle stays at the bottom
	target.scale.y = -1.0 if cos(_current_angle) < 0 else 1.0
