extends RefCounted


static func create() -> SkillData:
	var s := SkillData.new()
	s.skill_id = "looter"
	s.skill_name = "Looter"
	s.description = "Increases drop chance and quantity."
	s.category = "passive"
	s.path_tags = ["utility"]
	s.max_level = 5
	s.base_weight = 1.0

	var descs := [
		"Enemies drop loot more often.",
		"Even better drop rates.",
		"Extra drops from enemies.",
		"Loot practically rains down.",
		"Maximum plunder.",
	]
	for i in range(5):
		var ld := _level(i + 1, descs[i])
		ld.drop_chance_bonus = 0.05
		if i + 1 == 3 or i + 1 == 5:
			ld.extra_drops = 1
		s.levels.append(ld)

	return s


static func _level(lvl: int, desc: String) -> SkillLevelData:
	var ld := SkillLevelData.new()
	ld.level = lvl
	ld.description = desc
	return ld
