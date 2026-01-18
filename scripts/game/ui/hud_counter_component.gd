class_name HUDCounterComponent
extends Control

## Reusable HUD counter component for displaying icon + count
## Auto-connects to GameStats based on counter_type

@export_group("Configuration")
@export var counter_type: String = "kills"  # "kills" or "coins"
@export var icon_texture: Texture2D
@export var icon_size: Vector2 = Vector2(24, 24)

@export_group("Appearance")
@export var text_color: Color = Color.WHITE
@export var font_size: int = 20
@export var spacing: float = 8.0  # Space between icon and text

@export_group("Animation")
@export var animate_changes: bool = true
@export var animation_duration: float = 0.3

# Internal state
var current_count: int = 0
var display_count: float = 0.0
var target_count: int = 0
var animation_timer: float = 0.0

# UI nodes
var icon_rect: TextureRect
var count_label: Label

func _ready() -> void:
	_setup_ui()
	_connect_to_stats()

func _setup_ui() -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(spacing))
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(hbox)

	# Set minimum size for parent control
	custom_minimum_size = Vector2(icon_size.x + spacing + 40, icon_size.y)

	icon_rect = TextureRect.new()
	icon_rect.texture = icon_texture
	icon_rect.custom_minimum_size = icon_size
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hbox.add_child(icon_rect)

	count_label = Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_color_override("font_color", text_color)
	count_label.add_theme_font_size_override("font_size", font_size)
	count_label.add_theme_constant_override("shadow_offset_x", 1)
	count_label.add_theme_constant_override("shadow_offset_y", 1)
	count_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	hbox.add_child(count_label)

	_update_display()

func _connect_to_stats() -> void:
	if not GameStats:
		push_warning("HUDCounterComponent: GameStats autoload not found")
		return
	
	# Connect to appropriate signal based on counter type
	if counter_type == "kills":
		GameStats.kill_count_changed.connect(_on_count_changed)
		current_count = GameStats.get_kill_count()
	elif counter_type == "coins":
		GameStats.coin_count_changed.connect(_on_count_changed)
		current_count = GameStats.get_coin_count()
	else:
		push_warning("HUDCounterComponent: Unknown counter_type '%s'" % counter_type)
	
	display_count = float(current_count)
	target_count = current_count
	_update_display()

func _on_count_changed(new_count: int) -> void:
	target_count = new_count
	if animate_changes:
		animation_timer = animation_duration
	else:
		current_count = new_count
		display_count = float(new_count)
		_update_display()

func _process(delta: float) -> void:
	if animation_timer > 0:
		animation_timer -= delta
		# Smooth interpolation
		var t = 1.0 - (animation_timer / animation_duration)
		display_count = lerp(float(current_count), float(target_count), t)
		
		if animation_timer <= 0:
			current_count = target_count
			display_count = float(target_count)
		
		_update_display()

func _update_display() -> void:
	if count_label:
		count_label.text = str(int(display_count))
