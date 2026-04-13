## EnemyBase.gd  (FINAL — fully typed)
## Base class for all enemies.

extends CharacterBody2D
class_name EnemyBase

signal died(enemy)

@export var max_hp:          int   = 30
@export var move_speed:      float = 90.0
@export var damage:          int   = 10
@export var contact_rate:    float = 1.0
@export var score_value:     int   = 10
@export var body_color:      Color = Color(0.9, 0.2, 0.2)
@export var arena_half_size: float = 480.0

@onready var visual:  ColorRect = $Visual
@onready var hp_bar:  ColorRect = $HPBar
@onready var hp_fill: ColorRect = $HPBar/Fill

var current_hp:         int             = max_hp
var player:             CharacterBody2D = null
var _contact_timer:     float           = 0.0
var _is_dead:           bool            = false
var _separation_force:  Vector2         = Vector2.ZERO
var _target_offset:     Vector2         = Vector2.ZERO

var target_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	current_hp     = max_hp
	visual.color   = body_color
	hp_bar.visible = false
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if _is_dead or not player:
		return
	var desired: Vector2 = compute_velocity(delta)
	velocity              = desired + _separation_force
	_separation_force     = Vector2.ZERO
	move_and_slide()
	_clamp_to_arena()
	_contact_timer -= delta
	if _contact_timer <= 0.0:
		_check_contact_damage()
		_contact_timer = contact_rate

func compute_velocity(_delta: float) -> Vector2:
	return Vector2.ZERO

func take_damage(amount: int) -> void:
	if _is_dead:
		return
	current_hp -= amount
	_update_hp_bar()
	_flash()
	_spawn_damage_number(amount)
	if current_hp <= 0:
		_die()

func _check_contact_damage() -> void:
	if not player:
		return
	if global_position.distance_to(player.global_position) < 36.0:
		if player.has_method("take_damage"):
			player.take_damage(damage)

func _die() -> void:
	_is_dead = true
	died.emit(self)
	var main: Node = get_node_or_null("/root/Main")
	if main and main.has_method("add_score"):
		main.add_score(score_value)
	_spawn_death_particles()
	queue_free()

func _flash() -> void:
	var orig: Color = visual.color
	visual.color    = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(self):
		visual.color = orig

func _update_hp_bar() -> void:
	hp_bar.visible   = true
	var ratio: float = float(current_hp) / float(max_hp)
	hp_fill.size.x   = hp_bar.size.x * clampf(ratio, 0.0, 1.0)
	hp_fill.color    = Color(1.0 - ratio, ratio * 0.8, 0.1)

func _spawn_damage_number(amount: int) -> void:
	var dn_scene: PackedScene = load("res://systems/DamageNumber.tscn") as PackedScene
	if not dn_scene:
		return
	var dn: Node = dn_scene.instantiate()
	get_tree().current_scene.add_child(dn)
	dn.global_position = global_position + Vector2(randf_range(-12.0, 12.0), -20.0)
	if dn.has_method("setup"):
		dn.setup(amount, Color(1.0, 0.9, 0.3))

func _spawn_death_particles() -> void:
	for _i: int in range(6):
		var dot: ColorRect  = ColorRect.new()
		get_tree().current_scene.add_child(dot)
		dot.size            = Vector2(6.0, 6.0)
		dot.color           = body_color
		dot.global_position = global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
		var target: Vector2 = dot.global_position + Vector2(randf_range(-50.0, 50.0), randf_range(-60.0, -10.0))
		var tween: Tween    = dot.create_tween()
		tween.set_parallel(true)
		tween.tween_property(dot, "global_position", target, 0.4)
		tween.tween_property(dot, "modulate:a", 0.0, 0.4)
		tween.tween_callback(dot.queue_free).set_delay(0.4)

func _clamp_to_arena() -> void:
	global_position.x = clampf(global_position.x, -arena_half_size, arena_half_size)
	global_position.y = clampf(global_position.y, -arena_half_size, arena_half_size)

func get_player_direction() -> Vector2:
	if not player:
		return Vector2.ZERO
	return (player.global_position - global_position).normalized()

func get_distance_to_player() -> float:
	if not player:
		return INF
	return global_position.distance_to(player.global_position)

func get_offset_target() -> Vector2:
	if not player:
		return global_position
	return player.global_position + _target_offset

func set_target_offset(offset: Vector2) -> void:
	_target_offset = offset
