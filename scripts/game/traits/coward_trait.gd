class_name CowardTrait
extends NemesisTraitData

## Makes enemies flee when health drops below threshold

@export var health_threshold: float = 0.3
@export var flee_speed_multiplier: float = 1.5
@export var off_screen_buffer: float = 200.0

var coward_dialogue: DialogueData = preload("res://resources/dialogue/coward_flee_dialogue.tres")
var _instance_data: Dictionary = {}

func _init() -> void:
	trait_name = "Coward"
	priority = 90
	can_execute_parallel = false

func _get_data(owner: Node) -> Dictionary:
	var id = owner.get_instance_id()
	if not _instance_data.has(id):
		_instance_data[id] = { "health_component": null, "is_fleeing": false, "check_process": null }
	return _instance_data[id]

func setup(owner: Node, arbiter: NemesisArbiter) -> void:
	var data = _get_data(owner)
	data.health_component = owner.get_node_or_null("HealthComponent")

	if data.health_component and data.health_component.has_signal("health_changed"):
		data.health_component.health_changed.connect(_on_health_changed.bind(owner, arbiter))
	else:
		push_warning("CowardTrait: No HealthComponent found on %s" % owner.name)

func _on_health_changed(current: float, max_health: float, owner: Node, arbiter: NemesisArbiter) -> void:
	var data = _get_data(owner)

	if current <= 0:
		return

	if data.is_fleeing:
		return

	var health_percent = current / max_health

	if health_percent <= health_threshold:
		var request = TraitRequest.new()
		request.nemesis_trait = self
		request.priority = priority
		request.can_execute_parallel = can_execute_parallel
		request.context = {
			"owner": owner,
			"health_percent": health_percent,
			"current_health": current,
			"max_health": max_health
		}
		arbiter.request_execution(request)

func execute(context: Dictionary) -> void:
	var owner: Node = context.get("owner")
	if not owner:
		return

	var data = _get_data(owner)
	data.is_fleeing = true

	var movement_component = owner.get_node_or_null("MovementComponent")
	if movement_component and "move_speed" in movement_component:
		if not data.has("original_speed"):
			data.original_speed = movement_component.move_speed
		movement_component.move_speed = data.original_speed * flee_speed_multiplier

	_start_off_screen_check(owner)

	var text_bubble = owner.get_node_or_null("TextBubbleComponent")
	if text_bubble and text_bubble.has_method("trigger_manual"):
		if coward_dialogue and coward_dialogue.has_method("get_random_line"):
			var dialogue_line = coward_dialogue.get_random_line()
			text_bubble.trigger_manual(dialogue_line)

	print("CowardTrait: %s marked for fleeing! (Health: %.1f%%)" % [owner.name, context.get("health_percent", 0) * 100])

func _start_off_screen_check(owner: Node) -> void:
	var data = _get_data(owner)

	var timer = Timer.new()
	timer.name = "CowardOffScreenCheckTimer"
	timer.wait_time = 0.1
	timer.one_shot = false
	timer.timeout.connect(_check_if_off_screen.bind(owner, timer))
	owner.add_child(timer)
	timer.start()

	data.check_process = timer

func _check_if_off_screen(owner: Node, timer: Timer) -> void:
	if not is_instance_valid(owner):
		if is_instance_valid(timer):
			timer.queue_free()
		return

	# Make sure owner is a Node2D with position
	if not owner is Node2D:
		return

	# Get the viewport and camera to check screen bounds
	var viewport = owner.get_viewport()
	if not viewport:
		return

	var camera = viewport.get_camera_2d()
	if not camera:
		return

	# Get screen bounds in world coordinates
	var viewport_rect = viewport.get_visible_rect()
	var viewport_size = viewport_rect.size
	var camera_pos = camera.get_screen_center_position()
	var zoom = camera.zoom

	# Calculate the screen boundaries in world space
	var half_width = (viewport_size.x / zoom.x) / 2.0
	var half_height = (viewport_size.y / zoom.y) / 2.0

	var screen_left = camera_pos.x - half_width - off_screen_buffer
	var screen_right = camera_pos.x + half_width + off_screen_buffer
	var screen_top = camera_pos.y - half_height - off_screen_buffer
	var screen_bottom = camera_pos.y + half_height + off_screen_buffer

	# Check if entity is outside screen bounds
	var entity_pos = owner.global_position
	var is_off_screen = (
		entity_pos.x < screen_left or
		entity_pos.x > screen_right or
		entity_pos.y < screen_top or
		entity_pos.y > screen_bottom
	)

	if is_off_screen:
		# Stop the timer first
		timer.stop()
		timer.queue_free()

		# Remove the entity
		_remove_fleeing_enemy(owner)

func _remove_fleeing_enemy(owner: Node) -> void:
	if not is_instance_valid(owner):
		return

	print("CowardTrait: %s fled off-screen and was removed" % owner.name)

	# Unregister from spatial grid if present
	if SpatialGrid:
		SpatialGrid.unregister_entity(owner, "enemies")

	# Queue free the owner
	owner.queue_free()

	# Clean up instance data
	var id = owner.get_instance_id()
	_instance_data.erase(id)

func cleanup() -> void:
	# Cleanup all instance data
	for id in _instance_data.keys():
		var data = _instance_data[id]
		var health_comp = data.get("health_component")
		if health_comp and is_instance_valid(health_comp) and health_comp.has_signal("health_changed"):
			if health_comp.health_changed.is_connected(_on_health_changed):
				health_comp.health_changed.disconnect(_on_health_changed)

		# Cleanup check process node if it exists
		var check_node = data.get("check_process")
		if check_node and is_instance_valid(check_node):
			check_node.queue_free()
	_instance_data.clear()
