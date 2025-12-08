class_name WeaponComponent
extends Node

@export var sprite: Sprite2D
@export var hitbox: HitboxComponent
@export var hitbox_collision: CollisionShape2D
@export var attack_cooldown: float = 1.0
@export var attack_duration: float = 0.3

var _cooldown_timer: Timer
var _attack_timer: Timer

func _ready() -> void:
	if sprite:
		sprite.visible = false
	if hitbox:
		hitbox.active = false
	if hitbox_collision:
		hitbox_collision.disabled = true
	_cooldown()
	_attack()
	
func _cooldown() -> void:
	_cooldown_timer = Timer.new()
	_cooldown_timer.wait_time = attack_cooldown
	_cooldown_timer.one_shot = false
	_cooldown_timer.autostart = true
	_cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(_cooldown_timer)
	
func _attack() -> void:
	_attack_timer = Timer.new()
	_attack_timer.wait_time = attack_duration
	_attack_timer.one_shot = true
	_attack_timer.timeout.connect(_on_attack_timeout)
	add_child(_attack_timer)

func _on_cooldown_timeout() -> void:
	_start_attack()

func _start_attack() -> void:
	if sprite:
		sprite.visible = true
	if hitbox_collision:
		hitbox_collision.disabled = false
	if hitbox:
		hitbox.active = true
	
	_attack_timer.start()

func _on_attack_timeout() -> void:
	_end_attack()

func _end_attack() -> void:
	if hitbox_collision:
		hitbox_collision.disabled = true
	if sprite:
		sprite.visible = false
	if hitbox:
		hitbox.active = false

func trigger_attack() -> void:
	if _cooldown_timer.is_stopped():
		_start_attack()
		_cooldown_timer.start()

func reset_cooldown() -> void:
	_cooldown_timer.stop()
	_cooldown_timer.start()
