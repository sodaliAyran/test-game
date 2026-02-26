class_name ProjectileComponent
extends Node

## Handles projectile flight behavior: movement, homing, falloff, and collision.
## Attach to an Area2D scene that represents the projectile.
## The parent Area2D handles collision detection.

@export_group("Movement")
@export var speed: float = 400.0
@export var max_distance: float = 500.0
@export var lifetime: float = 5.0

@export_group("Homing")
@export var homing_enabled: bool = false
@export var homing_turn_rate: float = 180.0  ## Degrees per second
@export var homing_acquire_delay: float = 0.1  ## Delay before homing activates
@export var homing_lose_target_range: float = 800.0  ## Stop homing if target beyond this

@export_group("Visuals")
@export var rotate_to_direction: bool = true
@export var sprite: Node2D  ## Sprite2D or AnimatedSprite2D

@export_group("Combat")
@export var hitbox: HitboxComponent
@export var pierce_count: int = 0  ## 0 = destroy on first hit
@export var linger_time: float = 0.0  ## Time to linger after hit before destroying (0 = instant)

@export_group("Impact Particles")
@export var impact_particles_enabled: bool = false
@export var impact_particle_color: Color = Color(0.6, 0.4, 1.0, 1.0)
@export var impact_particle_count: int = 8

@export_group("Collision")
@export_flags_2d_physics var wall_collision_mask: int = 1  ## Layer 1 is typically walls/environment

signal hit_target(target: HurtboxComponent)
signal destroyed(reason: String)

var direction: Vector2 = Vector2.RIGHT
var homing_target: Node2D = null
var source_entity: Node2D = null
var speed_multiplier: float = 1.0

var _is_initialized: bool = false
var _is_destroyed: bool = false
var _distance_traveled: float = 0.0
var _lifetime_timer: float = 0.0
var _homing_delay_timer: float = 0.0
var _pierce_remaining: int = 0
var _start_position: Vector2
var _parent_area: Area2D


func _ready() -> void:
	_parent_area = get_parent() as Area2D
	if not _parent_area:
		push_error("ProjectileComponent must be a child of Area2D")
		return

	_setup_collision()
	_setup_hitbox()


func _setup_collision() -> void:
	if not _parent_area:
		return

	# Connect body entered for wall collision
	if not _parent_area.body_entered.is_connected(_on_body_entered):
		_parent_area.body_entered.connect(_on_body_entered)

	# Connect area entered for any area collision (enemies, obstacles)
	if not _parent_area.area_entered.is_connected(_on_area_entered):
		_parent_area.area_entered.connect(_on_area_entered)


func _setup_hitbox() -> void:
	if not hitbox:
		return

	hitbox.active = true
	if not hitbox.hit.is_connected(_on_hitbox_hit):
		hitbox.hit.connect(_on_hitbox_hit)


func initialize(dir: Vector2, target: Node2D, source: Node2D, damage_mult: float = 1.0, speed_mult: float = 1.0) -> void:
	"""Configure the projectile before it starts moving.
	Call this after adding to scene tree but before _physics_process runs."""
	direction = dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT
	homing_target = target if homing_enabled else null
	source_entity = source
	speed_multiplier = speed_mult
	_pierce_remaining = pierce_count
	_start_position = _parent_area.global_position if _parent_area else Vector2.ZERO

	print("DEBUG ProjectileComponent.initialize: dir=%s, speed=%s, _parent_area=%s" % [direction, speed * speed_multiplier, _parent_area])

	if hitbox:
		hitbox.set_damage_multiplier(damage_mult)

	_update_rotation()
	_is_initialized = true


func _physics_process(delta: float) -> void:
	if not _is_initialized or _is_destroyed:
		return

	if not _parent_area:
		return

	_lifetime_timer += delta

	# Check lifetime falloff
	if _lifetime_timer >= lifetime:
		_destroy("lifetime")
		return

	# Update homing if enabled
	if homing_enabled:
		_update_homing(delta)

	# Move in current direction
	var velocity = direction * speed * speed_multiplier
	_parent_area.global_position += velocity * delta

	# Track distance traveled
	_distance_traveled = _parent_area.global_position.distance_to(_start_position)

	# Check distance falloff
	if _distance_traveled >= max_distance:
		_destroy("distance")
		return

	_update_rotation()


func _update_homing(delta: float) -> void:
	# Delay before homing activates
	_homing_delay_timer += delta
	if _homing_delay_timer < homing_acquire_delay:
		return

	# Check if target is valid
	if not homing_target or not is_instance_valid(homing_target):
		homing_target = null
		return

	# Check if target is too far
	var distance_to_target = _parent_area.global_position.distance_to(homing_target.global_position)
	if distance_to_target > homing_lose_target_range:
		homing_target = null
		return

	# Calculate turn toward target
	var target_direction = (homing_target.global_position - _parent_area.global_position).normalized()
	var current_angle = direction.angle()
	var target_angle = target_direction.angle()

	# Smoothly rotate toward target
	var turn_speed = deg_to_rad(homing_turn_rate) * delta
	var angle_diff = angle_difference(current_angle, target_angle)
	var new_angle = current_angle + clampf(angle_diff, -turn_speed, turn_speed)

	direction = Vector2.from_angle(new_angle)


func _update_rotation() -> void:
	if not rotate_to_direction:
		return

	if sprite:
		sprite.rotation = direction.angle()
	elif _parent_area:
		_parent_area.rotation = direction.angle()


func _on_hitbox_hit(target: HurtboxComponent) -> void:
	if _is_destroyed:
		return

	hit_target.emit(target)

	# Handle piercing
	if _pierce_remaining > 0:
		_pierce_remaining -= 1
		if _pierce_remaining <= 0:
			_destroy("pierce_exhausted")
	else:
		_destroy("collision")


func _on_area_entered(_area: Area2D) -> void:
	if _is_destroyed:
		return

	# Handle piercing
	if _pierce_remaining > 0:
		_pierce_remaining -= 1
		if _pierce_remaining <= 0:
			_destroy("pierce_exhausted")
	else:
		_destroy("collision")


func _on_body_entered(body: Node2D) -> void:
	if _is_destroyed:
		return

	# Check if this is a wall/environment collision
	# The body_entered signal only fires for bodies matching our collision mask
	# which we set to wall layer
	if body == source_entity:
		return

	# Skip if it's another character (handled by hitbox)
	if body is CharacterBody2D:
		return

	_destroy("wall")


func _destroy(reason: String) -> void:
	if _is_destroyed:
		return

	_is_destroyed = true

	if hitbox:
		hitbox.active = false

	if sprite:
		sprite.visible = false

	var hit_reasons := ["collision", "pierce_exhausted"]
	if impact_particles_enabled and reason in hit_reasons and _parent_area:
		_spawn_impact_particles()

	destroyed.emit(reason)

	if _parent_area:
		if linger_time > 0:
			await get_tree().create_timer(linger_time).timeout
		_parent_area.queue_free()


func _spawn_impact_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = impact_particle_count
	particles.lifetime = 0.3
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = impact_particle_color
	particles.global_position = _parent_area.global_position
	particles.z_index = _parent_area.z_index
	_parent_area.get_tree().current_scene.add_child(particles)
	particles.finished.connect(particles.queue_free)


func get_distance_traveled() -> float:
	return _distance_traveled


func get_lifetime_elapsed() -> float:
	return _lifetime_timer


func is_homing_active() -> bool:
	return homing_enabled and homing_target != null and _homing_delay_timer >= homing_acquire_delay
