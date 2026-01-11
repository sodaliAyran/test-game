class_name NemesisComponent
extends Node

## Manages nemesis traits for an enemy
## Completely agnostic of events - traits handle their own signal connections

@export var traits: Array[NemesisTraitData] = []

var arbiter: NemesisArbiter

func _ready() -> void:
	# Initialize arbiter
	arbiter = NemesisArbiter.new()
	
	# Setup all traits
	for t in traits:
		if t:
			t.setup(get_parent(), arbiter)

func _exit_tree() -> void:
	# Cleanup all traits
	for t in traits:
		if t:
			t.cleanup()
