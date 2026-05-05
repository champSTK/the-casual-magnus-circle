## Projectile.gd
## Moving Area2D that damages enemies on contact.
## Scene: Area2D → CollisionShape2D + ColorRect "Visual"

extends Area2D

var _direction: Vector2       = Vector2.RIGHT
var _speed:     float         = 400.0
var _damage:    int           = 10
var _lifetime:  float         = 1.0
var _size:      float         = 8.0
var _piercing:  bool          = false
var _hit_set:   Array[Node]   = []

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var visual:    ColorRect        = $Visual

func setup(
	dir:      Vector2,
	speed:    float,
	damage:   int,
	color:    Color,
	lifetime: float,
	size:     float,
	piercing: bool = false
) -> void:
	_direction = dir.normalized()
	_speed     = speed
	_damage    = damage
	_lifetime  = lifetime
	_size      = size
	_piercing  = piercing

	visual.size     = Vector2(_size * 2.0, _size * 2.0)
	visual.position = Vector2(-_size, -_size)
	visual.color    = color

	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius             = _size
	collision.shape          = shape
	rotation                 = _direction.angle()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position  += _direction * _speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		if _piercing:
			if _hit_set.has(body):
				return
			_hit_set.append(body)
		body.take_damage(_damage)
		if not _piercing:
			queue_free()
	elif body is StaticBody2D:
		queue_free()

func _on_area_entered(area: Node) -> void:
	if area.has_method("take_damage"):
		area.take_damage(_damage)
		if not _piercing:
			queue_free()
