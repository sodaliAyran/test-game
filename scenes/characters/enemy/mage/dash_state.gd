extends NodeState

## State where enemy performs a dash with invincibility.
## Transitions back to previous state or a specified state when dash ends.

@export var dash: DashComponent
@export var hurtbox: HurtboxComponent
@export var health: HealthComponent
@export var facing: FacingComponent
@export var return_state: String = "Flee"

var _dash_direction: Vector2 = Vector2.ZERO


func set_dash_direction(direction: Vector2) -> void:
	"""Call this before transitioning to set the dash direction"""
	_dash_direction = direction


func _on_enter() -> void:
	_connect_health()

	if dash:
		dash.dash_ended.connect(_on_dash_ended)

		# Start the dash
		if _dash_direction != Vector2.ZERO:
			dash.dash(_dash_direction)
		else:
			# Default: dash away from center or random direction
			_dash_direction = Vector2.RIGHT.rotated(randf() * TAU)
			dash.dash(_dash_direction)

	# Update facing direction
	if facing:
		facing.set_facing_from_direction(_dash_direction)


func _on_process(_delta: float) -> void:
	pass


func _on_physics_process(_delta: float) -> void:
	pass


func _on_exit() -> void:
	if dash and dash.dash_ended.is_connected(_on_dash_ended):
		dash.dash_ended.disconnect(_on_dash_ended)
	_disconnect_health()
	_dash_direction = Vector2.ZERO


func _on_dash_ended() -> void:
	transition.emit(return_state)


func _connect_health() -> void:
	if health and not health.died.is_connected(_on_death):
		health.died.connect(_on_death)


func _on_death() -> void:
	if dash:
		dash.force_end_dash()
	transition.emit("Death")


func _disconnect_health() -> void:
	if health and health.died.is_connected(_on_death):
		health.died.disconnect(_on_death)
