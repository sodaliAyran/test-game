extends NodeState

@export var movement: MovementComponent
@export var pathfinding: PathfindingComponent
@export var sense: EnemySenseComponent
@export var hurtbox: HurtboxComponent
@export var health: HealthComponent
@export var wobble: WobbleAnimationComponent

var got_hurt: bool = false
var target: Node2D = null

func _on_process(delta : float) -> void:
	if got_hurt:
		got_hurt = false
		transition.emit("Hurt")
	if not movement or not pathfinding:
		return
	if target:
		pathfinding.agent.target_position = target.global_position
	var target_direction = pathfinding.get_target_direction()
	
	if wobble:
		var wobble_offset = wobble.get_wobble_offset(delta)
		var perpendicular = Vector2(-target_direction.y, target_direction.x)
		target_direction += perpendicular * wobble_offset * delta
		target_direction = target_direction.normalized()
		
	movement.set_velocity(target_direction)

func _on_physics_process(_delta : float) -> void:
	pass
	
func _on_next_transitions() -> void:
	pass

func _on_enter() -> void:
	target = sense.current_target
	_connect_sense()
	_connect_hurtbox()
	_connect_health()

func _on_exit() -> void:
	movement.set_velocity(Vector2.ZERO)
	_disconnect_hurtbox()
	_disconnect_health()
	_disconnect_sense()


func _connect_hurtbox() -> void:
	if hurtbox and not hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.connect(_on_hurt)

func _on_hurt(amount) -> void:
	health.take_damage(amount)
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
