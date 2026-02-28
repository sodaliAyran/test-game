class_name EnemyKnockbackStun
extends Node

## Macro component bundling the knockback/stun/down flow.
## Contains: KnockbackableComponent, CombatDirectorRequestComponent,
## StunAnimationComponent, StunBarComponent, DownAnimationComponent.
##
## Set the external exports (sprite, health, state_machine) in the inspector
## after instancing this scene. The wrapper distributes them to children in _ready().

@export var sprite: Sprite2D
@export var health: HealthComponent
@export var state_machine: Node  # NodeStateMachine

@onready var knockbackable: KnockbackableComponent = $KnockbackableComponent
@onready var stun_animation: StunAnimationComponent = $StunAnimationComponent
@onready var stun_bar: StunBarComponent = $StunBarComponent
@onready var down_animation: DownAnimationComponent = $DownAnimationComponent
@onready var combat_director_request: CombatDirectorRequestComponent = $CombatDirectorRequestComponent


func _ready() -> void:
	if sprite:
		stun_animation.sprite = sprite
		down_animation.sprite = sprite
	else:
		push_warning("EnemyKnockbackStun: sprite not set")

	if health:
		knockbackable.health = health
	else:
		push_warning("EnemyKnockbackStun: health not set")

	if state_machine:
		knockbackable.state_machine = state_machine
	else:
		push_warning("EnemyKnockbackStun: state_machine not set")
