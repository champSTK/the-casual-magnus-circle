## EnemyProjectile.gd
## Projectile fired by Ranged enemies. Damages the player on contact.
## Scene: Area2D → CollisionShape2D + ColorRect "Visual"

extends Area2D

var _direction: Vector2 = Vector2.RIGHT
var _speed:     float   = 220.0
var _damage:    int     = 8
var _lifetime:  float   = 2.5

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var visual:    ColorRect        = $Visual

func setup(
	dir:      Vector2,
	speed:    float,
	damage:   int,
	color:    Color,
	lifetime: float,
	size:     float
) -> void:
	_direction = dir.normalized()
	_speed     = speed
	_damage    = damage
	_lifetime  = lifetime

	visual.size     = Vector2(size * 2.0, size * 2.0)
	visual.position = Vector2(-size, -size)
	visual.color    = color

	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius             = size
	collision.shape          = shape
	rotation                 = _direction.angle()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position  += _direction * _speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(_damage)
		queue_free()
	elif body is StaticBody2D:
		queue_free()
