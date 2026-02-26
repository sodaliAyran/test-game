class_name CollisionLayers

## Collision layer constants for the project.
## Each value is a bitmask (power of 2) corresponding to a Godot physics layer.

# Body layers (CharacterBody2D)
const ENEMY_BODY = 2        # Layer 2

# Damage layers
const PLAYER_HITBOX = 4     # Layer 3
const ENEMY_HITBOX = 8      # Layer 4
const PLAYER_HURTBOX = 16   # Layer 5
const ENEMY_HURTBOX = 32    # Layer 6

# Collectibles
const COLLECTIBLE = 64      # Layer 7
const COLLECTION_AREA = 128 # Layer 8
