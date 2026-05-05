## DamageNumber.gd
## Short-lived floating label showing damage dealt.
## Scene: Label (root node, this script attached)

extends Label

@export var float_speed:  float = 60.0
@export var lifetime:     float = 0.7
@export var rise_height:  float = 40.0

func _ready() -> void:
	z_index = 10
	add_theme_font_size_override("font_size", 18)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - rise_height, lifetime)
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free).set_delay(lifetime)

func setup(amount: int, color: Color = Color.WHITE) -> void:
	text         = "-%d" % amount
	modulate     = color
	pivot_offset = size / 2.0
