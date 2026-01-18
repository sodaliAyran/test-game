class_name HUDXPBar
extends Control

## HUD-style XP bar for player (displayed below health bar)
## Displays XP progress and current level

# Visual customization
@export_group("Appearance")
@export var bar_width: float = 300.0
@export var bar_height: float = 6.0
@export var background_color: Color = Color(0.08, 0.06, 0.1, 0.95)
@export var xp_color: Color = Color(0.2, 0.4, 0.9, 1.0)
@export var border_color: Color = Color(0.02, 0.02, 0.05, 1.0)
@export var border_width: float = 2.0

@export_group("Level Text")
@export var show_level: bool = true
@export var level_color: Color = Color(0.7, 0.8, 1.0, 1.0)
@export var level_font_size: int = 10
@export var level_offset: float = 2.0

@export_group("Positioning")
@export var bottom_margin: float = 1.0

@export_group("Animation")
@export var smooth_transition: bool = true
@export var transition_speed: float = 10.0
@export var level_up_flash: bool = true
@export var flash_duration: float = 0.3

# Internal state
var current_xp: int = 0
var xp_for_next_level: int = 100
var current_level: int = 1
var target_xp_ratio: float = 0.0
var current_xp_ratio: float = 0.0
var flash_timer: float = 0.0

# UI nodes
var background_rect: ColorRect
var xp_rect: ColorRect
var border_panel: Panel
var level_label: Label

func _ready() -> void:
	_adjust_positioning()
	_setup_ui()
	_connect_to_game_stats()

func _adjust_positioning() -> void:
	offset_left = -bar_width / 2
	offset_right = bar_width / 2
	offset_top = -(bar_height + bottom_margin)
	offset_bottom = -bottom_margin

func _setup_ui() -> void:
	border_width = max(1.0, bar_height * 0.15)

	custom_minimum_size = Vector2(bar_width, bar_height)
	size = custom_minimum_size

	# Create border/background panel
	border_panel = Panel.new()
	border_panel.size = size
	add_child(border_panel)

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

	# Create XP rect (foreground)
	xp_rect = ColorRect.new()
	xp_rect.color = xp_color
	xp_rect.position = Vector2(border_width, border_width)
	xp_rect.size = Vector2(0, bar_height - border_width * 2)
	add_child(xp_rect)

	# Create level label below the bar
	if show_level:
		level_label = Label.new()
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		level_label.position = Vector2(0, bar_height + level_offset)
		level_label.size = Vector2(bar_width, level_font_size + 4)
		level_label.add_theme_color_override("font_color", level_color)
		level_label.add_theme_font_size_override("font_size", level_font_size)
		level_label.add_theme_constant_override("shadow_offset_x", 1)
		level_label.add_theme_constant_override("shadow_offset_y", 1)
		level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		add_child(level_label)
		_update_level_text()

func _process(delta: float) -> void:
	if smooth_transition:
		current_xp_ratio = lerp(current_xp_ratio, target_xp_ratio, transition_speed * delta)
	else:
		current_xp_ratio = target_xp_ratio

	# Update XP bar width
	var bar_inner_width = bar_width - border_width * 2
	xp_rect.size.x = bar_inner_width * current_xp_ratio

	# Handle level up flash
	if flash_timer > 0:
		flash_timer -= delta
		var flash_intensity = flash_timer / flash_duration
		xp_rect.modulate = Color(1.0 + flash_intensity * 0.8, 1.0 + flash_intensity * 0.8, 1.0 + flash_intensity * 0.3)
	else:
		xp_rect.modulate = Color.WHITE

func update_xp(new_xp: int, new_xp_for_next: int, new_level: int) -> void:
	var old_level = current_level
	current_xp = new_xp
	xp_for_next_level = new_xp_for_next
	current_level = new_level
	target_xp_ratio = clamp(float(current_xp) / float(xp_for_next_level), 0.0, 1.0)

	if show_level and level_label:
		_update_level_text()

	# Trigger flash effect on level up
	if level_up_flash and new_level > old_level:
		flash_timer = flash_duration

func _update_level_text() -> void:
	if level_label:
		level_label.text = "Lv %d" % current_level

func _connect_to_game_stats() -> void:
	# Wait a frame for autoloads to be ready
	await get_tree().process_frame

	if GameStats:
		GameStats.xp_changed.connect(update_xp)
		# Initialize with current values
		update_xp(GameStats.get_xp(), GameStats.get_xp_for_next_level(), GameStats.get_level())
		print("HUDXPBar: Connected to GameStats")
	else:
		push_warning("HUDXPBar: GameStats autoload not found")
