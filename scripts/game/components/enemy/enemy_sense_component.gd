class_name EnemySenseComponent
extends Area2D

@export var detection_radius: float = 150.0
@export var target_group: String = "Player"
@export var debug_visible: bool = false

signal target_acquired(target: Node2D)
signal target_lost(target: Node2D)

var current_target: Node2D = null
var potential_targets: Array = []

func _ready() -> void:
	var shape = CircleShape2D.new()
	shape.radius = detection_radius
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	add_child(collision_shape)

	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	
#	if debug_visible:
#		_draw()  
		
#func _draw() -> void:
#	draw_circle(Vector2.ZERO, detection_radius, Color(1, 0, 0, 0.3))  # semi-transparent red# triggers _draw

func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group(target_group):
		potential_targets.append(body)
		_update_current_target()


func _on_body_exited(body: CharacterBody2D) -> void:
	if body in potential_targets:
		potential_targets.erase(body)
		if body == current_target:
			_update_current_target()

func _update_current_target() -> void:
	var previous_target = current_target
	
	if potential_targets.size() == 0:
		current_target = null
	else:
		current_target = _pick_closest_target()
	
	if previous_target != current_target:
		_emit_target_changed(previous_target, current_target)
	
func _pick_closest_target() -> Node2D:
	var closest = null
	for target in potential_targets:
		var dist = owner.global_position.distance_to(target.global_position)
		closest = target
	return closest

func _emit_target_changed(previous: Node2D, current: Node2D) -> void:
	if current:
		emit_signal("target_acquired", current)
	elif previous:
		emit_signal("target_lost", previous)
	
