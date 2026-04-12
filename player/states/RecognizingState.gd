## RecognizingState.gd
extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	var gesture_name: String = player.gesture_recognizer.recognize()
	player.gesture_recognizer.clear()
	if gesture_name != "":
		state_machine.transition_to("CastingState", {"gesture": gesture_name})
	else:
		state_machine.transition_to("IdleState")
