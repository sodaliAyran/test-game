extends NodeState

## State where enemy flees from player
## Enemies can be hurt while fleeing - transitions to Hurt then back to Flee

@export var movement: MovementComponent
@export var pathfinding: PathfindingComponent
@export var sense: EnemySenseComponent
@export var separation: SeparationComponent
@export var hurtbox: HurtboxComponent
@export var health: HealthComponent
@export var facing: FacingComponent
@export var wobble_animation: WobbleAnimationComponent

var flee_direction: Vector2 = Vector2.ZERO
var got_hurt: bool = false

func _on_enter() -> void:
	got_hurt = false
	_connect_hurtbox()
	_connect_health()

	# Calculate flee direction (opposite of player)
	if sense and sense.current_target:
		var to_player = (sense.current_target.global_position - owner.global_position).normalized()
		flee_direction = -to_player

func _on_process(delta: float) -> void:
	if got_hurt:
		got_hurt = false
		transition.emit("Hurt")
	
	# Update wobble animation while fleeing
	# Pass a position in the flee direction so enemy faces where they're running
	if wobble_animation:
		var flee_target_pos = owner.global_position + flee_direction * 100.0
		wobble_animation.play(delta, flee_direction, flee_target_pos)

func _on_physics_process(_delta: float) -> void:
	if not movement or not sense:
		return

	# Update flee direction periodically
	if sense.current_target:
		var to_player = (sense.current_target.global_position - owner.global_position).normalized()
		flee_direction = -to_player

	# Update facing direction
	if facing:
		facing.set_facing_from_direction(flee_direction)

	# Move away from player
	var desired_velocity = flee_direction * movement.move_speed

	# Apply separation to avoid other enemies
	if separation:
		var separation_force = separation.get_separation_vector()
		desired_velocity += separation_force

	movement.move(desired_velocity)

func _on_exit() -> void:
	movement.stop()
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
