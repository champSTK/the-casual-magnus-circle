## GestureCanvas.gd
## Draws the gesture trail using _draw(). Attach as child of Player.

extends Node2D

const LINE_COLOR:  Color = Color(0.4, 0.9, 1.0, 0.85)
const LINE_WIDTH:  float = 3.0
const FADE_TIME:   float = 0.35
const DOT_RADIUS:  float = 4.0

var _points:     Array[Vector2] = []
var _is_drawing: bool           = false
var _fade_alpha: float          = 1.0
var _fading:     bool           = false

func start_drawing() -> void:
	_points.clear()
	_is_drawing = true
	_fading     = false
	_fade_alpha = 1.0
	queue_redraw()

func add_point(screen_pos: Vector2) -> void:
	_points.append(screen_pos)
	queue_redraw()

func stop_drawing() -> void:
	_is_drawing = false
	_fading     = true

func _process(delta: float) -> void:
	if _fading:
		_fade_alpha -= delta / FADE_TIME
		if _fade_alpha <= 0.0:
			_fade_alpha = 0.0
			_fading     = false
			_points.clear()
		queue_redraw()

func _draw() -> void:
	if _points.size() < 2:
		return
	var color: Color = Color(LINE_COLOR.r, LINE_COLOR.g, LINE_COLOR.b, LINE_COLOR.a * _fade_alpha)
	for i: int in range(1, _points.size()):
		var t: float = float(i) / float(_points.size())
		var w: float = LINE_WIDTH * t
		draw_line(_points[i - 1], _points[i], color, w, true)
	if _is_drawing and _points.size() > 0:
		draw_circle(_points[-1], DOT_RADIUS * _fade_alpha, color)
