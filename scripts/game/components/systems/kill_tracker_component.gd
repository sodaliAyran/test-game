class_name KillTrackerComponent
extends Node

## Lightweight component that tracks when an entity dies
## and reports it to the GameStats manager

func _ready() -> void:
	# Wait a frame for parent to be fully ready
	await get_tree().process_frame
	
	# Find HealthComponent in parent
	var parent = get_parent()
	if not parent:
		push_warning("KillTrackerComponent: No parent found")
		return
	
	var health_component: HealthComponent = null
	
	# Look for HealthComponent in parent's children
	for child in parent.get_children():
		if child is HealthComponent:
			health_component = child
			break
	
	# Try direct path if not found
	if not health_component and parent.has_node("HealthComponent"):
		var node = parent.get_node("HealthComponent")
		if node is HealthComponent:
			health_component = node
	
	if health_component:
		health_component.died.connect(_on_died)
	else:
		push_warning("KillTrackerComponent: No HealthComponent found in parent '%s'" % parent.name)

func _on_died() -> void:
	"""Called when the entity dies."""
	if GameStats:
		GameStats.increment_kills()
