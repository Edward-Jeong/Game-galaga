extends Node2D

const STAR_COUNT := 105

var _stars: Array[Dictionary] = []
var _nebula_phase := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5A17D3F
	for index in STAR_COUNT:
		_stars.append({
			"position": Vector2(
				rng.randf_range(0.0, GameRules.VIEW_SIZE.x),
				rng.randf_range(0.0, GameRules.VIEW_SIZE.y)
			),
			"speed": rng.randf_range(12.0, 62.0),
			"radius": rng.randf_range(0.65, 2.2),
			"alpha": rng.randf_range(0.35, 0.92),
		})
	queue_redraw()


func _process(delta: float) -> void:
	_nebula_phase += delta
	for star in _stars:
		var star_position: Vector2 = star["position"]
		star_position.y += float(star["speed"]) * delta
		if star_position.y > GameRules.VIEW_SIZE.y + 3.0:
			star_position.y = -3.0
			star_position.x = fposmod(star_position.x * 1.731 + 97.0, GameRules.VIEW_SIZE.x)
		star["position"] = star_position
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, GameRules.VIEW_SIZE), Color("#030611"))
	draw_circle(
		Vector2(80.0 + sin(_nebula_phase * 0.18) * 25.0, 230.0),
		220.0,
		Color(0.11, 0.45, 0.72, 0.055)
	)
	draw_circle(
		Vector2(470.0, 650.0 + cos(_nebula_phase * 0.15) * 35.0),
		250.0,
		Color(0.52, 0.12, 0.72, 0.045)
	)
	for star in _stars:
		var color := Color(0.78, 0.91, 1.0, float(star["alpha"]))
		draw_circle(star["position"], float(star["radius"]), color)
