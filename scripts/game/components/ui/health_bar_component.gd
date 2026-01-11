class_name HealthBarComponent
extends Control

## Visual health bar component that displays current/max health
## Automatically updates when connected to a HealthComponent

# Visual customization
@export_group("Appearance")
@export var bar_width: float = 100.0
@export var bar_height: float = 12.0
@export var background_color: Color = Color(0.2, 0.2, 0.2, 0.8)
@export var health_color: Color = Color(0.2, 0.8, 0.3, 1.0)
@export var low_health_color: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var low_health_threshold: float = 0.3
@export var border_color: Color = Color(0.1, 0.1, 0.1, 1.0)
@export var border_width: float = 2.0

@export_group("Animation")
@export var smooth_transition: bool = true
@export var transition_speed: float = 10.0
@export var damage_flash: bool = true
@export var flash_duration: float = 0.2

@export_group("Positioning")
@export var offset_above_entity: Vector2 = Vector2(0, -40)
@export var auto_position: bool = true
@export var auto_connect: bool = true

# Internal state
var current_health: float = 100.0
var max_health: float = 100.0
var target_health_ratio: float = 1.0
var current_health_ratio: float = 1.0
var flash_timer: float = 0.0

# UI nodes
var background_rect: ColorRect
var health_rect: ColorRect
var border_panel: Panel

func _ready() -> void:
	_setup_ui()
	
	# Auto-connect to parent's HealthComponent if enabled
	if auto_connect:
		_auto_connect_to_parent()
	
func _setup_ui() -> void:
	# Set control size
	custom_minimum_size = Vector2(bar_width, bar_height)
	size = custom_minimum_size
	
	# Create border/background panel
	border_panel = Panel.new()
	border_panel.size = size
	add_child(border_panel)
	
	# Style the border
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = border_color
	border_style.border_width_left = int(border_width)
	border_style.border_width_right = int(border_width)
	border_style.border_width_top = int(border_width)
	border_style.border_width_bottom = int(border_width)
	border_style.border_color = border_color
	border_panel.add_theme_stylebox_override("panel", border_style)
	
	# Create background rect
	background_rect = ColorRect.new()
	background_rect.color = background_color
	background_rect.position = Vector2(border_width, border_width)
	background_rect.size = Vector2(bar_width - border_width * 2, bar_height - border_width * 2)
	add_child(background_rect)
	
	# Create health rect (foreground)
	health_rect = ColorRect.new()
	health_rect.color = health_color
	health_rect.position = Vector2(border_width, border_width)
	health_rect.size = Vector2(bar_width - border_width * 2, bar_height - border_width * 2)
	add_child(health_rect)

func _process(delta: float) -> void:
	# Auto-position above parent entity
	if auto_position:
		_update_position()
	
	if smooth_transition:
		# Smoothly interpolate to target health ratio
		current_health_ratio = lerp(current_health_ratio, target_health_ratio, transition_speed * delta)
	else:
		current_health_ratio = target_health_ratio
	
	# Update health bar width
	var bar_inner_width = bar_width - border_width * 2
	health_rect.size.x = bar_inner_width * current_health_ratio
	
	# Update color based on health percentage
	var health_percentage = current_health_ratio
	if health_percentage <= low_health_threshold:
		health_rect.color = low_health_color
	else:
		health_rect.color = health_color
	
	# Handle damage flash
	if flash_timer > 0:
		flash_timer -= delta
		var flash_intensity = flash_timer / flash_duration
		health_rect.modulate = Color(1.0 + flash_intensity * 0.5, 1.0 - flash_intensity * 0.5, 1.0 - flash_intensity * 0.5)
	else:
		health_rect.modulate = Color.WHITE

func update_health(new_current: float, new_max: float) -> void:
	var old_health = current_health
	current_health = new_current
	max_health = new_max
	target_health_ratio = clamp(current_health / max_health, 0.0, 1.0)
	
	# Trigger flash effect if health decreased
	if damage_flash and new_current < old_health:
		flash_timer = flash_duration

func connect_to_health_component(health_component: HealthComponent) -> void:
	if health_component:
		health_component.health_changed.connect(update_health)
		# Initialize with current health
		update_health(health_component.current_health, health_component.max_health)

func _auto_connect_to_parent() -> void:
	# Try to find HealthComponent in parent
	var parent = get_parent()
	if not parent:
		return
	
	# Look for HealthComponent as a child of parent
	for child in parent.get_children():
		if child is HealthComponent:
			connect_to_health_component(child)
			print("HealthBar: Auto-connected to HealthComponent in ", parent.name)
			return
	
	# If not found, check if parent has a HealthComponent node path
	if parent.has_node("HealthComponent"):
		var health_comp = parent.get_node("HealthComponent")
		if health_comp is HealthComponent:
			connect_to_health_component(health_comp)
			print("HealthBar: Auto-connected to HealthComponent in ", parent.name)

func _update_position() -> void:
	# Center the health bar horizontally above the parent
	var bar_offset = Vector2(-bar_width / 2, offset_above_entity.y)
	position = bar_offset

