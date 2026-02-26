class_name SkillTriggerArea
extends Area2D

## Area2D-based trigger for skills. Emits signal when valid targets are in range
## and conditions are met (cone direction, cooldown).
## Works for both player and enemy skills (weapons, projectiles, etc.).
## Uses signals for efficient detection - no per-frame polling.

signal targets_changed
signal attack_triggered  ## Emitted when trigger conditions are met - skill should respond

@export var detection_radius: float = 80.0
@export var target_group: String = ""  ## Optional group filter. If empty, uses collision mask only.
@export var cooldown: Node  ## SkillCooldownComponent - optional cooldown manager

@export_group("Direction Filter")
@export var require_direction: bool = true  ## Require character facing toward target
@export var cone_angle: float = 45.0  ## Half-angle in degrees (45 = 90 degree total cone)

@export_group("Debug")
@export var debug_visible: bool = false  ## Show detection area and cone
@export var debug_color_area: Color = Color(0.2, 0.6, 1.0, 0.2)  ## Circle fill color
@export var debug_color_cone: Color = Color(0.2, 1.0, 0.2, 0.4)  ## Cone color when direction active
@export var debug_color_ready: Color = Color(1.0, 1.0, 0.2, 0.3)  ## Color when ready to fire

var targets_in_area: Array[Node2D] = []
var _collision_shape: CollisionShape2D
var facing: FacingComponent


func _ready() -> void:
	_find_facing_component()
	_setup_collision_shape()
	_connect_signals()
	set_process(debug_visible)


func _find_facing_component() -> void:
	# Search up the tree for a FacingComponent
	var node = get_parent()
	while node:
		var found = node.find_child("FacingComponent", false, false)
		if found and found is FacingComponent:
			facing = found
			facing.facing_changed.connect(_on_facing_changed)
			return
		node = node.get_parent()
	if require_direction:
		push_warning("SkillTriggerArea: Could not find FacingComponent in parent hierarchy")


func _process(_delta: float) -> void:
	if debug_visible:
		queue_redraw()


func _draw() -> void:
	if not debug_visible:
		return

	# Draw detection circle
	draw_circle(Vector2.ZERO, detection_radius, debug_color_area)
	draw_arc(Vector2.ZERO, detection_radius, 0, TAU, 32, debug_color_area.lightened(0.3), 2.0)

	# Draw direction cone if direction filtering is enabled
	if require_direction:
		var direction = _get_direction()
		if direction != Vector2.ZERO:
			var color = debug_color_ready if _is_ready() and _has_valid_target() else debug_color_cone
			_draw_cone(direction, color)


func _draw_cone(direction: Vector2, color: Color) -> void:
	var angle = direction.angle()
	var half_cone = deg_to_rad(cone_angle)
	var start_angle = angle - half_cone
	var end_angle = angle + half_cone

	# Draw cone as filled polygon
	var points: PackedVector2Array = [Vector2.ZERO]
	var segments = 16
	for i in range(segments + 1):
		var t = float(i) / segments
		var a = lerp(start_angle, end_angle, t)
		points.append(Vector2.from_angle(a) * detection_radius)
	draw_colored_polygon(points, color)

	# Draw cone outline
	draw_arc(Vector2.ZERO, detection_radius, start_angle, end_angle, segments, color.lightened(0.3), 2.0)
	draw_line(Vector2.ZERO, Vector2.from_angle(start_angle) * detection_radius, color.lightened(0.3), 2.0)
	draw_line(Vector2.ZERO, Vector2.from_angle(end_angle) * detection_radius, color.lightened(0.3), 2.0)


func _setup_collision_shape() -> void:
	# Check if a collision shape already exists in the scene
	for child in get_children():
		if child is CollisionShape2D:
			_collision_shape = child
			# Update the radius if it's a CircleShape2D
			if _collision_shape.shape is CircleShape2D:
				(_collision_shape.shape as CircleShape2D).radius = detection_radius
			return

	# Create one dynamically if not present
	var shape = CircleShape2D.new()
	shape.radius = detection_radius
	_collision_shape = CollisionShape2D.new()
	_collision_shape.shape = shape
	add_child(_collision_shape)


func _connect_signals() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if cooldown:
		cooldown.cooldown_ready.connect(_on_cooldown_ready)


func _on_body_entered(body: Node2D) -> void:
	# If target_group is set, check group membership. Otherwise accept any body.
	if target_group.is_empty() or body.is_in_group(target_group):
		targets_in_area.append(body)
		targets_changed.emit()
		_try_trigger()


func _on_body_exited(body: Node2D) -> void:
	targets_in_area.erase(body)
	targets_changed.emit()


func _on_cooldown_ready() -> void:
	# Weapon became ready - check if we should fire
	_try_trigger()


func _on_facing_changed(_new_direction: Vector2) -> void:
	# Player turned - check if enemies now in cone
	_try_trigger()


func _try_trigger() -> void:
	if not _has_valid_target():
		return
	if not _is_ready():
		return
	_trigger()


func _has_valid_target() -> bool:
	if targets_in_area.is_empty():
		return false

	# Clean up invalid targets
	targets_in_area = targets_in_area.filter(func(t): return is_instance_valid(t))
	if targets_in_area.is_empty():
		return false

	if not require_direction:
		return true  # Any target in area is valid

	# Check cone
	var direction = _get_direction()
	if direction == Vector2.ZERO:
		return false

	for target in targets_in_area:
		if _is_in_cone(target.global_position, direction):
			return true

	return false


func _is_in_cone(target_pos: Vector2, direction: Vector2) -> bool:
	var to_target = (target_pos - global_position).normalized()
	var angle_cos = to_target.dot(direction.normalized())
	var cone_cos = cos(deg_to_rad(cone_angle))
	return angle_cos >= cone_cos


func _get_direction() -> Vector2:
	if facing:
		return facing.facing_direction
	return Vector2.ZERO


func _is_ready() -> bool:
	if cooldown:
		return cooldown.is_ready
	return true  # No cooldown = always ready


func _trigger() -> void:
	attack_triggered.emit()
	if cooldown:
		cooldown.start_cooldown()


func set_detection_radius(new_radius: float) -> void:
	detection_radius = new_radius
	if _collision_shape and _collision_shape.shape is CircleShape2D:
		(_collision_shape.shape as CircleShape2D).radius = new_radius
