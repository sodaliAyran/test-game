extends CanvasLayer
class_name LevelUpScreen

var PIXEL_FONT = load("res://assets/game/ui/fonts/PixelOperator8.ttf")

signal panel_selected(panel_index: int)

@export var skill_panel_scene: PackedScene
@export var panel_count: int = 3
@export var panel_spacing: int = 12

var _background: Control
var _title_label: Label
var _panel_container: HBoxContainer
var _current_offerings: Array[Dictionary] = []
var _selected_index: int = -1

# Detail panel references
var _detail_panel: PanelContainer
var _detail_name_label: Label
var _detail_stars_label: Label
var _detail_level_label: Label
var _detail_desc_label: Label
var _detail_mod_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_setup_ui()
	_background.visible = false
	_connect_to_game_stats()
	print("LevelUpScreen: Initialized")


func _connect_to_game_stats() -> void:
	await get_tree().process_frame
	print("LevelUpScreen: GameStats exists = %s" % (GameStats != null))
	if GameStats:
		GameStats.level_up.connect(_on_level_up)
		print("LevelUpScreen: Connected to GameStats.level_up")
	else:
		push_error("LevelUpScreen: GameStats autoload not found!")


func _setup_ui() -> void:
	# Root control that fills the viewport
	_background = Control.new()
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	# Dark overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.add_child(overlay)

	# === Upper section: panels (top portion) ===
	var upper_vbox = VBoxContainer.new()
	upper_vbox.anchor_left = 0.0
	upper_vbox.anchor_top = 0.1
	upper_vbox.anchor_right = 1.0
	upper_vbox.anchor_bottom = 0.5
	upper_vbox.offset_left = 0
	upper_vbox.offset_top = 0
	upper_vbox.offset_right = 0
	upper_vbox.offset_bottom = 0
	upper_vbox.add_theme_constant_override("separation", 8)
	upper_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_background.add_child(upper_vbox)

	# Panel container (horizontal, centered)
	_panel_container = HBoxContainer.new()
	_panel_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel_container.add_theme_constant_override("separation", panel_spacing)
	upper_vbox.add_child(_panel_container)

	# === Middle section: "LEVEL UP!" title centered between panels and detail ===
	_title_label = Label.new()
	_title_label.text = "LEVEL UP!"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_override("font", PIXEL_FONT)
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	_title_label.anchor_left = 0.0
	_title_label.anchor_top = 0.5
	_title_label.anchor_right = 1.0
	_title_label.anchor_bottom = 0.6
	_title_label.offset_left = 0
	_title_label.offset_top = 0
	_title_label.offset_right = 0
	_title_label.offset_bottom = 0
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.add_child(_title_label)

	# === Lower section: detail panel ===
	_setup_detail_panel()


func _setup_detail_panel() -> void:
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	detail_style.set_corner_radius_all(6)
	detail_style.set_border_width_all(1)
	detail_style.border_color = Color(0.5, 0.5, 0.6, 1.0)

	_detail_panel = PanelContainer.new()
	_detail_panel.add_theme_stylebox_override("panel", detail_style)
	# Anchor to bottom-center, below the title separator
	_detail_panel.anchor_left = 0.1
	_detail_panel.anchor_top = 0.6
	_detail_panel.anchor_right = 0.9
	_detail_panel.anchor_bottom = 0.9
	_detail_panel.offset_left = 0
	_detail_panel.offset_top = 0
	_detail_panel.offset_right = 0
	_detail_panel.offset_bottom = 0
	_detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_panel.visible = false
	_background.add_child(_detail_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# Skill name (top)
	_detail_name_label = Label.new()
	_detail_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_name_label.add_theme_font_override("font", PIXEL_FONT)
	_detail_name_label.add_theme_font_size_override("font_size", 10)
	_detail_name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7, 1.0))
	_detail_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_detail_name_label)

	# Separator after name
	var sep = HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)

	# Top spacer to push description to vertical center
	var top_spacer = Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_spacer)

	# Description
	_detail_desc_label = Label.new()
	_detail_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc_label.add_theme_font_override("font", PIXEL_FONT)
	_detail_desc_label.add_theme_font_size_override("font_size", 8)
	_detail_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	_detail_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_detail_desc_label)

	# Modifier summary
	_detail_mod_label = Label.new()
	_detail_mod_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_mod_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_mod_label.add_theme_font_override("font", PIXEL_FONT)
	_detail_mod_label.add_theme_font_size_override("font_size", 8)
	_detail_mod_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5, 1.0))
	_detail_mod_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_detail_mod_label)

	# Bottom spacer to balance vertical centering
	var bottom_spacer = Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom_spacer)

	# Bottom separator before stars
	var bottom_sep = HSeparator.new()
	bottom_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom_sep)

	# Stars + level at the bottom
	var star_row = HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 6)
	star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(star_row)

	_detail_stars_label = Label.new()
	_detail_stars_label.add_theme_font_override("font", PIXEL_FONT)
	_detail_stars_label.add_theme_font_size_override("font_size", 12)
	_detail_stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	_detail_stars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_row.add_child(_detail_stars_label)

	_detail_level_label = Label.new()
	_detail_level_label.add_theme_font_override("font", PIXEL_FONT)
	_detail_level_label.add_theme_font_size_override("font_size", 10)
	_detail_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_row.add_child(_detail_level_label)


