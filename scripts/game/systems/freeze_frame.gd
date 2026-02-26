extends Node
class_name FreezeFrameManager

## Global freeze frame manager for hit impact juice.
## Freezes the entire game briefly for impact feel.
## Usage: FreezeFrame.freeze(0.1)

var _freeze_end_time: int = 0
var _is_frozen: bool = false


func _process(_delta: float) -> void:
	if not _is_frozen:
		return

	# Use real time (unaffected by time_scale)
	if Time.get_ticks_msec() >= _freeze_end_time:
		_is_frozen = false
		Engine.time_scale = 1


func freeze(duration: float = 0.1) -> void:
	var end_time = Time.get_ticks_msec() + int(duration * 1000)

	if _is_frozen:
		# Extend existing freeze if longer
		_freeze_end_time = max(_freeze_end_time, end_time)
		return

	_is_frozen = true
	_freeze_end_time = end_time
	Engine.time_scale = 0.0