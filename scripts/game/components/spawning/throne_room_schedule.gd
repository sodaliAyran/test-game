class_name ThroneRoomSchedule
extends SpawnSchedule

## 15-minute session schedule with Rogues and Berserkers.
## Ramps from 3 enemies on screen to ~15, with breathing room mid-game.

var rogue_scene: PackedScene = preload("res://scenes/characters/enemy/rogue/rogue.tscn")
var berserker_scene: PackedScene = preload("res://scenes/characters/enemy/berserker/berserker.tscn")


func _init() -> void:
	_build_schedule()


func _build_schedule() -> void:
	entries.clear()

	# --- Phase 1: Early Game (0:00 - 5:00) ---
	# 3-5 on screen, singles, non-uniform 8-20s intervals
	_add(0, rogue_scene, 2, 0.3)
	_add(3, berserker_scene, 1)
	_add(12, rogue_scene, 1)
	_add(20, rogue_scene, 1)
	_add(30, berserker_scene, 1)
	_add(42, rogue_scene, 1)
	_add(55, rogue_scene, 1)
	_add(65, berserker_scene, 1)
	_add(80, rogue_scene, 1)
	_add(95, rogue_scene, 1)
	_add(110, berserker_scene, 1)
	_add(130, rogue_scene, 1)
	_add(150, rogue_scene, 1)
	_add(170, berserker_scene, 1)
	_add(190, rogue_scene, 1)
	_add(210, rogue_scene, 1)
	_add(230, berserker_scene, 1)
	_add(250, rogue_scene, 1)
	_add(270, rogue_scene, 1)
	_add(290, berserker_scene, 1)

	# --- Phase 2: Mid Game (5:00 - 10:00) ---
	# 6-8 on screen, longer gaps (20-35s), breathing room
	_add(310, rogue_scene, 1)
	_add(335, berserker_scene, 1)
	_add(365, rogue_scene, 1)
	_add(400, berserker_scene, 1)
	_add(430, rogue_scene, 1)
	_add(455, rogue_scene, 1)
	_add(480, berserker_scene, 1)
	_add(510, rogue_scene, 2, 0.5)
	_add(540, berserker_scene, 1)
	_add(565, rogue_scene, 1)
	_add(590, berserker_scene, 1)

	# --- Phase 3: Late Game (10:00 - 15:00) ---
	# 10-15 on screen, pairs and triples, 15-20s intervals
	_add(620, rogue_scene, 2, 0.4)
	_add(645, berserker_scene, 2, 0.4)
	_add(665, rogue_scene, 2, 0.4)
	_add(685, berserker_scene, 1)
	_add(700, rogue_scene, 3, 0.3)
	_add(720, berserker_scene, 2, 0.4)
	_add(740, rogue_scene, 2, 0.4)
	_add(760, berserker_scene, 2, 0.4)
	_add(775, rogue_scene, 3, 0.3)
	_add(795, berserker_scene, 2, 0.4)
	_add(810, rogue_scene, 2, 0.4)
	_add(830, berserker_scene, 3, 0.3)
	_add(850, rogue_scene, 2, 0.4)
	_add(870, berserker_scene, 2, 0.4)
	_add(890, rogue_scene, 3, 0.3)


func _add(time: float, scene: PackedScene, count: int = 1, stagger: float = 0.0) -> void:
	var entry := SpawnScheduleEntry.new()
	entry.time = time
	entry.enemy_scene = scene
	entry.count = count
	entry.stagger = stagger
	entries.append(entry)
