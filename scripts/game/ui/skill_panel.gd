extends Control
class_name SkillPanel

var PIXEL_FONT = load("res://assets/game/ui/fonts/PixelOperator8.ttf")

signal clicked

@export var panel_size: Vector2 = Vector2(90, 80)
@export var normal_color: Color = Color(0.2, 0.2, 0.25, 0.9)
@export var hover_color: Color = Color(0.3, 0.3, 0.4, 0.95)
@export var pressed_color: Color = Color(0.15, 0.15, 0.2, 1.0)
@export var selected_color: Color = Color(0.35, 0.35, 0.5, 1.0)
@export var selected_border_color: Color = Color(1.0, 0.9, 0.3, 1.0)

var _is_hovered: bool = false
var _is_pressed: bool = false
var _is_selected: bool = false
var _panel: PanelContainer
var _style: StyleBoxFlat
var _content: VBoxContainer
var _select_label: Label

var _skill_data: SkillData
var _target_level: int = 0

var _default_border_color: Color = Color(0.4, 0.4, 0.5, 1.0)


func _ready() -> void:
	_setup_ui()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _setup_ui() -> void:
	# Force exact size - no growing or shrinking
	custom_minimum_size = panel_size
	size = panel_size
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style = StyleBoxFlat.new()
	_style.bg_color = normal_color
	# Capsule shape: corner radius = half the height
	_style.set_corner_radius_all(20)
	_style.set_border_width_all(2)
	_style.border_color = _default_border_color

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _style)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.clip_contents = true
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_theme_constant_override("separation", 1)
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(_content)

	# "Select" indicator below the panel
	_select_label = Label.new()
	_select_label.text = "Select"
	_select_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_select_label.add_theme_font_override("font", PIXEL_FONT)
	_select_label.add_theme_font_size_override("font_size", 8)
	_select_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	_select_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_select_label.visible = false
	add_child(_select_label)
	# Position below the panel, centered with it
	_select_label.position = Vector2(0, panel_size.y + 4)
	_select_label.size = Vector2(panel_size.x, 14)


func set_skill_offering(skill_data: SkillData, target_level: int) -> void:
	_skill_data = skill_data
	_target_level = target_level
	_populate_content()


func get_skill_data() -> SkillData:
	return _skill_data


func get_target_level() -> int:
	return _target_level


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_select_label.visible = selected
	_update_style()


func _populate_content() -> void:
	if not _content:
		return

	for child in _content.get_children():
		child.queue_free()

	if not _skill_data:
		return

	# Skill name (wraps to next line if too long)
	var name_label = Label.new()
	name_label.text = _skill_data.skill_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_override("font", PIXEL_FONT)
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7, 1.0))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(name_label)

	# Star-based level indicator (single row, max 3 visible)
	var star_label = Label.new()
	star_label.text = _build_star_string()
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.clip_text = true
	star_label.add_theme_font_override("font", PIXEL_FONT)
	star_label.add_theme_font_size_override("font_size", 10)
	star_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(star_label)


func _build_star_string() -> String:
	var current_level = _target_level - 1  # levels already owned
	# Show max 3 stars to keep compact
	var max_stars = mini(_skill_data.max_level, 3)
	# Scale filled proportionally if max_level > 3
	var filled: int
	if _skill_data.max_level <= 3:
		filled = mini(current_level, max_stars)
	else:
		filled = roundi(float(current_level) / float(_skill_data.max_level) * 3.0)
	filled = clampi(filled, 0, max_stars)
	var empty = max_stars - filled
	return "★".repeat(filled) + "☆".repeat(empty)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_pressed = true
				_update_style()
			else:
				if _is_pressed and _is_hovered:
					clicked.emit()
				_is_pressed = false
				_update_style()


func _on_mouse_entered() -> void:
	_is_hovered = true
	_update_style()


func _on_mouse_exited() -> void:
	_is_hovered = false
	_is_pressed = false
	_update_style()


func _update_style() -> void:
	if _is_pressed:
		_style.bg_color = pressed_color
	elif _is_selected:
		_style.bg_color = selected_color
		_style.border_color = selected_border_color
	elif _is_hovered:
		_style.bg_color = hover_color
		_style.border_color = _default_border_color
	else:
		_style.bg_color = normal_color
		_style.border_color = _default_border_color
