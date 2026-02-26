extends Control
class_name SkillPanel

var PIXEL_FONT = load("res://assets/game/ui/fonts/PixelOperator8.ttf")

signal clicked

@export var panel_size: Vector2 = Vector2(120, 160)
@export var normal_color: Color = Color(0.2, 0.2, 0.25, 0.9)
@export var hover_color: Color = Color(0.3, 0.3, 0.4, 0.95)
@export var pressed_color: Color = Color(0.15, 0.15, 0.2, 1.0)

var _is_hovered: bool = false
var _is_pressed: bool = false
var _panel: PanelContainer
var _style: StyleBoxFlat
var _content: VBoxContainer

var _skill_data: SkillData
var _target_level: int = 0


func _ready() -> void:
	_setup_ui()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _setup_ui() -> void:
	custom_minimum_size = panel_size
	size = panel_size
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	clip_contents = true

	_style = StyleBoxFlat.new()
	_style.bg_color = normal_color
	_style.set_corner_radius_all(8)
	_style.set_border_width_all(2)
	_style.border_color = Color(0.4, 0.4, 0.5, 1.0)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _style)
	_panel.custom_minimum_size = panel_size
	_panel.size = panel_size
	_panel.clip_contents = true
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_theme_constant_override("separation", 6)
	margin.add_child(_content)


func set_skill_offering(skill_data: SkillData, target_level: int) -> void:
	_skill_data = skill_data
	_target_level = target_level
	_populate_content()


func _populate_content() -> void:
	if not _content:
		return

	# Clear existing children
	for child in _content.get_children():
		child.queue_free()

	if not _skill_data:
		return

	# Skill name
	var name_label = Label.new()
	name_label.text = _skill_data.skill_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_override("font", PIXEL_FONT)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7, 1.0))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(name_label)

	# Level indicator
	var level_label = Label.new()
	if _target_level == 1:
		level_label.text = "NEW"
		level_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	else:
		level_label.text = "Lv %d -> %d" % [_target_level - 1, _target_level]
		level_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1.0))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_override("font", PIXEL_FONT)
	level_label.add_theme_font_size_override("font_size", 10)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(level_label)

	# Separator
	var sep = HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(sep)

	# Description from the target level data
	var level_data = _skill_data.get_level_data(_target_level)
	if level_data and level_data.description != "":
		var desc_label = Label.new()
		desc_label.text = level_data.description
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_override("font", PIXEL_FONT)
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content.add_child(desc_label)

	# Modifier summary
	var summary = _skill_data.get_level_modifier_summary(_target_level)
	if summary != "No modifiers":
		var mod_label = Label.new()
		mod_label.text = summary
		mod_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mod_label.add_theme_font_override("font", PIXEL_FONT)
		mod_label.add_theme_font_size_override("font_size", 8)
		mod_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5, 1.0))
		mod_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content.add_child(mod_label)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_pressed = true
				_update_style()
			else:
				if _is_pressed and _is_hovered:
					print("SkillPanel: Clicked!")
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
	elif _is_hovered:
		_style.bg_color = hover_color
	else:
		_style.bg_color = normal_color
