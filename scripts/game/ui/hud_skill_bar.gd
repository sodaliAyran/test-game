class_name HUDSkillBar
extends Control

## HUD skill cooldown bar - shows active skill cooldowns as small squares
## above the health bar at the bottom of the screen.
## Each slot shows a skill icon that grays out during cooldown and fills up as it recharges.

var PIXEL_FONT = load("res://assets/game/ui/fonts/PixelOperator8.ttf")

@export_group("Appearance")
@export var slot_size: float = 20.0
@export var slot_gap: float = 2.0
@export var border_width: float = 2.0
@export var max_slots: int = 6

@export_group("Colors")
@export var background_color: Color = Color(0.08, 0.06, 0.06, 0.95)
@export var border_color: Color = Color(0.02, 0.02, 0.02, 1.0)
@export var cooldown_overlay_color: Color = Color(0.02, 0.02, 0.05, 0.7)
@export var ready_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var cooldown_tint: Color = Color(0.3, 0.3, 0.3, 0.9)

# Internal state
# Each entry: { skill_id: String, cooldown_ref: SkillCooldownComponent, panel: Panel, icon: TextureRect, overlay: ColorRect, label: Label }
var _slots: Array[Dictionary] = []


func _ready() -> void:
	# Connect to registry for new skills
	SkillCooldownRegistry.skill_registered.connect(_on_skill_registered)
	SkillCooldownRegistry.skill_unregistered.connect(_on_skill_unregistered)

	# Pick up any already-registered cooldowns (skills loaded before HUD)
	await get_tree().process_frame
	for skill_id in SkillCooldownRegistry.get_all():
		var cooldown = SkillCooldownRegistry.get_cooldown(skill_id)
		if cooldown and not _has_slot(skill_id):
			_add_slot(skill_id, cooldown)


func _process(_delta: float) -> void:
	for slot in _slots:
		var cooldown: SkillCooldownComponent = slot.cooldown_ref
		if not is_instance_valid(cooldown):
			continue

		var progress = cooldown.get_cooldown_progress()
		var inner_h = slot_size - border_width * 2.0
		var overlay: ColorRect = slot.overlay

		# Overlay covers from top, shrinks as cooldown completes
		overlay.size.y = inner_h * (1.0 - progress)
		overlay.visible = progress < 1.0

		# Tint icon
		var icon: TextureRect = slot.icon
		var label: Label = slot.label
		if progress >= 1.0:
			icon.modulate = ready_tint
			if label:
				label.modulate = ready_tint
		else:
			icon.modulate = cooldown_tint
			if label:
				label.modulate = cooldown_tint


func _on_skill_registered(skill_id: String, cooldown: SkillCooldownComponent) -> void:
	if _slots.size() >= max_slots:
		return
	if _has_slot(skill_id):
		return
	_add_slot(skill_id, cooldown)


func _on_skill_unregistered(skill_id: String) -> void:
	_remove_slot(skill_id)


func _has_slot(skill_id: String) -> bool:
	for slot in _slots:
		if slot.skill_id == skill_id:
			return true
	return false


func _add_slot(skill_id: String, cooldown: SkillCooldownComponent) -> void:
	var inner_size = slot_size - border_width * 2.0

	# Panel with border
	var panel = Panel.new()
	panel.size = Vector2(slot_size, slot_size)
	var style = StyleBoxFlat.new()
	style.bg_color = background_color
	var bw = int(border_width)
	style.border_width_left = bw
	style.border_width_right = bw
	style.border_width_top = bw
	style.border_width_bottom = bw
	style.border_color = border_color
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# Icon (TextureRect)
	var icon = TextureRect.new()
	icon.position = Vector2(border_width, border_width)
	icon.size = Vector2(inner_size, inner_size)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

	# Try loading icon from SkillData
	var skill_data: SkillData = SkillManager.find_skill_in_trees(skill_id)
	if skill_data and skill_data.icon_path != "" and ResourceLoader.exists(skill_data.icon_path):
		icon.texture = load(skill_data.icon_path)

	panel.add_child(icon)

	# Fallback label if no icon texture
	var label: Label = null
	if not icon.texture:
		label = Label.new()
		var display_name = skill_id
		if skill_data:
			display_name = skill_data.skill_name
		label.text = display_name.left(2).to_upper()
		label.position = Vector2(border_width, border_width)
		label.size = Vector2(inner_size, inner_size)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", PIXEL_FONT)
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 1.0))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		panel.add_child(label)

	# Cooldown overlay (fills from top, shrinks as cooldown completes)
	var overlay = ColorRect.new()
	overlay.color = cooldown_overlay_color
	overlay.position = Vector2(border_width, border_width)
	overlay.size = Vector2(inner_size, 0)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(overlay)

	# Flash on cooldown ready
	cooldown.cooldown_ready.connect(_on_cooldown_ready.bind(icon, label))

	var slot = {
		"skill_id": skill_id,
		"cooldown_ref": cooldown,
		"panel": panel,
		"icon": icon,
		"overlay": overlay,
		"label": label,
	}
	_slots.append(slot)
	_recenter()


func _remove_slot(skill_id: String) -> void:
	for i in range(_slots.size()):
		if _slots[i].skill_id == skill_id:
			var panel: Panel = _slots[i].panel
			panel.queue_free()
			_slots.remove_at(i)
			_recenter()
			return


func _recenter() -> void:
	var count = _slots.size()
	if count == 0:
		return

	var total_width = count * slot_size + (count - 1) * slot_gap
	var start_x = -total_width / 2.0

	for i in range(count):
		var panel: Panel = _slots[i].panel
		panel.position = Vector2(start_x + i * (slot_size + slot_gap), -slot_size)


func _on_cooldown_ready(icon: TextureRect, label: Label) -> void:
	# Brief brightness flash when skill becomes ready
	if not is_instance_valid(icon):
		return
	var tween = create_tween()
	tween.tween_property(icon, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.1)
	tween.tween_property(icon, "modulate", ready_tint, 0.15)
	if label and is_instance_valid(label):
		var tween2 = create_tween()
		tween2.tween_property(label, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.1)
		tween2.tween_property(label, "modulate", ready_tint, 0.15)
