extends RefCounted


static func create() -> SkillData:
	var s := SkillData.new()
	s.skill_id = "sword_slash"
	s.skill_name = "Sword Slash"
	s.description = "A swift sword attack that strikes nearby enemies."
	s.category = "melee"
	s.path_tags = ["sword", "melee"]
	s.max_level = 7
	s.base_weight = 1.0
	s.scene_path = "res://scenes/skills/sword/sword.tscn"

	var l1 := _level(1, "Slash nearby enemies with your sword.")

	var l2 := _level(2, "Sharpen your blade for more damage.")
	l2.damage_bonus = 0.15

	var l3 := _level(3, "Faster swing speed.")
	l3.speed_bonus = 0.1

	var l4 := _level(4, "Strike forward then backward.")
	l4.feature_flags = ["double_strike"]
	l4.multi_hit_count = 2
	l4.attack_directions = [0.0, 180.0]

	var l5 := _level(5, "Wider slash arc.")
	l5.size_bonus = 0.2

	var l6 := _level(6, "Keener edge cuts deeper.")
	l6.damage_bonus = 0.15

	var l7 := _level(7, "Three rapid strikes in sequence.")
	l7.feature_flags = ["triple_strike"]
	l7.multi_hit_count = 3
	l7.attack_directions = [0.0, 180.0, 0.0]

	s.levels = [l1, l2, l3, l4, l5, l6, l7]
	return s


static func _level(lvl: int, desc: String) -> SkillLevelData:
	var ld := SkillLevelData.new()
	ld.level = lvl
	ld.description = desc
	return ld
