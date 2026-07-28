extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")

var _failures := 0
var _game: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_game = MAIN_SCENE.instantiate()
	root.add_child(_game)
	await process_frame
	var sound_bank := _game.get("sound") as SoundBank
	if sound_bank:
		sound_bank.set_muted(true)

	_game.call("_start_new_game")
	await process_frame
	_expect(_session().state == GameSession.State.PLAYING, "start enters playing state")
	_expect(_session().lives == 3, "start restores three lives")
	_expect(int(_game.get("_active_targets")) == 24, "wave one spawns 24 targets")

	_destroy_all_enemies()
	await create_timer(1.4, true).timeout
	_expect(_session().wave == 2, "clearing wave one advances to wave two")
	_expect(int(_game.get("_active_targets")) == 32, "wave two spawns 32 targets")

	_destroy_all_enemies()
	await create_timer(1.4, true).timeout
	_expect(_session().wave == 3, "clearing wave two advances to the boss")
	_expect(int(_game.get("_active_targets")) == 5, "boss wave contains flagship and four escorts")

	var boss := _find_boss()
	_expect(boss != null, "boss is present in final wave")
	if boss:
		boss.take_damage(BossShip.MAX_HEALTH)
	await create_timer(1.0, true).timeout
	_expect(_session().state == GameSession.State.VICTORY, "destroying the boss reaches victory")

	_game.call("_on_start_pressed")
	await process_frame
	_expect(_session().state == GameSession.State.PLAYING, "victory screen can restart")
	_expect(_session().wave == 1, "victory restart returns to wave one")

	for hit_index in 3:
		_game.call("_on_player_hit")
	await create_timer(0.6, true).timeout
	_expect(_session().lives == 0, "three hits consume all lives")
	_expect(_session().state == GameSession.State.GAME_OVER, "zero lives reaches game over")

	_game.call("_on_start_pressed")
	await process_frame
	_expect(_session().state == GameSession.State.PLAYING, "game-over screen can restart")
	_expect(_session().lives == 3, "game-over restart restores lives")
	_expect(int(_game.get("_active_targets")) == 24, "rapid restart creates one fresh wave")

	if sound_bank:
		sound_bank.set_muted(true)
	_game.free()
	await process_frame
	await process_frame
	if _failures == 0:
		print("PASS: Starline Defender full game flow")
		quit(0)
	else:
		push_error("FAIL: %d game-flow checks failed" % _failures)
		quit(1)


func _session() -> GameSession:
	return _game.get("session") as GameSession


func _entities() -> Node:
	return _game.get_node("World/Entities")


func _destroy_all_enemies() -> void:
	for child in _entities().get_children():
		if child is EnemyShip:
			child.take_damage(999)


func _find_boss() -> BossShip:
	for child in _entities().get_children():
		if child is BossShip:
			return child
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error(message)
