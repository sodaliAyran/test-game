# Damage → Stun → Knockback System

Core gameplay loop where enemies don't die from direct damage. Instead, they become stunned when their health is depleted, giving the player a window to walk over them for a finishing knockback.

## Flow Overview

```
[Enemy takes damage]
        │
        ▼
  HealthComponent.take_damage()
        │
        ▼
  health reaches 0 → health_depleted signal
        │
        ▼
  KnockbackableComponent._on_health_depleted()
        │
        ▼
  Transition to STUNNED state
        │
        ├──── Player walks over enemy ──────► STOMP detected
        │     (within stomp_detection_radius)     │
        │                                         ▼
        │                                    Freeze frame
        │                                    Knockback force applied
        │                                         │
        │                                         ▼
        │                                    DOWN state
        │                                    (directional knockdown animation)
        │                                         │
        │                                         ▼
        │                                    KnockbackableComponent.recover()
        │                                    Health restored → Chase
        │                                    OR CowardTrait → Flee
        │
        └──── Stun timer expires ───────────► KnockbackableComponent.recover()
              (no player stomp)                Health restored → Chase
```

## Key Files

| File | Role |
|------|------|
| [health_component.gd](scripts/game/components/core/health_component.gd) | Emits `health_depleted` before `died`; skips `died` if `KnockbackableComponent` exists |
| [knockbackable_component.gd](scripts/game/components/combat/knockbackable_component.gd) | Listens for `health_depleted`, transitions to Stunned, handles health recovery |
| [stunned_state.gd](scripts/game/states/enemy/stunned_state.gd) | Incapacitation state with stomp detection and stun timer |
| [down_state.gd](scripts/game/states/enemy/down_state.gd) | Knockdown animation state after stomp, trait-aware exit (Flee vs Chase) |
| [stun_animation_component.gd](scripts/game/components/animation/stun_animation_component.gd) | Glory kill-style pulsing glow shader + wobble during stun |
| [stun_bar_component.gd](scripts/game/components/ui/stun_bar_component.gd) | Shrinking grey bar showing remaining stun time |
| [down_animation_component.gd](scripts/game/components/animation/down_animation_component.gd) | Directional sprite rotation for knockdown |
| [glory_kill_glow.gdshader](shaders/glory_kill_glow.gdshader) | Shader for the stun glow effect |

## Component Details

### HealthComponent (Entry Point)

When `take_damage()` reduces health to 0:
1. Emits `health_depleted` signal
2. Checks for `KnockbackableComponent` on the owner node
3. If present: does **not** emit `died` — the knockback system takes over
4. If absent: emits `died` normally (instant death, no stun phase)

This is what makes enemies "knockbackable" vs "killable" — simply having the `KnockbackableComponent` attached changes the death behavior.

### KnockbackableComponent (Orchestrator)

Signals: `became_knockbackable`, `recovered`

- Connects to `health.health_depleted`
- On depletion: sets `is_knockbackable = true`, transitions state machine to `"Stunned"`
- `recover()`: resets `is_knockbackable`, restores health to `recovery_health_percent` (default 100%) of max

### StunnedState (Incapacitation)

Configurable exports:
- `stun_duration`: Base stun time (default 5.0s), extended by `stun_duration_bonus` passive skill
- `stomp_detection_radius`: How close the player must be to trigger knockback (default 5px)
- `invulnerability_duration`: Grace period before stomp detection activates (default 0.5s)
- `knockback_force`: Force applied on stomp (default 1500.0)
- `freeze_duration`: Freeze frame on stomp impact (default 0.25s)

On enter:
1. Cancels any pending CombatDirector requests
2. Stops movement
3. Sets hurtbox to invincible (no further damage)
4. Disables contact damage (player can walk over safely)
5. Plays stun animation (glow shader + wobble)
6. Shows stun bar UI

Stomp detection:
- After `invulnerability_duration`, creates a temporary `Area2D` with `CircleShape2D`
- Detects `PLAYER_HURTBOX` collision layer overlap
- On overlap: records knockback direction (away from player), applies knockback force, triggers freeze frame

Transitions:
- **Stomped** → passes knockback direction to Down state → `"Down"`
- **Timer expired** → `knockbackable.recover()` → `"Chase"`

### DownState (Knockdown)

On enter:
- Plays directional knockdown animation (sprite rotates based on knockback direction)
- Checks for `down_duration_bonus` passive skill to extend ground time
- Connects to `health.died` for death during down

On exit:
- Calls `knockbackable.recover()` to restore health
- Checks `CowardTrait` via `NemesisComponent` — if `is_fleeing` is true, transitions to `"Flee"` instead of `"Chase"`

### Visual Feedback

**StunAnimationComponent:**
- Applies `glory_kill_glow.gdshader` to the sprite
- Pulses between two colors (warm orange ↔ pale yellow-white)
- Adds sprite wobble rotation
- Configurable: `pulse_speed`, `glow_strength`, `brightness_boost`, `fade_in_time`

**StunBarComponent:**
- Grey bar above the enemy's head
- Shrinks left-to-right as stun time elapses
- Custom `_draw()` rendering (no texture needed)

**DownAnimationComponent:**
- Tween-based sprite rotation to 90° in knockback direction
- Holds for `down_duration`, then rotates back up
- Direction-aware: rotation sign depends on knockback direction + sprite flip

## Integration Checklist

To make an enemy use this system:

1. **HealthComponent** — already handles the `health_depleted` / `died` branching automatically
2. **KnockbackableComponent** — add as child node, export-wire `health` and `state_machine`
3. **StunnedState** — add as child of StateMachine, export-wire all component references
4. **DownState** — add as child of StateMachine, export-wire `down_animation`, `hurtbox`, `health`, `knockbackable`
5. **StunAnimationComponent** — add as child node, export-wire `sprite`
6. **StunBarComponent** — add as child node (Node2D), position via `bar_offset`
7. **DownAnimationComponent** — add as child node, export-wire `sprite`

All wiring is done via `@export` variables in the scene editor.

## Skill Modifiers

Two passive skills extend this system:
- `stun_duration_bonus` — adds seconds to stun duration (read in `StunnedState._get_effective_stun_duration()`)
- `down_duration_bonus` — adds seconds enemy stays on the ground after knockdown (read in `DownState._on_enter()`)

Both are queried via `SkillManager.get_passive_float()`.

## Design Notes

- Enemies **never truly die from damage alone** when they have `KnockbackableComponent`. Health depletion → stun → stomp → down → recover is the full cycle.
- The stomp is proximity-based (Area2D overlap), not attack-based. The player walks over the stunned enemy.
- During stun, the enemy is invincible (`hurtbox.invincible = true`) and contact damage is disabled. This lets the player safely approach.
- The freeze frame on stomp gives the knockback a satisfying impact feel.
- Recovery always restores health — the enemy gets back up and re-enters combat. This creates a loop where enemies are downed repeatedly rather than killed outright (unless other systems like death are triggered separately).
