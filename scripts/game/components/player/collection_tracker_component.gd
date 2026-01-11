class_name CollectionTrackerComponent
extends Node

## Lightweight component that tracks when items are collected
## and reports them to the GameStats manager

func _ready() -> void:
	# Wait a frame for parent to be fully ready
	await get_tree().process_frame
	
	# Find CollectorComponent in parent
	var parent = get_parent()
	if not parent:
		push_warning("CollectionTrackerComponent: No parent found")
		return
	
	var collector_component: CollectorComponent = null
	
	# Look for CollectorComponent in parent's children
	for child in parent.get_children():
		if child is CollectorComponent:
			collector_component = child
			break
	
	# Try direct path if not found
	if not collector_component and parent.has_node("CollectorComponent"):
		var node = parent.get_node("CollectorComponent")
		if node is CollectorComponent:
			collector_component = node
	
	if collector_component:
		collector_component.item_collected.connect(_on_item_collected)
	else:
		push_warning("CollectionTrackerComponent: No CollectorComponent found in parent '%s'" % parent.name)

func _on_item_collected(collectible_type: String, value: int) -> void:
	"""Called when an item is collected."""
	if collectible_type == "coin" and GameStats:
		GameStats.add_coins(value)
