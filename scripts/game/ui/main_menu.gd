extends Control

var PIXEL_FONT = load("res://assets/game/ui/fonts/PixelOperator8.ttf")

const GAME_SCENE := "res://scenes/test/test_aura.tscn"
const TITLE_COLOR := Color(0.784, 0.659, 0.306, 1.0) # Gold #C8A84E
const BUTTON_NORMAL_COLOR := Color(0.6, 0.6, 0.6, 1.0)
const BUTTON_HOVER_COLOR := Color(1.0, 1.0, 1.0, 1.0)

var _title_label: Label
var _play_button: Button
var _quit_button: Button


func _ready() -> void:
	_setup_ui()
	_animate_intro()


func _setup_ui() -> void:
	# Black background
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Vertical layout
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "TEST GAME"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_override("font", PIXEL_FONT)
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.add_theme_color_override("font_color", TITLE_COLOR)
	_title_label.modulate.a = 0.0
	vbox.add_child(_title_label)

	# Button container
	var button_box := VBoxContainer.new()
	button_box.add_theme_constant_override("separation", 16)
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.modulate.a = 0.0
	vbox.add_child(button_box)

	# Play button
	_play_button = _create_button("Play")
	_play_button.pressed.connect(_on_play_pressed)
	button_box.add_child(_play_button)

	# Quit button
	_quit_button = _create_button("Quit")
	_quit_button.pressed.connect(_on_quit_pressed)
	button_box.add_child(_quit_button)


func _create_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", PIXEL_FONT)
	button.add_theme_font_size_override("font_size", 20)
	button.custom_minimum_size = Vector2(120, 32)

	# Flat dark style
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	normal_style.border_color = Color(0.4, 0.4, 0.4, 0.6)
	normal_style.set_border_width_all(1)
	normal_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	hover_style.border_color = TITLE_COLOR
	hover_style.set_border_width_all(1)
	hover_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.05, 0.05, 0.05, 0.9)
	pressed_style.border_color = TITLE_COLOR
	pressed_style.set_border_width_all(1)
	pressed_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("pressed", pressed_style)

	button.add_theme_color_override("font_color", BUTTON_NORMAL_COLOR)
	button.add_theme_color_override("font_hover_color", BUTTON_HOVER_COLOR)
	button.add_theme_color_override("font_pressed_color", TITLE_COLOR)

	return button


func _animate_intro() -> void:
	var tween := create_tween()
	# Fade in title
	tween.tween_property(_title_label, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_IN)
	# Then fade in buttons
	var button_box := _title_label.get_parent().get_child(1)
	tween.tween_property(button_box, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
