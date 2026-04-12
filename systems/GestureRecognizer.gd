## GestureRecognizer.gd
## Analyzes mouse positions and classifies the gesture into:
##   "line", "zigzag", "triangle", "circle", "scribble"

extends Node

const MIN_POINTS:      int   = 8
const RESAMPLE_COUNT:  int   = 32
const SAMPLE_DISTANCE: float = 6.0

var _raw_points: Array[Vector2] = []

# ── API ───────────────────────────────────────────────────────
func start_drawing(first_point: Vector2) -> void:
	_raw_points.clear()
	_raw_points.append(first_point)

func add_point(pos: Vector2) -> void:
	if _raw_points.is_empty():
		_raw_points.append(pos)
		return
	if pos.distance_to(_raw_points[-1]) >= SAMPLE_DISTANCE:
		_raw_points.append(pos)

func clear() -> void:
	_raw_points.clear()

func recognize() -> String:
	if _raw_points.size() < MIN_POINTS:
		return ""

	# _resample returns Array[Vector2] but typed as Array for scorer compat
	var pts: Array[Vector2] = _resample(_raw_points, RESAMPLE_COUNT)

	var score_circle:   float = _score_circle(pts)
	var score_triangle: float = _score_triangle(pts)
	var score_zigzag:   float = _score_zigzag(pts)
	var score_line:     float = _score_line(pts)
	var score_scribble: float = _score_scribble(pts)

	# Find best above threshold
	var best_name:  String = ""
	var best_score: float  = 0.5

	if score_circle > best_score:
		best_score = score_circle
		best_name  = "circle"
	if score_triangle > best_score:
		best_score = score_triangle
		best_name  = "triangle"
	if score_zigzag > best_score:
		best_score = score_zigzag
		best_name  = "zigzag"
	if score_line > best_score:
		best_score = score_line
		best_name  = "line"
	if score_scribble > best_score:
		best_score = score_scribble
		best_name  = "scribble"

	return best_name

# ── Scorers ───────────────────────────────────────────────────
func _score_circle(pts: Array[Vector2]) -> float:
	var center: Vector2 = _centroid(pts)
	var avg_r:  float   = 0.0
	for p: Vector2 in pts:
		avg_r += p.distance_to(center)
	avg_r /= float(pts.size())

	if avg_r < 15.0:
		return 0.0

	var var_r: float = 0.0
	for p: Vector2 in pts:
		var d: float = p.distance_to(center) - avg_r
		var_r += d * d
	var_r /= float(pts.size())

	var close: float         = pts[0].distance_to(pts[-1]) / (avg_r * 2.0)
	var radius_score: float  = clampf(1.0 - var_r / (avg_r * avg_r * 0.5), 0.0, 1.0)
	var closure_score: float = clampf(1.0 - close * 1.5, 0.0, 1.0)
	return (radius_score * 0.6 + closure_score * 0.4)

func _score_triangle(pts: Array[Vector2]) -> float:
	var corners: int    = _find_corners(pts, 45.0)
	if corners < 2 or corners > 5:
		return 0.0
	var circle_s: float = _score_circle(pts)
	if circle_s > 0.65:
		return 0.0
	return clampf(0.5 + (1.0 - absf(float(corners) - 3.0) / 3.0) * 0.5, 0.0, 1.0)

func _score_zigzag(pts: Array[Vector2]) -> float:
	var corners: int    = _find_corners(pts, 40.0)
	if corners < 3:
		return 0.0
	var tri_s: float    = _score_triangle(pts)
	if tri_s > 0.70:
		return 0.0
	return clampf(float(corners) / 10.0, 0.0, 1.0)

func _score_line(pts: Array[Vector2]) -> float:
	var straight: float  = pts[0].distance_to(pts[-1])
	var total: float     = _path_length(pts)
	if total < 30.0:
		return 0.0
	var ratio: float        = straight / total
	var corners: int        = _find_corners(pts, 35.0)
	var linearity: float    = clampf(ratio, 0.0, 1.0)
	var straightness: float = clampf(1.0 - float(corners) / 4.0, 0.0, 1.0)
	return (linearity * 0.7 + straightness * 0.3)

func _score_scribble(pts: Array[Vector2]) -> float:
	var bbox: Vector2  = _bounding_box(pts)
	var area: float    = bbox.x * bbox.y
	if area < 100.0:
		return 0.0
	var total: float   = _path_length(pts)
	var density: float = clampf(total / (area + 1.0) * 40.0, 0.0, 1.0)
	var corners: int   = _find_corners(pts, 30.0)
	var chaos: float   = clampf(float(corners) / 12.0, 0.0, 1.0)
	return (density * 0.5 + chaos * 0.5)

# ── Helpers ───────────────────────────────────────────────────
func _resample(points: Array[Vector2], count: int) -> Array[Vector2]:
	if points.size() <= 1:
		var copy: Array[Vector2] = []
		copy.assign(points)
		return copy
	var total: float    = _path_length(points)
	var interval: float = total / float(count - 1)
	var result: Array[Vector2] = [points[0]]
	var accumulated: float = 0.0
	var i: int = 1
	while i < points.size() and result.size() < count:
		var d: float = points[i - 1].distance_to(points[i])
		if accumulated + d >= interval:
			var t: float    = (interval - accumulated) / d
			var np: Vector2 = points[i - 1].lerp(points[i], t)
			result.append(np)
			accumulated = 0.0
			i -= 1
		else:
			accumulated += d
		i += 1
	if result.size() < count:
		result.append(points[-1])
	return result

func _path_length(pts: Array[Vector2]) -> float:
	var l: float = 0.0
	for i: int in range(1, pts.size()):
		l += pts[i - 1].distance_to(pts[i])
	return l

func _centroid(pts: Array[Vector2]) -> Vector2:
	var c: Vector2 = Vector2.ZERO
	for p: Vector2 in pts:
		c += p
	return c / float(pts.size())

func _bounding_box(pts: Array[Vector2]) -> Vector2:
	var mn: Vector2 = pts[0]
	var mx: Vector2 = pts[0]
	for p: Vector2 in pts:
		mn = mn.min(p)
		mx = mx.max(p)
	return mx - mn

func _find_corners(pts: Array[Vector2], angle_threshold: float) -> int:
	if pts.size() < 3:
		return 0
	var count: int = 0
	for i: int in range(1, pts.size() - 1):
		var d1: Vector2 = (pts[i]     - pts[i - 1]).normalized()
		var d2: Vector2 = (pts[i + 1] - pts[i]).normalized()
		if d1.length() < 0.001 or d2.length() < 0.001:
			continue
		var angle: float = rad_to_deg(acos(clampf(d1.dot(d2), -1.0, 1.0)))
		if angle > angle_threshold:
			count += 1
	return count
