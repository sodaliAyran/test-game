# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Test Game** - A Godot 4.4 action game built with a component-based architecture featuring state machines, skill progression, and a nemesis trait system.

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
- **core/** - `HealthComponent`, `MovementComponent`, `HitboxComponent`, `HurtboxComponent`
- **player/** - `PlayerInputComponent`, `CollectorComponent`, `CollectionTrackerComponent`
- **enemy/** - `EnemySenseComponent`, `PathfindingComponent`, `SeparationComponent`, `EnemyDamageComponent`
- **combat/** - `WeaponComponent`, `DirectionalWeaponComponent`, `AutoAttackComponent`, `SkillModifierComponent`
- **animation/** - `AnimationComponent` (base), `HurtFlashAnimationComponent`, `SpawnAnimationComponent`, `DeathAnimationComponent`, etc.
- **ui/** - `HealthBarComponent`, `TextBubbleComponent`, `DamageNumberComponent`
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
- **Enemy (Skeleton):** Spawn → Idle → Chase/Flee → Hurt → Death

States are defined as child nodes of `NodeStateMachine` and reference components via `@export var component_name: NodePath`.

#### 3. Autoload Singletons
Global managers defined in [project.godot](project.godot:18-24):
- **SpatialGrid** - Spatial partitioning for efficient radius queries (64px cells, multiple layers)
- **SkillManager** - Centralized skill tree progression with prerequisite validation
- **SkillTreeLoader** - Loads skill tree resources
- **SkillDebugInput** - Debug keyboard shortcuts for skill unlocking
- **GameStats** - Global statistics (kills, coins) with change signals

#### 4. Nemesis Trait System
**Architecture:**
- `NemesisComponent` - Attached to entities, holds array of trait resources
- `NemesisTraitData` (Resource) - Base class for traits with `setup()`, `execute()`, `cleanup()`, `priority`, `can_execute_parallel`
- `NemesisArbiter` - Orchestrates trait execution (batching, priority sorting, parallel vs exclusive)
- Example: [coward_trait.gd](scripts/game/traits/coward_trait.gd) - Flees when health is low

**Pattern:** Traits are event-agnostic - they connect to signals and request execution via arbiter when conditions are met.

#### 5. Spawn Timeline System
**Files:** [spawn_timeline.gd](scripts/game/systems/spawn_timeline.gd), [timeline_spawner.gd](scripts/game/components/spawning/timeline_spawner.gd)

**Pattern:**
- `SpawnTimeline` (Resource) - Container of spawn events
- Event types: `BurstSpawnEvent` (single), `ContinuousSpawnEvent` (over time)
- `TimelineSpawner` (Node2D) - Executes timeline, auto-collects `Marker2D` children as spawn points
- Emits: `enemy_spawned`, `event_started`, `timeline_completed`

#### 6. Procedural World Generation
**Files:** [procedural_world.gd](scripts/game/world/procedural_world.gd), [chunk_manager.gd](scripts/game/world/chunk_manager.gd), [chunk_generator.gd](scripts/game/world/chunk_generator.gd)

Chunk-based world generation system for infinite terrain.

### Scene Organization

**Character Scene Pattern:**
```
CharacterBody2D (root)
├── CollisionShape2D
├── Sprite2D
│   └── HurtboxComponent (Area2D) - Receives damage
├── Components (various specialized nodes)
└── StateMachine
    ├── Idle (NodeState)
    ├── Move (NodeState)
    └── ... (other states)
```

States wire to components via `@export` NodePath variables set in the scene editor.

### Damage System

**Hitbox/Hurtbox Pattern:**
- `HitboxComponent` (attacker) - Tracks hit targets per attack to prevent multi-hits from single attack
- `HurtboxComponent` (defender) - Receives damage, applies knockback
- Uses collision layers/masks for filtering
- Signals: `hurt(amount)`, `knocked(direction, force)`

### Spatial Optimization

**SpatialGrid Singleton** - Efficient entity queries without O(n) every frame
- Grid-based spatial hash (64px cells)
- Multiple layers: "enemies", "players", "collectibles"
- API: `register_entity()`, `unregister_entity()`, `update_entity_position()`, `query_nearby()`
- Usage: `CollectorComponent` uses it for magnetic item collection

### Resource-Based Configuration

Game content is data-driven using Godot resources:
- **Traits:** [resources/traits/](resources/traits/) - Enemy behavior modifiers
- **Dialogue:** [resources/dialogue/](resources/dialogue/) - Text bubble content
- **Timelines:** [resources/timelines/](resources/timelines/) - Spawn sequences
- **Skills:** Loaded by `SkillTreeLoader` autoload

## Adding New Features

### Adding a New Enemy
1. Create scene extending `CharacterBody2D`
2. Add components: HealthComponent, MovementComponent, HurtboxComponent, EnemySenseComponent, etc.
3. Create `StateMachine` with state nodes (Spawn, Idle, Chase, Hurt, Death)
4. Wire states to components via `@export` variables in scene editor
5. Optionally add `NemesisComponent` with trait resources

### Adding a New Skill
1. Create `SkillData` resource with ID, name, description, prerequisites
2. Add to skill tree resource
3. Implement skill effects in weapon/character state code by checking `SkillManager.is_skill_unlocked()`

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

**Export Variables:** Use `@export` with NodePath for scene-wired references, avoiding hardcoded node paths.

**State Transitions:** Always use `transition.emit()` rather than directly manipulating state machine.

**Autoload Access:** Access singletons directly (e.g., `SpatialGrid.query_nearby()`, `SkillManager.unlock_skill()`).

**Component Lifecycle:** Components should handle their own cleanup (disconnect signals, free resources) when removed from tree.
