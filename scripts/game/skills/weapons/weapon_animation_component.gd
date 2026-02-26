class_name WeaponAnimationComponent
extends Node

## Plays an AnimatedSprite2D animation when a weapon attacks.
## Repositions the sprite in front of the skill owner using facing direction.

@export var animated_sprite: AnimatedSprite2D
@export var animation_name: String = "attack"
@export var weapon: WeaponComponent
@export var trigger_area: SkillTriggerArea
@export var weapon_offset_horizontal: Vector2 = Vector2(30, -4)
@export var weapon_offset_vertical: Vector2 = Vector2(20, -4)

var facing: FacingComponent


func _ready() -> void:
	_find_facing_component()
	if weapon:
		weapon.attack_started.connect(_on_attack_started)
		weapon.attack_ended.connect(_on_attack_ended)
	if animated_sprite:
		animated_sprite.visible = false
		animated_sprite.top_level = true


func _find_facing_component() -> void:
	var node = get_parent()
	while node:
		var found = node.find_child("FacingComponent", false, false)
		if found and found is FacingComponent:
			facing = found
			return
		node = node.get_parent()


func _on_attack_started(target: Node2D = null) -> void:
	if not animated_sprite:
		return
	_reposition_at_target(target)
	_sync_animation_speed()
	animated_sprite.visible = true
	animated_sprite.play(animation_name)
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)


func _sync_animation_speed() -> void:
	if not weapon or not animated_sprite or not animated_sprite.sprite_frames:
		return
	var frame_count = animated_sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return
	var base_fps = animated_sprite.sprite_frames.get_animation_speed(animation_name)
	if base_fps <= 0:
		return
	var effective_duration = weapon.attack_duration
	if weapon.skill_modifier:
		var speed_mult = weapon.skill_modifier.get_attack_speed_multiplier()
		if speed_mult > 0:
			effective_duration = weapon.attack_duration / speed_mult
	var required_fps = frame_count / effective_duration
	animated_sprite.speed_scale = required_fps / base_fps


func _on_animation_finished() -> void:
	if animated_sprite:
		animated_sprite.visible = false


func _on_attack_ended() -> void:
	if not animated_sprite:
		return
	animated_sprite.stop()
	animated_sprite.visible = false


func _reposition_at_target(_target: Node2D = null) -> void:
	# Only reposition the animated sprite for visual effect
	# Hitbox positioning is handled by DirectionalWeaponComponent

	# Use fixed position if weapon has one set (e.g. slam locks position at windup)
	if weapon and weapon.attack_position is Vector2:
		var pos: Vector2 = weapon.attack_position
		animated_sprite.global_position = pos
		return

	# Position in front of the owner using facing direction
	var owner_node = animated_sprite.get_parent()
	if not owner_node:
		return

	var direction = Vector2.RIGHT
	if facing:
		direction = facing.facing_direction
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	var is_horizontal = absf(direction.x) > absf(direction.y)
	var weapon_offset = weapon_offset_horizontal if is_horizontal else weapon_offset_vertical
	var offset = direction.normalized() * weapon_offset.x + Vector2(0, weapon_offset.y)
	animated_sprite.global_position = owner_node.global_position + offset
	animated_sprite.rotation = direction.angle()
	animated_sprite.flip_v = direction.x < 0
