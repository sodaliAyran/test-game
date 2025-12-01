class_name PlayerInputComponent
extends Node

var movement_direction: Vector2 = Vector2.ZERO
var attack_pressed: bool = false

func is_movement_input() -> bool:
	return movement_direction != Vector2.ZERO

func _process(_delta: float) -> void:
	_read_movement()
	_read_actions()
	
func _read_movement() -> void:
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	movement_direction = Vector2(x, y).normalized()

func _read_actions() -> void:
	attack_pressed = Input.is_action_pressed("attack")
	
	
