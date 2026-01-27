class_name CombatParticipantComponent
extends Node

## Component that handles an enemy's interaction with the Combat Director
## Manages AP requests, callbacks, and attack state

signal attack_approved(action_type: String)
signal attack_denied(reason: String)
signal attack_completed()

@export var base_priority: int = 50

# Map friendly names to action types
@export var action_type_map: Dictionary = {
	"basic": "basic_melee",
	"heavy": "heavy_melee",
	"special": "special_attack",
	"dash": "dash_attack",
	"ranged": "ranged_attack",
}

var _is_attacking: bool = false
var _current_action: String = ""
var _has_pending_request: bool = false
var _combat_director: Node = null


func _ready() -> void:
	# Get reference to CombatDirector autoload
	_combat_director = get_node_or_null("/root/CombatDirector")

	# Connect to CombatDirector signals for denied requests
	if _combat_director:
		_combat_director.attack_denied.connect(_on_attack_denied)


func _exit_tree() -> void:
	cancel_pending_request()
	if _is_attacking and _combat_director:
		_combat_director.complete_attack(owner)
	if _combat_director and _combat_director.attack_denied.is_connected(_on_attack_denied):
		_combat_director.attack_denied.disconnect(_on_attack_denied)


## Request permission to perform an attack
## attack_name can be a friendly name (mapped via action_type_map) or direct action type
## Returns true if request was queued
func request_attack(attack_name: String) -> bool:
	if _is_attacking or _has_pending_request:
		return false

	if not _combat_director:
		# No combat director, approve immediately
		_approve_attack(attack_name)
		return true

	# Map friendly name to action type
	var action_type = action_type_map.get(attack_name, attack_name)

	# Create request
	var request = APRequest.create(
		owner,
		action_type,
		func(): _on_request_approved(action_type),
		_calculate_priority()
	)

	_has_pending_request = _combat_director.request_ap(request)
	return _has_pending_request


## Cancel any pending attack request
func cancel_pending_request() -> void:
	if _combat_director and _has_pending_request:
		_combat_director.cancel_request(owner)
	_has_pending_request = false


## Notify that attack animation/action is complete
## IMPORTANT: Must be called when attack animation finishes
func notify_attack_complete() -> void:
	if _combat_director and _is_attacking:
		_combat_director.complete_attack(owner)

	_is_attacking = false
	_current_action = ""
	attack_completed.emit()


## Check if we're currently in an attack
func is_attacking() -> bool:
	return _is_attacking


## Check if we have a pending request
func has_pending_request() -> bool:
	return _has_pending_request


## Get current action type (if attacking)
func get_current_action() -> String:
	return _current_action


## Get cost of an action
func get_action_cost(attack_name: String) -> float:
	var action_type = action_type_map.get(attack_name, attack_name)
	return _combat_director.get_action_cost(action_type) if _combat_director else 1.0


## Calculate priority based on context
func _calculate_priority() -> int:
	var priority = base_priority

	# Bonus for being in inner ring (more aggressive positioning)
	if owner.has_node("SlotSeekerComponent"):
		var slot_seeker = owner.get_node("SlotSeekerComponent") as SlotSeekerComponent
		if slot_seeker and slot_seeker.is_in_inner_ring():
			priority += 20

	# Could add more modifiers based on health, enemy type, etc.

	return priority


## Called when request is approved by CombatDirector
func _on_request_approved(action_type: String) -> void:
	_has_pending_request = false
	_approve_attack(action_type)


## Internal: approve and start the attack
func _approve_attack(action_type: String) -> void:
	_is_attacking = true
	_current_action = action_type
	attack_approved.emit(action_type)


## Called when CombatDirector denies a request
func _on_attack_denied(enemy: Node2D, reason: String) -> void:
	if enemy == owner:
		_has_pending_request = false
		attack_denied.emit(reason)
