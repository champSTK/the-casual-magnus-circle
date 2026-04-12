## WaveManager.gd  (FINAL — fully typed)
## Spawns waves, assigns offset targets, runs separation, scales difficulty.

extends Node

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)

var enemy_container: Node2D          = null
var player:          CharacterBody2D = null

@export var base_enemy_count:     int   = 4
@export var enemies_per_wave:     int   = 2
@export var wave_delay:           float = 3.5
@export var arena_spawn_radius:   float = 200.0

@export var offset_radius:        float = 65.0
@export var separation_radius:    float = 50.0
@export var separation_strength:  float = 130.0
@export var hp_scale_per_wave:    float = 0.12
@export var speed_scale_per_wave: float = 0.06

var current_wave:   int   = 0
var _between_waves: bool  = true
var _wave_timer:    float = 2.0

var _scene_chaser: PackedScene = preload("res://enemies/Chaser.tscn")
var _scene_ranged: PackedScene = preload("res://enemies/Ranged.tscn")
var _scene_tank:   PackedScene = preload("res://enemies/Tank.tscn")

func _process(delta: float) -> void:
	if _between_waves:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_spawn_wave()
	else:
		_run_separation_pass()
		_check_wave_cleared()

func _spawn_wave() -> void:
	current_wave   += 1
	_between_waves  = false
	wave_started.emit(current_wave)
	var count: int = base_enemy_count + (current_wave - 1) * enemies_per_wave
	for i: int in range(count):
		var scene: PackedScene = _pick_enemy_scene()
		var enemy: EnemyBase   = _instantiate_enemy(scene)
		_configure_enemy(enemy, i, count)
	print("[WaveManager] Wave %d — %d enemies" % [current_wave, count])

func _pick_enemy_scene() -> PackedScene:
	if current_wave == 1:
		return _scene_chaser
	if current_wave == 2:
		var pool: Array[PackedScene] = [_scene_chaser, _scene_ranged]
		return pool[randi() % 2]
	var roll: int = randi() % 100
	if roll < 50:
		return _scene_chaser
	elif roll < 78:
		return _scene_ranged
	else:
		return _scene_tank

func _instantiate_enemy(scene: PackedScene) -> EnemyBase:
	var enemy: EnemyBase = scene.instantiate() as EnemyBase
	enemy_container.add_child(enemy)
	return enemy

func _configure_enemy(enemy: EnemyBase, index: int, total: int) -> void:
	enemy.player = player
	enemy.died.connect(_on_enemy_died)

	var angle: float = (float(index) / float(total)) * TAU + randf_range(-0.25, 0.25)
	var dist: float  = arena_spawn_radius * randf_range(0.80, 1.0)
	enemy.global_position = Vector2(cos(angle), sin(angle)) * dist

	var off_angle: float = (float(index) / float(total)) * TAU
	var off_dist: float  = randf_range(offset_radius * 0.3, offset_radius)
	enemy.set_target_offset(Vector2(cos(off_angle), sin(off_angle)) * off_dist)

	var wave_mult: float  = 1.0 + float(current_wave - 1) * hp_scale_per_wave
	enemy.max_hp          = int(float(enemy.max_hp) * wave_mult)
	enemy.current_hp      = enemy.max_hp
	enemy.move_speed     *= 1.0 + float(current_wave - 1) * speed_scale_per_wave

func _run_separation_pass() -> void:
	var children: Array[Node] = []
	children.assign(enemy_container.get_children())
	var count: int = children.size()
	for i: int in range(count):
		var a: EnemyBase = children[i] as EnemyBase
		if not a:
			continue
		for j: int in range(i + 1, count):
			var b: EnemyBase = children[j] as EnemyBase
			if not b:
				continue
			var delta_v: Vector2 = a.global_position - b.global_position
			var dist: float      = delta_v.length()
			if dist < separation_radius and dist > 0.5:
				var strength: float  = (separation_radius - dist) / separation_radius
				var push: Vector2    = delta_v.normalized() * strength * separation_strength
				a._separation_force += push
				b._separation_force -= push

func _check_wave_cleared() -> void:
	if enemy_container.get_child_count() == 0:
		_between_waves = true
		_wave_timer    = wave_delay
		wave_cleared.emit(current_wave)
		print("[WaveManager] Wave %d cleared. Next in %.1fs" % [current_wave, wave_delay])

func _on_enemy_died(_enemy: Node) -> void:
	pass
