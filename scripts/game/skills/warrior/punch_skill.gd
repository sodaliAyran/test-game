extends RefCounted


static func create() -> SkillData:
	var s := SkillData.new()
	s.skill_id = "punch"
	s.skill_name = "Punch"
	s.description = "A close-range punch that damages enemies."
	s.category = "melee"
	s.path_tags = ["punch", "melee"]
	s.max_level = 7
	s.base_weight = 1.0
	s.scene_path = "res://scenes/skills/punch/punch.tscn"

	var l1 := _level(1, "Punch enemies up close.")

	var l2 := _level(2, "Heavier fists deal more damage.")
	l2.damage_bonus = 0.1

	var l3 := _level(3, "Larger impact area.")
	l3.size_bonus = 0.15

	var l4 := _level(4, "Faster punching rhythm.")
	l4.speed_bonus = 0.1

	var l5 := _level(5, "Devastating uppercut punch.")
	l5.feature_flags = ["uppercut"]
	l5.damage_bonus = 0.1

	var l6 := _level(6, "Iron fists crush harder.")
	l6.damage_bonus = 0.2

	var l7 := _level(7, "Lightning-fast combinations.")
	l7.speed_bonus = 0.15

	s.levels = [l1, l2, l3, l4, l5, l6, l7]
	return s


static func _level(lvl: int, desc: String) -> SkillLevelData:
	var ld := SkillLevelData.new()
	ld.level = lvl
	ld.description = desc
	return ld
