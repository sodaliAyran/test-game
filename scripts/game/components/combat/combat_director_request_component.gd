class_name CombatDirectorRequestComponent
extends Node

## Handles AP token requests to CombatDirector for skills and abilities.
## Attach this component to any entity that needs to request actions from the AI Director.
## Reusable across all skills (dash, ranged, special attacks, etc.)

@export var enabled: bool = true  ## Enable/disable AP requirement
@export var default_priority: int = 50  ## Default priority for AP requests

signal action_approved(action_type: String)
signal action_denied(action_type: String, reason: String)

var _pending_request: APRequest = null


func _ready() -> void:
	if enabled:
		_connect_combat_director()


func _exit_tree() -> void:
	cancel_pending_request()
	_disconnect_combat_director()


## Request an action from CombatDirector
## Returns true if request was queued, false if rejected
func request_action(request: APRequest) -> bool:
	if not enabled:
		# No AP requirement - execute immediately
		if request.callback.is_valid():
			request.callback.call()
		return true

	# Can't have multiple pending requests
	if _pending_request != null:
		return false

	if CombatDirector.request_ap(request):
		_pending_request = request
		return true

	return false


## Notify CombatDirector that an action has completed
func complete_action() -> void:
	if enabled:
		CombatDirector.complete_attack(get_parent())


## Cancel any pending request
func cancel_pending_request() -> void:
	if _pending_request != null:
		CombatDirector.cancel_request(get_parent())
		_pending_request = null


## Check if there's a pending request
func has_pending_request() -> bool:
	return _pending_request != null


## Get the pending action type (or empty string if none)
func get_pending_action_type() -> String:
	if _pending_request != null:
		return _pending_request.action_type
	return ""


## CombatDirector Signal Handlers

func _connect_combat_director() -> void:
	if not CombatDirector.attack_approved.is_connected(_on_attack_approved):
		CombatDirector.attack_approved.connect(_on_attack_approved)
	if not CombatDirector.attack_denied.is_connected(_on_attack_denied):
		CombatDirector.attack_denied.connect(_on_attack_denied)


func _disconnect_combat_director() -> void:
	if CombatDirector.attack_approved.is_connected(_on_attack_approved):
		CombatDirector.attack_approved.disconnect(_on_attack_approved)
	if CombatDirector.attack_denied.is_connected(_on_attack_denied):
		CombatDirector.attack_denied.disconnect(_on_attack_denied)


func _on_attack_approved(enemy: Node2D, action_type: String) -> void:
	# Check if this approval is for our pending request
	if _pending_request != null and enemy == get_parent() and action_type == _pending_request.action_type:
		_pending_request = null
		action_approved.emit(action_type)


func _on_attack_denied(enemy: Node2D, reason: String) -> void:
	# Check if this denial is for our pending request
	if _pending_request != null and enemy == get_parent():
		var action_type = _pending_request.action_type
		_pending_request = null
		action_denied.emit(action_type, reason)
