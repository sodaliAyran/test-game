extends RefCounted


static func create() -> SkillData:
	var s := SkillData.new()
	s.skill_id = "magnetism"
	s.skill_name = "Magnetism"
	s.description = "Increases collection range for items."
	s.category = "passive"
	s.path_tags = ["utility"]
	s.max_level = 5
	s.base_weight = 1.0

	var descs := [
		"Attract nearby items.",
		"Stronger attraction field.",
		"Items fly from further away.",
		"Magnetic aura expands.",
		"Nothing escapes your pull.",
	]
	for i in range(5):
		var ld := _level(i + 1, descs[i])
		ld.magnet_radius_bonus = 5.0
		s.levels.append(ld)

	return s


static func _level(lvl: int, desc: String) -> SkillLevelData:
	var ld := SkillLevelData.new()
	ld.level = lvl
	ld.description = desc
	return ld
