## DrawingState.gd
extends PlayerState

const SLOW_FACTOR: float = 0.3


func enter(_data: Dictionary = {}) -> void:
	print("DRAWING STATE ENTERED")
	player.gesture_recognizer.start_drawing(player.get_global_mouse_position())
	player.gesture_canvas.start_drawing()

func exit() -> void:
	player.gesture_canvas.stop_drawing()

func physics_update(_delta: float) -> void:
	var dir: Vector2 = player.get_move_input()
	player.velocity  = dir * player.move_speed * SLOW_FACTOR

func update(_delta: float) -> void:
	var mouse_pos: Vector2 = player.get_global_mouse_position()
	player.gesture_recognizer.add_point(mouse_pos)
	player.gesture_canvas.add_point(mouse_pos)

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			state_machine.transition_to("RecognizingState")
