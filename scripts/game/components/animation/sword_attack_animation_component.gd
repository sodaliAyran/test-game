class_name SwordAttackAnimationComponent
extends Node

## Animates the weapon sword through attack swing motions with ghost-sprite smear trail.
## Takes over sword transform during attacks, overriding WeaponOrbitComponent.

signal attack_animation_started
signal attack_animation_finished

@export var sword_root: Node2D
@export var sprite: Sprite2D

@export_group("Swing Parameters")
@export var swing_radius: float = 18.0
@export var upslash_start_offset: float = 0.8    ## Radians below facing direction
@export var upslash_end_offset: float = -1.2      ## Radians above facing direction
@export var anticipation_ratio: float = 0.15
@export var swing_ratio: float = 0.55
@export var hold_ratio: float = 0.30
@export var combo_reset_time: float = 0.8

@export_group("Trail")
@export var ghost_count: int = 3
@export var ghost_opacity_start: float = 0.5
@export var ghost_color: Color = Color(0.7, 0.85, 1.0, 1.0)
@export var ghost_arc_spread: float = 0.35 ## Radians of arc the ghosts span behind the sword

var is_animating: bool = false

var _weapon: WeaponComponent
var _orbit: WeaponOrbitComponent
var _wobble: WobbleAnimationComponent
var _facing: FacingComponent

var _combo_index: int = 0
var _combo_reset_timer: Timer
var _anim_time: float = 0.0
var _anim_duration: float = 0.3
var _facing_angle: float = 0.0
var _facing_right: bool = true
var _current_swing_angle: float = 0.0
var _ghost_sprites: Array[Sprite2D] = []
var _return_tween: Tween

enum Phase { ANTICIPATION, SWING, HOLD, IDLE }
var _phase: Phase = Phase.IDLE


func _ready() -> void:
	_wobble = get_parent().find_child("WobbleAnimationComponent", false, false)
	_create_ghost_sprites()
	_setup_combo_timer()
	# Defer dependency search to allow skill scenes to load
	await get_tree().process_frame
	await get_tree().process_frame
	_find_dependencies()


func _find_dependencies() -> void:
	# Find WeaponOrbitComponent on the warrior (parent of sword_root)
	var warrior = sword_root.get_parent()
	if warrior:
		_orbit = warrior.find_child("WeaponOrbitComponent", false, false)
		# Find the player's FacingComponent
		_facing = warrior.find_child("FacingComponent", false, false)
		# Find WeaponComponent in skill scenes (loaded by SkillSceneLoader)
		for child in warrior.get_children():
			var wc = child.find_child("WeaponComponent", true, false)
			if wc and wc is WeaponComponent:
				_weapon = wc
				_weapon.attack_started.connect(_on_attack_started)
				_weapon.attack_ended.connect(_on_attack_ended)
				_anim_duration = _weapon.attack_duration
				break


func _setup_combo_timer() -> void:
	_combo_reset_timer = Timer.new()
	_combo_reset_timer.wait_time = combo_reset_time
	_combo_reset_timer.one_shot = true
	_combo_reset_timer.timeout.connect(func(): _combo_index = 0)
	add_child(_combo_reset_timer)


func _create_ghost_sprites() -> void:
	# Ghosts are added as children of sword_root's parent (the entity node)
	# so they aren't affected by sword_root's own rotation/position changes
	var ghost_parent = sword_root.get_parent() if sword_root.get_parent() else sword_root
	for i in ghost_count:
		var ghost = Sprite2D.new()
		ghost.texture = sprite.texture
		ghost.visible = false
		ghost_parent.add_child.call_deferred(ghost)
		_ghost_sprites.append(ghost)


## Manually trigger the attack animation (for testing or custom integration).
func play_attack(facing_angle_override := NAN, duration_override := NAN) -> void:
	var angle = facing_angle_override if not is_nan(facing_angle_override) else (_facing.facing_direction.angle() if _facing else 0.0)
	var dur = duration_override if not is_nan(duration_override) else _anim_duration
	_start_swing(angle, angle >= -PI / 2.0 and angle <= PI / 2.0, dur)


func _on_attack_started(_target: Node2D = null) -> void:
	var angle := 0.0
	var right := true
	if _facing:
		angle = _facing.facing_direction.angle()
		right = _facing.facing_direction.x >= 0
	var dur = _weapon.attack_duration if _weapon else 0.3
	if _weapon and _weapon.skill_modifier:
		var speed_mult = _weapon.skill_modifier.get_attack_speed_multiplier()
		if speed_mult > 0:
			dur = _weapon.attack_duration / speed_mult
	_start_swing(angle, right, dur)


func _start_swing(angle: float, right: bool, duration: float) -> void:
	if _return_tween:
		_return_tween.kill()

	_facing_angle = angle
	_facing_right = right
	_anim_duration = duration

	is_animating = true
	if _orbit:
		_orbit.is_attack_animating = true
	if _wobble:
		_wobble.enabled = false

	_hide_ghosts()

	_anim_time = 0.0
	_current_swing_angle = _get_start_angle()
	_phase = Phase.ANTICIPATION
	attack_animation_started.emit()


