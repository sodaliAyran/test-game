extends CharacterBody2D

## Simple test player for procedural world testing
## Just basic movement and camera following

@export var speed: float = 200.0

@onready var camera: Camera2D = $Camera2D


func _physics_process(_delta: float) -> void:
	# Get input direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Set velocity
	velocity = input_dir * speed
	
	# Move
	move_and_slide()
