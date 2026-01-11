class_name MovementComponent
extends Node

@export var character_body: CharacterBody2D
@export var move_speed: float = 300.0
@export var drag: float = 10.0
@export var knockback_decay: float = 5.0

var velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO
var speed_multiplier: float = 1.0  # For temporary speed boosts


func _physics_process(delta: float) -> void:
	if not character_body:
		return
	var total_velocity = velocity + knockback_velocity
	character_body.velocity = total_velocity
	
	character_body.move_and_slide()
	
	velocity = _decay_velocity(velocity, drag, delta)
	knockback_velocity = _decay_velocity(knockback_velocity, knockback_decay, delta)
	

func _decay_velocity(v: Vector2, decay: float, delta: float) -> Vector2:
	return v.move_toward(Vector2.ZERO, decay * delta)
	
func set_velocity(direction: Vector2) -> void:
	velocity = direction.normalized() * move_speed * speed_multiplier

func set_speed_multiplier(multiplier: float) -> void:
	speed_multiplier = multiplier
	
func apply_knockback(force: Vector2) -> void:
	knockback_velocity += force

func move(desired_velocity: Vector2) -> void:
	"""Helper method for states to directly set velocity"""
	velocity = desired_velocity * speed_multiplier
	
func stop() -> void:
	velocity = Vector2.ZERO

	
		
		
