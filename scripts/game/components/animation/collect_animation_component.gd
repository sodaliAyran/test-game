class_name CollectAnimationComponent
extends Node

## Animates the parent collectible when picked up.
## Plays a pullback-then-swoop animation before freeing.
## Attach as a child of a CollectibleComponent.

@export var pullback_distance: float = 15.0  ## How far the item moves away from the collector
@export var pullback_duration: float = 0.12  ## Duration of the pullback phase
@export var return_duration: float = 0.18  ## Duration of the return-to-collector phase
@export var scale_shrink: float = 0.3  ## Final scale multiplier when arriving at collector

var _collector: Node2D
var _return_start_pos: Vector2

func play(collector: Node2D) -> void:
	var parent = get_parent() as Node2D
	if not parent or not is_instance_valid(collector):
		if parent:
			parent.queue_free()
		return

	_collector = collector

	# Calculate pullback direction (away from collector)
	var dir_away = (parent.global_position - collector.global_position).normalized()
	if dir_away.is_zero_approx():
		dir_away = Vector2.UP
	var pullback_target = parent.global_position + dir_away * pullback_distance

	# Single tween with sequential phases using chain()
	var tween = create_tween()

	# Phase 1: Pullback position (ease out)
	tween.tween_property(parent, "global_position", pullback_target, pullback_duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Phase 1: Scale up (runs in parallel with position via set_parallel on this tweener)
	tween.parallel().tween_property(parent, "scale", Vector2(1.3, 1.3), pullback_duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Callback to capture start position for phase 2
	tween.tween_callback(_capture_return_start)

	# Phase 2: Swoop back to collector (ease in)
	tween.tween_method(_update_return_position, 0.0, 1.0, return_duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Phase 2: Shrink (parallel with return)
	tween.parallel().tween_property(parent, "scale", Vector2(scale_shrink, scale_shrink), return_duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Finish
	tween.tween_callback(_on_finished)

func _capture_return_start() -> void:
	var parent = get_parent() as Node2D
	if parent:
		_return_start_pos = parent.global_position

func _update_return_position(t: float) -> void:
	var parent = get_parent() as Node2D
	if not parent:
		return

	var target_pos = _collector.global_position if is_instance_valid(_collector) else _return_start_pos
	parent.global_position = _return_start_pos.lerp(target_pos, t)

func _on_finished() -> void:
	var parent = get_parent()
	if parent:
		parent.queue_free()
