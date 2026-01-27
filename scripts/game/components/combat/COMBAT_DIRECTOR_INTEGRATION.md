# Combat Director Integration Guide

## Overview

The CombatDirector system implements the global AP token bucket pattern from the Game Design Document. Entities (primarily enemies) must request AP tokens before performing special attacks, preventing unreactable spam and creating more strategic combat pacing.

## Architecture

### Components

1. **CombatDirector** (Autoload Singleton)
   - Manages global AP pool
   - Processes AP requests in priority order
   - Enforces concurrent attack limits
   - Refills AP over time

2. **CombatDirectorRequestComponent** (Reusable Component)
   - Handles AP request/response lifecycle
   - Attach to any entity that needs AP-gated abilities
   - Emits signals for approved/denied actions
   - Automatically cleans up on entity removal

3. **Skill Components** (DashComponent, etc.)
   - Optional `director_request` export variable
   - Provides both AP-gated and immediate execution methods
   - Notifies director when actions complete

## Usage Pattern

### For Enemies Requiring AP

**1. Add Components to Scene:**
```gdscript
[node name="Enemy" type="CharacterBody2D"]

# Add CombatDirectorRequestComponent
[node name="CombatDirectorRequestComponent" type="Node" parent="."]
script = preload("res://scripts/game/components/combat/combat_director_request_component.gd")
enabled = true
default_priority = 60

# Wire skill to director component
[node name="DashComponent" type="Node" parent="." node_paths=PackedStringArray("director_request")]
script = ExtResource("dash_component")
director_request = NodePath("../CombatDirectorRequestComponent")
```

**2. Configure AP Cost (Optional):**
```gdscript
# In DashComponent exports
ap_cost = 2.5  # Customize AP cost for this specific dash
ap_priority = 60  # Higher priority = processed first
action_label = "dash_attack"  # For debugging/logging
```

**3. Request Actions in States/AI:**
```gdscript
# In enemy AI/state script
if dash_component.can_dash():
    var direction = (target.global_position - owner.global_position).normalized()
    # This will request AP from CombatDirector
    if dash_component.request_dash(direction):
        # Request queued - dash will execute when approved
        pass
```

**4. React to Dash Execution:**
```gdscript
# Connect to dash_started signal to transition states
func _connect_dash():
    dash.dash_started.connect(_on_dash_started)

func _on_dash_started(_direction: Vector2):
    transition.emit("Dash")  # Transition to dash state
```

**5. Cleanup:**
```gdscript
func _disconnect_dash():
    if dash:
        if dash.dash_started.is_connected(_on_dash_started):
            dash.dash_started.disconnect(_on_dash_started)
        # Cancel pending requests on cleanup
        dash.cancel_pending_request()
```

### For Player Abilities (No AP)

Simply don't add `CombatDirectorRequestComponent` and use direct execution:

```gdscript
# In player input handler
if Input.is_action_just_pressed("dash") and dash_component.can_dash():
    # Execute immediately (no AP check)
    dash_component.dash(input_direction)
```

## Action Costs

**Skills define their own AP costs** via the `ap_cost` export variable. This allows each skill component to be independently configured.

**Recommended Cost Guidelines:**

| Ability Type     | Cost | Notes                          |
|-----------------|------|--------------------------------|
| basic_melee     | 1.0  | Basic attacks                  |
| heavy_melee     | 2.0  | Power attacks                  |
| dash_attack     | 2.5  | Gap closers (Rogue)            |
| special_attack  | 3.0  | Special abilities (3.0+ = "special") |
| ranged_attack   | 1.5  | Ranged attacks (Mage)          |
| ultimate        | 5.0  | Ultimate abilities             |
| recovery        | 4.0  | Reviving downed heroes         |

**Note:** Actions costing 3.0 AP or more are considered "special" and are subject to the `max_concurrent_specials` limit (default: 1).

## Request Priority

Higher priority = processed first when AP available:
- **60**: Dash attacks (aggressive gap closers)
- **50**: Default priority
- **40**: Basic melee
- **30**: Lower priority actions

## Creating New AP-Gated Skills

1. Create your skill component with optional `director_request` export and AP configuration:
   ```gdscript
   @export var director_request: CombatDirectorRequestComponent

   @export_group("AP Integration")
   @export var ap_cost: float = 3.0  # Define cost for this skill
   @export var ap_priority: int = 70  # Higher = processed first
   @export var action_label: String = "special_attack"  # For logging
   ```

2. Implement `request_action()` method that creates APRequest:
   ```gdscript
   func request_special_attack() -> bool:
       if not can_attack():
           return false

       if not director_request:
           return execute_immediately()

       # Create AP request with this skill's cost
       var request = APRequest.create(
           character_body,  # The entity
           action_label,    # Label for logging
           ap_cost,         # Cost defined by this skill
           Callable(self, "_execute_approved_attack"),
           ap_priority
       )

       return director_request.request_action(request)
   ```

3. Notify director when complete:
   ```gdscript
   func _on_attack_complete():
       if director_request:
           director_request.complete_action()
   ```

## Benefits

- **Reusable**: Same components work for player and enemies
- **Flexible**: Skill works with or without AP requirement
- **Decoupled**: Skill logic separate from director integration
- **Scalable**: Easy to add new AP-gated abilities
- **Clean**: Signal-based, follows component architecture
