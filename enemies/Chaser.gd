## Chaser.gd
## Fast melee enemy. Moves toward the player's offset target.

extends EnemyBase

func _ready() -> void:
	max_hp      = 30
	move_speed  = 115.0
	damage      = 12
	body_color  = Color(0.9, 0.25, 0.25)
	score_value = 10
	super._ready()

func compute_velocity(_delta: float) -> Vector2:
	var target: Vector2 = get_offset_target()
	var dir: Vector2    = (target - global_position).normalized()
	var dist: float     = global_position.distance_to(target)
	var speed: float    = move_speed if dist > 40.0 else move_speed * 0.3
	return dir * speed
