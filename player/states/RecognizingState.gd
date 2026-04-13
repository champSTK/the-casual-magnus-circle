## RecognizingState.gd
extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	var gesture_name: String = player.gesture_recognizer.recognize()

	# 🔥 GET DRAW POSITION BEFORE CLEARING
	var draw_pos: Vector2 = player.gesture_recognizer.get_draw_center()

	player.gesture_recognizer.clear()

	if gesture_name != "":
		state_machine.transition_to("CastingState", {
			"gesture": gesture_name,
			"draw_pos": draw_pos   # 🔥 PASS IT HERE
		})
	else:
		state_machine.transition_to("IdleState")
