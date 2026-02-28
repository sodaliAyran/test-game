class_name EnemyFeedback
extends Node

## Macro component bundling combat feedback visuals.
## Contains: FadeAnimationComponent, DamageNumberComponent, KillTrackerComponent.
##
## Internal wire: DamageNumberComponent.fade_animation_component is set in the .tscn.
## Set the external exports (hurtbox, health) in the inspector after instancing.

@export var hurtbox: HurtboxComponent
@export var health: HealthComponent

@onready var fade_animation: FadeAnimationComponent = $FadeAnimationComponent
@onready var damage_numbers: DamageNumberComponent = $DamageNumberComponent
@onready var kill_tracker: KillTrackerComponent = $KillTrackerComponent


func _ready() -> void:
	if hurtbox:
		damage_numbers.hurtbox_component = hurtbox
	else:
		push_warning("EnemyFeedback: hurtbox not set")

	if health:
		kill_tracker.health = health
	else:
		push_warning("EnemyFeedback: health not set")