func _on_level_up(_new_level: int) -> void:
	print("LevelUpScreen: _on_level_up called!")
	_current_offerings = SkillOfferingService.generate_offerings(panel_count)

	if _current_offerings.is_empty():
		print("LevelUpScreen: No offerings available (all skills maxed)")
		return

	# Defer level-up screen until execution camera finishes (stomp slow-mo)
	if ExecutionCamera.is_playing():
		print("LevelUpScreen: Waiting for execution camera to finish")
		await ExecutionCamera.execution_finished

	show_screen(_current_offerings.size())


func show_screen(count: int = 3) -> void:
	print("LevelUpScreen: Showing screen with %d panels" % count)
	_selected_index = -1
	_detail_panel.visible = false
	_clear_panels()
	_spawn_panels(count)
	_background.visible = true
	get_tree().paused = true


func _spawn_panels(count: int) -> void:
	for i in range(count):
		var panel = skill_panel_scene.instantiate() as SkillPanel
		panel.clicked.connect(_on_panel_clicked.bind(i))
		_panel_container.add_child(panel)

		if i < _current_offerings.size():
			var offering: Dictionary = _current_offerings[i]
			panel.set_skill_offering(offering.skill_data, offering.target_level)


func _clear_panels() -> void:
	for child in _panel_container.get_children():
		_panel_container.remove_child(child)
		child.queue_free()


func _on_panel_clicked(panel_index: int) -> void:
	if panel_index == _selected_index:
		_acquire_skill(panel_index)
	else:
		_select_panel(panel_index)


func _select_panel(index: int) -> void:
	# Deselect previous
	if _selected_index >= 0:
		var prev_panel = _panel_container.get_child(_selected_index) as SkillPanel
		if prev_panel:
			prev_panel.set_selected(false)

	_selected_index = index

	var panel = _panel_container.get_child(index) as SkillPanel
	if panel:
		panel.set_selected(true)

	if index < _current_offerings.size():
		var offering: Dictionary = _current_offerings[index]
		_populate_detail(offering.skill_data, offering.target_level)
		_detail_panel.visible = true


func _populate_detail(skill_data: SkillData, target_level: int) -> void:
	_detail_name_label.text = skill_data.skill_name

	# Stars showing post-acquisition state (max 3)
	var max_stars = mini(skill_data.max_level, 3)
	var filled: int
	if skill_data.max_level <= 3:
		filled = mini(target_level, max_stars)
	else:
		filled = roundi(float(target_level) / float(skill_data.max_level) * 3.0)
	filled = clampi(filled, 0, max_stars)
	var empty = max_stars - filled
	_detail_stars_label.text = "★".repeat(filled) + "☆".repeat(empty)

	# Level indicator
	if target_level == 1:
		_detail_level_label.text = "NEW"
		_detail_level_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	else:
		_detail_level_label.text = "Lv %d → %d" % [target_level - 1, target_level]
		_detail_level_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1.0))

	# Description
	var level_data = skill_data.get_level_data(target_level)
	if level_data and level_data.description != "":
		_detail_desc_label.text = level_data.description
		_detail_desc_label.visible = true
	else:
		_detail_desc_label.visible = false

	# Modifier summary
	var summary = skill_data.get_level_modifier_summary(target_level)
	if summary != "No modifiers":
		_detail_mod_label.text = summary
		_detail_mod_label.visible = true
	else:
		_detail_mod_label.visible = false


func _acquire_skill(panel_index: int) -> void:
	if panel_index < _current_offerings.size():
		var offering: Dictionary = _current_offerings[panel_index]
		var skill_data: SkillData = offering.skill_data
		SkillManager.acquire_skill(skill_data.skill_id)
		print("LevelUpScreen: Player selected '%s' (level %d)" % [skill_data.skill_name, offering.target_level])

	panel_selected.emit(panel_index)
	hide_screen()


func hide_screen() -> void:
	_background.visible = false
	_current_offerings.clear()
	_selected_index = -1
	_detail_panel.visible = false
	get_tree().paused = false
