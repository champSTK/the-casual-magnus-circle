extends Control


func show_menu():
	visible = true
	modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	scale = Vector2(0.9, 0.9)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2)
	
func hide_menu():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	visible = false

func resume():
	get_tree().paused = false
	hide_menu()

func restart():
	get_tree().paused = false
	get_tree().reload_current_scene()

func quit_to_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide_menu()
	
func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	
func _on_quit_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Menus/MainMenu.tscn")
