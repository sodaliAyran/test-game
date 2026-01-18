extends NodeState

@export var movement: MovementComponent
@export var pathfinding: PathfindingComponent
@export var sense: EnemySenseComponent
@export var hurtbox: HurtboxComponent
@export var health: HealthComponent
@export var wobble_animation: WobbleAnimationComponent
@export var separation: SeparationComponent
@export var dash: DashComponent

@export_range(0.0, 1.0) var pathfinding_weight: float = 0.7
@export_range(0.0, 1.0) var separation_weight: float = 0.3

@export_group("Dash Gap Closer")
@export var min_dash_distance: float = 100.0
@export var max_dash_distance: float = 250.0

var got_hurt: bool = false
var target: Node2D = null

func _on_process(delta : float) -> void:
	if got_hurt:
		got_hurt = false
		transition.emit("Hurt")
	if not movement or not pathfinding:
		return

	if target:
		# Target behind the player if they have a facing component
		var target_pos = target.global_position
		if target.get("facing"):
			target_pos = target.facing.get_back_position(50.0)
		pathfinding.set_target_position_throttled(target_pos)

		if dash and dash.can_dash():
			var distance = owner.global_position.distance_to(target_pos)
			if distance >= min_dash_distance and distance <= max_dash_distance:
				_trigger_dash()
				return
	
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
	_connect_sense()
	target = sense.current_target
	_connect_hurtbox()
	_connect_health()

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


func _trigger_dash() -> void:
	if not target:
		return
	# Dash towards the back of the player if they have a facing component
	var target_pos = target.global_position
	if target.get("facing"):
		target_pos = target.facing.get_back_position(50.0)
	var dash_direction = (target_pos - owner.global_position).normalized()
	var dash_state = get_parent().get_node_or_null("Dash")
	if dash_state and dash_state.has_method("set_dash_direction"):
		dash_state.set_dash_direction(dash_direction)
	transition.emit("Dash")
