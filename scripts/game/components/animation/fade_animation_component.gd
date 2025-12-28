class_name FadeAnimationComponent
extends Node

signal animation_complete(target)

@export var fade_in_duration: float = 0.15
@export var peak_duration: float = 0.15
@export var fade_out_duration: float = 0.3
@export var start_scale: float = 0.5
@export var peak_scale: float = 1.2
@export var end_scale: float = 0.5

enum AnimationPhase {
	FADE_IN,
	PEAK,
	FADE_OUT,
	IDLE
}

# Track multiple active animations
var active_animations: Dictionary = {}  # {CanvasItem: {phase, time, original_modulate, original_scale}}

func play(target_node: CanvasItem) -> void:
	"""Start a fade animation on the given target node."""
	if not target_node:
		push_warning("FadeAnimationComponent: target_node is null")
		return
	
	# Initialize animation state for this target
	active_animations[target_node] = {
		"phase": AnimationPhase.FADE_IN,
		"time": 0.0,
		"original_modulate": target_node.modulate,
		"original_scale": target_node.scale
	}
	
	# Start invisible and small
	target_node.modulate.a = 0.0
	target_node.scale = active_animations[target_node].original_scale * start_scale

func _process(delta: float) -> void:
	# Process all active animations
	var completed_targets = []
	
	for target in active_animations.keys():
		if not is_instance_valid(target):
			completed_targets.append(target)
			continue
		
		var anim_state = active_animations[target]
		anim_state.time += delta
		
		match anim_state.phase:
			AnimationPhase.FADE_IN:
				_process_fade_in(target, anim_state)
			AnimationPhase.PEAK:
				_process_peak(target, anim_state)
			AnimationPhase.FADE_OUT:
				if _process_fade_out(target, anim_state):
					completed_targets.append(target)
	
	# Clean up completed animations
	for target in completed_targets:
		active_animations.erase(target)
		if is_instance_valid(target):
			animation_complete.emit(target)

func _process_fade_in(target: CanvasItem, anim_state: Dictionary) -> void:
	var progress = anim_state.time / fade_in_duration
	
	if progress >= 1.0:
		# Move to peak phase
		anim_state.phase = AnimationPhase.PEAK
		anim_state.time = 0.0
		return
	
	# Ease out for smooth fade in
	var eased_progress = ease(progress, -0.5)
	
	# Fade in alpha
	target.modulate.a = eased_progress
	
	# Scale up
	var scale_value = lerp(start_scale, peak_scale, eased_progress)
	target.scale = anim_state.original_scale * scale_value

func _process_peak(target: CanvasItem, anim_state: Dictionary) -> void:
	var progress = anim_state.time / peak_duration
	
	if progress >= 1.0:
		# Move to fade out phase
		anim_state.phase = AnimationPhase.FADE_OUT
		anim_state.time = 0.0
		return
	
	# Hold at peak values
	target.modulate.a = 1.0
	target.scale = anim_state.original_scale * peak_scale

func _process_fade_out(target: CanvasItem, anim_state: Dictionary) -> bool:
	var progress = anim_state.time / fade_out_duration
	
	if progress >= 1.0:
		# Animation complete
		return true
	
	# Ease in for smooth fade out
	var eased_progress = ease(progress, 0.5)
	
	# Fade out alpha
	target.modulate.a = 1.0 - eased_progress
	
	# Scale down
	var scale_value = lerp(peak_scale, end_scale, eased_progress)
	target.scale = anim_state.original_scale * scale_value
	
	return false

func stop(target_node: CanvasItem = null) -> void:
	"""Stop animation(s). If target_node is null, stops all animations."""
	if target_node:
		if target_node in active_animations:
			var anim_state = active_animations[target_node]
			target_node.modulate = anim_state.original_modulate
			target_node.scale = anim_state.original_scale
			active_animations.erase(target_node)
	else:
		# Stop all animations
		for target in active_animations.keys():
			if is_instance_valid(target):
				var anim_state = active_animations[target]
				target.modulate = anim_state.original_modulate
				target.scale = anim_state.original_scale
		active_animations.clear()