func _on_attack_ended() -> void:
	_hide_ghosts()
	_phase = Phase.IDLE
	is_animating = false

	if _orbit:
		var rest = _orbit.get_rest_transform()
		if _return_tween:
			_return_tween.kill()
		_return_tween = create_tween().set_parallel(true)
		_return_tween.tween_property(sword_root, "position", rest["position"], 0.1)
		_return_tween.tween_property(sword_root, "rotation", rest["rotation"], 0.1)
		_return_tween.chain().tween_callback(func():
			_orbit.is_attack_animating = false
			if _wobble:
				_wobble.enabled = true
		)
	else:
		if _wobble:
			_wobble.enabled = true

	_combo_index = (_combo_index + 1) % 2
	_combo_reset_timer.start()

	attack_animation_finished.emit()


func _process(delta: float) -> void:
	if _phase == Phase.IDLE:
		return

	_anim_time += delta

	match _phase:
		Phase.ANTICIPATION:
			_process_anticipation()
		Phase.SWING:
			_process_swing()
		Phase.HOLD:
			_process_hold()


func _process_anticipation() -> void:
	var anticipation_duration = _anim_duration * anticipation_ratio
	var progress = clampf(_anim_time / anticipation_duration, 0.0, 1.0)

	if progress >= 1.0:
		_phase = Phase.SWING
		_anim_time = 0.0
		return

	var eased = ease(progress, -0.5)
	var start_angle = _get_start_angle()
	var pullback = 0.15 if _facing_right else -0.15
	_current_swing_angle = start_angle + pullback * (1.0 - eased)
	_apply_sword_transform(_current_swing_angle)


func _process_swing() -> void:
	var swing_duration = _anim_duration * swing_ratio
	var progress = clampf(_anim_time / swing_duration, 0.0, 1.0)

	if progress >= 1.0:
		_phase = Phase.HOLD
		_anim_time = 0.0
		_hide_ghosts()
		return

	var eased = ease(progress, 2.5)
	var start_angle = _get_start_angle()
	var end_angle = _get_end_angle()
	_current_swing_angle = lerpf(start_angle, end_angle, eased)
	_apply_sword_transform(_current_swing_angle)

	# Place ghosts along the arc behind the current sword position
	_update_ghosts_arc()


func _process_hold() -> void:
	var hold_duration = _anim_duration * hold_ratio
	var progress = clampf(_anim_time / hold_duration, 0.0, 1.0)

	var end_angle = _get_end_angle()
	_apply_sword_transform(end_angle)

	if not _weapon and progress >= 1.0:
		_on_attack_ended()


func _get_start_angle() -> float:
	if _combo_index == 0:
		var offset = upslash_start_offset if _facing_right else -upslash_start_offset
		return _facing_angle + offset
	else:
		var offset = upslash_end_offset if _facing_right else -upslash_end_offset
		return _facing_angle + offset


func _get_end_angle() -> float:
	if _combo_index == 0:
		var offset = upslash_end_offset if _facing_right else -upslash_end_offset
		return _facing_angle + offset
	else:
		var offset = upslash_start_offset if _facing_right else -upslash_start_offset
		return _facing_angle + offset


func _apply_sword_transform(angle: float) -> void:
	if not sword_root:
		return
	var offset = Vector2.from_angle(angle) * swing_radius
	sword_root.position = offset
	sword_root.rotation = angle
	sword_root.scale.x = -1.0 if cos(angle) > 0 else 1.0
	sword_root.scale.y = -1.0 if cos(angle) < 0 else 1.0


func _update_ghosts_arc() -> void:
	## Place ghosts at evenly spaced angles behind the current sword angle.
	## Ghosts are children of sword_root's parent, so positions are in local space.
	var swing_direction = signf(_get_end_angle() - _get_start_angle())
	var trail_step = -swing_direction * (ghost_arc_spread / float(ghost_count))

	for i in ghost_count:
		var ghost = _ghost_sprites[i]
		var ghost_angle = _current_swing_angle + trail_step * float(i + 1)
		var ghost_offset = Vector2.from_angle(ghost_angle) * swing_radius
		# Position in local space (same parent as sword_root)
		ghost.position = ghost_offset
		ghost.rotation = ghost_angle
		ghost.scale.x = -1.0 if cos(ghost_angle) > 0 else 1.0
		ghost.scale.y = -1.0 if cos(ghost_angle) < 0 else 1.0
		ghost.visible = true
		var t = float(i + 1) / float(ghost_count + 1)
		var opacity = ghost_opacity_start * (1.0 - t)
		ghost.modulate = Color(ghost_color.r, ghost_color.g, ghost_color.b, opacity)


func _hide_ghosts() -> void:
	for ghost in _ghost_sprites:
		ghost.visible = false
