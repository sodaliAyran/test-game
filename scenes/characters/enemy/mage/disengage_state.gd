extends NodeState

## Disengage state - mage retreats from the player to restore safe distance.
## Transitions back to Engage once safe_distance is reached.
## Does NOT fire skills while retreating.

@export var movement: MovementComponent
@export var sense: EnemySenseComponent
@export var separation: SeparationComponent
@export var hurtbox: HurtboxComponent
@export var health: HealthComponent
@export var facing: FacingComponent
@export var wobble_animation: WobbleAnimationComponent

## Distance at which the mage considers itself safe and returns to Engage
@export var safe_distance: float = 90.0

var got_hurt: bool = false
var target: Node2D = null


func _on_enter() -> void:
	got_hurt = false
	target = sense.current_target
	_connect_hurtbox()
	_connect_health()


func _on_process(delta: float) -> void:
	if got_hurt:
		got_hurt = false
		transition.emit("Hurt")
		return

	if not target or not is_instance_valid(target):
		transition.emit("Idle")
		return

	# Check if we've reached safe distance
	var distance_to_target = owner.global_position.distance_to(target.global_position)
	if distance_to_target >= safe_distance:
		transition.emit("Engage")
		return

	# Calculate retreat direction (away from player)
	var retreat_direction = (owner.global_position - target.global_position).normalized()

	# Blend with separation to avoid stacking with other enemies
	if separation:
		var separation_force = separation.get_separation_vector()
		retreat_direction = (retreat_direction + separation_force * 0.3).normalized()

	# Update facing
	if facing:
		facing.set_facing_from_direction(retreat_direction)

	# Update wobble animation
	if wobble_animation:
		var retreat_target_pos = owner.global_position + retreat_direction * 100.0
		wobble_animation.play(delta, retreat_direction, retreat_target_pos)

	movement.set_velocity(retreat_direction)


func _on_physics_process(_delta: float) -> void:
	pass


func _on_next_transitions() -> void:
	pass


func _on_exit() -> void:
	if movement:
		movement.set_velocity(Vector2.ZERO)
	if wobble_animation:
		wobble_animation.reset()
	_disconnect_hurtbox()
	_disconnect_health()


func _connect_hurtbox() -> void:
	if hurtbox and not hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.connect(_on_hurt)

func _on_hurt(_amount) -> void:
	got_hurt = true

func _disconnect_hurtbox() -> void:
	if hurtbox and hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.disconnect(_on_hurt)

func _connect_health() -> void:
	if health and not health.died.is_connected(_on_death):
		health.died.connect(_on_death)

func _on_death() -> void:
	transition.emit("Death")

func _disconnect_health() -> void:
	if health and health.died.is_connected(_on_death):
		health.died.disconnect(_on_death)
