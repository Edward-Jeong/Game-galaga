extends Area2D
class_name Projectile

enum Faction {
	PLAYER,
	ENEMY,
}

var faction := Faction.PLAYER
var velocity := Vector2.ZERO
var damage := 1
var _consumed := false


func configure(
	value_faction: Faction,
	value_position: Vector2,
	value_velocity: Vector2,
	value_damage: int = 1
) -> void:
	faction = value_faction
	position = value_position
	velocity = value_velocity
	damage = value_damage


func _ready() -> void:
	if faction == Faction.PLAYER:
		collision_layer = 4
		collision_mask = 2
	else:
		collision_layer = 8
		collision_mask = 1
	monitoring = true
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(7.0, 22.0)
	collision.shape = shape
	add_child(collision)
	queue_redraw()


func _physics_process(delta: float) -> void:
	position += velocity * delta
	if position.y < -40.0 or position.y > GameRules.VIEW_SIZE.y + 40.0:
		queue_free()
	elif position.x < -50.0 or position.x > GameRules.VIEW_SIZE.x + 50.0:
		queue_free()


func consume() -> bool:
	if _consumed:
		return false
	_consumed = true
	collision_layer = 0
	collision_mask = 0
	queue_free()
	return true


func _draw() -> void:
	var color := Color("#f5fbff") if faction == Faction.PLAYER else Color("#ff4f85")
	draw_rect(Rect2(-4.5, -13.0, 9.0, 26.0), Color(color, 0.16))
	draw_rect(Rect2(-2.0, -11.0, 4.0, 22.0), color)
