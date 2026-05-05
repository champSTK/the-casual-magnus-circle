extends Control

@onready var icon = $Icon
@onready var cooldown_rect = $Cooldown

var max_cd := 1.0
var current_cd := 0.0

func set_cooldown(cd: float, max_cd_value: float):
	current_cd = max(cd, 0.0)
	max_cd = max_cd_value

func _process(_delta):
	if max_cd <= 0:
		return

	var ratio = current_cd / max_cd

	# 🔥 DARK OVERLAY
	cooldown_rect.scale.y = ratio

	# 🔥 ICON DARKEN
	if current_cd > 0:
		icon.modulate = Color(0.4, 0.4, 0.4)
	else:
		icon.modulate = Color(1,1,1)
