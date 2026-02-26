class_name EnemyDamageComponent
extends Node2D

## Component that damages the player when enemy collides with them
## Uses damage cooldown to prevent rapid repeated damage for performance

signal damage_dealt(target: Node2D, amount: int)

@export var damage_amount: int = 5
@export var damage_cooldown: float = 0.3  # Seconds between damage instances
@export var detection_radius: float = 8.0  # How close to detect player

var damage_area: Area2D
var last_damage_time: float = -999.0  # Start ready to damage
var overlapping_hurtboxes: Array[HurtboxComponent] = []


func _ready() -> void:
	# Create Area2D for collision detection
	damage_area = Area2D.new()
	damage_area.collision_layer = 0
	damage_area.collision_mask = CollisionLayers.PLAYER_HURTBOX
	add_child(damage_area)
	
	# Create collision shape
	var shape = CircleShape2D.new()
	shape.radius = detection_radius
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	damage_area.add_child(collision_shape)
	
	# Connect signals
	damage_area.area_entered.connect(_on_area_entered)
	damage_area.area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D) -> void:
	# Check if it's a hurtbox
	if area is HurtboxComponent:
		var hurtbox := area as HurtboxComponent
		if not overlapping_hurtboxes.has(hurtbox):
			overlapping_hurtboxes.append(hurtbox)


func _on_area_exited(area: Area2D) -> void:
	# Remove from tracking when it exits
	if area is HurtboxComponent:
		overlapping_hurtboxes.erase(area)


func _process(_delta: float) -> void:
	# Check if enough time has passed since last damage
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_damage_time < damage_cooldown:
		return
	
	# Damage all overlapping hurtboxes
	for hurtbox in overlapping_hurtboxes:
		if is_instance_valid(hurtbox):
			hurtbox.receive_hit(damage_amount, 0.0)
			last_damage_time = current_time
			emit_signal("damage_dealt", hurtbox.get_parent(), damage_amount)
			break  # Only damage one per cooldown cycle


func reset_cooldown() -> void:
	"""Reset cooldown to allow immediate damage."""
	last_damage_time = -999.0
