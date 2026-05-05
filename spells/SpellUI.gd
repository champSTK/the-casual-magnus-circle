extends Control

@onready var spell_manager = get_node("/root/Main/Player/SpellManager")

var icons := {}

func _ready():
	# 🔥 auto map icons using names
	for child in $HBoxContainer.get_children():
		icons[child.name] = child
		
func _process(delta):
	for key in icons.keys():
		if not spell_manager._spells.has(key):
			continue

		var max_cd = spell_manager._spells[key].cooldown
		var current_cd = spell_manager._cooldowns[key]

		icons[key].set_cooldown(current_cd, max_cd)		
