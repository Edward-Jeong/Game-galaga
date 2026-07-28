extends Node

@onready var world: Node2D = $World
@onready var entities: Node2D = $World/Entities
@onready var effects: Node2D = $World/Effects
@onready var hud: GameHUD = $HUD

var session := GameSession.new()
var player: PlayerShip
var sound: SoundBank
var _rng := RandomNumberGenerator.new()
var _active_targets := 0
var _dive_timer := 0.0
var _shot_timer := 0.0
var _transitioning := false
var _shake_time := 0.0
var _shake_strength := 0.0


func _ready() -> void:
	_rng.seed = 0x51A2B3C4
	sound = SoundBank.new()
	add_child(sound)
	sound.set_muted(session.muted)

	session.score_changed.connect(hud.update_score)
	session.best_score_changed.connect(hud.update_best)
	session.lives_changed.connect(hud.update_lives)
	session.wave_changed.connect(hud.update_wave)
	session.state_changed.connect(_on_state_changed)
	session.muted_changed.connect(_on_muted_changed)
	hud.start_pressed.connect(_on_start_pressed)
	hud.pause_pressed.connect(toggle_pause)
	hud.mute_pressed.connect(session.toggle_muted)

	hud.update_best(session.best_score)
	hud.update_muted(session.muted)
	hud.set_state(session.state)
	get_tree().paused = false
	if "--autoplay-preview" in OS.get_cmdline_user_args():
		call_deferred("_start_new_game")


