## CastingState.gd
extends PlayerState

const CAST_ANIM_TIME: float = 0.12

func enter(data: Dictionary = {}) -> void:
	var gesture: String = data.get("gesture", "") as String
	if gesture == "":
		state_machine.transition_to("IdleState")
		return
	var draw_pos: Vector2 = data.get("draw_pos", player.global_position)
	player.spell_manager.cast(gesture, draw_pos)
	player.visual.color = Color(1.0, 0.9, 0.2)
	player.velocity     = Vector2.ZERO
	await player.get_tree().create_timer(CAST_ANIM_TIME).timeout
	player.visual.color = Color(0.3, 0.7, 1.0)
	var cd: float = player.spell_manager.get_cooldown(gesture)
	state_machine.transition_to("CooldownState", {"duration": cd})
