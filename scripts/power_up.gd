extends Area2D
class_name PowerUp

signal collected(at_position: Vector2)

var velocity := Vector2(0.0, 105.0)
var _elapsed := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	monitoring = true
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 17.0
	collision.shape = shape
	add_child(collision)
	area_entered.connect(_on_area_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	position += velocity * delta
	position.x += sin(_elapsed * 7.0) * 26.0 * delta
	rotation += delta * 1.8
	queue_redraw()
	if position.y > GameRules.VIEW_SIZE.y + 40.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _taken or not (area is PlayerShip):
		return
	_taken = true
	collision_layer = 0
	collision_mask = 0
	area.collect_power_up()
	collected.emit(position)
	queue_free()


func _draw() -> void:
	var pulse := 1.0 + sin(_elapsed * 8.0) * 0.08
	draw_circle(Vector2.ZERO, 24.0 * pulse, Color(1.0, 0.82, 0.25, 0.08))
	draw_rect(Rect2(-14.0, -14.0, 28.0, 28.0), Color("#ffd45a"))
	draw_rect(Rect2(-9.0, -3.0, 18.0, 6.0), Color("#071021"))
	draw_rect(Rect2(-3.0, -9.0, 6.0, 18.0), Color("#ff4f85"))