func _process(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time = maxf(0.0, _shake_time - delta)
		world.position = Vector2(
			_rng.randf_range(-_shake_strength, _shake_strength),
			_rng.randf_range(-_shake_strength, _shake_strength)
		)
	else:
		world.position = Vector2.ZERO

	if session.state != GameSession.State.PLAYING or _transitioning:
		return
	if session.wave < 3:
		_dive_timer -= delta
		_shot_timer -= delta
		var config := GameRules.wave_config(session.wave)
		if _dive_timer <= 0.0:
			_dive_timer = float(config["dive_interval"])
			_order_dive()
		if _shot_timer <= 0.0:
			_shot_timer = float(config["shot_interval"])
			_order_enemy_shot()


func _unhandled_input(event: InputEvent) -> void:
	var is_echo: bool = event is InputEventKey and event.echo
	if event.is_action_pressed("pause_game") and not is_echo:
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm") and not is_echo:
		if session.state != GameSession.State.PLAYING:
			_on_start_pressed()
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and session.state == GameSession.State.PLAYING:
		toggle_pause()


func _on_start_pressed() -> void:
	if session.state == GameSession.State.PAUSED:
		toggle_pause()
	elif session.state != GameSession.State.PLAYING:
		_start_new_game()


func _start_new_game() -> void:
	get_tree().paused = false
	_clear_entities()
	_transitioning = false
	_active_targets = 0
	session.start_new_game()
	_spawn_player()
	_start_wave(1)


func _spawn_player() -> void:
	player = PlayerShip.new()
	player.name = "Player"
	entities.add_child(player)
	player.reset_ship()
	player.set_active(true)
	player.fire_requested.connect(_on_player_fire)
	player.hit_received.connect(_on_player_hit)
	player.power_up_collected.connect(_on_player_power_up)


func _start_wave(wave_number: int) -> void:
	if session.state != GameSession.State.PLAYING:
		return
	_transitioning = false
	_clear_hostiles()
	session.set_wave(wave_number)
	hud.set_boss_health(0, 1)
	_active_targets = 0
	if wave_number < 3:
		_spawn_formation(wave_number)
		var config := GameRules.wave_config(wave_number)
		_dive_timer = float(config["dive_interval"]) * 0.7
		_shot_timer = float(config["shot_interval"]) * 0.8
		hud.show_banner("WAVE %d" % wave_number)
	else:
		_spawn_boss_wave()
		hud.show_banner("FINAL WAVE · FLAGSHIP")
	sound.play(&"wave")


func _spawn_formation(wave_number: int) -> void:
	var config := GameRules.wave_config(wave_number)
	for row in int(config["rows"]):
		for column in int(config["columns"]):
			var enemy := EnemyShip.new()
			var spawn_position := GameRules.formation_position(config, row, column)
			var phase := float(row * int(config["columns"]) + column) * 0.37
			enemy.configure(spawn_position, row, phase, wave_number)
			entities.add_child(enemy)
			enemy.destroyed.connect(_on_target_destroyed.bind(false))
			_active_targets += 1


func _spawn_boss_wave() -> void:
	var boss := BossShip.new()
	entities.add_child(boss)
	boss.destroyed.connect(_on_target_destroyed.bind(true))
	boss.health_changed.connect(hud.set_boss_health)
	boss.fire_pattern.connect(_on_boss_fire)
	hud.set_boss_health(BossShip.MAX_HEALTH, BossShip.MAX_HEALTH)
	_active_targets += 1

	var escort_positions := [
		Vector2(110.0, 310.0),
		Vector2(200.0, 340.0),
		Vector2(340.0, 340.0),
		Vector2(430.0, 310.0),
	]
	for index in escort_positions.size():
		var escort := EnemyShip.new()
		escort.configure(escort_positions[index], 0, float(index) * 0.9, 2)
		entities.add_child(escort)
		escort.destroyed.connect(_on_target_destroyed.bind(false))
		_active_targets += 1


func _on_player_fire(origin: Vector2, weapon_level: int) -> void:
	if session.state != GameSession.State.PLAYING:
		return
	var patterns := {
		1: [[0.0, 0.0]],
		2: [[-10.0, -30.0], [10.0, 30.0]],
		3: [[-16.0, -85.0], [0.0, 0.0], [16.0, 85.0]],
	}
	for pattern in patterns[clampi(weapon_level, 1, 3)]:
		var projectile := Projectile.new()
		var angle := deg_to_rad(float(pattern[1]))
		projectile.configure(
			Projectile.Faction.PLAYER,
			origin + Vector2(float(pattern[0]), 0.0),
			Vector2.UP.rotated(angle) * 760.0
		)
		entities.add_child(projectile)
	sound.play(&"shoot")


func _order_dive() -> void:
	if not is_instance_valid(player):
		return
	var candidates: Array[EnemyShip] = []
	for child in entities.get_children():
		if child is EnemyShip and child.active:
			candidates.append(child)
	if candidates.is_empty():
		return
	var first_index := _rng.randi_range(0, candidates.size() - 1)
	candidates[first_index].start_dive(player.position)
	if session.wave == 2 and candidates.size() > 7 and _rng.randf() < 0.42:
		var second_index := (first_index + _rng.randi_range(2, candidates.size() - 2)) % candidates.size()
		candidates[second_index].start_dive(player.position + Vector2(_rng.randf_range(-90.0, 90.0), 0.0))


func _order_enemy_shot() -> void:
	if not is_instance_valid(player):
		return
	var candidates: Array[EnemyShip] = []
	for child in entities.get_children():
		if child is EnemyShip and child.active and child.position.y < 520.0:
			candidates.append(child)
	if candidates.is_empty():
		return
	var shooter := candidates[_rng.randi_range(0, candidates.size() - 1)]
	var direction := shooter.position.direction_to(player.position)
	_spawn_enemy_projectile(shooter.position + Vector2(0.0, 18.0), direction * (285.0 + session.wave * 28.0))


func _on_boss_fire(origin: Vector2, phase: int) -> void:
	if phase == 1:
		for angle in [-20.0, 0.0, 20.0]:
			_spawn_enemy_projectile(origin, Vector2.DOWN.rotated(deg_to_rad(angle)) * 330.0)
	else:
		for angle in [-42.0, -21.0, 0.0, 21.0, 42.0]:
			_spawn_enemy_projectile(origin, Vector2.DOWN.rotated(deg_to_rad(angle)) * 390.0)
		if is_instance_valid(player):
			_spawn_enemy_projectile(origin, origin.direction_to(player.position) * 450.0)


func _spawn_enemy_projectile(origin: Vector2, velocity: Vector2) -> void:
	if session.state != GameSession.State.PLAYING:
		return
	var projectile := Projectile.new()
	projectile.configure(Projectile.Faction.ENEMY, origin, velocity)
	entities.add_child(projectile)


func _on_target_destroyed(points: int, target_position: Vector2, may_drop: bool, is_boss: bool) -> void:
	if session.state != GameSession.State.PLAYING:
		return
	session.add_score(points)
	_active_targets = maxi(0, _active_targets - 1)
	_spawn_burst(target_position, Color("#ff5a91"), 22 if is_boss else 14, 330.0 if is_boss else 210.0)
	sound.play(&"explode")
	if may_drop and _rng.randf() < 0.22:
		_spawn_power_up(target_position)
	if is_boss:
		_transitioning = true
		if is_instance_valid(player):
			player.set_active(false)
		_clear_enemy_projectiles()
		call_deferred("_finish_game", true)
	elif _active_targets == 0 and session.wave < 3:
		_transitioning = true
		call_deferred("_advance_wave")


func _spawn_power_up(at_position: Vector2) -> void:
	var power_up := PowerUp.new()
	power_up.position = at_position
	entities.add_child(power_up)
	power_up.collected.connect(func(effect_position: Vector2) -> void:
		_spawn_burst(effect_position, Color("#ffd45a"), 18, 190.0)
	)


func _on_player_power_up() -> void:
	session.add_score(150)
	sound.play(&"power")


func _on_player_hit() -> void:
	if session.state != GameSession.State.PLAYING or not is_instance_valid(player):
		return
	var hit_position := player.position
	var remaining := session.lose_life()
	_spawn_burst(hit_position, Color("#45d8ff"), 30, 300.0)
	sound.play(&"hit")
	_shake(0.32, 10.0)
	_clear_enemy_projectiles()
	if remaining <= 0:
		player.set_active(false)
		_transitioning = true
		call_deferred("_finish_game", false)
	else:
		player.respawn()


func _advance_wave() -> void:
	if session.state != GameSession.State.PLAYING:
		return
	if is_instance_valid(player):
		player.set_active(false)
	hud.show_banner("SECTOR CLEAR")
	await get_tree().create_timer(1.25).timeout
	if session.state != GameSession.State.PLAYING:
		return
	if is_instance_valid(player):
		player.set_active(true)
	_start_wave(session.wave + 1)


func _finish_game(victory: bool) -> void:
	if session.state != GameSession.State.PLAYING:
		return
	if victory:
		_spawn_burst(Vector2(270.0, 240.0), Color("#ffd45a"), 48, 430.0)
		_shake(0.65, 13.0)
		await get_tree().create_timer(0.8).timeout
		session.set_state(GameSession.State.VICTORY)
	else:
		await get_tree().create_timer(0.45).timeout
		session.set_state(GameSession.State.GAME_OVER)
	if is_instance_valid(player):
		player.set_active(false)
	get_tree().paused = true


func toggle_pause() -> void:
	if session.state == GameSession.State.PLAYING:
		if is_instance_valid(player):
			player.cancel_pointer()
		session.set_state(GameSession.State.PAUSED)
		get_tree().paused = true
	elif session.state == GameSession.State.PAUSED:
		get_tree().paused = false
		session.set_state(GameSession.State.PLAYING)


func _on_state_changed(value: GameSession.State) -> void:
	hud.set_state(value)


func _on_muted_changed(value: bool) -> void:
	sound.set_muted(value)
	hud.update_muted(value)


func _spawn_burst(effect_position: Vector2, color: Color, count: int, force: float) -> void:
	var burst := BurstEffect.new()
	burst.configure(effect_position, color, count, force)
	effects.add_child(burst)


func _shake(duration: float, strength: float) -> void:
	_shake_time = maxf(_shake_time, duration)
	_shake_strength = maxf(_shake_strength, strength)


func _clear_hostiles() -> void:
	for child in entities.get_children():
		if child == player:
			continue
		entities.remove_child(child)
		child.queue_free()


func _clear_enemy_projectiles() -> void:
	for child in entities.get_children():
		if child is Projectile and child.faction == Projectile.Faction.ENEMY:
			entities.remove_child(child)
			child.queue_free()


func _clear_entities() -> void:
	for child in entities.get_children():
		entities.remove_child(child)
		child.queue_free()
	for child in effects.get_children():
		effects.remove_child(child)
		child.queue_free()
	player = null
