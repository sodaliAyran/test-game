extends Node2D

func _ready() -> void:
	print("Test HUD Scene - Press K for kills, C for coins, R to reset")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_K:
				GameStats.increment_kills()
			KEY_C:
				GameStats.add_coins(10)
			KEY_R:
				GameStats.reset_stats()
