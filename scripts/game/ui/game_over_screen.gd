extends CanvasLayer

var PIXEL_FONT = load("res://assets/game/ui/fonts/PixelOperator8.ttf")

const GAME_SCENE := "res://scenes/test/test_aura.tscn"
const DIED_COLOR := Color(0.545, 0.0, 0.0, 1.0) # Dark red #8B0000
const BUTTON_NORMAL_COLOR := Color(0.6, 0.6, 0.6, 1.0)
const BUTTON_HOVER_COLOR := Color(1.0, 1.0, 1.0, 1.0)

var _background: ColorRect
var _died_label: Label
var _restart_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_setup_ui()
	_background.visible = false
	_connect_to_player_death()


func _connect_to_player_death() -> void:
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		push_warning("GameOverScreen: No player found in 'Player' group")
		return

	var player: Node = players[0]
	# Find the Death state inside the StateMachine
	var state_machine := player.get_node_or_null("StateMachine")
	if not state_machine:
		push_warning("GameOverScreen: No StateMachine found on player")
		return

	var death_state := state_machine.get_node_or_null("Death")
	if not death_state:
		push_warning("GameOverScreen: No Death state found in StateMachine")
		return

	if death_state.has_signal("player_died"):
		death_state.player_died.connect(_on_player_died)
	else:
		push_warning("GameOverScreen: Death state has no player_died signal")


func _setup_ui() -> void:
	# Dark background
	_background = ColorRect.new()
	_background.color = Color(0.0, 0.0, 0.0, 0.85)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.add_child(center)

	# Vertical layout
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# "YOU DIED" text
	_died_label = Label.new()
	_died_label.text = "YOU DIED"
	_died_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_died_label.add_theme_font_override("font", PIXEL_FONT)
	_died_label.add_theme_font_size_override("font_size", 48)
	_died_label.add_theme_color_override("font_color", DIED_COLOR)
	_died_label.modulate.a = 0.0
	vbox.add_child(_died_label)

	# Restart button
	_restart_button = _create_button("Restart")
	_restart_button.pressed.connect(_on_restart_pressed)
	_restart_button.modulate.a = 0.0
	vbox.add_child(_restart_button)


func _create_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", PIXEL_FONT)
	button.add_theme_font_size_override("font_size", 20)
	button.custom_minimum_size = Vector2(120, 32)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	normal_style.border_color = Color(0.4, 0.4, 0.4, 0.6)
	normal_style.set_border_width_all(1)
	normal_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	hover_style.border_color = DIED_COLOR
	hover_style.set_border_width_all(1)
	hover_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.05, 0.05, 0.05, 0.9)
	pressed_style.border_color = DIED_COLOR
	pressed_style.set_border_width_all(1)
	pressed_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("pressed", pressed_style)

	button.add_theme_color_override("font_color", BUTTON_NORMAL_COLOR)
	button.add_theme_color_override("font_hover_color", BUTTON_HOVER_COLOR)
	button.add_theme_color_override("font_pressed_color", DIED_COLOR)

	return button


func _on_player_died() -> void:
	show_screen()


func show_screen() -> void:
	_background.visible = true
	_background.modulate.a = 0.0
	get_tree().paused = true

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Fade in background
	tween.tween_property(_background, "modulate:a", 1.0, 1.0)
	# Fade in "YOU DIED" text
	tween.tween_property(_died_label, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_IN)
	# Pause, then show restart button
	tween.tween_interval(1.0)
	tween.tween_property(_restart_button, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_IN)


func _on_restart_pressed() -> void:
	GameStats.reset_stats()
	SkillManager.reset_skills()
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)
