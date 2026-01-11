# Text Bubble System - Usage Guide

## Quick Start

### 1. Add Component to Enemy

Add `TextBubbleComponent` as a child node to your enemy scene (e.g., `skeleton_soldier.tscn`):

```gdscript
# In the scene tree:
SkeletonSoldier (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── HealthComponent
├── HurtboxComponent
└── TextBubbleComponent  # Add this
    └── FadeAnimationComponent  # Optional, for smooth animations
```

### 2. Configure the Component

In the Inspector, set these properties:

- **Dialogue Data**: Assign a dialogue resource (e.g., `res://resources/dialogue/skeleton_spawn_dialogue.tres`)
- **Trigger Probability**: `0.2` (20% chance to show bubble)
- **Trigger On Spawn**: `true`
- **Display Duration**: `3.0` seconds
- **Vertical Offset**: `-40.0` (pixels above entity)

### 3. Customize Appearance

**Bubble Style:**
- **Bubble Color**: `Color(0.1, 0.1, 0.1, 0.9)` - Dark semi-transparent
- **Border Color**: `Color.WHITE`
- **Border Width**: `2`
- **Corner Radius**: `8`
- **Padding**: `Vector2(12, 8)`

**Text Style:**
- **Text Color**: `Color.WHITE`
- **Font Size**: `14`

## Creating Dialogue Resources

### Basic Dialogue

Create a new `.tres` file in `resources/dialogue/`:

```gdscript
[gd_resource type="Resource" script_class="DialogueData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/game/systems/dialogue_data.gd" id="1_dialogue"]

[resource]
script = ExtResource("1_dialogue")
dialogue_lines = Array[String](["Hello!", "Watch out!", "Here I come!"])
state_key = "basic_greeting"
metadata = {}
priority = 0
```

### Nemesis System Dialogue

For future nemesis system integration:

```gdscript
dialogue_lines = Array[String](["We meet again...", "Remember me?"])
state_key = "skeleton_nemesis"  # Track this conversation branch
metadata = {"requires_previous_encounter": true}
priority = 10  # Higher priority than normal dialogue
```

## Trigger Types

### Automatic Triggers

- **On Spawn**: Set `trigger_on_spawn = true`
- **On Hurt**: Set `trigger_on_hurt = true`
- **On Attack**: Set `trigger_on_attack = true`, then call `trigger_attack()` in attack code

### Manual Triggers

```gdscript
# Trigger with dialogue data
text_bubble_component.trigger_manual()

# Trigger with custom text
text_bubble_component.trigger_manual("Custom message!")
```

## Advanced Features

### Probability Control

Adjust `trigger_probability` to control screen clutter:
- `0.1` = 10% chance (sparse)
- `0.2` = 20% chance (default, balanced)
- `0.5` = 50% chance (frequent)
- `1.0` = 100% chance (always shows)

### Animation Integration

For smooth fade effects, add a `FadeAnimationComponent` as a child and assign it:

```gdscript
@export var fade_animation_component: FadeAnimationComponent
```

Configure fade timings in the `FadeAnimationComponent`:
- **Fade In Duration**: `0.15s`
- **Peak Duration**: `0.15s`
- **Fade Out Duration**: `0.3s`

### Future Sprite Replacement

To replace with a sprite later:

1. Replace `PanelContainer` creation in `_show_bubble()` with `NinePatchRect` or `Sprite2D`
2. Keep all other logic unchanged
3. The component will work exactly the same

## Example: Skeleton Enemy Setup

```gdscript
# skeleton_soldier.tscn configuration
[node name="TextBubbleComponent" type="Node2D" parent="."]
script = ExtResource("text_bubble_component")
dialogue_data = ExtResource("skeleton_spawn_dialogue")
trigger_probability = 0.2
trigger_on_spawn = true
display_duration = 3.0
vertical_offset = -40.0
bubble_color = Color(0.1, 0.1, 0.1, 0.9)
border_color = Color.WHITE
text_color = Color.WHITE
font_size = 14
```

## Signals

Listen to these signals for custom behavior:

```gdscript
text_bubble_component.bubble_shown.connect(_on_bubble_shown)
text_bubble_component.bubble_hidden.connect(_on_bubble_hidden)

func _on_bubble_shown(text: String) -> void:
    print("Enemy said: ", text)

func _on_bubble_hidden() -> void:
    print("Bubble disappeared")
```
