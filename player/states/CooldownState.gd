## CooldownState.gd
extends PlayerState

var _timer: float = 0.0

func enter(data: Dictionary = {}) -> void:
	_timer = data.get("duration", 0.8) as float

func update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.transition_to("IdleState")

func physics_update(_delta: float) -> void:
	var dir: Vector2 = player.get_move_input()
	player.velocity  = dir * player.move_speed if dir != Vector2.ZERO else Vector2.ZERO
