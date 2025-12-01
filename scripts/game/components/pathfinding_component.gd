class_name PathfindingComponent
extends Node

@export var agent: NavigationAgent2D

func get_target_direction() -> Vector2:
	if not agent:
		return Vector2.ZERO
	if agent.is_target_reached():
		return Vector2.ZERO
		
	var target_direction = agent.get_next_path_position()
	return (target_direction  - owner.global_position).normalized()

		
