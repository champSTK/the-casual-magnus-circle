## IdleState.gd
extends PlayerState



func enter(_data: Dictionary = {}) -> void:
	player.velocity = Vector2.ZERO
	player.play_animation("idle")

func physics_update(_delta: float) -> void:
	var dir: Vector2 = player.get_move_input()
	if dir != Vector2.ZERO:
		state_machine.transition_to("MoveState")

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			state_machine.transition_to("DrawingState")
