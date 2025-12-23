extends Label

## Debug UI for showing procedural world stats

@onready var world: Node2D = get_node("../../ProceduralWorld")


func _process(_delta: float) -> void:
	if world and world.has_method("get_stats"):
		var stats = world.get_stats()
		text = "Procedural World Test\n"
		text += "Active Chunks: %d\n" % stats["active_chunks"]
		text += "Cached Chunks: %d\n" % stats["cached_chunks"]
		text += "Total Generated: %d" % stats["total_generated"]
