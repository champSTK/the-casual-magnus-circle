extends Node2D

@onready var label: Label = $Label

func setup(amount: int):
	label.text = "+"

	# random slight offset (optional)
	position += Vector2(randf_range(-10, 10), randf_range(-10, 10))

	# animation
	var tween = create_tween()

	tween.tween_property(self, "position:y", position.y - 20, 0.6)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.6)

	tween.tween_callback(queue_free)
