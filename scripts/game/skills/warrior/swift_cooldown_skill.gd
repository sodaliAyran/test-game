extends RefCounted


static func create() -> SkillData:
	var s := SkillData.new()
	s.skill_id = "swift_cooldown"
	s.skill_name = "Swift Cooldown"
	s.description = "Reduces skill cooldown times."
	s.category = "passive"
	s.path_tags = ["speed"]
	s.max_level = 5
	s.base_weight = 0.9

	var descs := [
		"Skills recharge faster.",
		"Improved recovery.",
		"Rapid skill cycling.",
		"Near-instant readiness.",
		"Relentless assault.",
	]
	for i in range(5):
		var ld := _level(i + 1, descs[i])
		ld.cooldown_reduction = 0.04
		s.levels.append(ld)

	return s


static func _level(lvl: int, desc: String) -> SkillLevelData:
	var ld := SkillLevelData.new()
	ld.level = lvl
	ld.description = desc
	return ld
