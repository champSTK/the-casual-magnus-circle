extends Node2D

func _ready():
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0

	var tween = create_tween()

	# fade in + scale up
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)

	# pulse loop
	await tween.finished
	_pulse()

func _pulse():
	var tween = create_tween().set_loops()

	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.5)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
