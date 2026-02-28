extends NodeState

## Generic Engage state - enemy has reached its slot and requests AP for available skills.
## Inner ring: iterates skill nodes and requests use for the first available one.
## Outer ring: waits for promotion to inner ring, holds position at slot.

@export var movement: MovementComponent
@export var sense: EnemySenseComponent
@export var hurtbox: HurtboxComponent
@export var health: HealthComponent
@export var wobble_animation: WobbleAnimationComponent
@export var slot_seeker: Node  # SlotSeekerComponent

## Paths to skill nodes that implement can_use() -> bool and request_use(context: Dictionary) -> bool
@export var skill_paths: Array[NodePath] = []

## Time between skill request attempts when denied
@export var request_cooldown: float = 0.8
## Initial delay before first skill request (randomized ± 50%)
@export var initial_delay: float = 0.6

var got_hurt: bool = false
var target: Node2D = null
var _request_cooldown_timer: float = 0.0
var _skills: Array[Node] = []


func _on_enter() -> void:
	got_hurt = false
	_request_cooldown_timer = initial_delay * randf_range(0.5, 1.5)
	target = sense.current_target

	_skills.clear()
	for path in skill_paths:
		var node = get_node_or_null(path)
		if node:
			_skills.append(node)

	_activate_skills()
	_connect_hurtbox()
	_connect_health()
	_connect_sense()
	_connect_skills()

	if movement:
		movement.set_velocity(Vector2.ZERO)


func _on_process(delta: float) -> void:
	if got_hurt:
		got_hurt = false
		transition.emit("Hurt")
		return

	if not target or not is_instance_valid(target):
		transition.emit("Idle")
		return

	# If slot was lost, go back to chase
	if slot_seeker and not slot_seeker.has_slot():
		transition.emit("Chase")
		return

	# Stop movement during windup, otherwise hold position at slot
	if _any_skill_winding_up():
		if movement:
			movement.set_velocity(Vector2.ZERO)
	else:
		_move_to_slot(delta)

	# Check ring and act accordingly
	if slot_seeker and slot_seeker.is_in_inner_ring():
		_inner_ring_behavior(delta)
	else:
		_outer_ring_behavior(delta)


func _on_physics_process(_delta: float) -> void:
	pass


func _on_next_transitions() -> void:
	pass


func _on_exit() -> void:
	if movement:
		movement.set_velocity(Vector2.ZERO)
	if wobble_animation:
		wobble_animation.reset()

	_cancel_all_pending()
	_deactivate_skills()
	_disconnect_hurtbox()
	_disconnect_health()
	_disconnect_sense()
	_disconnect_skills()

	# Release slot when leaving engage (combat flow ended)
	if slot_seeker and slot_seeker.has_method("release_current_slot"):
		slot_seeker.release_current_slot()


## Move toward assigned slot position
func _move_to_slot(delta: float) -> void:
	if not slot_seeker or not movement:
		return

	var slot_pos = slot_seeker.get_target_position()
	var to_slot = slot_pos - owner.global_position
	var distance = to_slot.length()

	if distance > 5.0:
		var direction = to_slot.normalized()
		if wobble_animation:
			var player_pos = target.global_position if target else Vector2.ZERO
			wobble_animation.play(delta, direction, player_pos)
		movement.set_velocity(direction)
	else:
		movement.set_velocity(Vector2.ZERO)


## Inner ring: try to use the first available skill
func _inner_ring_behavior(delta: float) -> void:
	_request_cooldown_timer -= delta
	if _request_cooldown_timer > 0.0:
		return

	var context := {"target": target}

	for skill in _skills:
		if skill.can_use() and skill.request_use(context):
			return

	# All skills denied or unavailable, wait before retrying
	_request_cooldown_timer = request_cooldown


## Outer ring: wait for promotion
func _outer_ring_behavior(_delta: float) -> void:
	pass


func _any_skill_winding_up() -> bool:
	for skill in _skills:
		if skill.has_method("is_winding_up") and skill.is_winding_up():
			return true
	return false


func _activate_skills() -> void:
	for skill in _skills:
		if skill.has_method("activate"):
			skill.activate()


func _deactivate_skills() -> void:
	for skill in _skills:
		if skill.has_method("deactivate"):
			skill.deactivate()


func _cancel_all_pending() -> void:
	for skill in _skills:
		if skill.has_method("cancel_pending_request"):
			skill.cancel_pending_request()


## Signal connections

func _connect_hurtbox() -> void:
	if hurtbox and not hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.connect(_on_hurt)

func _on_hurt(_amount) -> void:
	got_hurt = true

func _disconnect_hurtbox() -> void:
	if hurtbox and hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.disconnect(_on_hurt)

func _connect_health() -> void:
	if health and not health.died.is_connected(_on_death):
		health.died.connect(_on_death)

func _on_death() -> void:
	transition.emit("Death")

func _disconnect_health() -> void:
	if health and health.died.is_connected(_on_death):
		health.died.disconnect(_on_death)

func _connect_sense() -> void:
	if sense and not sense.is_connected("target_lost", _on_target_lost):
		sense.connect("target_lost", Callable(self, "_on_target_lost"))

func _on_target_lost(lost_target) -> void:
	if lost_target == target:
		target = null
		transition.emit("Idle")

func _disconnect_sense() -> void:
	if sense and sense.is_connected("target_lost", _on_target_lost):
		sense.disconnect("target_lost", Callable(self, "_on_target_lost"))

func _connect_skills() -> void:
	for skill in _skills:
		if skill is DashComponent:
			if not skill.windup_finished.is_connected(_on_windup_finished):
				skill.windup_finished.connect(_on_windup_finished)

func _on_windup_finished(direction: Vector2) -> void:
	# Pass direction to Dash state before transitioning
	var dash_state = get_parent().get_node_or_null("Dash")
	if dash_state and dash_state.has_method("set_dash_direction"):
		dash_state.set_dash_direction(direction)
	transition.emit("Dash")

func _disconnect_skills() -> void:
	for skill in _skills:
		if skill is DashComponent:
			if skill.windup_finished.is_connected(_on_windup_finished):
				skill.windup_finished.disconnect(_on_windup_finished)
