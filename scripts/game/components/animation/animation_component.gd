class_name AnimationComponent
extends Node

@export var animation_player: AnimationPlayer
@export var name_prefix: String = ""

var _current_animation: String = ""

func play(animation_name: String) -> void:
	if not animation_player:
		return
	if _current_animation == animation_name:
		return
	
	var prefixed_animation_name = name_prefix + animation_name
	if not animation_player.has_animation(prefixed_animation_name):
		return
	
	animation_player.play(prefixed_animation_name)
	_current_animation = animation_name

func stop_if(animation_name: String):
	if _current_animation == animation_name:
		animation_player.stop()
		_current_animation = ""

func is_finished(animation_name: String):
	return _current_animation == animation_name and not animation_player.is_playing()
