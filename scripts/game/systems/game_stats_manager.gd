extends Node

## Centralized game statistics manager
## Tracks kills, coins, and other player statistics

signal kill_count_changed(new_count: int)
signal coin_count_changed(new_count: int)
signal xp_changed(current_xp: int, xp_for_next_level: int, level: int)
signal level_up(new_level: int)

const MAX_LEVEL: int = 50

var kill_count: int = 0
var coin_count: int = 0
var current_xp: int = 0
var player_level: int = 1
var xp_for_next_level: int = 5

func _ready() -> void:
	print("GameStats: Manager initialized")

func increment_kills() -> void:
	"""Increment the kill counter by 1."""
	kill_count += 1
	kill_count_changed.emit(kill_count)
	print("GameStats: Kill count = %d" % kill_count)

func add_coins(amount: int) -> void:
	"""Add coins to the counter."""
	coin_count += amount
	coin_count_changed.emit(coin_count)
	print("GameStats: Coin count = %d" % coin_count)

func reset_stats() -> void:
	"""Reset all statistics to zero."""
	kill_count = 0
	coin_count = 0
	current_xp = 0
	player_level = 1
	xp_for_next_level = _calculate_xp_for_level(1)
	kill_count_changed.emit(kill_count)
	coin_count_changed.emit(coin_count)
	xp_changed.emit(current_xp, xp_for_next_level, player_level)
	print("GameStats: Statistics reset")

func get_kill_count() -> int:
	return kill_count

func get_coin_count() -> int:
	return coin_count

func add_xp(amount: int) -> void:
	"""Add XP and handle level ups."""
	if player_level >= MAX_LEVEL:
		return

	current_xp += amount
	while current_xp >= xp_for_next_level and player_level < MAX_LEVEL:
		current_xp -= xp_for_next_level
		player_level += 1
		if player_level < MAX_LEVEL:
			xp_for_next_level = _calculate_xp_for_level(player_level)
		else:
			current_xp = 0
			xp_for_next_level = 0
		level_up.emit(player_level)
		print("GameStats: Level up! Now level %d" % player_level)
	xp_changed.emit(current_xp, xp_for_next_level, player_level)
	print("GameStats: XP = %d/%d (Level %d)" % [current_xp, xp_for_next_level, player_level])

func _calculate_xp_for_level(level: int) -> int:
	"""Calculate XP required for the next level using a three-tier system.
	Early (1-20): Starts at 5, increases by 10 per level. Formula: 5 + (level - 1) * 10
	Mid (21-40): Starts at 2100, increases by 130 per level.
	Late (41+): Starts at 4700, increases by 600 per level."""
	if level <= 20:
		# Early game: fast leveling, +10 XP per level
		return 5 + (level - 1) * 10
	elif level <= 40:
		# Mid game: steeper curve, +130 XP per level
		return 2100 + (level - 21) * 130
	else:
		# Late game: heavy climb, +600 XP per level
		return 4700 + (level - 41) * 600

func get_xp() -> int:
	return current_xp

func get_xp_for_next_level() -> int:
	return xp_for_next_level

func get_level() -> int:
	return player_level
