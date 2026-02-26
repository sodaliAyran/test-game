# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Test Game** - A Godot 4.4 action game built with a component-based architecture featuring state machines, skill progression, Arkham-style combat coordination, knockback/stun mechanics, and a nemesis trait system.

**Engine:** Godot 4.4 (GDScript)
**Display:** 640x360 viewport, scaled 2x to 1280x720 (integer scaling, pixel art)
**Input:** WASD/Arrow keys for movement, Left mouse button for attack

## Running the Game

This is a Godot project - open it in the Godot 4.4 editor and press F5 to run. The main scene is configured in [project.godot](project.godot).

**Testing Skills:** Press number keys 1-9 during gameplay to unlock skills (see [SKILL_TESTING.md](SKILL_TESTING.md) for details).

## Architecture Overview

### Core Architectural Patterns

#### 1. Component-Based Entity System
Entities (players, enemies) are composed from reusable component nodes rather than deep inheritance hierarchies. Components communicate via signals and exported NodePath references.

**Component Folder Structure** ([scripts/game/components/](scripts/game/components/)):
- **core/** - `HealthComponent`, `MovementComponent`, `HitboxComponent`, `HurtboxComponent`, `FacingComponent`
- **player/** - `PlayerInputComponent`, `CollectorComponent`, `CollectionTrackerComponent`
- **enemy/** - `EnemySenseComponent`, `PathfindingComponent`, `SeparationComponent`, `EnemyDamageComponent`, `SlotSeekerComponent`, `CombatParticipantComponent`
- **combat/** - `DashComponent`, `CombatDirectorRequestComponent`, `KnockbackableComponent`
- **animation/** - `AnimationComponent` (base), `HurtFlashAnimationComponent`, `HurtStaggerAnimationComponent`, `SpawnAnimationComponent`, `DeathAnimationComponent`, `DownAnimationComponent`, `AttackAnimationComponent`, `FadeAnimationComponent`, `FountainSpawnAnimationComponent`, `WobbleAnimationComponent`, `StunAnimationComponent`, `WindupIndicatorComponent`, `WindupEffect`, `DashWindupEffect`, `FacingIndicatorComponent`, `CircleShapeRenderer`, `LineShapeRenderer`
- **ui/** - `HealthBarComponent`, `TextBubbleComponent`, `DamageNumberComponent`, `StunBarComponent`
- **collectibles/** - `CollectibleComponent`, `DeathDropComponent`, `HitDropComponent`
- **spawning/** - `TimelineSpawner`, `WaveSpawner`
- **systems/** - `SpatialGrid`, `NemesisComponent`, `KillTrackerComponent`

See usage guides: [HEALTH_BAR_USAGE.md](scripts/game/components/ui/HEALTH_BAR_USAGE.md), [TEXT_BUBBLE_USAGE.md](scripts/game/components/ui/TEXT_BUBBLE_USAGE.md)

#### 2. Hierarchical State Machine System
**Base Classes:**
- [node_state.gd](scripts/game/state_machine/node_state.gd) - Base state with lifecycle callbacks
- [node_state_machine.gd](scripts/game/state_machine/node_state_machine.gd) - State manager with queued transitions

**State Lifecycle:**
1. `_on_enter()` - Setup (connect signals, start timers)
2. `_on_process(delta)` - Frame updates
3. `_on_physics_process(delta)` - Physics queries
4. `_on_next_transitions()` - Evaluate next state
5. `_on_exit()` - Cleanup (disconnect signals)

**Transition Pattern:** States emit `transition.emit("StateName")` signal. Transitions are queued and applied safely between frames to prevent mid-frame state corruption.

**Character States:**
- **Player (Warrior):** Idle → Move → Hurt → Death
- **Enemy (Skeleton Soldier):** Spawn → Idle → Chase → Engage → Hurt → Down → Stunned → Death → Flee
- **Enemy (Rogue):** Spawn → Idle → Chase → Engage → Dash → Attack → Hurt → Death → Flee
- **Enemy (Berserker):** Idle → Chase → Attack → Hurt → Death → Flee

**Generic Enemy States** ([scripts/game/states/enemy/](scripts/game/states/enemy/)):
- `hurt_state.gd` - Generic hurt reaction
- `down_state.gd` - Knockdown state with trait-aware transitions (checks CowardTrait for flee)
- `stunned_state.gd` - Time-based incapacitation with recovery or knockback-to-down flow

States are defined as child nodes of `NodeStateMachine` and reference components via `@export var component_name: ComponentType`.

#### 3. Autoload Singletons
Global managers defined in [project.godot](project.godot):
- **SpatialGrid** - Spatial partitioning for efficient radius queries (64px cells, multiple layers)
- **SkillManager** - Centralized skill tree progression with prerequisite validation
- **SkillTreeLoader** - Loads skill tree resources
- **SkillDebugInput** - Debug keyboard shortcuts for skill unlocking
- **GameStats** - Global statistics (kills, coins, XP, level) with change signals (including `level_up`)
- **CircleSlotManager** - Arkham-style positioning with inner/outer ring slots around targets
- **CombatDirector** - Global AP token bucket system controlling when enemies can attack
- **FreezeFrame** - Freeze frame manager for hit impact juice (`FreezeFrame.freeze(duration)`)

#### 4. Combat Director System (AP Token Bucket)
**Files:** [combat_director.gd](scripts/game/systems/combat_director.gd), [ap_request.gd](scripts/game/systems/ap_request.gd), [combat_director_request_component.gd](scripts/game/components/combat/combat_director_request_component.gd), [combat_participant_component.gd](scripts/game/components/enemy/combat_participant_component.gd)

**Architecture:**
- Global AP pool (refills at 2.0 AP/sec, max 10.0)
- Priority queue for attack requests
- Concurrency limits: max 3 simultaneous attacks, max 1 special (cost >= 3.0)
- Request-response pattern with callbacks
- AP refund on cancelled windups

**Action Costs:** basic_melee: 1.0, heavy_melee: 2.0, dash_attack: 2.5, special_attack: 3.0+, ultimate: 5.0

**Integration Pattern:**
```gdscript
var request = APRequest.create(owner, "dash_attack", 2.5, callback, priority)
director_request.request_action(request)
```

See [COMBAT_DIRECTOR_INTEGRATION.md](scripts/game/components/combat/COMBAT_DIRECTOR_INTEGRATION.md) for details.

#### 5. Circle Slot Manager (Arkham-style Positioning)
**Files:** [circle_slot_manager.gd](scripts/game/systems/circle_slot_manager.gd), [slot_seeker_component.gd](scripts/game/components/enemy/slot_seeker_component.gd)

**Architecture:**
- Inner ring (6 slots @ 60px) and outer ring (12 slots @ 120px)
- Recovery zone (150px) for downed enemies
- Automatic promotion from outer to inner based on priority + wait time
- Orbit rotation based on player movement direction
- `SlotSeekerComponent` provides per-enemy interface to the slot system

#### 6. Engage State Pattern
**Files:** [rogue/engage_state.gd](scenes/characters/enemy/rogue/engage_state.gd), [skeleton_soldier/engage_state.gd](scenes/characters/enemy/skeleton_soldier/engage_state.gd)

Enemies at their slot position iterate through skill nodes and request the first available via the AP system. Skills implement a generic interface:
- `can_use() -> bool`
- `request_use(context) -> bool`
- `cancel_pending_request()`
- `activate()` / `deactivate()` - Enable/disable skill when entering/leaving engage state

#### 7. Knockback & Stun System
**Files:** [knockbackable_component.gd](scripts/game/components/combat/knockbackable_component.gd), [stunned_state.gd](scripts/game/states/enemy/stunned_state.gd), [stun_animation_component.gd](scripts/game/components/animation/stun_animation_component.gd), [stun_bar_component.gd](scripts/game/components/ui/stun_bar_component.gd)

**Flow:**
1. `KnockbackableComponent` listens for `health_depleted` signal
2. On depletion → transitions to `Stunned` state (enemy incapacitated)
3. `StunnedState` shows stun bar and plays stun animation for `stun_duration` seconds
4. If attacked during stun → freeze frame + knockback → transitions to `Down` state
5. If stun expires without attack → `KnockbackableComponent.recover()` restores health → transitions to `Chase`
6. `Down` state plays directional knockdown animation, checks CowardTrait for flee

#### 8. Windup Indicator System
**Files:** [windup_indicator_component.gd](scripts/game/components/animation/windup_indicator_component.gd), [circle_shape_renderer.gd](scripts/game/components/animation/circle_shape_renderer.gd), [line_shape_renderer.gd](scripts/game/components/animation/line_shape_renderer.gd), [windup_effect.gd](scripts/game/components/animation/windup_effect.gd), [dash_windup_effect.gd](scripts/game/components/animation/dash_windup_effect.gd)

**Architecture:**
- `WindupIndicatorComponent` - Manages circle or line shape visual preview of attack area
- `CircleShapeRenderer` - Growing fill circle for slam/area attacks
- `LineShapeRenderer` - Directional line for dash/ranged attacks
- `WindupEffect` - Sprite color pulse during windup
- `DashWindupEffect` - Darken/squeeze sprite effect during dash charge

#### 9. Nemesis Trait System
**Architecture:**
- `NemesisComponent` - Attached to entities, holds array of trait resources
- `NemesisTraitData` (Resource) - Base class for traits with `setup()`, `execute()`, `cleanup()`, `priority`, `can_execute_parallel`
- `NemesisArbiter` - Orchestrates trait execution (batching, priority sorting, parallel vs exclusive)
- Example: [coward_trait.gd](scripts/game/traits/coward_trait.gd) - Flees when health is low, sets `is_fleeing` flag read by Down state

**Pattern:** Traits are event-agnostic - they connect to signals and request execution via arbiter when conditions are met.

#### 10. Spawn Timeline System
**Files:** [spawn_timeline.gd](scripts/game/systems/spawn_timeline.gd), [timeline_spawner.gd](scripts/game/components/spawning/timeline_spawner.gd)

- `SpawnTimeline` (Resource) - Container of spawn events
- Event types: `BurstSpawnEvent` (single), `ContinuousSpawnEvent` (over time)
- `TimelineSpawner` (Node2D) - Executes timeline, auto-collects `Marker2D` children as spawn points
- Emits: `enemy_spawned`, `event_started`, `timeline_completed`

#### 11. Procedural World Generation
**Files:** [procedural_world.gd](scripts/game/world/procedural_world.gd), [chunk_manager.gd](scripts/game/world/chunk_manager.gd), [chunk_generator.gd](scripts/game/world/chunk_generator.gd), [world_config.gd](scripts/game/world/world_config.gd)

Chunk-based infinite terrain generation using FastNoiseLite. 16x16 tile chunks with load/unload radius management and auto-tiling terrain sets.

#### 12. Skill System
**Files:** [scripts/game/skills/](scripts/game/skills/)
- **core/** - `SkillData`, `SkillTree`, `SkillManager`, `SkillTreeLoader`, `SkillDebugInput`
- **modifiers/** - `SkillModifierComponent` (caches damage/speed/size multipliers, multi-hit count)
- **triggers/** - `SkillCooldownComponent`, `SkillTriggerArea`
- **weapons/** - `WeaponComponent`, `DirectionalWeaponComponent`, `AutoAttackComponent`, `WeaponAnimationComponent`
- **slam/** - `SlamSkillComponent` (area attack with circle windup indicator, AP integration)
- **projectile/** - `ProjectileSkillComponent` (spawning, patterns, cooldown, AP integration), `ProjectileComponent` (flight, homing, pierce, falloff)

**Warrior Skills:** Swift Strike → Double Strike → Triple Strike → Whirlwind Strike (multi-hit chain), Power Strike → Devastating Blow (damage chain), Wide Slash (size).

**Skill Types:**
- **Melee** - `WeaponComponent` with hitbox, directional positioning
- **Slam** - `SlamSkillComponent` with circle windup at target position (non-tracking)
- **Projectile** - `ProjectileSkillComponent` with multi-projectile patterns, spread angle, burst delay, auto-targeting, homing support
- **Dash** - `DashComponent` with invincibility, windup effects, backstab targeting

#### 13. Collision Layer Constants
**File:** [collision_layers.gd](scripts/game/constants/collision_layers.gd)

Centralized bitmask constants: `ENEMY_BODY` (L2), `PLAYER_HITBOX` (L3), `ENEMY_HITBOX` (L4), `PLAYER_HURTBOX` (L5), `ENEMY_HURTBOX` (L6), `COLLECTIBLE` (L7), `COLLECTION_AREA` (L8).

### Scene Organization

**Character Scene Pattern:**
```
CharacterBody2D (root)
├── CollisionShape2D
├── Sprite2D
├── HurtboxComponent (Area2D)
├── Components (HealthComponent, MovementComponent, FacingComponent, etc.)
├── KnockbackableComponent [enemies]
└── StateMachine
    ├── Idle (NodeState)
    ├── Move/Chase (NodeState)
    ├── Engage (NodeState) [enemies]
    ├── Stunned (NodeState) [enemies]
    ├── Down (NodeState) [enemies]
    └── ... (other states)
```

**Enemy Types:**
- **Skeleton Soldier** ([skeleton_soldier.tscn](scenes/characters/enemy/skeleton_soldier/skeleton_soldier.tscn)) - Basic melee with slot engagement, knockback/stun flow
- **Rogue** ([rogue.tscn](scenes/characters/enemy/rogue/rogue.tscn)) - Dash attacks with windup indicators, backstab targeting, most complex AI
- **Berserker** ([berserker.tscn](scenes/characters/enemy/berserker/berserker.tscn)) - Aggressive melee fighter with slam skill

**Skill Scenes** ([scenes/skills/](scenes/skills/)):
- **sword/** - Melee sword attack
- **dash/** - Dash ability
- **punch/** - Punch attack with projectiles
- **arrow/** - Arrow projectile skill
- **slam/** - Slam area attack

States wire to components via `@export` typed variables set in the scene editor.

### Damage System

**Hitbox/Hurtbox Pattern:**
- `HitboxComponent` (attacker) - Tracks hit targets per attack to prevent multi-hits from single attack, applies damage multipliers
- `HurtboxComponent` (defender) - Receives damage, applies knockback
- Uses collision layers/masks for filtering
- Signals: `hurt(amount)`, `knocked(direction, force)`

### Spatial Optimization

**SpatialGrid Singleton** - Efficient entity queries without O(n) every frame
- Grid-based spatial hash (64px cells)
- Multiple layers: "enemies", "players", "collectibles"
- API: `register_entity()`, `unregister_entity()`, `update_entity_position()`, `query_nearby()`

### Resource-Based Configuration

Game content is data-driven using Godot resources:
- **Traits:** [resources/traits/](resources/traits/) - Enemy behavior modifiers
- **Dialogue:** [resources/dialogue/](resources/dialogue/) - Text bubble content
- **Timelines:** [resources/timelines/](resources/timelines/) - Spawn sequences
- **Skills:** [resources/skills/](resources/skills/) - Skill tree definitions
- **World Config:** [resources/world_config_default.tres](resources/world_config_default.tres)

### UI System
- **HUD** ([hud.tscn](scenes/ui/hud.tscn)) - Health bar, XP bar, counters
- **Level-Up Screen** ([level_up_screen.tscn](scenes/ui/level_up_screen.tscn)) - Pauses game, shows skill panels on level up via `GameStats.level_up` signal
- **Skill Panel** ([skill_panel.tscn](scenes/ui/skill_panel.tscn)) - Individual skill selection panel
- **UI Scripts:** [scripts/game/ui/](scripts/game/ui/) - `HudCounterComponent`, `HudHealthBar`, `HudXpBar`, `LevelUpScreen`, `SkillPanel`

## Adding New Features

### Adding a New Enemy
1. Create scene extending `CharacterBody2D`
2. Add components: HealthComponent, MovementComponent, HurtboxComponent, EnemySenseComponent, FacingComponent, SlotSeekerComponent, CombatParticipantComponent/CombatDirectorRequestComponent, KnockbackableComponent, etc.
3. Create `StateMachine` with state nodes (Spawn, Idle, Chase, Engage, Hurt, Stunned, Down, Death)
4. Wire states to components via `@export` variables in scene editor
5. Optionally add `NemesisComponent` with trait resources
6. Add skill nodes as children for the Engage state to iterate

### Adding a New Skill
1. Create `SkillData` resource with ID, name, description, prerequisites
2. Add to skill tree resource
3. Implement skill effects by checking `SkillManager.is_skill_unlocked()`
4. For enemy skills: implement `can_use()`, `request_use(context)`, `cancel_pending_request()`, `activate()`, `deactivate()` interface
5. For projectile skills: use `ProjectileSkillComponent` with a `ProjectileComponent`-containing scene
6. For area skills: use `SlamSkillComponent` with `WindupIndicatorComponent`

### Adding a New Trait
1. Extend `NemesisTraitData` resource script
2. Implement `setup()` to connect to signals
3. Implement `execute(context)` for behavior modification
4. Set `priority` and `can_execute_parallel` flags
5. Attach resource to entity's `NemesisComponent`

### Adding a New Component
1. Create script extending `Node` or appropriate base class
2. Use `@export` variables for configuration and node references
3. Emit signals for events rather than direct coupling
4. Document usage pattern if reusable (see component USAGE.md files)

## Code Conventions

**Signal-Driven Communication:** Components use signals instead of direct method calls to maintain loose coupling.

**Export Variables:** Use `@export` with typed references for scene-wired component references.

**State Transitions:** Always use `transition.emit()` rather than directly manipulating state machine.

**Autoload Access:** Access singletons directly (e.g., `SpatialGrid.query_nearby()`, `SkillManager.unlock_skill()`, `CombatDirector.request_action()`, `CircleSlotManager.request_slot()`, `FreezeFrame.freeze()`).

**Component Lifecycle:** Components should handle their own cleanup (disconnect signals, free resources) when removed from tree.

**Generic Skill Interface:** Combat skills implement `can_use() -> bool`, `request_use(context) -> bool`, `cancel_pending_request()`, `activate()`, `deactivate()` for use with the Engage state pattern.

**Collision Layers:** Use `CollisionLayers` constants from [collision_layers.gd](scripts/game/constants/collision_layers.gd) instead of raw bitmask values.
