## Player.gd  (FINAL — explicit types)
## Top-down player controller. All behaviour delegated to StateMachine.

extends CharacterBody2D

signal died

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
	current_hp -= amount
	_flash_damage()
	CameraFollow.trigger_shake(self, 6.0)
	if current_hp <= 0:
		current_hp = 0
		died.emit()
		return
	is_invincible = true
	await get_tree().create_timer(invincible_time).timeout
	is_invincible = false

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)

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
