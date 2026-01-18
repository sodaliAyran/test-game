extends Node

## Centralized game statistics manager
## Tracks kills, coins, and other player statistics

signal kill_count_changed(new_count: int)
signal coin_count_changed(new_count: int)
signal xp_changed(current_xp: int, xp_for_next_level: int, level: int)

var kill_count: int = 0
var coin_count: int = 0
var current_xp: int = 0
var player_level: int = 1
var xp_for_next_level: int = 100

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
	xp_for_next_level = 100
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
	current_xp += amount
	while current_xp >= xp_for_next_level:
		current_xp -= xp_for_next_level
		player_level += 1
		xp_for_next_level = _calculate_xp_for_level(player_level)
		print("GameStats: Level up! Now level %d" % player_level)
	xp_changed.emit(current_xp, xp_for_next_level, player_level)
	print("GameStats: XP = %d/%d (Level %d)" % [current_xp, xp_for_next_level, player_level])

func _calculate_xp_for_level(level: int) -> int:
	"""Calculate XP required for next level (scales with level)."""
	return 100 + (level - 1) * 50

func get_xp() -> int:
	return current_xp

func get_xp_for_next_level() -> int:
	return xp_for_next_level

func get_level() -> int:
	return player_level
