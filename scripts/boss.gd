extends Area2D
class_name BossShip

signal destroyed(points: int, at_position: Vector2, may_drop: bool)
signal health_changed(current: int, maximum: int)
signal fire_pattern(origin: Vector2, phase: int)

const MAX_HEALTH := 120

var active := true
var hit_points := MAX_HEALTH
var _elapsed := 0.0
var _fire_cooldown := 0.8
var _dead := false
var _phase := 1


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	monitoring = true
	monitorable = true
	position = Vector2(270.0, 190.0)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(142.0, 82.0)
	collision.shape = shape
	add_child(collision)
	area_entered.connect(_on_area_entered)
	health_changed.emit(hit_points, MAX_HEALTH)
	queue_redraw()


func take_damage(amount: int) -> void:
	if _dead or not active:
		return
	hit_points = maxi(0, hit_points - maxi(0, amount))
	var next_phase := 2 if hit_points <= MAX_HEALTH / 2 else 1
	if next_phase != _phase:
		_phase = next_phase
		_fire_cooldown = 0.12
	health_changed.emit(hit_points, MAX_HEALTH)
	if hit_points <= 0:
		_dead = true
		collision_layer = 0
		collision_mask = 0
		destroyed.emit(3000, position, false)
		queue_free()
	else:
		modulate = Color.WHITE * 2.2
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.07)


func _physics_process(delta: float) -> void:
	if _dead or not active:
		return
	_elapsed += delta
	position.x = 270.0 + sin(_elapsed * (1.05 if _phase == 1 else 1.55)) * (150.0 if _phase == 1 else 190.0)
	position.y = 188.0 + sin(_elapsed * 2.1) * 26.0
	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		_fire_cooldown = 0.82 if _phase == 1 else 0.48
		fire_pattern.emit(position + Vector2(0.0, 46.0), _phase)


func _on_area_entered(area: Area2D) -> void:
	if area is Projectile and area.faction == Projectile.Faction.PLAYER:
		if area.consume():
			take_damage(area.damage)


func _draw() -> void:
	var core := Color("#ff4f85") if _phase == 1 else Color("#ff335f")
	draw_circle(Vector2.ZERO, 92.0, Color(core, 0.045))
	var hull := PackedVector2Array([
		Vector2(-78.0, 8.0),
		Vector2(-47.0, -37.0),
		Vector2(-20.0, -24.0),
		Vector2(0.0, -51.0),
		Vector2(20.0, -24.0),
		Vector2(47.0, -37.0),
		Vector2(78.0, 8.0),
		Vector2(48.0, 38.0),
		Vector2(0.0, 27.0),
		Vector2(-48.0, 38.0),
	])
	draw_colored_polygon(hull, Color("#5928a8"))
	draw_polyline(hull + PackedVector2Array([hull[0]]), Color("#d090ff"), 3.0, true)
	draw_circle(Vector2.ZERO, 23.0, core)
	draw_circle(Vector2.ZERO, 10.0, Color("#fff3b0"))
	draw_line(Vector2(-61.0, 13.0), Vector2(-31.0, 21.0), Color("#45d8ff"), 5.0)
	draw_line(Vector2(61.0, 13.0), Vector2(31.0, 21.0), Color("#45d8ff"), 5.0)
