extends  NodeState

@export var movement: MovementComponent
@export var wobble_animation: WobbleAnimationComponent
@export var sprite: Sprite2D
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
	pass


func _on_exit() -> void:
	movement.stop()
	if wobble_animation:
		wobble_animation.reset()
