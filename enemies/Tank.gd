## Tank.gd
## Slow, high HP. Periodically charges toward the player.

extends EnemyBase

@export var charge_speed:    float = 280.0
@export var charge_interval: float = 4.0
@export var charge_duration: float = 0.6
@export var charge_damage:   int   = 25

var _charge_timer:   float   = 2.0
var _charging:       bool    = false
var _charge_dir:     Vector2 = Vector2.ZERO
var _charge_elapsed: float   = 0.0

func _ready() -> void:
	max_hp      = 120
	move_speed  = 52.0
	damage      = 18
	body_color  = Color(0.55, 0.2, 0.7)
	score_value = 30
	super._ready()

func _physics_process(delta: float) -> void:
	if not _charging:
		_charge_timer -= delta
		if _charge_timer <= 0.0:
			_start_charge()
	else:
		_charge_elapsed += delta
		if _charge_elapsed >= charge_duration:
			_end_charge()
	super._physics_process(delta)

func compute_velocity(_delta: float) -> Vector2:
	if _charging:
		return _charge_dir * charge_speed
	return get_player_direction() * move_speed

func _start_charge() -> void:
	_charging       = true
	_charge_elapsed = 0.0
	_charge_dir     = get_player_direction()
	visual.color    = Color(1.0, 0.9, 1.0)

func _end_charge() -> void:
	_charging     = false
	_charge_timer = charge_interval
	visual.color  = body_color
