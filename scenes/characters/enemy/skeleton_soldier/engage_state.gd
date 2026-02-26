extends NodeState

## Engage state - enemy has reached its slot and decides what to do based on ring position.
## Inner ring: requests AP for melee attack, holds position at slot.
## Outer ring: waits for promotion to inner ring, holds position at slot.

@export var movement: MovementComponent
@export var sense: EnemySenseComponent
@export var hurtbox: HurtboxComponent
@export var health: HealthComponent
@export var wobble_animation: WobbleAnimationComponent
@export var slot_seeker: Node  # SlotSeekerComponent

## AP cost for a melee attack request
@export var melee_ap_cost: float = 1.5
## Time between AP request attempts when denied/expired
@export var request_cooldown: float = 0.8

@export_group("Windup")
@export var windup_duration: float = 0.35
@export var windup_color: Color = Color.RED
@export var windup_sprite: Sprite2D
@export var ap_refund_ratio: float = 0.5

var got_hurt: bool = false
var target: Node2D = null
var _ap_requested: bool = false
var _ap_approved: bool = false
var _request_cooldown_timer: float = 0.0
var _windup: WindupEffect


func _on_enter() -> void:
	got_hurt = false
	_ap_requested = false
	_ap_approved = false
	_request_cooldown_timer = 0.0
	target = sense.current_target

	_connect_hurtbox()
	_connect_health()
	_connect_sense()
	_connect_combat_director()

	# Stop movement on enter
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

	# If slot was lost or enemy no longer has one, go back to chase
	if slot_seeker and not slot_seeker.has_slot():
		transition.emit("Chase")
		return

	# Stop movement during windup, otherwise hold position at slot
	if _windup and _windup.is_active():
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

	_cancel_ap_request()
	_disconnect_hurtbox()
	_disconnect_health()
	_disconnect_sense()
	_disconnect_combat_director()

	# Release slot when leaving engage
	if slot_seeker and slot_seeker.has_method("release_current_slot"):
		slot_seeker.release_current_slot()


## Move toward assigned slot position (gentle correction, not full chase)
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


## Inner ring: request AP for melee attack
func _inner_ring_behavior(delta: float) -> void:
	if _ap_approved:
		_ap_approved = false
		transition.emit("Attack")
		return

	_request_cooldown_timer -= delta

	if not _ap_requested and _request_cooldown_timer <= 0.0:
		_request_melee_ap()


## Outer ring: wait for promotion (slot_seeker handles promotion via CircleSlotManager)
func _outer_ring_behavior(_delta: float) -> void:
	# Promotion happens automatically in CircleSlotManager._process_promotions()
	# SlotSeekerComponent emits promoted_to_inner when it happens
	# We just hold position and wait
	pass


func _request_melee_ap() -> void:
	var request = APRequest.create(
		owner,
		"melee_attack",
		melee_ap_cost,
		Callable(self, "_on_ap_approved"),
		50  # Default priority
	)
	if CombatDirector.request_ap(request):
		_ap_requested = true
	else:
		_request_cooldown_timer = request_cooldown


func _cancel_ap_request() -> void:
	if _windup and _windup.is_active():
		_windup.cancel()
		_windup = null
		CombatDirector.complete_attack(owner)
		CombatDirector.refund_ap(melee_ap_cost * ap_refund_ratio)
	if _ap_requested:
		CombatDirector.cancel_request(owner)
		_ap_requested = false
	_ap_approved = false


func _on_ap_approved() -> void:
	_ap_requested = false

	if windup_duration > 0.0 and windup_sprite:
		_windup = WindupEffect.create(windup_sprite, windup_duration, windup_color)
		_windup.completed.connect(_on_windup_completed)
	else:
		_on_windup_completed()


func _on_windup_completed() -> void:
	_windup = null
	_ap_approved = true


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

func _connect_combat_director() -> void:
	if not CombatDirector.attack_denied.is_connected(_on_attack_denied):
		CombatDirector.attack_denied.connect(_on_attack_denied)

func _on_attack_denied(enemy: Node2D, _reason: String) -> void:
	if enemy == owner:
		_ap_requested = false
		_request_cooldown_timer = request_cooldown

func _disconnect_combat_director() -> void:
	if CombatDirector.attack_denied.is_connected(_on_attack_denied):
		CombatDirector.attack_denied.disconnect(_on_attack_denied)
