extends  NodeState

@export var movement: MovementComponent
@export var health: HealthComponent
@export var hurtbox: HurtboxComponent
@export var hurt_flash_animation: HurtFlashAnimationComponent
@onready var player_input: PlayerInputComponent = %PlayerInputComponent

func _on_process(_delta : float) -> void:
	if player_input.is_movement_input():
		transition.emit("Move")

func _on_physics_process(_delta : float) -> void:
	pass

func _on_next_transitions() -> void:
	pass

func _on_enter() -> void:
	_connect_health()


func _on_exit() -> void:
	_disconnect_health()


func _connect_health() -> void:
	if hurtbox and not hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.connect(_on_hurt)
	if health and not health.died.is_connected(_on_death):
		health.died.connect(_on_death)


func _on_hurt(_amount: int) -> void:
	if hurt_flash_animation:
		hurt_flash_animation.play()


func _on_death() -> void:
	transition.emit("Death")


func _disconnect_health() -> void:
	if hurtbox and hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.disconnect(_on_hurt)
	if health and health.died.is_connected(_on_death):
		health.died.disconnect(_on_death)
