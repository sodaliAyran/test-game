class_name DirectionalWeaponComponent
extends Node

@export var weapon_sprite: Sprite2D
@export var weapon_component: WeaponComponent
@export var skill_modifier: SkillModifierComponent
@export var weapon_offset: Vector2 = Vector2(43, -4)
@export var delay_between_hits: float = 0.15

var _facing: FacingComponent
var _hit_timer: Timer
var _current_hit_index: int = 0
var _total_hits: int = 1
var _is_front_attack: bool = true

func _ready() -> void:
	_find_facing_component()
	_connect_to_weapon_component()
	_setup_hit_timer()

func _find_facing_component() -> void:
	# Search the weapon's parent (the character) for a FacingComponent
	var parent = owner.get_parent()
	if not parent:
		return

	for child in parent.get_children():
		if child is FacingComponent:
			_facing = child
			return

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

func _set_weapon_direction() -> void:
	"""Set weapon position and flip based on character direction and attack type"""
	if not _facing:
		return

	var facing_right = _facing.is_facing_right()
	var attack_on_right = (facing_right and _is_front_attack) or (not facing_right and not _is_front_attack)

	if attack_on_right:
		owner.position.x = weapon_offset.x
		if weapon_sprite:
			weapon_sprite.flip_h = false
	else:
		owner.position.x = -weapon_offset.x
		if weapon_sprite:
			weapon_sprite.flip_h = true

	owner.position.y = weapon_offset.y
