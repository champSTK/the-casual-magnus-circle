extends Control

@onready var score_label = $CenterContainer/VBoxContainer/ScoreLabel

func show_game_over(score: int):
	visible = true
	modulate.a = 0.0
	
	score_label.text = "Score: %d" % score
	
	scale = Vector2(0.9, 0.9)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.25)




func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Menus/MainMenu.tscn")
