extends Node2D
class_name BurstEffect

var _particles: Array[Dictionary] = []


func configure(effect_position: Vector2, color: Color, count: int = 18, force: float = 210.0) -> void:
	position = effect_position
	var rng := RandomNumberGenerator.new()
	rng.seed = int(effect_position.x * 1009.0 + effect_position.y * 917.0 + count * 31)
	for index in count:
		var angle := rng.randf_range(0.0, TAU)
		var speed := rng.randf_range(force * 0.3, force)
		_particles.append({
			"position": Vector2.ZERO,
			"velocity": Vector2.from_angle(angle) * speed,
			"life": rng.randf_range(0.28, 0.62),
			"max_life": 0.62,
			"color": color,
		})


func _process(delta: float) -> void:
	for particle in _particles:
		particle["position"] += particle["velocity"] * delta
		particle["velocity"] += Vector2(0.0, 120.0) * delta
		particle["life"] = float(particle["life"]) - delta
	_particles = _particles.filter(func(item: Dictionary) -> bool: return float(item["life"]) > 0.0)
	queue_redraw()
	if _particles.is_empty():
		queue_free()


func _draw() -> void:
	for particle in _particles:
		var alpha := clampf(float(particle["life"]) / float(particle["max_life"]), 0.0, 1.0)
		var color: Color = particle["color"]
		color.a = alpha
		var particle_position: Vector2 = particle["position"]
		draw_circle(particle_position, 3.2, color)
