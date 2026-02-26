class_name TextBubbleComponent
extends Node2D

var PIXEL_FONT = load("res://assets/game/ui/fonts/PixelOperator8.ttf")

## Component that displays text bubbles above entities with randomized triggering
## Designed for enemy dialogue with future nemesis system support

signal bubble_shown(text: String)
signal bubble_hidden()

enum TriggerType {
	SPAWN,      ## Triggered when entity spawns
	ATTACK,     ## Triggered when entity attacks
	HURT,       ## Triggered when entity takes damage
	DEATH,      ## Triggered when entity dies
	MANUAL      ## Triggered manually via code
}

## Dialogue data resource containing possible lines
@export var dialogue_data: DialogueData

## Probability (0.0 to 1.0) that bubble will trigger
@export_range(0.0, 1.0) var trigger_probability: float = 0.2

## Which events should trigger the bubble
@export var trigger_on_spawn: bool = true
@export var trigger_on_attack: bool = false
@export var trigger_on_hurt: bool = false

## How long the bubble stays visible (seconds)
@export var display_duration: float = 1.5

## Vertical offset above the entity
@export var vertical_offset: float = -40.0

## Bubble styling
@export_group("Bubble Style")
@export var bubble_color: Color = Color(0.1, 0.1, 0.1, 0.9)
@export var border_color: Color = Color.WHITE
@export var border_width: int = 2
@export var corner_radius: int = 4
@export var padding: Vector2 = Vector2(6, 4)

## Text styling
@export_group("Text Style")
@export var text_color: Color = Color.WHITE
@export var font_size: int = 8

## Animation component for fade effects
@export var fade_animation_component: FadeAnimationComponent

## Spawn animation component to wait for before showing bubble
@export var spawn_animation_component: SpawnAnimationComponent

## Delay after spawn animation completes before showing bubble (seconds)
@export var spawn_delay: float = 0.5

## References
var current_bubble: Control = null
var display_timer: Timer = null
var hurtbox_component: HurtboxComponent = null


func _ready() -> void:
	# Setup display timer
	display_timer = Timer.new()
	display_timer.one_shot = true
	display_timer.timeout.connect(_on_display_timeout)
	add_child(display_timer)
	
	# Find hurtbox for hurt trigger
	if trigger_on_hurt:
		hurtbox_component = _find_component(HurtboxComponent)
		if hurtbox_component:
			hurtbox_component.hurt.connect(_on_hurt_trigger)
	
	# Find spawn animation component for spawn trigger
	if trigger_on_spawn:
		# If not manually assigned, try to find it
		if not spawn_animation_component:
			spawn_animation_component = _find_component(SpawnAnimationComponent)
		
		if spawn_animation_component:
			spawn_animation_component.spawn_complete.connect(_on_spawn_complete)
		else:
			# No spawn animation, trigger immediately
			call_deferred("_try_trigger", TriggerType.SPAWN)
	
	# Clean up bubble when entity is removed from scene
	var parent = get_parent()
	if parent:
		parent.tree_exiting.connect(_on_entity_removed)


func _find_component(component_class) -> Node:
	"""Helper to find a component in parent or siblings."""
	var parent = get_parent()
	if not parent:
		return null
	
	for child in parent.get_children():
		if is_instance_of(child, component_class):
			return child
	return null


func _try_trigger(trigger_type: TriggerType) -> void:
	"""Attempt to trigger a bubble based on probability."""
	if current_bubble != null:
		return  # Already showing a bubble
	
	if randf() > trigger_probability:
		return  # Probability check failed
	
	if not dialogue_data or not dialogue_data.has_dialogue():
		return  # No dialogue to show
	
	_show_bubble(dialogue_data.get_random_line())


func _show_bubble(text: String) -> void:
	"""Create and display a text bubble."""
	if text.is_empty():
		return
	
	# Create bubble container
	var bubble = PanelContainer.new()
	
	# Create and apply StyleBoxFlat
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = bubble_color
	style_box.border_color = border_color
	style_box.border_width_left = border_width
	style_box.border_width_right = border_width
	style_box.border_width_top = border_width
	style_box.border_width_bottom = border_width
	style_box.corner_radius_top_left = corner_radius
	style_box.corner_radius_top_right = corner_radius
	style_box.corner_radius_bottom_left = corner_radius
	style_box.corner_radius_bottom_right = corner_radius
	style_box.content_margin_left = padding.x
	style_box.content_margin_right = padding.x
	style_box.content_margin_top = padding.y
	style_box.content_margin_bottom = padding.y
	
	bubble.add_theme_stylebox_override("panel", style_box)
	
	# Create label
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", PIXEL_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Add outline for better readability
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	bubble.add_child(label)
	
	# Position bubble
	bubble.position = Vector2(0, vertical_offset)
	
	# Add to scene tree (as child of current scene to avoid transform issues)
	get_tree().current_scene.add_child(bubble)
	
	# Center the bubble horizontally on the entity
	await get_tree().process_frame  # Wait for size calculation
	bubble.global_position = global_position + Vector2(-bubble.size.x / 2, vertical_offset)
	
	current_bubble = bubble
	
	# Play fade animation if available
	if fade_animation_component:
		fade_animation_component.play(bubble)
		fade_animation_component.animation_complete.connect(_on_fade_complete, CONNECT_ONE_SHOT)
	
	# Start display timer
	display_timer.start(display_duration)
	
	emit_signal("bubble_shown", text)


func _on_display_timeout() -> void:
	"""Hide bubble after display duration."""
	_hide_bubble()


func _on_fade_complete(_target: Node) -> void:
	"""Called when fade animation completes."""
	# Bubble will be cleaned up by _hide_bubble or timer


func _hide_bubble() -> void:
	"""Remove the current bubble."""
	if current_bubble and is_instance_valid(current_bubble):
		current_bubble.queue_free()
		current_bubble = null
		emit_signal("bubble_hidden")


func _on_spawn_complete() -> void:
	"""Triggered when spawn animation completes."""
	# Wait for spawn_delay before trying to trigger bubble
	if spawn_delay > 0:
		await get_tree().create_timer(spawn_delay).timeout
	_try_trigger(TriggerType.SPAWN)


func _on_entity_removed() -> void:
	"""Triggered when the parent entity is removed from the scene."""
	_hide_bubble()


func _on_hurt_trigger(_amount: int) -> void:
	"""Triggered when entity takes damage."""
	_try_trigger(TriggerType.HURT)


func trigger_attack() -> void:
	"""Manually trigger attack dialogue."""
	if trigger_on_attack:
		_try_trigger(TriggerType.ATTACK)


func trigger_manual(override_text: String = "") -> void:
	"""Manually trigger a bubble with optional custom text."""
	if not override_text.is_empty():
		_show_bubble(override_text)
	else:
		_try_trigger(TriggerType.MANUAL)


func _process(_delta: float) -> void:
	# Update bubble position to follow entity
	if current_bubble and is_instance_valid(current_bubble):
		current_bubble.global_position = global_position + Vector2(-current_bubble.size.x / 2, vertical_offset)
