extends Area2D
class_name EnemyShip

signal destroyed(points: int, at_position: Vector2, may_drop: bool)

var row := 0
var hit_points := 1
var point_value := 100
var base_position := Vector2.ZERO
var active := true
var _phase := 0.0
var _elapsed := 0.0
var _diving := false
var _dive_time := 0.0
var _dive_start := Vector2.ZERO
var _dive_control := Vector2.ZERO
var _dive_end := Vector2.ZERO
var _dead := false


func configure(spawn_position: Vector2, value_row: int, phase: float, wave: int) -> void:
	position = spawn_position
	base_position = spawn_position
	row = value_row
	_phase = phase
	hit_points = 2 if row == 0 else 1
	if wave == 2 and row < 2:
		hit_points += 1
	point_value = GameRules.enemy_points(row)


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	monitoring = true
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(38.0, 30.0)
	collision.shape = shape
	add_child(collision)
	area_entered.connect(_on_area_entered)
	queue_redraw()


func start_dive(target: Vector2) -> bool:
	if _dead or _diving or not active:
		return false
	_diving = true
	_dive_time = 0.0
	_dive_start = position
	var side := -1.0 if position.x > GameRules.VIEW_SIZE.x * 0.5 else 1.0
	_dive_control = Vector2(target.x + side * 150.0, target.y - 150.0)
	_dive_end = Vector2(target.x - side * 80.0, GameRules.VIEW_SIZE.y + 70.0)
	return true


func take_damage(amount: int) -> void:
	if _dead or not active:
		return
	hit_points -= maxi(0, amount)
	if hit_points <= 0:
		_dead = true
		collision_layer = 0
		collision_mask = 0
		destroyed.emit(point_value, position, row <= 1)
		queue_free()
	else:
		modulate = Color.WHITE * 2.4
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.09)


func _physics_process(delta: float) -> void:
	if not active or _dead:
		return
	_elapsed += delta
	if _diving:
		_dive_time += delta
		var t := clampf(_dive_time / 3.0, 0.0, 1.0)
		var a := _dive_start.lerp(_dive_control, t)
		var b := _dive_control.lerp(_dive_end, t)
		position = a.lerp(b, t)
		rotation = sin(t * TAU) * 0.5
		if t >= 1.0:
			_diving = false
			position = base_position
			rotation = 0.0
	else:
		position = base_position + Vector2(
			sin(_elapsed * 1.25 + _phase) * 28.0,
			sin(_elapsed * 2.0 + _phase) * 5.0
		)


func _on_area_entered(area: Area2D) -> void:
	if area is Projectile and area.faction == Projectile.Faction.PLAYER:
		if area.consume():
			take_damage(area.damage)


func _draw() -> void:
	var color := Color("#ff4f85") if row == 0 else (Color("#ffd45a") if row == 1 else Color("#68f0b0"))
	draw_circle(Vector2.ZERO, 27.0, Color(color, 0.05))
	draw_rect(Rect2(-18.0, -12.0, 36.0, 23.0), color)
	draw_rect(Rect2(-27.0, -2.0, 10.0, 17.0), color.darkened(0.1))
	draw_rect(Rect2(17.0, -2.0, 10.0, 17.0), color.darkened(0.1))
	draw_rect(Rect2(-9.0, -5.0, 6.0, 6.0), Color("#071021"))
	draw_rect(Rect2(3.0, -5.0, 6.0, 6.0), Color("#071021"))
	draw_line(Vector2(-13.0, 14.0), Vector2(13.0, 14.0), Color("#f5fbff"), 3.0)
