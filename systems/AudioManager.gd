extends Node

@export var max_players := 16

var players: Array[AudioStreamPlayer] = []

# enemy death spam control
var last_enemy_sound_time := 0.0
var enemy_sound_cooldown := 0.08
@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

# sounds (assign in inspector)
@export var snd_enemy_die_default: AudioStream
@export var snd_enemy_die_circle: AudioStream

@export var snd_spell_line: AudioStream
@export var snd_spell_circle: AudioStream
@export var snd_spell_lightning: AudioStream
@export var snd_spell_beam: AudioStream
@export var snd_spell_shield: AudioStream
@export var snd_spell_shieldbroken: AudioStream

@export var snd_player_hit: AudioStream
@export var snd_player_die: AudioStream
@export var music_main: AudioStream


func _ready():
	music_player.bus = "Music"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	music_player.volume_db = -12   # music should be quieter
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(max_players):
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		players.append(p)

func play_music(stream: AudioStream):
	if stream == null:
		return

	# 🔥 don't restart same music
	if music_player.stream == stream and music_player.playing:
		return

	music_player.stream = stream
	music_player.stream.loop = true
	music_player.play()

func play_sound(stream: AudioStream):
	if stream == null:
		return

	for p in players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = randf_range(0.95, 1.05)
			p.volume_db = randf_range(-9.0, -6.0)
			await get_tree().process_frame
			p.play()
			return

func play_enemy_die(stream: AudioStream):
	var now = Time.get_ticks_msec() / 1000.0

	if now - last_enemy_sound_time < enemy_sound_cooldown:
		return

	last_enemy_sound_time = now
	play_sound(stream)
