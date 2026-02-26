class_name SpawnSchedule
extends Resource

@export var entries: Array[SpawnScheduleEntry] = []


func get_sorted_entries() -> Array[SpawnScheduleEntry]:
	var sorted := entries.duplicate()
	sorted.sort_custom(func(a: SpawnScheduleEntry, b: SpawnScheduleEntry) -> bool:
		return a.time < b.time
	)
	return sorted
