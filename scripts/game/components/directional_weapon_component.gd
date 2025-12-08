class_name DirectionalWeaponComponent
extends Node

@export var weapon_sprite: Sprite2D
@export var weapon_offset: Vector2 = Vector2(43, -4)
@export var character_sprite_name: String = "CharacterSprite"

var _character_sprite: Sprite2D

func _ready() -> void:
	_find_character_sprite()

func _find_character_sprite() -> void:
	if not owner.get_parent():
		return
	
	var parent = owner.get_parent()
	
	_character_sprite = _find_by_name(parent)
	if not _character_sprite:
		_character_sprite = _find_first_sprite(parent)

func _find_by_name(parent: Node) -> Sprite2D:
	if parent.has_node(character_sprite_name):
		var node = parent.get_node(character_sprite_name)
		if node is Sprite2D:
			return node
	return null

func _find_first_sprite(parent: Node) -> Sprite2D:
	for child in parent.get_children():
		if child is Sprite2D:
			return child
	return null

func _process(_delta: float) -> void:
	_update_position_and_flip()

func _update_position_and_flip() -> void:
	if not _character_sprite:
		return
	
	if _character_sprite.flip_h:
		owner.position.x = weapon_offset.x
		if weapon_sprite:
			weapon_sprite.flip_h = false
	else:
		owner.position.x = -weapon_offset.x
		if weapon_sprite:
			weapon_sprite.flip_h = true
	owner.position.y = weapon_offset.y
