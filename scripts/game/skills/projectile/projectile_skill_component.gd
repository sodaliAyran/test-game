class_name ProjectileSkillComponent
extends Node

## Skill component for projectile attacks.
## Implements the generic skill interface (can_use, request_use, cancel_pending_request).
## Handles spawning, patterns, cooldown, and AP integration.

@export var character_body: CharacterBody2D
@export var facing: FacingComponent
@export var skill_modifier: SkillModifierComponent
@export var director_request: CombatDirectorRequestComponent
@export var cooldown: SkillCooldownComponent
@export var trigger_area: SkillTriggerArea

@export_group("Projectile")
@export var projectile_scene: PackedScene  ## The projectile scene to spawn

@export_group("Spawn Pattern")
@export var projectile_count: int = 1
@export var spread_angle: float = 0.0  ## Total spread angle for multiple projectiles (degrees)
@export var burst_delay: float = 0.0  ## Delay between projectiles (0 = simultaneous)
@export var spawn_offset: Vector2 = Vector2(20, 0)  ## Offset from character center

@export_group("Targeting")
@export var auto_target_range: float = 300.0  ## Range for player auto-targeting

@export_group("AP Integration")
@export var ap_cost: float = 1.5
@export var ap_priority: int = 55
@export var action_label: String = "projectile_attack"

@export_group("Windup")
@export var windup_duration: float = 0.0
@export var windup_sprite: Sprite2D  ## Sprite for windup effect (optional)

signal projectile_fired(projectile: Node2D)
signal all_projectiles_fired
signal windup_started
signal windup_finished

var _active: bool = false  ## Set by state on enter/exit
var _pending: bool = false
var _pending_direction: Vector2 = Vector2.ZERO
var _pending_target: Node2D = null
var _burst_timer: Timer
var _burst_remaining: int = 0
var _windup_timer: Timer


func _ready() -> void:
	_find_character_body()
	_find_facing_component()
	_setup_timers()
	_connect_trigger_area()


func _connect_trigger_area() -> void:
	if trigger_area:
		trigger_area.attack_triggered.connect(_on_trigger_area_triggered)


func _on_trigger_area_triggered() -> void:
	fire_auto_target()


func _find_character_body() -> void:
	if character_body:
		return
	# Search up the tree for a CharacterBody2D
	var node = get_parent()
	while node:
		if node is CharacterBody2D:
			character_body = node
			return
		node = node.get_parent()
	push_warning("ProjectileSkillComponent: Could not find CharacterBody2D in parent hierarchy")


func _find_facing_component() -> void:
	if facing:
		return
	# Search up the tree for a FacingComponent
	var node = get_parent()
	while node:
		var found = node.find_child("FacingComponent", false, false)
		if found and found is FacingComponent:
			facing = found
			return
		node = node.get_parent()


func _setup_timers() -> void:
	_burst_timer = Timer.new()
	_burst_timer.one_shot = true
	_burst_timer.timeout.connect(_on_burst_timer_timeout)
	add_child(_burst_timer)

	_windup_timer = Timer.new()
	_windup_timer.one_shot = true
	_windup_timer.timeout.connect(_on_windup_timeout)
	add_child(_windup_timer)


## Skill interface - called by state on enter
func activate() -> void:
	_active = true


## Skill interface - called by state on exit
func deactivate() -> void:
	_active = false
	cancel_pending_request()


## Skill interface - check if skill can be used
func can_use() -> bool:
	if not _active:
		return false
	if _pending:
		return false
	if cooldown and not cooldown.is_ready:
		return false
	if director_request and director_request.has_pending_request():
		return false
	return true


## Skill interface - request to use skill (for enemies via AP system)
func request_use(context: Dictionary) -> bool:
	if not can_use():
		return false

	var target: Node2D = context.get("target")
	if not target:
		return false

	var direction = (target.global_position - character_body.global_position).normalized()

	# If no director component, fire immediately
	if not director_request:
		_execute_fire(direction, target)
		return true

	# Store for when AP is approved
	_pending_direction = direction
	_pending_target = target

	# Create AP request
	var request = APRequest.create(
		character_body,
		action_label,
		ap_cost,
		Callable(self, "_on_ap_approved"),
		ap_priority
	)

	if director_request.request_action(request):
		_pending = true
		return true

	return false


## Skill interface - cancel pending request
func cancel_pending_request() -> void:
	if _windup_timer and not _windup_timer.is_stopped():
		_windup_timer.stop()

	if _burst_timer and not _burst_timer.is_stopped():
		_burst_timer.stop()
		_burst_remaining = 0

	if director_request:
		director_request.cancel_pending_request()

	_pending = false
	_pending_direction = Vector2.ZERO
	_pending_target = null


## Direct fire - for player use (no AP check)
func fire(direction: Vector2, target: Node2D = null) -> void:
	_execute_fire(direction, target)


## Fire toward a specific target
func fire_at_target(target: Node2D) -> void:
	if not target or not is_instance_valid(target):
		return

	var direction = (target.global_position - character_body.global_position).normalized()
	var homing_target = target if _projectile_has_homing() else null
	_execute_fire(direction, homing_target)


## Fire with auto-targeting (for player)
func fire_auto_target() -> void:
	if not character_body:
		push_error("ProjectileSkillComponent: character_body is null in fire_auto_target")
		return

	var enemies = SpatialGrid.query_nearby(
		character_body.global_position,
		auto_target_range,
		"enemies",
		character_body
	)

	print("DEBUG fire_auto_target: found %d enemies, character_body=%s" % [enemies.size(), character_body.name])

	if enemies.size() > 0:
		var nearest = _get_nearest_entity(enemies)
		fire_at_target(nearest)
	else:
		# No target found, fire in facing direction
		var direction = facing.facing_direction if facing else Vector2.RIGHT
		print("DEBUG fire_auto_target: no enemies, firing in direction %s" % direction)
		fire(direction, null)


