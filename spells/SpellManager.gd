## SpellManager.gd
## Central spell dispatcher. Called by CastingState with a gesture name.

extends Node

var player:    CharacterBody2D = null
var container: Node2D          = null

# Spell stats stored as typed structs via inner class
class SpellEntry:
	var damage:   int
	var cooldown: float
	var color:    Color
	func _init(dmg: int, cd: float, col: Color) -> void:
		damage   = dmg
		cooldown = cd
		color    = col

# Keyed by gesture name
var _spells: Dictionary = {}

# Per-spell cooldown tracking  (String -> float)
var _cooldowns: Dictionary = {}

func _ready() -> void:
	_spells["line"]     = SpellEntry.new(35, 0.4, Color(1.0, 0.8, 0.2))
	_spells["zigzag"]   = SpellEntry.new(15, 0.7, Color(0.2, 0.8, 1.0))
	_spells["triangle"] = SpellEntry.new(80, 1.2, Color(0.7, 0.3, 1.0))
	_spells["circle"]   = SpellEntry.new(50, 1.5, Color(1.0, 0.4, 0.2))
	_spells["scribble"] = SpellEntry.new(20, 1.0, Color(1.0, 0.2, 0.8))
	for key: String in _spells:
		_cooldowns[key] = 0.0

func _process(delta: float) -> void:
	for key: String in _cooldowns:
		var cd: float = _cooldowns[key] as float
		if cd > 0.0:
			_cooldowns[key] = cd - delta

# ── API ───────────────────────────────────────────────────────
func cast(gesture: String) -> void:
	if not _spells.has(gesture):
		return
	if (_cooldowns[gesture] as float) > 0.0:
		return
	var entry: SpellEntry = _spells[gesture] as SpellEntry
	_cooldowns[gesture]   = entry.cooldown
	print("Casting:", gesture)   
	
	match gesture:
		
		"line":     _cast_slash(entry)
		"zigzag":   _cast_spray(entry)
		"triangle": _cast_lightning(entry)
		"circle":   _cast_aoe(entry)
		"scribble": _cast_chaos(entry)

func get_cooldown(gesture: String) -> float:
	if not _spells.has(gesture):
		return 0.5
	return (_spells[gesture] as SpellEntry).cooldown

func is_on_cooldown(gesture: String) -> bool:
	return (_cooldowns.get(gesture, 0.0) as float) > 0.0

# ── Spell implementations ─────────────────────────────────────
func _cast_slash(entry: SpellEntry) -> void:
	var aim: Vector2           = _get_aim_direction()
	var angles: Array[float]   = [-30.0, -15.0, 0.0, 15.0, 30.0]
	for a: float in angles:
		var dir: Vector2 = aim.rotated(deg_to_rad(a))
		_spawn_projectile(player.global_position, dir, 550.0,
			entry.damage, entry.color, 0.18, 10.0, true)
	_screen_flash(entry.color, 0.1)
	CameraFollow.trigger_shake(player, 4.0)

func _cast_spray(entry: SpellEntry) -> void:
	var aim: Vector2 = _get_aim_direction()
	var count: int   = 5
	var spread: float = 40.0
	for i: int in range(count):
		var t: float   = float(i) / float(count - 1)
		var a: float   = (t - 0.5) * spread
		var dir: Vector2 = aim.rotated(deg_to_rad(a))
		_spawn_projectile(player.global_position, dir, 420.0,
			entry.damage, entry.color, 1.2, 7.0)
	_screen_flash(entry.color, 0.08)

func _cast_lightning(entry: SpellEntry) -> void:
	var target: Node = _find_nearest_enemy(800.0)
	if not target:
		return
	_spawn_lightning_arc(player.global_position, target.global_position, entry.color)
	if target.has_method("take_damage"):
		target.take_damage(entry.damage)
	_screen_flash(entry.color, 0.15)
	CameraFollow.trigger_shake(player, 8.0)

func _cast_aoe(entry: SpellEntry) -> void:
	var radius: float = 200.0
	_spawn_aoe_ring(player.global_position, radius, entry.color)
	var enemies: Array[Node] = _get_enemies_in_radius(player.global_position, radius)
	for enemy: Node in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(entry.damage)
	_screen_flash(entry.color, 0.2)
	CameraFollow.trigger_shake(player, 10.0)

