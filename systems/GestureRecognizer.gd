extends Node

const DEBUG = true

var _points: Array[Vector2] = []

# ── INPUT ─────────────────────────────

func start_drawing(pos: Vector2):
	_points.clear()
	_points.append(pos)

func add_point(pos: Vector2):
	if _points.is_empty():
		return
	
	if pos.distance_to(_points[-1]) > 5:
		_points.append(pos)

func clear():
	_points.clear()

# ── MAIN RECOGNITION ──────────────────

func recognize() -> String:
	if _points.size() < 5:
		return ""

	var start: Vector2 = _points[0]
	var end: Vector2 = _points[-1]

	var total_len: float = _path_length(_points)
	var direct_len: float = start.distance_to(end)

	var closure: float = start.distance_to(end)
	var turns: int = _count_direction_changes(_points)
	var rotation: float = _total_rotation(_points)

	if DEBUG:
		print("len:", total_len, " direct:", direct_len, " closure:", closure, " turns:", turns, " rot:", rotation)

	# ── CIRCLE ───────────────────────
	if total_len <2000 and closure < 200 and rotation > 6.0 and turns == 0:
		return "circle"
		
	# ── LINE ─────────────────────────
	if total_len <1000 and direct_len > 100 and turns <= 1:
		return "line"

	# ── TRIANGLE ─────────────────────
	if total_len >1200 and closure < 310 and turns > 2 and turns <= 4:
		return "triangle"

	# ── ZIGZAG ───────────────────────
	if turns == 4 or turns ==5:
		return "zigzag"

	# ── SCRIBBLE ─────────────────────
	if total_len > 4000:
		return "scribble"
	
	return ""

# ── HELPERS ──────────────────────────

func _path_length(points: Array[Vector2]) -> float:
	var len: float = 0.0
	for i in range(1, points.size()):
		len += points[i - 1].distance_to(points[i])
	return len

func _count_direction_changes(points: Array[Vector2]) -> int:
	var changes: int = 0

	for i in range(2, points.size()):
		var a = (points[i - 1] - points[i - 2]).normalized()
		var b = (points[i] - points[i - 1]).normalized()

		if a.length() < 0.01 or b.length() < 0.01:
			continue

		var dot = a.dot(b)

		# sharp turn
		if dot < 0.5:
			changes += 1

	return changes

func _total_rotation(points: Array[Vector2]) -> float:
	var total: float = 0.0

	for i in range(2, points.size()):
		var a = (points[i - 1] - points[i - 2])
		var b = (points[i] - points[i - 1])

		if a.length() < 0.01 or b.length() < 0.01:
			continue

		var angle = atan2(a.cross(b), a.dot(b))
		total += angle

	return abs(total)
