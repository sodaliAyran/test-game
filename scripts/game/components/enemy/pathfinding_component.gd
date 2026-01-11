class_name PathfindingComponent
extends Node

@export var agent: NavigationAgent2D
@export var update_interval: float = 0.2  # How often to recalculate path (in seconds)

var _timer: Timer
var _pending_target: Vector2 = Vector2.ZERO
var _has_pending_target: bool = false

func _ready() -> void:
	# Create and configure the timer
	_timer = Timer.new()
	_timer.wait_time = update_interval
	_timer.one_shot = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start()

func _on_timer_timeout() -> void:
	# Update target position when timer fires
	if _has_pending_target and agent:
		agent.target_position = _pending_target
		_has_pending_target = false

func set_target_position_throttled(target_pos: Vector2) -> void:
	"""Set the target position with automatic throttling for performance."""
	_pending_target = target_pos
	_has_pending_target = true

func get_target_direction() -> Vector2:
	if not agent:
		return Vector2.ZERO
	if agent.is_target_reached():
		return Vector2.ZERO
		
	var target_direction = agent.get_next_path_position()
	return (target_direction  - owner.global_position).normalized()
