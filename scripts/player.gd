extends Area2D
class_name PlayerShip

signal fire_requested(origin: Vector2, weapon_level: int)
signal hit_received
signal power_up_collected

const MOVE_SPEED := 430.0
const FOLLOW_SPEED := 13.0
const FIRE_INTERVAL := 0.18
const FINGER_OFFSET := 76.0

var active := false
var weapon_level := 1
var invincible_time := 0.0
var _fire_cooldown := 0.0
var _touch_target := Vector2.ZERO
var _tracking_touch := false
var _touch_index := -1
var _mouse_dragging := false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 2 | 8 | 16
	monitoring = true
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 14.0
	shape.height = 48.0
	collision.shape = shape
	add_child(collision)
	area_entered.connect(_on_area_entered)
	queue_redraw()


func set_active(value: bool) -> void:
	active = value
	if not active:
		cancel_pointer()


func reset_ship() -> void:
	position = GameRules.PLAYER_START
	weapon_level = 1
	invincible_time = 0.0
	_fire_cooldown = 0.08
	cancel_pointer()
	queue_redraw()


func respawn() -> void:
	position = GameRules.PLAYER_START
	weapon_level = maxi(1, weapon_level - 1)
	invincible_time = 1.6
	cancel_pointer()


func take_hit() -> void:
	if not active or invincible_time > 0.0:
		return
	hit_received.emit()


func collect_power_up() -> void:
	if not active:
		return
	weapon_level = mini(3, weapon_level + 1)
	power_up_collected.emit()
	queue_redraw()


func cancel_pointer() -> void:
	_tracking_touch = false
	_touch_index = -1
	_mouse_dragging = false


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch:
		if event.pressed and not _tracking_touch:
			_tracking_touch = true
			_touch_index = event.index
			_set_touch_target(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch_index:
			_tracking_touch = false
			_touch_index = -1
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_set_touch_target(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_dragging = event.pressed
		if _mouse_dragging:
			_set_touch_target(event.position, false)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _mouse_dragging and not _tracking_touch:
		_set_touch_target(event.position, false)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	invincible_time = maxf(0.0, invincible_time - delta)
	if not active:
		queue_redraw()
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length_squared() > 0.0:
		position += input_vector.normalized() * MOVE_SPEED * delta

	if _tracking_touch or _mouse_dragging:
		position = position.lerp(_touch_target, minf(1.0, FOLLOW_SPEED * delta))

	position.x = clampf(position.x, GameRules.PLAY_BOUNDS.position.x, GameRules.PLAY_BOUNDS.end.x)
	position.y = clampf(position.y, 430.0, GameRules.PLAY_BOUNDS.end.y)

	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		_fire_cooldown += FIRE_INTERVAL
		fire_requested.emit(position + Vector2(0.0, -32.0), weapon_level)
	queue_redraw()


func _set_touch_target(screen_position: Vector2, offset_for_finger: bool = true) -> void:
	_touch_target = screen_position
	if offset_for_finger:
		_touch_target.y -= FINGER_OFFSET
	_touch_target.x = clampf(_touch_target.x, GameRules.PLAY_BOUNDS.position.x, GameRules.PLAY_BOUNDS.end.x)
	_touch_target.y = clampf(_touch_target.y, 430.0, GameRules.PLAY_BOUNDS.end.y)


func _on_area_entered(area: Area2D) -> void:
	if area is Projectile and area.faction == Projectile.Faction.ENEMY:
		if area.consume():
			take_hit()
	elif area is EnemyShip or area is BossShip:
		take_hit()


func _draw() -> void:
	if invincible_time > 0.0 and int(invincible_time * 12.0) % 2 == 0:
		return
	for radius in [34.0, 29.0]:
		draw_circle(Vector2.ZERO, radius, Color(0.1, 0.78, 1.0, 0.035))
	var hull := PackedVector2Array([
		Vector2(0.0, -31.0),
		Vector2(24.0, 23.0),
		Vector2(7.0, 15.0),
		Vector2(0.0, 29.0),
		Vector2(-7.0, 15.0),
		Vector2(-24.0, 23.0),
	])
	draw_colored_polygon(hull, Color("#45d8ff"))
	draw_polyline(hull + PackedVector2Array([hull[0]]), Color("#d8f8ff"), 2.0, true)
	draw_rect(Rect2(-5.0, -11.0, 10.0, 23.0), Color("#f5fbff"))
	draw_rect(Rect2(-18.0, 20.0, 10.0, 7.0), Color("#ff4f85"))
	draw_rect(Rect2(8.0, 20.0, 10.0, 7.0), Color("#ff4f85"))
	if weapon_level > 1:
		draw_arc(Vector2.ZERO, 37.0, -2.6, -0.55, 20, Color(1.0, 0.82, 0.25, 0.65), 2.0)
