class_name DamageNumberComponent
extends Node2D

@export var hurtbox_component: HurtboxComponent
@export var fade_animation_component: FadeAnimationComponent
@export var float_speed: float = 30.0  # Pixels per second upward
@export var position_randomness: float = 10.0  # Random offset range
@export var font_size: int = 16
@export var damage_color: Color = Color.WHITE

var active_labels: Array[Node2D] = []

func _ready() -> void:
	if hurtbox_component:
		hurtbox_component.hurt.connect(_on_hurt)
	else:
		push_warning("DamageNumberComponent: hurtbox_component not set")
	
	if fade_animation_component:
		fade_animation_component.animation_complete.connect(_on_animation_complete)

func _on_hurt(amount: int) -> void:
	_spawn_damage_number(amount)

func _spawn_damage_number(damage: int) -> void:
	# Create a container node for the label
	var container = Node2D.new()
	
	# Add random offset to position
	var random_offset = Vector2(
		randf_range(-position_randomness, position_randomness),
		randf_range(-position_randomness * 0.5, position_randomness * 0.5)
	)
	container.global_position = global_position + random_offset
	
	# Create the label
	var label = Label.new()
	label.text = str(damage)
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = damage_color
	
	# Center the label on its position
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Add outline for better visibility
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	container.add_child(label)
	
	# Add to scene tree
	get_tree().current_scene.add_child(container)
	
	# Track active labels
	active_labels.append(container)
	
	# Play animation if available
	if fade_animation_component:
		fade_animation_component.play(label)
	else:
		# No animation, just clean up after a delay
		await get_tree().create_timer(1.0).timeout
		_on_animation_complete(label)

func _process(delta: float) -> void:
	# Move all active labels upward
	for container in active_labels:
		if is_instance_valid(container):
			container.global_position.y -= float_speed * delta

func _on_animation_complete(target: Node2D) -> void:
	# Find and remove the container that holds this label
	for container in active_labels:
		if is_instance_valid(container) and container.get_child_count() > 0:
			if container.get_child(0) == target:
				active_labels.erase(container)
				container.queue_free()
				break
