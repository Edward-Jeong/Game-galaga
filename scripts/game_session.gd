extends RefCounted
class_name GameSession

signal score_changed(value: int)
signal best_score_changed(value: int)
signal lives_changed(value: int)
signal wave_changed(value: int)
signal state_changed(value: State)
signal muted_changed(value: bool)

enum State {
	READY,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY,
}

const STARTING_LIVES := 3
const MAX_WAVE := 3
const SAVE_PATH := "user://starline_defender.cfg"

var state := State.READY
var score := 0
var best_score := 0
var lives := STARTING_LIVES
var wave := 1
var muted := false


func _init() -> void:
	load_settings()


func start_new_game() -> void:
	score = 0
	lives = STARTING_LIVES
	wave = 1
	score_changed.emit(score)
	lives_changed.emit(lives)
	wave_changed.emit(wave)
	set_state(State.PLAYING)


func add_score(points: int) -> void:
	if state != State.PLAYING or points <= 0:
		return
	score = max(0, score + points)
	score_changed.emit(score)
	if score > best_score:
		best_score = score
		best_score_changed.emit(best_score)


func lose_life() -> int:
	if state != State.PLAYING:
		return lives
	lives = max(0, lives - 1)
	lives_changed.emit(lives)
	return lives


func set_wave(value: int) -> void:
	wave = clampi(value, 1, MAX_WAVE)
	wave_changed.emit(wave)


func set_state(value: State) -> void:
	if state == value:
		return
	state = value
	state_changed.emit(state)
	if state == State.GAME_OVER or state == State.VICTORY:
		save_settings()


func set_muted(value: bool) -> void:
	if muted == value:
		return
	muted = value
	muted_changed.emit(muted)
	save_settings()


func toggle_muted() -> void:
	set_muted(not muted)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	best_score = maxi(0, int(config.get_value("scores", "best", 0)))
	muted = bool(config.get_value("audio", "muted", false))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("scores", "best", best_score)
	config.set_value("audio", "muted", muted)
	config.save(SAVE_PATH)
