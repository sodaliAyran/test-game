extends CharacterBody2D

## Example player script showing health bar integration
## This demonstrates how to add and position a health bar above the player

@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: HealthBarComponent = $HealthBar

func _ready() -> void:
	# Connect health bar to health component
	if health_component and health_bar:
		health_bar.connect_to_health_component(health_component)
		print("Health bar connected to player")

func _process(_delta: float) -> void:
	# Keep health bar positioned above player
	if health_bar:
		# Center the health bar horizontally above the player
		var bar_offset = Vector2(-health_bar.bar_width / 2, health_bar.offset_above_entity.y)
		health_bar.position = bar_offset

# Example: Take damage for testing
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Space key
		if health_component:
			health_component.take_damage(10)
			print("Player took 10 damage! Current health: ", health_component.current_health)
