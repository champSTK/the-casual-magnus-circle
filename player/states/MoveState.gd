## MoveState.gd
extends PlayerState

func physics_update(delta: float) -> void:
	var dir: Vector2 = player.get_move_input()
	if dir == Vector2.ZERO:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, player.move_speed * 8.0 * delta)
		if player.velocity.length() < 5.0:
			state_machine.transition_to("IdleState")
	else:
		player.velocity = dir * player.move_speed

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			state_machine.transition_to("DrawingState")
