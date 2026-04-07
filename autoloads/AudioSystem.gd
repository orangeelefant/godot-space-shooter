extends Node

const VOL_UI     := -10.0   # combo, pickup, score sounds
const VOL_WEAPON := -4.0    # shoot, enemy bullet sounds
const VOL_IMPACT := 0.0     # explosion, damage, boss sounds

var _enabled := true
var _players: Array[AudioStreamPlayer] = []
var _pool_size := 8

# Pre-generated streams — never synthesized at runtime
var _snd_shoot: AudioStreamWAV
var _snd_explosion: AudioStreamWAV
var _snd_damage: AudioStreamWAV
var _snd_boss_hit: AudioStreamWAV
var _snd_shield_hit: AudioStreamWAV
var _snd_powerup: Array[AudioStreamWAV] = []
var _snd_level_complete: Array[AudioStreamWAV] = []
var _snd_shield_activate: Array[AudioStreamWAV] = []
var _snd_boss_defeated: Array[AudioStreamWAV] = []
var _snd_combo_up: Array[AudioStreamWAV] = []  # index = multiplier (1-5)


func _ready() -> void:
	_enabled = SaveSystem.get_audio_enabled()
	for i in _pool_size:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)

	# Pre-generate all streams once at startup
	_snd_shoot = _make_beep(880.0, 440.0, 0.07, 0.12)
	_snd_explosion = _make_noise(0.25, 800.0, 100.0)
	_snd_damage = _make_sawtooth(120.0, 60.0, 0.2)
	_snd_boss_hit = _make_sawtooth(100.0, 50.0, 0.15)
	_snd_shield_hit = _make_beep(2000.0, 1000.0, 0.1, 0.22)

	for f in [523.0, 659.0, 784.0, 1047.0]:
		_snd_powerup.append(_make_beep(f, f, 0.1, 0.1))

	for f in [523.0, 659.0, 784.0, 1047.0, 1047.0]:
		_snd_level_complete.append(_make_beep(f, f, 0.18, 0.15))

	for f in [880.0, 1100.0, 1320.0, 1760.0]:
		_snd_shield_activate.append(_make_beep(f, f * 1.1, 0.08, 0.18))

	for f in [300.0, 220.0, 150.0, 80.0]:
		_snd_boss_defeated.append(_make_noise(0.28, f, f * 0.4))

	_snd_combo_up.append(null)  # index 0 unused
	for level in range(1, 6):
		var freq := 440.0 + float(level) * 80.0
		_snd_combo_up.append(_make_beep(freq, freq * 1.5, 0.08, 0.15))


func play_shoot() -> void:
	_play(_snd_shoot, VOL_WEAPON)


func play_explosion() -> void:
	_play(_snd_explosion, VOL_IMPACT)


func play_powerup() -> void:
	for i in _snd_powerup.size():
		get_tree().create_timer(i * 0.08).timeout.connect(
			func(): _play(_snd_powerup[i], VOL_UI), CONNECT_ONE_SHOT
		)


func play_damage() -> void:
	_play(_snd_damage, VOL_IMPACT)


func play_level_complete() -> void:
	for i in _snd_level_complete.size():
		get_tree().create_timer(i * 0.15).timeout.connect(
			func(): _play(_snd_level_complete[i], VOL_UI), CONNECT_ONE_SHOT
		)


func play_shield_activate() -> void:
	for i in _snd_shield_activate.size():
		get_tree().create_timer(i * 0.06).timeout.connect(
			func(): _play(_snd_shield_activate[i], VOL_UI), CONNECT_ONE_SHOT
		)


func play_shield_hit() -> void:
	_play(_snd_shield_hit, VOL_IMPACT)


func play_boss_hit() -> void:
	_play(_snd_boss_hit, VOL_IMPACT)


func play_boss_defeated() -> void:
	for i in _snd_boss_defeated.size():
		get_tree().create_timer(i * 0.18).timeout.connect(
			func(): _play(_snd_boss_defeated[i], VOL_IMPACT), CONNECT_ONE_SHOT
		)


func play_combo_up(level: int) -> void:
	var idx := clampi(level, 1, _snd_combo_up.size() - 1)
	_play(_snd_combo_up[idx], VOL_UI)


func set_enabled(on: bool) -> void:
	_enabled = on
	SaveSystem.set_audio_enabled(on)


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
