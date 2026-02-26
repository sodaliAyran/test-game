extends RefCounted


static func create() -> SkillData:
	var s := SkillData.new()
	s.skill_id = "stunning_blows"
	s.skill_name = "Stunning Blows"
	s.description = "Enemies remain stunned for longer."
	s.category = "passive"
	s.path_tags = ["offensive"]
	s.max_level = 3
	s.base_weight = 0.8

	var descs := [
		"Enemies stay stunned longer.",
		"Staggering strikes.",
		"Devastating stun duration.",
	]
	for i in range(3):
		var ld := _level(i + 1, descs[i])
		ld.stun_duration_bonus = 1.0
		s.levels.append(ld)

	return s


static func _level(lvl: int, desc: String) -> SkillLevelData:
	var ld := SkillLevelData.new()
	ld.level = lvl
	ld.description = desc
	return ld
