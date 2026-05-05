## CameraFollow.gd
## Smooth camera with screen shake. Attach to Camera2D in Main.tscn.

extends Camera2D

class_name CameraFollow

@export var follow_speed: float = 6.0
@export var look_ahead:   float = 60.0

var _shake_intensity: float  = 0.0
var _shake_decay:     float  = 8.0
var _target:          Node2D = null

func _ready() -> void:
	var found: Node = get_node_or_null("/root/Main/Player")
	if found:
		_target = found as Node2D

func _process(delta: float) -> void:
	if not _target:
		return
	var mouse_world: Vector2  = get_global_mouse_position()
	var mouse_offset: Vector2 = (mouse_world - _target.global_position).limit_length(look_ahead)
	var desired_pos: Vector2  = _target.global_position + mouse_offset * 0.3
	global_position           = global_position.lerp(desired_pos, follow_speed * delta)

	if _shake_intensity > 0.01:
		offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		_shake_intensity = lerpf(_shake_intensity, 0.0, _shake_decay * delta)
	else:
		_shake_intensity = 0.0
		offset           = Vector2.ZERO

func shake(strength: float) -> void:
	_shake_intensity = maxf(_shake_intensity, strength)

static func trigger_shake(from_node: Node, strength: float) -> void:
	var cam: Node = from_node.get_node_or_null("/root/Main/Camera2D")
	if cam and cam.has_method("shake"):
		cam.shake(strength)
