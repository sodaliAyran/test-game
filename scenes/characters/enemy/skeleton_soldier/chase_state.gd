extends NodeState

@export var movement: MovementComponent
@export var pathfinding: PathfindingComponent
@export var sense: EnemySenseComponent
@export var hurtbox: HurtboxComponent
@export var health: HealthComponent
@export var wobble_animation: WobbleAnimationComponent
@export var separation: SeparationComponent
@export var slot_seeker: Node  # SlotSeekerComponent

@export_range(0.0, 1.0) var pathfinding_weight: float = 0.7
@export_range(0.0, 1.0) var separation_weight: float = 0.3
## Distance threshold to consider the enemy "at" its slot position
@export var slot_arrival_distance: float = 10.0

var got_hurt: bool = false
var target: Node2D = null

func _on_process(delta : float) -> void:
	if got_hurt:
		got_hurt = false
		transition.emit("Hurt")
	if not movement or not pathfinding:
		return

	# Check if enemy has reached its slot position → transition to Engage
	if slot_seeker and slot_seeker.has_slot():
		var slot_pos = slot_seeker.get_target_position()
		var distance_to_slot = owner.global_position.distance_to(slot_pos)
		if distance_to_slot <= slot_arrival_distance:
			transition.emit("Engage")
			return

	# Use slot position if available, otherwise direct chase
	var chase_target_pos: Vector2
	if slot_seeker and slot_seeker.has_method("get_target_position"):
		chase_target_pos = slot_seeker.get_target_position()
	elif target:
		chase_target_pos = target.global_position
	else:
		chase_target_pos = owner.global_position

	pathfinding.set_target_position_throttled(chase_target_pos)

	# Get pathfinding direction
	var path_direction = pathfinding.get_target_direction()
	
	# Get separation direction
	var separation_direction = Vector2.ZERO
	if separation:
		separation_direction = separation.get_separation_vector()
	
	# Blend directions with weights
	var final_direction = Vector2.ZERO
	if path_direction != Vector2.ZERO or separation_direction != Vector2.ZERO:
		final_direction = (
			path_direction * pathfinding_weight + 
			separation_direction * separation_weight
		).normalized()
	
	# Update wobble animation
	if wobble_animation:
		var player_pos = target.global_position if target else Vector2.ZERO
		wobble_animation.play(delta, final_direction, player_pos)
		
	movement.set_velocity(final_direction)

func _on_physics_process(_delta : float) -> void:
	pass
	
func _on_next_transitions() -> void:
	pass

func _on_enter() -> void:
	target = sense.current_target
	_connect_sense()
	_connect_hurtbox()
	_connect_health()

	# Request a slot around the target
	if slot_seeker and target and slot_seeker.has_method("request_slot_for_target"):
		slot_seeker.request_slot_for_target(target)

func _on_exit() -> void:
	movement.set_velocity(Vector2.ZERO)
	if wobble_animation:
		wobble_animation.reset()
	_disconnect_hurtbox()
	_disconnect_health()
	_disconnect_sense()


func _connect_hurtbox() -> void:
	if hurtbox and not hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.connect(_on_hurt)

func _on_hurt(amount) -> void:
	# Damage is already applied by HurtboxComponent
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
		
func _connect_sense() -> void:
	if sense and not sense.is_connected("target_lost", _on_target_lost):
		sense.connect("target_lost", Callable(self, "_on_target_lost"))

func _on_target_lost(lost_target):
	if lost_target == target:
		target = null
		transition.emit("Idle")
		
func _disconnect_sense() -> void:
	if sense and sense.is_connected("target_lost", _on_target_lost):
		sense.disconnect("target_lost", Callable(self, "_on_target_lost"))
	
