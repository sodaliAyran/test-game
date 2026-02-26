class_name SkillLevelData
extends Resource

## Per-level configuration for a skill

@export var level: int = 1
@export_multiline var description: String = ""

## Stat modifiers (additive bonuses PER LEVEL)
@export_group("Stat Bonuses")
@export var damage_bonus: float = 0.0        ## +0.1 = +10% damage
@export var speed_bonus: float = 0.0         ## +0.1 = +10% attack speed
@export var size_bonus: float = 0.0          ## +0.1 = +10% attack size
@export var cooldown_reduction: float = 0.0  ## +0.04 = 4% faster cooldown

## Passive bonuses
@export_group("Passive Bonuses")
@export var health_bonus: int = 0             ## Flat HP increase
@export var magnet_radius_bonus: float = 0.0  ## Flat radius increase
@export var drop_chance_bonus: float = 0.0    ## +0.05 = +5% drop chance
@export var extra_drops: int = 0              ## Additional drops per trigger
@export var stun_duration_bonus: float = 0.0  ## Extra stun seconds on enemies
@export var down_duration_bonus: float = 0.0  ## Extra down seconds on enemies

## Feature flags - unlocked at this level
@export_group("Features")
@export var feature_flags: Array[String] = []

## Multi-hit override (0 = no change from previous level)
@export var multi_hit_count: int = 0
@export var attack_directions: Array[float] = []
