extends CanvasLayer
class_name LevelUpScreen

var PIXEL_FONT = load("res://assets/game/ui/fonts/PixelOperator8.ttf")

signal panel_selected(panel_index: int)

@export var skill_panel_scene: PackedScene
@export var panel_count: int = 3
@export var panel_spacing: int = 20

var _background: ColorRect
var _title_label: Label
var _panel_container: HBoxContainer
var _current_offerings: Array[Dictionary] = []


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
	# Dark semi-transparent background
	_background = ColorRect.new()
	_background.color = Color(0.0, 0.0, 0.0, 0.7)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	# Center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.add_child(center)

	# Main vertical layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)

	# Title label
	_title_label = Label.new()
	_title_label.text = "LEVEL UP!"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_override("font", PIXEL_FONT)
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	vbox.add_child(_title_label)

	# Panel container
	_panel_container = HBoxContainer.new()
	_panel_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel_container.add_theme_constant_override("separation", panel_spacing)
	vbox.add_child(_panel_container)


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
	_clear_panels()
	_spawn_panels(count)
	_background.visible = true
	get_tree().paused = true


func _spawn_panels(count: int) -> void:
	for i in range(count):
		var panel = skill_panel_scene.instantiate() as SkillPanel
		panel.clicked.connect(_on_panel_clicked.bind(i))
		_panel_container.add_child(panel)

		# Populate panel with skill offering data
		if i < _current_offerings.size():
			var offering: Dictionary = _current_offerings[i]
			panel.set_skill_offering(offering.skill_data, offering.target_level)


func _clear_panels() -> void:
	for child in _panel_container.get_children():
		child.queue_free()


func _on_panel_clicked(panel_index: int) -> void:
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
	get_tree().paused = false
