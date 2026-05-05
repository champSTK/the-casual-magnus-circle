extends Control

@onready var music_slider = $VBoxContainer/MusicSlider
@onready var sfx_slider = $VBoxContainer/SFXSlider

func _ready():
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	load_settings()
	
	
func _on_music_changed(value: float):
	var bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	save_settings()
		
		
func _on_sfx_changed(value: float):
	var bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	save_settings()
	
			
func linear_to_db(value: float) -> float:
	if value <= 0.01:
		return -80   # silence
	return lerp(-30, 0, value)	


func load_settings():
	var config = ConfigFile.new()

	if config.load("user://settings.cfg") == OK:
		music_slider.value = config.get_value("audio", "music", 1.0)
		sfx_slider.value = config.get_value("audio", "sfx", 1.0)

func save_settings():
	var config = ConfigFile.new()

	config.set_value("audio", "music", music_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)

	config.save("user://settings.cfg")

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
