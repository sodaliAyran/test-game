extends NodeState

@export var hurtbox: HurtboxComponent
@export var sense: EnemySenseComponent
@export var health: HealthComponent

var got_hurt: bool = false
var target_acquired_callable: Callable

func _on_process(_delta : float) -> void:
	if got_hurt:
		got_hurt = false
		transition.emit("Hurt")
	if sense.current_target:
		_on_target_acquired(sense.current_target)

func _on_physics_process(_delta : float) -> void:
	pass

func _on_next_transitions() -> void:
	pass

func _on_enter() -> void:
	got_hurt = false
	_connect_hurtbox()
	_connect_health()
	_connect_enemy_sense()
	
func _on_exit() -> void:
	_disconnect_health()
	_disconnect_hurtbox()
	_disconnect_enemy_sense()
	
func _connect_health() -> void:
	if health and not health.died.is_connected(_on_death):
		health.died.connect(_on_death)
		
func _on_death() -> void:
	transition.emit("Death")
	
func _disconnect_health() -> void:
	if health and health.died.is_connected(_on_death):
		health.died.disconnect(_on_death)

func _connect_hurtbox() -> void:
	if hurtbox and not hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.connect(_on_hurt)

func _on_hurt(amount) -> void:
	# Damage is already applied by HurtboxComponent
	got_hurt = true

func _disconnect_hurtbox() -> void:
	if hurtbox and hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.disconnect(_on_hurt)

func _connect_enemy_sense() -> void:
	if sense:
		target_acquired_callable = Callable(self, "_on_target_acquired")
		if not sense.is_connected("target_acquired", target_acquired_callable):
			sense.connect("target_acquired", target_acquired_callable)
	
func _on_target_acquired(target: Node2D) -> void:
	transition.emit("Chase")
	
func _disconnect_enemy_sense() -> void:
	if sense and target_acquired_callable and sense.is_connected("target_acquired", target_acquired_callable):
		sense.disconnect("target_acquired", target_acquired_callable)
