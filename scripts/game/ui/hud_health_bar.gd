class_name HUDHealthBar
extends Control

## HUD-style health bar for player (MOBA-style at bottom of screen)
## Displays health bar with current/max health text

# Visual customization
@export_group("Appearance")
@export var bar_width: float = 300.0
@export var bar_height: float = 30.0
@export var background_color: Color = Color(0.15, 0.15, 0.15, 0.9)
@export var health_color: Color = Color(0.2, 0.8, 0.3, 1.0)
@export var low_health_color: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var low_health_threshold: float = 0.3
@export var border_color: Color = Color(0.05, 0.05, 0.05, 1.0)
@export var border_width: float = 3.0

@export_group("Text")
@export var show_text: bool = true
@export var text_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var font_size: int = 16

@export_group("Animation")
@export var smooth_transition: bool = true
@export var transition_speed: float = 10.0
@export var damage_flash: bool = true
@export var flash_duration: float = 0.2

@export_group("Connection")
@export var auto_connect: bool = true
@export var player_group: String = "Player"

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
var health_label: Label

func _ready() -> void:
	# Auto-adjust offsets to center the bar
	_adjust_centering()
	
	_setup_ui()
	
	# Auto-connect to player's HealthComponent if enabled
	if auto_connect:
		_auto_connect_to_player()

func _adjust_centering() -> void:
	# Automatically adjust the offset to center the bar based on its size
	# This ensures the bar is always centered regardless of width/height changes
	offset_left = -bar_width / 2
	offset_right = bar_width / 2
	offset_top = -(bar_height + 30)  # 30 pixels from bottom
	offset_bottom = -30

func _setup_ui() -> void:
	# Calculate border width as a ratio of height (looks good at any size)
	border_width = max(2.0, bar_height * 0.1)
	
	# Calculate font size as a ratio of height
	if show_text:
		font_size = int(bar_height * 0.5)  # Font is 50% of bar height
	
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
	var border_px = int(border_width)
	border_style.border_width_left = border_px
	border_style.border_width_right = border_px
	border_style.border_width_top = border_px
	border_style.border_width_bottom = border_px
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
	
	# Create health text label
	if show_text:
		health_label = Label.new()
		health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		health_label.position = Vector2(0, 0)
		health_label.size = size
		health_label.add_theme_color_override("font_color", text_color)
		health_label.add_theme_font_size_override("font_size", font_size)
		# Add shadow for better readability
		health_label.add_theme_constant_override("shadow_offset_x", 1)
		health_label.add_theme_constant_override("shadow_offset_y", 1)
		health_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		add_child(health_label)
		_update_text()

func _process(delta: float) -> void:
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
	
	# Update text
	if show_text and health_label:
		_update_text()
	
	# Trigger flash effect if health decreased
	if damage_flash and new_current < old_health:
		flash_timer = flash_duration

func _update_text() -> void:
	if health_label:
		health_label.text = "%d / %d" % [int(current_health), int(max_health)]

func connect_to_health_component(health_component: HealthComponent) -> void:
	if health_component:
		health_component.health_changed.connect(update_health)
		# Initialize with current health
		update_health(health_component.current_health, health_component.max_health)

func _auto_connect_to_player() -> void:
	# Wait a frame for the scene tree to be ready
	await get_tree().process_frame
	
	# Find player in the scene tree
	var players = get_tree().get_nodes_in_group(player_group)
	if players.size() > 0:
		var player = players[0]
		
		# Look for HealthComponent in player
		for child in player.get_children():
			if child is HealthComponent:
				connect_to_health_component(child)
				print("HUDHealthBar: Auto-connected to player's HealthComponent")
				return
		
		# Try direct path
		if player.has_node("HealthComponent"):
			var health_comp = player.get_node("HealthComponent")
			if health_comp is HealthComponent:
				connect_to_health_component(health_comp)
				print("HUDHealthBar: Auto-connected to player's HealthComponent")
	else:
		push_warning("HUDHealthBar: No player found in group '%s'" % player_group)
