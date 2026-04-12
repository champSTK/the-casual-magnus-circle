## Ranged.gd
## Keeps preferred distance from player, shoots projectiles on a timer.

extends EnemyBase

@export var preferred_distance: float = 260.0
@export var shoot_interval:     float = 2.0
@export var projectile_speed:   float = 220.0
@export var projectile_damage:  int   = 8

var _shoot_timer: float = 0.5

func _ready() -> void:
	max_hp      = 20
	move_speed  = 75.0
	damage      = 5
	body_color  = Color(0.2, 0.55, 0.9)
	score_value = 15
	super._ready()

func _physics_process(delta: float) -> void:
	_shoot_timer -= delta
	if _shoot_timer <= 0.0 and player:
		_shoot()
		_shoot_timer = shoot_interval
	super._physics_process(delta)

func compute_velocity(_delta: float) -> Vector2:
	var dist: float  = get_distance_to_player()
	var dir: Vector2 = get_player_direction()
	if dist < preferred_distance - 30.0:
		return -dir * move_speed
	elif dist > preferred_distance + 50.0:
		return dir * move_speed * 0.6
	else:
		return dir.rotated(PI / 2.0) * move_speed * 0.4

func _shoot() -> void:
	if not player:
		return
	var container_node: Node = get_tree().current_scene.get_node_or_null("SpellContainer")
	if not container_node:
		return
	var proj: Node   = preload("res://enemies/EnemyProjectile.tscn").instantiate()
	container_node.add_child(proj)
	proj.global_position = global_position
	var dir: Vector2     = get_player_direction().rotated(randf_range(-0.15, 0.15))
	proj.setup(dir, projectile_speed, projectile_damage, Color(0.3, 0.7, 1.0), 2.5, 6.0)
