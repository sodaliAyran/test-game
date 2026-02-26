class_name HitboxComponent
extends Area2D

@export var min_damage: int = 8
@export var max_damage: int = 12
@export var knockback: float = 0.0
@export var knockback_enabled: bool = false  # Only special abilities enable knockback
@export var active: bool = false : set = set_active
@export_flags_2d_physics var hitbox_collision_layer: int = CollisionLayers.PLAYER_HITBOX
@export_flags_2d_physics var hitbox_collision_mask: int = CollisionLayers.ENEMY_HURTBOX

var damage_multiplier: float = 1.0
var hit_targets: Array[HurtboxComponent] = []  # Track targets hit in current attack

signal hit(target)

func _ready() -> void:
	# Apply collision settings from exports
	collision_layer = hitbox_collision_layer
	collision_mask = hitbox_collision_mask

	connect("area_entered", _on_area_entered)


func set_active(value: bool) -> void:
	active = value
	if active:
		# Hit any hurtboxes already inside the hitbox area.
		# area_entered won't fire for these since they entered before activation.
		for area in get_overlapping_areas():
			_on_area_entered(area)
	else:
		hit_targets.clear()


func set_damage_multiplier(multiplier: float) -> void:
	damage_multiplier = multiplier


func _get_attacker_position() -> Vector2:
	var node = get_parent()
	while node:
		if node is CharacterBody2D:
			return node.global_position
		node = node.get_parent()
	return global_position


func _on_area_entered(area: Area2D):
	if not active:
		return
	if area is not HurtboxComponent:
		return

	var hurtbox := area as HurtboxComponent

	# Check if we already hit this target in this attack
	if hit_targets.has(hurtbox):
		return

	# Add to hit targets
	hit_targets.append(hurtbox)

	var final_damage = int(randi_range(min_damage, max_damage) * damage_multiplier)
	var final_knockback = knockback if knockback_enabled else 0.0
	hurtbox.receive_hit(final_damage, final_knockback, _get_attacker_position())
	hit.emit(hurtbox)
