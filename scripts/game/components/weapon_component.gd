class_name WeaponComponent
extends Node

@export var sprite: Sprite2D
@export var hitbox: HitboxComponent
@export var hitbox_collision: CollisionShape2D
@export var skill_modifier: SkillModifierComponent
@export var attack_duration: float = 0.3
@export var fade_duration: float = 0.1

signal attack_started
signal attack_ended

var _attack_timer: Timer
var _tween: Tween


func _ready() -> void:
	if sprite:
		sprite.visible = true  # Keep visible but transparent
		sprite.modulate.a = 0.0  # Start fully transparent
	if hitbox:
		hitbox.active = false
	if hitbox_collision:
		hitbox_collision.disabled = true
	
	_setup_attack_timer()


func _setup_attack_timer() -> void:
	_attack_timer = Timer.new()
	_attack_timer.wait_time = attack_duration
	_attack_timer.one_shot = true
	_attack_timer.timeout.connect(_on_attack_timeout)
	add_child(_attack_timer)

func _start_attack() -> void:
	# Get skill modifiers
	var damage_mult = 1.0
	var size_mult = 1.0
	
	if skill_modifier:
		damage_mult = skill_modifier.get_damage_multiplier()
		size_mult = skill_modifier.get_attack_size_multiplier()
	
	# Emit signal for other components to react
	attack_started.emit()
	
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
	
	# Enable hitbox
	if hitbox_collision:
		hitbox_collision.disabled = false
	if hitbox:
		hitbox.active = true
	
	_attack_timer.start()

func _on_attack_timeout() -> void:
	_end_attack()

func _end_attack() -> void:
	# Disable hitbox immediately
	if hitbox_collision:
		hitbox_collision.disabled = true
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

func trigger_attack() -> void:
	"""Trigger an attack (call this from external systems like AutoAttackComponent or state machine)"""
	_start_attack()
