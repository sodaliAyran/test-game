extends Node

## Centralized game statistics manager
## Tracks kills, coins, and other player statistics

signal kill_count_changed(new_count: int)
signal coin_count_changed(new_count: int)

var kill_count: int = 0
var coin_count: int = 0

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
	kill_count_changed.emit(kill_count)
	coin_count_changed.emit(coin_count)
	print("GameStats: Statistics reset")

func get_kill_count() -> int:
	return kill_count

func get_coin_count() -> int:
	return coin_count
