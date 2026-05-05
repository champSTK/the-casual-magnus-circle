## CastingState.gd
extends PlayerState

const CAST_ANIM_TIME: float = 0.12

func enter(data: Dictionary = {}) -> void:
	var gesture: String = data.get("gesture", "") as String
	if gesture == "":
		state_machine.transition_to("IdleState")
		return
	var draw_pos: Vector2 = data.get("draw_pos", player.global_position)
	var draw_end: Vector2 = data.get("draw_end", draw_pos)
	player.spell_manager.cast(gesture, draw_pos,draw_end)
	player.sprite.modulate = Color(1.0, 0.9, 0.2)
	player.velocity     = Vector2.ZERO
	await player.get_tree().create_timer(CAST_ANIM_TIME).timeout
	player.sprite.modulate = Color(1, 1, 1)
	state_machine.transition_to("IdleState")
