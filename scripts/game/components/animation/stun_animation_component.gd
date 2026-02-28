extends Node
class_name StunAnimationComponent

## Doom glory kill-style glow during stunned state.
## Applies a shader that pulses the sprite between two bright colors.

@export var sprite: Sprite2D
@export var glow_color_a: Color = Color(1.0, 0.55, 0.1, 1.0)  # Warm orange
@export var glow_color_b: Color = Color(1.0, 1.0, 0.7, 1.0)  # Pale yellow-white
@export var pulse_speed: float = 3.0
@export var glow_strength: float = 0.5
@export var brightness_boost: float = 1.4
@export var fade_in_time: float = 0.2
@export var wobble_intensity: float = 2.0  # Degrees
@export var wobble_speed: float = 15.0

var is_playing: bool = false

var _original_material: Material
var _shader_material: ShaderMaterial
var _tween: Tween
var _original_rotation: float = 0.0
var _duration: float = 0.0
var _elapsed: float = 0.0

const GLORY_SHADER = preload("res://shaders/glory_kill_glow.gdshader")


func play(duration: float) -> void:
	if is_playing:
		return

	is_playing = true
	_duration = duration
	_elapsed = 0.0

	if sprite:
		_original_rotation = sprite.rotation
		_original_material = sprite.material
		_apply_shader()


func stop() -> void:
	is_playing = false
	_elapsed = 0.0

	if _tween:
		_tween.kill()
		_tween = null

	if sprite:
		sprite.material = _original_material
		sprite.rotation = _original_rotation

	_shader_material = null


func is_finished() -> bool:
	return not is_playing or _elapsed >= _duration


func _process(delta: float) -> void:
	if not is_playing:
		return

	_elapsed += delta

	# Wobble effect
	if sprite and wobble_intensity > 0:
		sprite.rotation = _original_rotation + sin(_elapsed * wobble_speed) * deg_to_rad(wobble_intensity)

	if _elapsed >= _duration:
		stop()


func _apply_shader() -> void:
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = GLORY_SHADER
	_shader_material.set_shader_parameter("glow_color_a", glow_color_a)
	_shader_material.set_shader_parameter("glow_color_b", glow_color_b)
	_shader_material.set_shader_parameter("pulse_speed", pulse_speed)
	_shader_material.set_shader_parameter("glow_strength", glow_strength)
	_shader_material.set_shader_parameter("brightness_boost", brightness_boost)
	_shader_material.set_shader_parameter("mix_amount", 0.0)

	sprite.material = _shader_material

	# Fade in the glow effect
	_tween = create_tween()
	_tween.tween_method(_set_mix_amount, 0.0, 1.0, fade_in_time)


func _set_mix_amount(value: float) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("mix_amount", value)
