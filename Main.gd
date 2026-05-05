## Main.gd — Root scene controller.

extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var enemy_container: Node2D = $EnemyContainer
@onready var spell_container: Node2D = $SpellContainer
@onready var wave_manager: Node      = $WaveManager
@onready var hud_label: Label        = $HUD/Label
@onready var game_over_panel = $HUD/GameOverPanel
@onready var pause_menu = $HUD/PauseMenu
@onready var fps_label: Label = $HUD/FPSLabel
@onready var pool = $ObjectPool

var score: int       = 0
var is_game_over: bool = false
var fps_timer: float = 0.0
var fps_update_rate: float = 0.25
var show_fps: bool = true
var debug_timer := 0.0



func _ready() -> void:
	var audio = $AudioManager
	audio.play_music(audio.music_main)
	wave_manager.enemy_container = enemy_container
	wave_manager.player          = player
	wave_manager.wave_started.connect(_on_wave_started)
	player.died.connect(_on_player_died)
	player.spell_container = spell_container
	player.hp_changed.connect(_on_hp_changed)
	fps_label.visible = show_fps
	update_hud()

func _process(delta: float) -> void:
	if is_game_over:
		return
	fps_timer -= delta
	
	if fps_timer <= 0.0:
		var fps: int = Engine.get_frames_per_second()
		fps_label.text = "FPS: %d" % fps
		
		fps_timer = fps_update_rate
	debug_timer -= delta
	
	if debug_timer <= 0:
		_print_pool_debug()
		debug_timer = 1.0

func _print_pool_debug():
	if not pool:
		return
	
	print("\n--- POOL DEBUG ---")
	
	for scene in pool.pools.keys():
		var pooled = pool.pools[scene].size()
		var active = pool.active[scene].size()
		
		print(scene.resource_path.get_file(), 
			" | active:", active, 
			" | pooled:", pooled,
			"TOTAL:", pooled + active)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fps"):
		show_fps = not show_fps
		fps_label.visible = show_fps
	if is_game_over and event.is_action_pressed("ui_accept"):
		get_tree().paused = false
		get_tree().reload_current_scene()	

func update_hud() -> void:
	hud_label.text = "HP: %d  |  Wave: %d  |  Score: %d" % [
		player.current_hp,
		wave_manager.current_wave,
		score
	]

func add_score(amount: int) -> void:
	score += amount
	update_hud()

func _on_wave_started(wave_number: int) -> void:
	print("Wave %d started!" % wave_number)
	update_hud()
	
func _on_hp_changed(_hp: int) -> void:
	update_hud()

func _on_player_died() -> void:
	is_game_over = true
	
	get_tree().paused = true
	set_process_input(true)
	
	game_over_panel.show_game_over(score)

func toggle_pause():
	get_tree().paused = not get_tree().paused
	
	if get_tree().paused:
		pause_menu.show_menu()
	else:
		pause_menu.visible = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and not is_game_over:
		toggle_pause()


func _on_menu_button_pressed() -> void:
	pass # Replace with function body.
