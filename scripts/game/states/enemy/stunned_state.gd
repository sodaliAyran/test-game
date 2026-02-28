extends NodeState
class_name StunnedState

## Time-based stunned state. Enemy is incapacitated and cannot act.
## If player walks on top during stun → knocked back to Down state.
## If stun expires without being walked on → recover health and resume.

@export var stun_animation: Node # StunAnimationComponent
@export var stun_bar: Node # StunBarComponent
@export var health: HealthComponent
@export var hurtbox: HurtboxComponent
@export var movement: MovementComponent
@export var knockbackable: Node # KnockbackableComponent
@export var director_request: Node # CombatDirectorRequestComponent
@export var down_state: Node # Down state (to pass knockback direction)
@export var enemy_damage: Node # EnemyDamageComponent - disabled during stun

@export_group("Stun Settings")
@export var stun_duration: float = 5.0 # Time before recovery
@export var knockback_force: float = 1500.0 # Force applied when walked on during stun
@export var freeze_duration: float = 0.25 # Freeze frame duration for impact

@export var stomp_detection_radius: float = 5.0 # How close player must be to trigger knockdown
@export var invulnerability_duration: float = 0.5 # Grace period before knockback is possible

var _elapsed_time: float = 0.0
var _stomp_active: bool = false
var _was_knocked: bool = false
var _knockback_direction: Vector2 = Vector2.ZERO
var _effective_stun_duration: float = 0.0
var _stomp_area: Area2D = null


func _get_effective_stun_duration() -> float:
	var bonus = 0.0
	if SkillManager:
		bonus = SkillManager.get_passive_float("stun_duration_bonus")
	return stun_duration + bonus


func _on_enter() -> void:
	_elapsed_time = 0.0
	_was_knocked = false
	_knockback_direction = Vector2.ZERO
	_stomp_active = false
	_effective_stun_duration = _get_effective_stun_duration()

	# Cancel any pending combat director requests
	_cancel_pending_actions()

	# Stop movement
	if movement:
		movement.stop()

	# Disable hurtbox entirely so player skills pass through
	if hurtbox:
		hurtbox.invincible = true
		hurtbox.monitorable = false

	# Disable contact damage so player can walk over safely
	if enemy_damage and enemy_damage.get("damage_area"):
		enemy_damage.set_process(false)
		enemy_damage.damage_area.monitoring = false

	# Play stun visual effect
	if stun_animation:
		stun_animation.play(_effective_stun_duration)

	# Show stun bar
	if stun_bar:
		stun_bar.show_bar(_effective_stun_duration)


func _on_process(delta: float) -> void:
	_elapsed_time += delta

	# Activate stomp detection after invulnerability grace period
	if not _stomp_active and _elapsed_time >= invulnerability_duration:
		_stomp_active = true
		_create_stomp_area()

	# Update stun bar
	if stun_bar:
		stun_bar.update_progress(_elapsed_time / _effective_stun_duration)


func _on_next_transitions() -> void:
	# Player knocked us during stun
	if _was_knocked:
		transition.emit("Down")
		return

	# Stun duration expired without being knocked
	if _elapsed_time >= _effective_stun_duration:
		# Recover health and go back to chase
		if knockbackable and knockbackable.has_method("recover"):
			knockbackable.recover()
		transition.emit("Chase")


func _on_exit() -> void:
	if stun_animation:
		stun_animation.stop()

	if stun_bar:
		stun_bar.hide_bar()

	# Re-enable contact damage
	if enemy_damage and enemy_damage.get("damage_area"):
		enemy_damage.set_process(true)
		enemy_damage.damage_area.monitoring = true

	# Re-enable hurtbox
	if hurtbox:
		hurtbox.invincible = false
		hurtbox.monitorable = true

	# Remove stomp detection area
	_destroy_stomp_area()

	# If knocked, pass direction to Down state
	if _was_knocked and down_state and down_state.has_method("set_knockback_direction"):
		down_state.set_knockback_direction(_knockback_direction)


func _cancel_pending_actions() -> void:
	if director_request and director_request.has_method("cancel_pending_request"):
		director_request.cancel_pending_request()
	CombatDirector.cancel_request(owner)
	CombatDirector.complete_attack(owner)


func _create_stomp_area() -> void:
	_stomp_area = Area2D.new()
	_stomp_area.collision_layer = 0
	_stomp_area.collision_mask = CollisionLayers.PLAYER_HURTBOX

	var shape = CircleShape2D.new()
	shape.radius = stomp_detection_radius
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	_stomp_area.add_child(collision_shape)

	owner.add_child(_stomp_area)
	_stomp_area.area_entered.connect(_on_player_stomp)
	# Check for player already overlapping (deferred so physics has updated)
	call_deferred("_check_existing_stomp_overlaps")


func _check_existing_stomp_overlaps() -> void:
	if _stomp_area and is_instance_valid(_stomp_area):
		for area in _stomp_area.get_overlapping_areas():
			_on_player_stomp(area)


func _destroy_stomp_area() -> void:
	if _stomp_area and is_instance_valid(_stomp_area):
		_stomp_area.area_entered.disconnect(_on_player_stomp)
		_stomp_area.queue_free()
		_stomp_area = null


func _on_player_stomp(area: Area2D) -> void:
	if _was_knocked:
		return
	# Check that the overlapping area belongs to a player
	if area.owner and area.owner.is_in_group("Player"):
		_was_knocked = true
		# Knockback direction: away from the player
		var player_pos = area.owner.global_position
		_knockback_direction = (owner.global_position - player_pos).normalized()
		# Apply knockback force
		if movement:
			movement.apply_knockback(_knockback_direction * knockback_force)
		# Execution camera effect: slow-mo, zoom, screen shake
		ExecutionCamera.play(owner.global_position)
		# Emit stomped signal for coin burst etc.
		if knockbackable:
			knockbackable.stomped.emit(_knockback_direction)