func _cast_chaos(entry: SpellEntry) -> void:
	var count: int = 12
	for i: int in range(count):
		var angle: float = (float(i) / float(count)) * TAU + randf_range(-0.2, 0.2)
		var dir: Vector2 = Vector2.RIGHT.rotated(angle)
		_spawn_projectile(
			player.global_position, dir,
			randf_range(280.0, 480.0),
			entry.damage, entry.color,
			randf_range(0.8, 1.4),
			randf_range(5.0, 9.0)
		)
	_screen_flash(entry.color, 0.12)
	CameraFollow.trigger_shake(player, 6.0)

# ── Spawning helpers ──────────────────────────────────────────
func _spawn_projectile(
	pos:      Vector2,
	dir:      Vector2,
	speed:    float,
	damage:   int,
	color:    Color,
	lifetime: float,
	size:     float,
	piercing: bool = false
) -> void:
	var proj: Node = preload("res://spells/Projectile.tscn").instantiate()
	_get_container().add_child(proj)
	proj.global_position = pos
	proj.setup(dir, speed, damage, color, lifetime, size, piercing)

func _spawn_lightning_arc(from: Vector2, to: Vector2, color: Color) -> void:
	var line: Line2D = Line2D.new()
	_get_container().add_child(line)
	line.width         = 3.0
	line.default_color = color
	var pts: Array[Vector2] = [from]
	var segments: int       = 8
	for i: int in range(1, segments):
		var t: float     = float(i) / float(segments)
		var mid: Vector2 = from.lerp(to, t)
		mid += Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
		pts.append(mid)
	pts.append(to)
	line.points      = pts
	var tween: Tween = line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.35)
	tween.tween_callback(line.queue_free)

func _spawn_aoe_ring(center: Vector2, radius: float, color: Color) -> void:
	var count: int = 20
	for i: int in range(count):
		var angle: float  = (float(i) / float(count)) * TAU
		var dir: Vector2  = Vector2.RIGHT.rotated(angle)
		var seg: Line2D   = Line2D.new()
		_get_container().add_child(seg)
		seg.global_position = center
		seg.width           = 2.5
		seg.default_color   = color
		seg.points          = PackedVector2Array([dir * radius * 0.1, dir * radius])
		var tween: Tween    = seg.create_tween()
		tween.tween_property(seg, "modulate:a", 0.0, 0.4)
		tween.tween_callback(seg.queue_free)

# ── Utilities ─────────────────────────────────────────────────
func _get_aim_direction() -> Vector2:
	var mouse_world: Vector2 = player.get_global_mouse_position()
	var dir: Vector2         = (mouse_world - player.global_position).normalized()
	return dir if dir != Vector2.ZERO else Vector2.RIGHT

func _find_nearest_enemy(max_range: float) -> Node:
	var best_dist: float = max_range
	var best: Node       = null
	var c: Node          = player.get_node_or_null("/root/Main/EnemyContainer")
	if not c:
		return null
	for enemy: Node in c.get_children():
		if not enemy.has_method("take_damage"):
			continue
		var d: float = player.global_position.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best      = enemy
	return best

func _get_enemies_in_radius(center: Vector2, radius: float) -> Array[Node]:
	var result: Array[Node] = []
	var c: Node             = player.get_node_or_null("/root/Main/EnemyContainer")
	if not c:
		return result
	for enemy: Node in c.get_children():
		if not enemy.has_method("take_damage"):
			continue
		if center.distance_to(enemy.global_position) <= radius:
			result.append(enemy)
	return result

func _get_container() -> Node:
	if container:
		return container
	var c: Node = player.get_node_or_null("/root/Main/SpellContainer")
	container   = c
	return c if c else player

func _screen_flash(color: Color, duration: float) -> void:
	var flash: Node = player.get_node_or_null("/root/Main/HUD/FlashRect")
	if not flash:
		return
	var rect: ColorRect  = flash as ColorRect
	rect.color           = Color(color.r, color.g, color.b, 0.25)
	rect.visible         = true
	var tween: Tween     = rect.create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	tween.tween_callback(func() -> void:
		rect.visible    = false
		rect.modulate.a = 1.0
	)
