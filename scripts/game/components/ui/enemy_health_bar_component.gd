class_name EnemyHealthBarComponent
extends Node2D

## Small health bar displayed above enemy heads.
## Uses _draw() for lightweight rendering. Auto-connects to parent's HealthComponent.

@export var bar_width: float = 20.0
@export var bar_height: float = 2.0
@export var bar_offset: Vector2 = Vector2(0, -20)
@export var bar_color: Color = Color(0.65, 0.22, 0.22, 0.9)
@export var background_color: Color = Color(0.15, 0.15, 0.15, 0.7)
@export var transition_speed: float = 10.0
@export var level_color: Color = Color(0.9, 0.8, 0.3, 0.9)

var _target_ratio: float = 1.0
var _current_ratio: float = 1.0
var _current_level: int = 1
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	var parent = get_parent()
	if not parent:
		return

	for child in parent.get_children():
		if child is HealthComponent:
			child.health_changed.connect(_on_health_changed)
			_target_ratio = child.current_health / child.max_health
			_current_ratio = _target_ratio
		elif child is KnockbackableComponent:
			child.became_knockbackable.connect(_on_became_knockbackable)
			child.recovered.connect(_on_recovered)
			child.leveled_up.connect(_on_leveled_up)


func _process(delta: float) -> void:
	if not is_equal_approx(_current_ratio, _target_ratio):
		_current_ratio = lerp(_current_ratio, _target_ratio, transition_speed * delta)
		queue_redraw()


func _draw() -> void:
	var pos = bar_offset - Vector2(bar_width / 2.0, 0)

	# Background
	draw_rect(Rect2(pos, Vector2(bar_width, bar_height)), background_color)

	# Health fill
	var fill_width = bar_width * _current_ratio
	if fill_width > 0:
		draw_rect(Rect2(pos, Vector2(fill_width, bar_height)), bar_color)

	# Level indicator
	if _font:
		var level_text = str(_current_level)
		var font_size = 5
		var text_pos = pos + Vector2(-6, bar_height)
		draw_string(_font, text_pos, level_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size, level_color)


func _on_health_changed(current: float, max_health: float) -> void:
	_target_ratio = clamp(current / max_health, 0.0, 1.0)
	queue_redraw()


func _on_became_knockbackable() -> void:
	visible = false


func _on_recovered() -> void:
	_target_ratio = 1.0
	_current_ratio = 1.0
	visible = true
	queue_redraw()


func _on_leveled_up(new_level: int) -> void:
	_current_level = new_level
	queue_redraw()
