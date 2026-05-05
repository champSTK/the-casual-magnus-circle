## WaveManager.gd  (FINAL — fully typed)
## Spawns waves, assigns offset targets, runs separation, scales difficulty.

extends Node

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
var _wave_active: bool = false

var enemy_container: Node2D          = null
var player:          CharacterBody2D = null
var active_enemies: Array[EnemyBase] = []

@export var base_enemy_count:     int   = 4
@export var enemies_per_wave:     int   = 2
@export var wave_delay:           float = 3.5
@export var arena_spawn_radius:   float = 200.0

@export var offset_radius:        float = 65.0
@export var separation_radius:    float = 50.0
@export var separation_strength:  float = 130.0
#@export var hp_scale_per_wave:    float = 0.12
#@export var speed_scale_per_wave: float = 0.06
@onready var pool = $"../ObjectPool"


var current_wave:   int   = 0
var _between_waves: bool  = true
var _wave_timer:    float = 2.0



var _scene_chaser: PackedScene = preload("res://enemies/Chaser.tscn")
var _scene_ranged: PackedScene = preload("res://enemies/Ranged.tscn")
var _scene_tank:   PackedScene = preload("res://enemies/Tank.tscn")

func _process(delta: float) -> void:
	#print("Timer:", _wave_timer, "Between:", _between_waves)
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
	_wave_active    = true
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
		var enemy_pool: Array[PackedScene] = [_scene_chaser, _scene_ranged]
		return enemy_pool[randi() % 2]
	var roll: int = randi() % 100
	if roll < 50:
		return _scene_chaser
	elif roll < 78:
		return _scene_ranged
	else:
		return _scene_tank

func _instantiate_enemy(scene: PackedScene) -> EnemyBase:
	var enemy: EnemyBase = pool.get_object(scene)
	if enemy.get_parent():
		enemy.get_parent().remove_child(enemy)

	enemy_container.add_child(enemy)

	enemy.pool_owner = pool
	enemy.pool_scene = scene

	return enemy

func _configure_enemy(enemy: EnemyBase, index: int, total: int) -> void:
	var angle: float = (float(index) / float(total)) * TAU + randf_range(-0.25, 0.25)
	var dist: float  = arena_spawn_radius * randf_range(0.80, 1.0)
	var spawn_pos = Vector2(cos(angle), sin(angle)) * dist
	if not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)
	if not enemy.activated.is_connected(_on_enemy_activated):
		enemy.activated.connect(_on_enemy_activated)

	if not enemy.deactivated.is_connected(_on_enemy_deactivated):
		enemy.deactivated.connect(_on_enemy_deactivated)
	enemy.activate(spawn_pos, player)
	var off_angle: float = (float(index) / float(total)) * TAU
	var off_dist: float  = randf_range(offset_radius * 0.3, offset_radius)
	enemy.set_target_offset(Vector2(cos(off_angle), sin(off_angle)) * off_dist)

	#var wave_mult: float  = 1.0 + float(current_wave - 1) * hp_scale_per_wave
	#enemy.max_hp          = int(float(enemy.max_hp) * wave_mult)
	#enemy.current_hp      = enemy.max_hp
	#enemy.move_speed     *= 1.0 + float(current_wave - 1) * speed_scale_per_wave

#func _run_separation_pass() -> void:
	#var children = active_enemies
	#var count: int = children.size()
	#var radius_sq = separation_radius * separation_radius
#
	#for i in range(count):
		#var a: EnemyBase = children[i]
		#if not a:
			#continue
#
		#for j in range(i + 1, count):
			#var b: EnemyBase = children[j]
			#if not b:
				#continue
#
			#var delta_v = a.global_position - b.global_position
			#var dist_sq = delta_v.length_squared()
			#if dist_sq> radius_sq:
				#continue
#
			#if dist_sq < radius_sq and dist_sq > 0.25:
				#var strength = (radius_sq - dist_sq) / radius_sq
				#var push = delta_v.normalized() * strength * separation_strength
				#a._separation_force += push
				#b._separation_force -= push
				
func _run_separation_pass() -> void:
	var children: Array[EnemyBase] = active_enemies
	var cell_size: float = separation_radius

	# 🔹 Build spatial grid
	var grid := {}

	for e in children:
		if not is_instance_valid(e):
			continue

		var cell := Vector2i(
			int(e.global_position.x / cell_size),
			int(e.global_position.y / cell_size)
		)

		if not grid.has(cell):
			grid[cell] = []

		grid[cell].append(e)

	# 🔹 Check neighbors only in nearby cells
	for e in children:
		if not is_instance_valid(e):
			continue

		var force := Vector2.ZERO
		var neighbor_count := 0

		var base_cell := Vector2i(
			int(e.global_position.x / cell_size),
			int(e.global_position.y / cell_size)
		)

		# Check 9 cells (current + neighbors)
		for x in range(-1, 2):
			for y in range(-1, 2):
				var cell := base_cell + Vector2i(x, y)

				if not grid.has(cell):
					continue

				for other in grid[cell]:
					if other == e:
						continue

					var offset: Vector2 = e.global_position - other.global_position
					var dist_sq: float = offset.length_squared()

					if dist_sq > separation_radius * separation_radius or dist_sq < 0.001:
						continue

					var dist := sqrt(dist_sq)

					# 🔥 smooth falloff
					var strength := (separation_radius - dist) / separation_radius
					strength *= strength

					force += (offset / dist) * strength
					neighbor_count += 1

		if neighbor_count > 0:
			force /= neighbor_count

		e._separation_force += force * separation_strength
				
func _check_wave_cleared() -> void:
	# 🔥 Don't run before first wave
	if not _wave_active:
		return

	#var alive := 0
	
	#for e in enemy_container.get_children():
		#if e is EnemyBase and not e._is_dead:
			#alive += 1

	if active_enemies.size() == 0:
		print("WAVE CLEARED")
		_wave_active   = false
		_between_waves = true
		_wave_timer    = wave_delay
		wave_cleared.emit(current_wave)
		
func _on_enemy_activated(e):
	if not active_enemies.has(e):
		active_enemies.append(e)

func _on_enemy_deactivated(e):
	active_enemies.erase(e)

func _on_enemy_died(_enemy: Node) -> void:
	pass
