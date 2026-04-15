extends CanvasLayer

@onready var main = get_parent()

func _input(event):
	if main.is_game_over and event.is_action_pressed("ui_accept"):
		get_tree().paused = false
		get_tree().reload_current_scene()	
