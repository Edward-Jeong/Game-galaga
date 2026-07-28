extends Node
class_name SoundBank

var muted := false
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _cursor := 0


func _ready() -> void:
	_streams = {
		"shoot": _make_tone(920.0, 0.045, 0.25, 0),
		"hit": _make_tone(240.0, 0.085, 0.38, 1),
		"explode": _make_tone(105.0, 0.16, 0.48, 2),
		"power": _make_tone(680.0, 0.14, 0.35, 3),
		"wave": _make_tone(420.0, 0.22, 0.30, 4),
	}
	for index in 8:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_players.append(player)


func set_muted(value: bool) -> void:
	muted = value
	if muted:
		for player in _players:
			player.stop()


func play(cue: StringName) -> void:
	if muted or not _streams.has(cue):
		return
	var player := _players[_cursor]
	_cursor = (_cursor + 1) % _players.size()
	player.stream = _streams[cue]
	player.play()


func _make_tone(frequency: float, duration: float, gain: float, flavor: int) -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	var frame_count := maxi(1, int(duration * SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in frame_count:
		var t := float(frame) / float(SAMPLE_RATE)
		var envelope := pow(1.0 - float(frame) / float(frame_count), 2.0)
		var sample := sin(TAU * frequency * t)
		if flavor == 1:
			sample = signf(sample) * 0.7
		elif flavor == 2:
			sample = sin(TAU * frequency * t * (1.0 - t * 2.0)) + sin(TAU * frequency * 0.47 * t) * 0.5
		elif flavor == 3:
			sample += sin(TAU * frequency * 1.5 * t) * 0.45
		elif flavor == 4:
			sample += sin(TAU * frequency * 1.25 * t) * 0.35
		var value := clampi(int(sample * envelope * gain * 32767.0), -32768, 32767)
		bytes[frame * 2] = value & 0xff
		bytes[frame * 2 + 1] = (value >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
