## Player.gd  (FINAL — explicit types)
## Top-down player controller. All behaviour delegated to StateMachine.

extends CharacterBody2D

signal died
signal hp_changed(current_hp: int)

@export var move_speed:      float = 220.0
@export var max_hp:          int   = 100
@export var invincible_time: float = 0.6

@onready var state_machine:      Node             = $StateMachine
@onready var gesture_recognizer: Node             = $GestureRecognizer
@onready var gesture_canvas:     Node2D           = $GestureCanvas
@onready var spell_manager:      Node             = $SpellManager
@onready var collision_shape: CollisionShape2D    = $CollisionShape2D
@onready var visual:          ColorRect           = $Visual

var current_hp:      int    = max_hp
var is_invincible:   bool   = false
var spell_container: Node2D = null
var shield_instance: Node2D = null
var is_shielded: bool = false
var shield_broken: bool = false

func _ready() -> void:
	current_hp = max_hp
	add_to_group("player")
	spell_manager.player = self

func _physics_process(_delta: float) -> void:
	move_and_slide()

func _input(event):
	state_machine._unhandled_input(event)


func get_move_input() -> Vector2:
	return Vector2(
		Input.get_axis("ui_left",  "ui_right"),
		Input.get_axis("ui_up",    "ui_down")
	).normalized()

func take_damage(amount: int) -> void:
	if is_invincible:
		return
		
	if is_shielded:
		shield_broken = true   # mark shield as broken
		is_shielded = false
		print("brokes")
		if is_instance_valid(shield_instance):
			shield_instance.queue_free()
			shield_instance = null
		return
	current_hp -= amount
	hp_changed.emit(current_hp)
	
	_flash_damage()
	CameraFollow.trigger_shake(self, 6.0)
	if current_hp <= 0:
		current_hp = 0
		died.emit()
		return
	is_invincible = true
	await get_tree().create_timer(invincible_time).timeout
	is_invincible = false

func activate_shield(duration: float) -> void:
	if is_shielded:
		return

	is_shielded = true
	shield_broken = false

	# 🔥 spawn and STORE shield
	var shield_scene = preload("res://spells/ShieldEffect.tscn")
	shield_instance = shield_scene.instantiate()
	add_child(shield_instance)
	
	await get_tree().create_timer(duration).timeout
	# 🔥 if already broken → do nothing
	if not is_shielded:
		return

	is_shielded = false

	# 🔥 REMOVE VISUAL
	if is_instance_valid(shield_instance):
		shield_instance.queue_free()
		shield_instance = null

	if not shield_broken:
		heal(20)

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp)
	var heal_scene = preload("res://systems/HealText.tscn")
	var heal_text = heal_scene.instantiate()

	heal_text.global_position = global_position
	get_parent().add_child(heal_text)

	heal_text.setup(amount)

func _flash_damage() -> void:
	var orig: Color = visual.color
	visual.color    = Color.RED
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		visual.color = orig

func set_cast_color(color: Color) -> void:
	visual.color = color

func reset_color() -> void:
	visual.color = Color(0.3, 0.7, 1.0)

func _draw() -> void:
	var mouse_local: Vector2 = get_local_mouse_position().normalized() * 20.0
	var perp: Vector2        = mouse_local.rotated(PI / 2.0).normalized() * 5.0
	draw_colored_polygon(
		PackedVector2Array([mouse_local, -mouse_local * 0.3 + perp, -mouse_local * 0.3 - perp]),
		Color(1.0, 1.0, 1.0, 0.6)
	)

func _process(_delta: float) -> void:
	queue_redraw()
