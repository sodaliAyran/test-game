# Health Bar Component Usage Guide

## Overview
The `HealthBarComponent` is a reusable UI component that displays an entity's health visually. It features smooth animations, damage flash effects, and automatic updates when connected to a `HealthComponent`.

## Features
- ✨ Smooth health depletion animation
- 💥 Damage flash effect when taking damage
- 🎨 Customizable colors and dimensions
- 🔴 Automatic color change at low health
- 📦 Fully reusable across any entity

## Quick Start

### Method 1: Add to Player Scene (Recommended)

1. Open your player scene in the Godot editor
2. Add a `Control` node as a child of your player
3. Attach the `health_bar_component.gd` script to it
4. In the script's `_ready()` function or player script, connect it to the HealthComponent:

```gdscript
# In your player script
@onready var health_component = $HealthComponent
@onready var health_bar = $HealthBar

func _ready():
	health_bar.connect_to_health_component(health_component)
```

### Method 2: Programmatic Creation

```gdscript
# Create health bar dynamically
var health_bar = preload("res://scripts/game/components/health_bar_component.gd").new()
add_child(health_bar)

# Connect to health component
var health_component = $HealthComponent
health_bar.connect_to_health_component(health_component)
```

### Method 3: Create a Reusable Scene

1. Create a new scene in Godot
2. Set the root node as `Control`
3. Attach `health_bar_component.gd` to the root
4. Save as `health_bar.tscn`
5. Instance this scene wherever you need a health bar

## Customization

### Export Variables

You can customize the health bar's appearance through export variables:

#### Appearance Group
- `bar_width` (float): Width of the health bar in pixels (default: 100)
- `bar_height` (float): Height of the health bar in pixels (default: 12)
- `background_color` (Color): Color of the background bar (default: dark gray)
- `health_color` (Color): Color when health is above threshold (default: green)
- `low_health_color` (Color): Color when health is below threshold (default: red)
- `low_health_threshold` (float): Health percentage to trigger color change (default: 0.3)
- `border_color` (Color): Color of the border (default: black)
- `border_width` (float): Width of the border in pixels (default: 2)

#### Animation Group
- `smooth_transition` (bool): Enable smooth health depletion (default: true)
- `transition_speed` (float): Speed of the smooth transition (default: 10)
- `damage_flash` (bool): Enable flash effect on damage (default: true)
- `flash_duration` (float): Duration of the flash effect in seconds (default: 0.2)

#### Positioning Group
- `offset_above_entity` (Vector2): Offset position above the entity (default: (0, -40))

### Example Customization

```gdscript
# Make a larger, blue health bar
health_bar.bar_width = 150.0
health_bar.bar_height = 20.0
health_bar.health_color = Color(0.2, 0.5, 1.0)  # Blue
health_bar.low_health_color = Color(1.0, 0.5, 0.0)  # Orange
health_bar.low_health_threshold = 0.25  # Change color at 25% health
```

## Positioning

### World Space (Above Entity)
To position the health bar above an entity in world space:

```gdscript
# In your entity script
@onready var health_bar = $HealthBar

func _process(_delta):
	# Keep health bar above entity
	health_bar.global_position = global_position + health_bar.offset_above_entity
```

### Screen Space (HUD)
To position the health bar in screen space (e.g., top-left corner):

```gdscript
# Add to a CanvasLayer for HUD
var canvas_layer = CanvasLayer.new()
add_child(canvas_layer)

var health_bar = HealthBarComponent.new()
canvas_layer.add_child(health_bar)
health_bar.position = Vector2(20, 20)  # Top-left corner
```

## Advanced Usage

### Manual Health Updates
If you don't want to use the automatic connection:

```gdscript
# Manually update health
health_bar.update_health(current_health, max_health)
```

### Disable Animations
For instant health updates:

```gdscript
health_bar.smooth_transition = false
health_bar.damage_flash = false
```

### Custom Colors Based on Health
The component automatically changes color when health drops below the threshold, but you can customize this further:

```gdscript
# Create a gradient effect
func _process(_delta):
	var health_ratio = health_bar.current_health_ratio
	health_bar.health_color = Color(1.0 - health_ratio, health_ratio, 0.0)
```

## Tips

1. **Performance**: The health bar uses `_process()` for smooth animations. If you have many entities, consider using a pooling system or disabling smooth transitions.

2. **Visibility**: For enemies, you might want to show the health bar only when damaged:
   ```gdscript
   health_bar.visible = false
   
   func _on_health_changed(current, max):
       health_bar.visible = true
       # Hide after 3 seconds
       await get_tree().create_timer(3.0).timeout
       health_bar.visible = false
   ```

3. **Scaling**: The health bar scales with the Control node. To make it larger/smaller, adjust `bar_width` and `bar_height`.

4. **Z-Index**: If the health bar appears behind other elements, adjust the `z_index` property:
   ```gdscript
   health_bar.z_index = 100
   ```

## Example: Complete Player Setup

```gdscript
extends CharacterBody2D

@onready var health_component = $HealthComponent
var health_bar: HealthBarComponent

func _ready():
	# Create health bar
	health_bar = preload("res://scripts/game/components/health_bar_component.gd").new()
	add_child(health_bar)
	
	# Customize appearance
	health_bar.bar_width = 80.0
	health_bar.bar_height = 10.0
	health_bar.health_color = Color(0.3, 0.9, 0.4)
	health_bar.offset_above_entity = Vector2(0, -50)
	
	# Connect to health component
	health_bar.connect_to_health_component(health_component)

func _process(_delta):
	# Keep health bar positioned above player
	health_bar.global_position = global_position + health_bar.offset_above_entity
```
