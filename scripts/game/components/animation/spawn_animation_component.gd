extends Node
class_name SpawnAnimationComponent

signal spawn_complete

@export var sprite: Sprite2D
@export var spawn_duration: float = 1.0
@export var rise_distance: float = 16.0

var _is_spawning: bool = false
var _spawn_timer: float = 0.0
var _initial_position: Vector2
var _shader_material: ShaderMaterial

func _ready() -> void:
	if sprite:
		_setup_shader()

func _setup_shader() -> void:
	# Create a shader material for the reveal effect
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float reveal_progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Reveal from top to bottom
	// UV.y goes from 0 (top) to 1 (bottom)
	if (UV.y > reveal_progress) {
		tex_color.a = 0.0;
	}
	
	COLOR = tex_color;
}
"""
	
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	_shader_material.set_shader_parameter("reveal_progress", 0.0)
	sprite.material = _shader_material

func play_spawn() -> void:
	if not sprite:
		push_error("SpawnAnimationComponent: sprite not set")
		spawn_complete.emit()
		return
	
	_is_spawning = true
	_spawn_timer = 0.0
	_initial_position = sprite.position
	
	# Start with sprite fully hidden
	if _shader_material:
		_shader_material.set_shader_parameter("reveal_progress", 0.0)

func _process(delta: float) -> void:
	if not _is_spawning:
		return
	
	_spawn_timer += delta
	var progress = clamp(_spawn_timer / spawn_duration, 0.0, 1.0)
	
	# Use ease-out curve for smoother motion
	var eased_progress = ease(progress, -2.0)
	
	# Update shader reveal (top to bottom)
	if _shader_material:
		_shader_material.set_shader_parameter("reveal_progress", eased_progress)
	
	# Move sprite upward as it rises from the ground
	# Start from below and move to initial position
	var offset_y = (1.0 - eased_progress) * rise_distance
	sprite.position = _initial_position + Vector2(0, offset_y)
	
	# Check if spawn is complete
	if progress >= 1.0:
		_finish_spawn()

func _finish_spawn() -> void:
	_is_spawning = false
	sprite.position = _initial_position
	
	# Remove shader material to restore normal rendering
	if sprite:
		sprite.material = null
	
	spawn_complete.emit()

func is_spawning() -> bool:
	return _is_spawning
