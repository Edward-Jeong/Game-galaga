extends SceneTree

const Session := preload("res://scripts/game_session.gd")
const Rules := preload("res://scripts/game_rules.gd")

var _failures := 0


func _init() -> void:
	_test_session_guards()
	_test_wave_layouts()
	if _failures == 0:
		print("PASS: Starline Defender rules")
		quit(0)
	else:
		push_error("FAIL: %d rule checks failed" % _failures)
		quit(1)


func _test_session_guards() -> void:
	var game := Session.new()
	game.start_new_game()
	_expect(game.score == 0, "new game score starts at zero")
	_expect(game.lives == 3, "new game starts with three lives")
	game.add_score(100)
	_expect(game.score == 100, "positive score is added")
	game.add_score(-500)
	_expect(game.score == 100, "negative score is ignored")
	game.lose_life()
	game.lose_life()
	game.lose_life()
	game.lose_life()
	_expect(game.lives == 0, "lives never become negative")
	game.set_state(Session.State.GAME_OVER)
	game.add_score(900)
	_expect(game.score == 100, "score does not change after game over")


func _test_wave_layouts() -> void:
	var wave_one: Dictionary = Rules.wave_config(1)
	var wave_two: Dictionary = Rules.wave_config(2)
	_expect(int(wave_one["rows"]) * int(wave_one["columns"]) == 24, "wave one has 24 enemies")
	_expect(int(wave_two["rows"]) * int(wave_two["columns"]) == 32, "wave two has 32 enemies")
	for wave_config in [wave_one, wave_two]:
		for row in int(wave_config["rows"]):
			for column in int(wave_config["columns"]):
				var spawn: Vector2 = Rules.formation_position(wave_config, row, column)
				_expect(spawn.x >= 24.0 and spawn.x <= 516.0, "enemy spawn stays inside horizontal bounds")
				_expect(spawn.y >= 96.0 and spawn.y < 430.0, "enemy spawn stays above player zone")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error(message)
