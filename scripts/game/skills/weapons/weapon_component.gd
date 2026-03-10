class_name WeaponComponent
extends Node

@export var sprite: Sprite2D
@export var hitbox: HitboxComponent
@export var hitbox_collision: CollisionShape2D
@export var skill_modifier: SkillModifierComponent
@export var cooldown: SkillCooldownComponent
@export var attack_duration: float = 0.3
@export var fade_duration: float = 0.1
@export var auto_trigger_on_cooldown: bool = true  ## When false, weapon only fires via external trigger_attack() calls

signal attack_started(target: Node2D)
signal attack_ended

var attack_target: Node2D
var attack_position: Variant = null  ## Optional fixed position (Vector2) override
var _attack_timer: Timer
var _tween: Tween


func _ready() -> void:
	if sprite:
		sprite.visible = true  # Keep visible but transparent
		sprite.modulate.a = 0.0  # Start fully transparent
	if hitbox:
		hitbox.active = false

	_setup_attack_timer()
	_connect_cooldown()


func _setup_attack_timer() -> void:
	_attack_timer = Timer.new()
	_attack_timer.wait_time = attack_duration
	_attack_timer.one_shot = true
	_attack_timer.timeout.connect(_on_attack_timeout)
	add_child(_attack_timer)


func _connect_cooldown() -> void:
	if cooldown and auto_trigger_on_cooldown:
		cooldown.cooldown_ready.connect(_on_cooldown_ready)
		# Defer first attack so all sibling nodes have finished _ready()
		_on_cooldown_ready.call_deferred()


func _on_cooldown_ready() -> void:
	trigger_attack()
	if cooldown:
		cooldown.start_cooldown()

func _start_attack() -> void:
	# Get skill modifiers
	var damage_mult = 1.0
	var size_mult = 1.0
	var speed_mult = 1.0

	if skill_modifier:
		damage_mult = skill_modifier.get_damage_multiplier()
		size_mult = skill_modifier.get_attack_size_multiplier()
		speed_mult = skill_modifier.get_attack_speed_multiplier()

	# Apply speed multiplier to attack timer
	_attack_timer.wait_time = attack_duration / maxf(speed_mult, 0.01)

	# Emit signal FIRST so listeners can reposition hitbox before it's enabled
	attack_started.emit(attack_target)

	# Kill any existing tween
	if _tween:
		_tween.kill()

	# Apply size multiplier to sprite
	if sprite:
		sprite.scale = Vector2.ONE * size_mult
		_tween = create_tween()
		_tween.tween_property(sprite, "modulate:a", 1.0, fade_duration)

	# Apply damage multiplier to hitbox
	if hitbox:
		hitbox.set_damage_multiplier(damage_mult)

	# Reposition hitbox to fixed attack position (e.g. slam)
	if hitbox and attack_position is Vector2:
		hitbox.global_position = attack_position

	# Activate hitbox — collision shape is always enabled,
	# so area_entered events are already tracked by the physics engine.
	# Setting active = true allows those events to deal damage.
	if hitbox:
		hitbox.active = true

	_attack_timer.start()

func _on_attack_timeout() -> void:
	_end_attack()

func _end_attack() -> void:
	# Deactivate hitbox — stops processing hits, clears hit_targets
	if hitbox:
		hitbox.active = false

	# Fade out the sprite
	if sprite:
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(sprite, "modulate:a", 0.0, fade_duration)

	# Emit signal for other components to react
	attack_ended.emit()

func trigger_attack(target: Node2D = null) -> void:
	attack_target = target
	attack_position = null
	_start_attack()


func trigger_attack_at_position(position: Vector2) -> void:
	attack_target = null
	attack_position = position
	_start_attack()
