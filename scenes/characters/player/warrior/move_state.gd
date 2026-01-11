extends  NodeState

@export var movement: MovementComponent
@export var wobble_animation: WobbleAnimationComponent
@export var sprite: Sprite2D
@export var health: HealthComponent
@export var hurtbox: HurtboxComponent
@export var hurt_flash_animation: HurtFlashAnimationComponent
@onready var player_input: PlayerInputComponent = %PlayerInputComponent

func _on_process(delta : float) -> void:
	var direction = player_input.movement_direction
	movement.set_velocity(direction)
	
	# Flip sprite based on horizontal movement
	if direction.x > 0:
		sprite.flip_h = true
	elif direction.x < 0:
		sprite.flip_h = false
	
	if wobble_animation and direction != Vector2.ZERO:
		wobble_animation.play(delta, direction, Vector2.ZERO)

func _on_physics_process(_delta : float) -> void:
	pass


func _on_next_transitions() -> void:
	if not player_input.is_movement_input():
		transition.emit("Idle")


func _on_enter() -> void:
	_connect_health()


func _on_exit() -> void:
	movement.stop()
	if wobble_animation:
		wobble_animation.reset()
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
