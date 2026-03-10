extends Node2D

## Test scene for SwordAttackAnimationComponent.
## Auto-attacks every 1.5s. Arrow keys change direction. Space for manual attack.

@onready var sword: Node2D = $Sword
@onready var attack_anim: SwordAttackAnimationComponent = $Sword/SwordAttackAnimationComponent
@onready var facing: FacingComponent = $Sword/FacingComponent

var _attack_timer: float = 0.0
var _attack_interval: float = 1.5


func _ready() -> void:
	position = Vector2(320, 180)
	# Scale up so it's easy to see
	sword.scale = Vector2(3, 3)
	facing.set_facing_from_direction(Vector2.RIGHT)
	# Give the attack anim a reference to the facing component directly
	attack_anim._facing = facing
	# Bigger radius and slower speed so it's easy to see
	attack_anim.swing_radius = 50.0
	attack_anim._anim_duration = 0.8


func _draw() -> void:
	# Draw a crosshair at the pivot so we can see the center point
	draw_line(Vector2(-10, 0), Vector2(10, 0), Color.DARK_GRAY, 1.0)
	draw_line(Vector2(0, -10), Vector2(0, 10), Color.DARK_GRAY, 1.0)
	draw_circle(Vector2.ZERO, 2, Color.WHITE)


func _process(delta: float) -> void:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		dir = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"):
		dir = Vector2.LEFT
	elif Input.is_action_pressed("ui_up"):
		dir = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		dir = Vector2.DOWN
	if dir != Vector2.ZERO:
		facing.set_facing_from_direction(dir)

	_attack_timer += delta
	if _attack_timer >= _attack_interval:
		_attack_timer = 0.0
		if not attack_anim.is_animating:
			attack_anim.play_attack()

	if Input.is_action_just_pressed("ui_accept") and not attack_anim.is_animating:
		attack_anim.play_attack()