func _on_ap_approved() -> void:
	"""Called when CombatDirector approves the request"""
	if windup_duration > 0.0:
		windup_started.emit()
		_windup_timer.wait_time = windup_duration
		_windup_timer.start()
	else:
		_execute_fire(_pending_direction, _pending_target)


func _on_windup_timeout() -> void:
	windup_finished.emit()
	_execute_fire(_pending_direction, _pending_target)


func _execute_fire(direction: Vector2, target: Node2D) -> void:
	_pending = false
	_pending_direction = Vector2.ZERO
	_pending_target = null

	if projectile_count <= 1 or burst_delay <= 0.0:
		# Fire all projectiles simultaneously
		_spawn_pattern(direction, target)
		_on_all_fired()
	else:
		# Fire in burst sequence
		_burst_remaining = projectile_count
		_spawn_single_in_pattern(direction, target, 0)
		_burst_remaining -= 1

		if _burst_remaining > 0:
			_burst_timer.wait_time = burst_delay
			_burst_timer.start()
		else:
			_on_all_fired()


func _on_burst_timer_timeout() -> void:
	if _burst_remaining <= 0:
		_on_all_fired()
		return

	var index = projectile_count - _burst_remaining
	_spawn_single_in_pattern(_pending_direction, _pending_target, index)
	_burst_remaining -= 1

	if _burst_remaining > 0:
		_burst_timer.start()
	else:
		_on_all_fired()


func _on_all_fired() -> void:
	# Start cooldown
	if cooldown:
		cooldown.start_cooldown()

	# Notify combat director that action is complete
	if director_request:
		director_request.complete_action()

	all_projectiles_fired.emit()


func _spawn_pattern(base_direction: Vector2, target: Node2D) -> void:
	"""Spawn all projectiles in the pattern simultaneously"""
	if projectile_count <= 1:
		_spawn_projectile(base_direction, target)
		return

	# Calculate spread angles
	var half_spread = deg_to_rad(spread_angle) / 2.0
	var base_angle = base_direction.angle()

	for i in range(projectile_count):
		var t = float(i) / float(projectile_count - 1) if projectile_count > 1 else 0.5
		var angle_offset = lerp(-half_spread, half_spread, t)
		var direction = Vector2.from_angle(base_angle + angle_offset)
		_spawn_projectile(direction, target)


func _spawn_single_in_pattern(base_direction: Vector2, target: Node2D, index: int) -> void:
	"""Spawn a single projectile at the given index in the pattern"""
	if projectile_count <= 1:
		_spawn_projectile(base_direction, target)
		return

	var half_spread = deg_to_rad(spread_angle) / 2.0
	var base_angle = base_direction.angle()
	var t = float(index) / float(projectile_count - 1) if projectile_count > 1 else 0.5
	var angle_offset = lerp(-half_spread, half_spread, t)
	var direction = Vector2.from_angle(base_angle + angle_offset)
	_spawn_projectile(direction, target)


func _spawn_projectile(direction: Vector2, target: Node2D) -> Node2D:
	if not projectile_scene:
		push_error("ProjectileSkillComponent: No projectile_scene assigned")
		return null

	var projectile = projectile_scene.instantiate()

	# Add to scene tree
	character_body.get_tree().current_scene.add_child(projectile)

	# Position projectile
	var spawn_pos = _calculate_spawn_position(direction)
	projectile.global_position = spawn_pos
	print("DEBUG _spawn_projectile: spawned at %s, direction=%s" % [spawn_pos, direction])

	# Get modifiers
	var damage_mult = 1.0
	var speed_mult = 1.0
	if skill_modifier:
		damage_mult = skill_modifier.get_damage_multiplier()
		speed_mult = skill_modifier.get_attack_speed_multiplier()

	# Initialize the projectile component
	var projectile_component = projectile.get_node_or_null("ProjectileComponent") as ProjectileComponent
	if projectile_component:
		print("DEBUG _spawn_projectile: initializing ProjectileComponent")
		projectile_component.initialize(direction, target, character_body, damage_mult, speed_mult)
	else:
		push_error("ProjectileSkillComponent: ProjectileComponent not found in spawned projectile")

	projectile_fired.emit(projectile)
	return projectile


func _calculate_spawn_position(direction: Vector2) -> Vector2:
	var base_pos = character_body.global_position

	# Apply offset in the direction of fire
	var offset = Vector2.ZERO
	if spawn_offset != Vector2.ZERO:
		# Rotate offset to match direction
		var angle = direction.angle()
		offset = spawn_offset.rotated(angle)

	return base_pos + offset


func _get_nearest_entity(entities: Array[Node2D]) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist_sq: float = INF

	for entity in entities:
		if not is_instance_valid(entity):
			continue
		var dist_sq = character_body.global_position.distance_squared_to(entity.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = entity

	return nearest


func _projectile_has_homing() -> bool:
	"""Check if the projectile scene has homing enabled"""
	if not projectile_scene:
		return false

	# We can't easily check this without instantiating, so we'll pass the target
	# and let the ProjectileComponent decide based on its homing_enabled setting
	return true


func is_winding_up() -> bool:
	return _windup_timer and not _windup_timer.is_stopped()
