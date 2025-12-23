extends NodeState

@export var movement: MovementComponent
@export var pathfinding: PathfindingComponent
@export var sense: EnemySenseComponent
@export var hurtbox: HurtboxComponent
@export var health: HealthComponent
@export var attack_animation: AttackAnimationComponent


var got_hurt: bool = false
var target: Node2D = null
var attack_range: float = 35.0
var attack_cooldown: float = 1.0  # Time between attacks
var time_since_last_attack: float = 0.0

func _on_process(delta: float) -> void:
	if got_hurt:
		got_hurt = false
		transition.emit("Hurt")
	
	if not target:
		transition.emit("Idle")
	
	var distance_to_target = owner.global_position.distance_to(target.global_position)
	if distance_to_target > attack_range:
		transition.emit("Chase")
	
	# Attack cooldown and triggering
	time_since_last_attack += delta
	if time_since_last_attack >= attack_cooldown and attack_animation:
		if not attack_animation.is_playing:
			attack_animation.play()
			time_since_last_attack = 0.0


func _on_physics_process(_delta: float) -> void:
	pass
	
func _on_next_transitions() -> void:
	pass

func _on_enter() -> void:
	target = sense.current_target
	time_since_last_attack = attack_cooldown  # Ready to attack immediately
	# Stop all movement when entering attack state
	if movement:
		movement.set_velocity(Vector2.ZERO)
	_connect_sense()
	_connect_hurtbox()
	_connect_health()
	_connect_attack_animation()

func _on_exit() -> void:
	_disconnect_hurtbox()
	_disconnect_health()
	_disconnect_sense()
	_disconnect_attack_animation()

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

func _connect_attack_animation() -> void:
	if attack_animation and not attack_animation.attack_hit.is_connected(_on_attack_hit):
		attack_animation.attack_hit.connect(_on_attack_hit)

func _on_attack_hit() -> void:
	# TODO: Deal damage to target when attack hits
	print("Attack hit!")

func _disconnect_attack_animation() -> void:
	if attack_animation and attack_animation.attack_hit.is_connected(_on_attack_hit):
		attack_animation.attack_hit.disconnect(_on_attack_hit)
	if attack_animation:
		attack_animation.stop()
