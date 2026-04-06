extends Node

const VOL_UI     := -10.0   # combo, pickup, score sounds
const VOL_WEAPON := -4.0    # shoot, enemy bullet sounds
const VOL_IMPACT := 0.0     # explosion, damage, boss sounds

var _enabled := true
var _players: Array[AudioStreamPlayer] = []
var _pool_size := 8


func _ready() -> void:
	for i in _pool_size:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)


func play_shoot() -> void:
	_play(_make_beep(880.0, 440.0, 0.07, 0.12), VOL_WEAPON)


func play_explosion() -> void:
	_play(_make_noise(0.25, 800.0, 100.0), VOL_IMPACT)


func play_powerup() -> void:
	# Ascending arpeggio
	var notes := [523.0, 659.0, 784.0, 1047.0]
	for i in notes.size():
		get_tree().create_timer(i * 0.08).timeout.connect(
			func(): _play(_make_beep(notes[i], notes[i], 0.1, 0.1), VOL_UI), CONNECT_ONE_SHOT
		)


func play_damage() -> void:
	_play(_make_sawtooth(120.0, 60.0, 0.2), VOL_IMPACT)


func play_level_complete() -> void:
	var melody := [523.0, 659.0, 784.0, 1047.0, 1047.0]
	for i in melody.size():
		get_tree().create_timer(i * 0.15).timeout.connect(
			func(): _play(_make_beep(melody[i], melody[i], 0.18, 0.15), VOL_UI), CONNECT_ONE_SHOT
		)


func play_shield_activate() -> void:
	# Ascending shimmer
	var notes := [880.0, 1100.0, 1320.0, 1760.0]
	for i in notes.size():
		get_tree().create_timer(i * 0.06).timeout.connect(
			func(): _play(_make_beep(notes[i], notes[i] * 1.1, 0.08, 0.18), VOL_UI), CONNECT_ONE_SHOT
		)


func play_shield_hit() -> void:
	_play(_make_beep(2000.0, 1000.0, 0.1, 0.22), VOL_IMPACT)


func play_boss_hit() -> void:
	_play(_make_sawtooth(100.0, 50.0, 0.15), VOL_IMPACT)


func play_boss_defeated() -> void:
	var seq := [300.0, 220.0, 150.0, 80.0]
	for i in seq.size():
		get_tree().create_timer(i * 0.18).timeout.connect(
			func(): _play(_make_noise(0.28, seq[i], seq[i] * 0.4), VOL_IMPACT), CONNECT_ONE_SHOT
		)


func play_combo_up(level: int) -> void:
	var freq := 440.0 + float(level) * 80.0
	_play(_make_beep(freq, freq * 1.5, 0.08, 0.15), VOL_UI)


func set_enabled(on: bool) -> void:
	_enabled = on


# ── Private ─────────────────────────────────────────────────────────────────

func _play(stream: AudioStreamWAV, vol: float = 0.0) -> void:
	if not _enabled:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = vol
			p.play()
			return


func _make_beep(freq_start: float, freq_end: float, duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * duration)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var pct := float(i) / float(n)
		var freq := lerpf(freq_start, freq_end, pct)
		var env := 1.0 - pct
		var s := int(clampf(sin(TAU * freq * t) * env * volume * 32767.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s)
	wav.data = data
	return wav


func _make_noise(duration: float, freq_start: float, freq_end: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * duration)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var pct := float(i) / float(n)
		var env := 1.0 - pct
		# Low-pass filtered noise approximation
		var noise := (randf() * 2.0 - 1.0) * env * 0.4
		var s := int(clampf(noise * 32767.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s)
	wav.data = data
	return wav


func _make_sawtooth(freq_start: float, freq_end: float, duration: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * duration)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var pct := float(i) / float(n)
		var freq := lerpf(freq_start, freq_end, pct)
		var env := 1.0 - pct
		phase = fmod(phase + freq / float(rate), 1.0)
		var s := int(clampf((phase * 2.0 - 1.0) * env * 0.25 * 32767.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s)
	wav.data = data
	return wav
