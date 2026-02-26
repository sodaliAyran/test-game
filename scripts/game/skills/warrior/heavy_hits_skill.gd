extends RefCounted


static func create() -> SkillData:
	var s := SkillData.new()
	s.skill_id = "heavy_hits"
	s.skill_name = "Heavy Hits"
	s.description = "Knocked down enemies stay down longer."
	s.category = "passive"
	s.path_tags = ["offensive"]
	s.max_level = 3
	s.base_weight = 0.8

	var descs := [
		"Enemies stay down longer.",
		"Crushing knockdowns.",
		"Enemies barely get back up.",
	]
	for i in range(3):
		var ld := _level(i + 1, descs[i])
		ld.down_duration_bonus = 0.5
		s.levels.append(ld)

	return s


static func _level(lvl: int, desc: String) -> SkillLevelData:
	var ld := SkillLevelData.new()
	ld.level = lvl
	ld.description = desc
	return ld
