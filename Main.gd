## Main.gd — Root scene controller.

extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var enemy_container: Node2D = $EnemyContainer
@onready var spell_container: Node2D = $SpellContainer
@onready var wave_manager: Node      = $WaveManager
@onready var hud_label: Label        = $HUD/Label
@onready var game_over_label: Label  = $HUD/GameOverLabel
@onready var pause_menu = $HUD/PauseMenu

var score: int       = 0
var is_game_over: bool = false

func _ready() -> void:
	wave_manager.enemy_container = enemy_container
	wave_manager.player          = player
	wave_manager.wave_started.connect(_on_wave_started)
	player.died.connect(_on_player_died)
	player.spell_container = spell_container
	game_over_label.visible = false
	update_hud()

func _process(_delta: float) -> void:
	if is_game_over:
		return
	update_hud()

func update_hud() -> void:
	hud_label.text = "HP: %d  |  Wave: %d  |  Score: %d" % [
		player.current_hp,
		wave_manager.current_wave,
		score
	]

func add_score(amount: int) -> void:
	score += amount

func _on_wave_started(wave_number: int) -> void:
	print("Wave %d started!" % wave_number)

func _on_player_died() -> void:
	is_game_over            = true
	game_over_label.visible = true
	game_over_label.text    = "GAME OVER\nScore: %d\nPress Enter to restart" % score
	get_tree().paused       = true
	set_process_input(true)

func toggle_pause():
	get_tree().paused = not get_tree().paused
	
	if get_tree().paused:
		pause_menu.show_menu()
	else:
		pause_menu.visible = false

func _input(event: InputEvent) -> void:
	if is_game_over and event.is_action_pressed("ui_accept"):
		print("done")
		get_tree().paused = false
		get_tree().reload_current_scene()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and not is_game_over:
		toggle_pause()
