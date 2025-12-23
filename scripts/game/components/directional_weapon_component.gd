class_name DirectionalWeaponComponent
extends Node

@export var weapon_sprite: Sprite2D
@export var weapon_component: WeaponComponent
@export var skill_modifier: SkillModifierComponent
@export var weapon_offset: Vector2 = Vector2(43, -4)
@export var character_sprite_name: String = "CharacterSprite"
@export var delay_between_hits: float = 0.15

var _character_sprite: Sprite2D
var _hit_timer: Timer
var _current_hit_index: int = 0
var _total_hits: int = 1
var _is_front_attack: bool = true

func _ready() -> void:
	_find_character_sprite()
	_connect_to_weapon_component()
	_setup_hit_timer()

func _setup_hit_timer() -> void:
	_hit_timer = Timer.new()
	_hit_timer.wait_time = delay_between_hits
	_hit_timer.one_shot = true
	_hit_timer.timeout.connect(_on_hit_timer_timeout)
	add_child(_hit_timer)

func _connect_to_weapon_component() -> void:
	"""Connect to WeaponComponent signals if set"""
	if weapon_component:	
		weapon_component.attack_started.connect(_on_attack_started)
	else:
		print("DirectionalWeaponComponent: WARNING - weapon_component not set!")

func _on_attack_started() -> void:
	# Get multi-hit count from skills
	if skill_modifier:
		_total_hits = skill_modifier.get_multi_hit_count()
	else:
		_total_hits = 1
	
	# First hit - set direction for front attack
	_current_hit_index = 0
	_is_front_attack = true
	_set_weapon_direction()
	
	print("DEBUG: Starting attack sequence, total hits: %d" % _total_hits)
	
	# If multi-hit is active, disconnect signal to prevent interference
	if _total_hits > 1:
		weapon_component.attack_started.disconnect(_on_attack_started)
	
	# Schedule additional hits if multi-hit is active
	_current_hit_index = 1
	if _current_hit_index < _total_hits:
		_hit_timer.start()

func _on_hit_timer_timeout() -> void:
	if _current_hit_index >= _total_hits:
		# Sequence complete - reconnect signal
		if not weapon_component.attack_started.is_connected(_on_attack_started):
			weapon_component.attack_started.connect(_on_attack_started)
		return
	
	# Alternate between front and back attacks
	_is_front_attack = (_current_hit_index % 2 == 0)
	
	print("DEBUG: Hit %d/%d, is_front_attack: %s" % [_current_hit_index, _total_hits, _is_front_attack])
	
	# Set weapon direction for this hit
	_set_weapon_direction()
	
	# Trigger the attack
	if weapon_component:
		weapon_component.trigger_attack()
	
	# Move to next hit
	_current_hit_index += 1
	
	# Schedule next hit if there are more
	if _current_hit_index < _total_hits:
		_hit_timer.start()
	else:
		# Sequence complete - reconnect signal
		if not weapon_component.attack_started.is_connected(_on_attack_started):
			weapon_component.attack_started.connect(_on_attack_started)

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

func _set_weapon_direction() -> void:
	"""Set weapon position and flip based on character direction and attack type"""
	if not _character_sprite:
		return
	
	# Determine final weapon position based on character facing and attack type
	# flip_h = true means character is facing RIGHT
	# flip_h = false means character is facing LEFT
	
	if _character_sprite.flip_h:
		# Character facing RIGHT
		if _is_front_attack:
			# Attack in front (right side)
			owner.position.x = weapon_offset.x
			if weapon_sprite:
				weapon_sprite.flip_h = false
		else:
			# Attack behind (left side)
			owner.position.x = -weapon_offset.x
			if weapon_sprite:
				weapon_sprite.flip_h = true
	else:
		# Character facing LEFT
		if _is_front_attack:
			# Attack in front (left side)
			owner.position.x = -weapon_offset.x
			if weapon_sprite:
				weapon_sprite.flip_h = true
		else:
			# Attack behind (right side)
			owner.position.x = weapon_offset.x
			if weapon_sprite:
				weapon_sprite.flip_h = false
	
	owner.position.y = weapon_offset.y
