extends RefCounted


static func create() -> SkillData:
	var s := SkillData.new()
	s.skill_id = "vitality"
	s.skill_name = "Vitality"
	s.description = "Increases maximum health."
	s.category = "passive"
	s.path_tags = ["defensive"]
	s.max_level = 5
	s.base_weight = 1.0

	var descs := [
		"Increases maximum health.",
		"Further health increase.",
		"Toughened body.",
		"Hardened constitution.",
		"Iron will, iron body.",
	]
	for i in range(5):
		var ld := _level(i + 1, descs[i])
		ld.health_bonus = 10
		s.levels.append(ld)

	return s


static func _level(lvl: int, desc: String) -> SkillLevelData:
	var ld := SkillLevelData.new()
	ld.level = lvl
	ld.description = desc
	return ld
