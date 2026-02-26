extends NodeState
class_name StunnedState

## Time-based stunned state. Enemy is incapacitated and cannot act.
## If player attacks during stun → knocked back to Down state.
## If stun expires without attack → recover health and resume.

@export var stun_animation: Node # StunAnimationComponent
@export var stun_bar: Node # StunBarComponent
@export var health: HealthComponent
@export var hurtbox: HurtboxComponent
@export var movement: MovementComponent
@export var knockbackable: Node # KnockbackableComponent
@export var director_request: Node # CombatDirectorRequestComponent
@export var down_state: Node # Down state (to pass knockback direction)

@export_group("Stun Settings")
@export var stun_duration: float = 5.0 # Time before recovery
@export var knockback_force: float = 1500.0 # Force applied when hit during stun
@export var freeze_duration: float = 0.25 # Freeze frame duration for impact

var _elapsed_time: float = 0.0
var _was_knocked: bool = false
var _knockback_direction: Vector2 = Vector2.ZERO
var _effective_stun_duration: float = 0.0


func _get_effective_stun_duration() -> float:
	var bonus = 0.0
	if SkillManager:
		bonus = SkillManager.get_passive_float("stun_duration_bonus")
	return stun_duration + bonus


func _on_enter() -> void:
	_elapsed_time = 0.0
	_was_knocked = false
	_knockback_direction = Vector2.ZERO
	_effective_stun_duration = _get_effective_stun_duration()

	# Cancel any pending combat director requests
	_cancel_pending_actions()

	# Stop movement
	if movement:
		movement.stop()

	# Enemy is NOT invincible - can be attacked during stun!
	if hurtbox:
		hurtbox.invincible = false

	# Play stun visual effect
	if stun_animation:
		stun_animation.play(_effective_stun_duration)

	# Show stun bar
	if stun_bar:
		stun_bar.show_bar(_effective_stun_duration)

	# Connect signals
	_connect_hurtbox()


func _on_process(delta: float) -> void:
	_elapsed_time += delta

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

	_disconnect_hurtbox()

	# If knocked, pass direction to Down state
	if _was_knocked and down_state and down_state.has_method("set_knockback_direction"):
		down_state.set_knockback_direction(_knockback_direction)


func _cancel_pending_actions() -> void:
	if director_request and director_request.has_method("cancel_pending_request"):
		director_request.cancel_pending_request()
	CombatDirector.cancel_request(owner)
	CombatDirector.complete_attack(owner)


func _connect_hurtbox() -> void:
	if hurtbox:
		if not hurtbox.hurt.is_connected(_on_hurt):
			hurtbox.hurt.connect(_on_hurt)
		if not hurtbox.knocked.is_connected(_on_knocked):
			hurtbox.knocked.connect(_on_knocked)


func _disconnect_hurtbox() -> void:
	if hurtbox:
		if hurtbox.hurt.is_connected(_on_hurt):
			hurtbox.hurt.disconnect(_on_hurt)
		if hurtbox.knocked.is_connected(_on_knocked):
			hurtbox.knocked.disconnect(_on_knocked)


func _on_hurt(_amount: int) -> void:
	# Any damage during stun triggers transition to Down
	# Direction and force come from _on_knocked which fires right after
	_was_knocked = true
	# Freeze frame for impact juice
	FreezeFrame.freeze(freeze_duration)


func _on_knocked(direction: Vector2, _force: float) -> void:
	_was_knocked = true
	_knockback_direction = direction
	# Apply our own knockback force (ignoring hitbox force)
	if movement:
		movement.apply_knockback(direction * knockback_force)
