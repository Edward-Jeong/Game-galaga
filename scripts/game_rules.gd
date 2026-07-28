extends RefCounted
class_name GameRules

const VIEW_SIZE := Vector2(540.0, 960.0)
const PLAY_BOUNDS := Rect2(24.0, 96.0, 492.0, 828.0)
const PLAYER_START := Vector2(270.0, 850.0)

const WAVE_DATA := {
	1: {
		"rows": 4,
		"columns": 6,
		"start_y": 180.0,
		"spacing_x": 68.0,
		"spacing_y": 58.0,
		"dive_interval": 2.2,
		"shot_interval": 1.8,
	},
	2: {
		"rows": 4,
		"columns": 8,
		"start_y": 150.0,
		"spacing_x": 58.0,
		"spacing_y": 54.0,
		"dive_interval": 1.5,
		"shot_interval": 1.15,
	},
}


static func wave_config(wave: int) -> Dictionary:
	return WAVE_DATA.get(wave, {}).duplicate(true)


static func enemy_points(row: int) -> int:
	if row == 0:
		return 240
	if row == 1:
		return 160
	return 100


static func formation_position(config: Dictionary, row: int, column: int) -> Vector2:
	var count: int = int(config["columns"])
	var spacing_x: float = float(config["spacing_x"])
	var width := float(count - 1) * spacing_x
	return Vector2(
		VIEW_SIZE.x * 0.5 - width * 0.5 + float(column) * spacing_x,
		float(config["start_y"]) + float(row) * float(config["spacing_y"])
	)
