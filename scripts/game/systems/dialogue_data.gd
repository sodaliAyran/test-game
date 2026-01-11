class_name DialogueData
extends Resource

## Resource for storing dialogue lines and metadata for the text bubble system
## Designed to support future nemesis system with state-based branching conversations

## Array of possible dialogue lines that can be displayed
@export var dialogue_lines: Array[String] = []

## Optional state key for tracking conversation branches in nemesis system
## Example: "first_encounter", "player_died_to_me", "low_health_taunt"
@export var state_key: String = ""

## Metadata for future expansion (e.g., emotion, voice type, etc.)
@export var metadata: Dictionary = {}

## Priority level for dialogue (higher priority shown first if multiple triggers)
@export var priority: int = 0


func get_random_line() -> String:
	"""Returns a random dialogue line from the array."""
	if dialogue_lines.is_empty():
		return ""
	return dialogue_lines.pick_random()


func get_line_by_index(index: int) -> String:
	"""Returns a specific dialogue line by index."""
	if index < 0 or index >= dialogue_lines.size():
		return ""
	return dialogue_lines[index]


func has_dialogue() -> bool:
	"""Check if this dialogue data has any lines."""
	return not dialogue_lines.is_empty()
