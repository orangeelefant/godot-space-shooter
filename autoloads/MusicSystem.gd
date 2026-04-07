extends Node

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _enabled: bool = true

# Synthesis state
var _t: float = 0.0
var _beat_t: float = 0.0
var _bar: int = 0
const SAMPLE_RATE := 44100.0
const TEMPO := 138.0  # BPM, energetic retro feel
const BEAT_LEN := 60.0 / TEMPO

# Retro space melody (semitones from A3=220Hz), 16 steps, 2 bars
const MELODY_NOTES := [0, 0, 7, 12, 7, 5, 3, 0,   3, 3, 10, 15, 10, 8, 7, 3]
const BASS_NOTES   := [-12, -12, -5, 0, -12, -12, -5, 0,  -14, -14, -7, -2, -14, -14, -7, -2]
const CHORD_NOTES  := [0, 4, 7]  # major chord intervals
const STEPS := 16

var _step: int = 0
var _step_t: float = 0.0
const STEP_LEN := BEAT_LEN / 4.0  # 16th notes

# Per-voice state
var _mel_phase: float = 0.0
var _bass_phase: float = 0.0
var _chord_phases := [0.0, 0.0, 0.0]
var _arp_idx: int = 0
var _noise_env: float = 0.0


func _ready() -> void:
	_enabled = true  # always start enabled; can be muted via set_enabled
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = 0.15
	_player = AudioStreamPlayer.new()
	_player.stream = gen
	_player.volume_db = -14.0
	_player.bus = "Master"
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	if not _enabled or _playback == null:
		return
	var frames_available := _playback.get_frames_available()
	if frames_available <= 0:
		return

	var inv_rate := 1.0 / SAMPLE_RATE
	for _i in frames_available:
		_step_t += inv_rate
		if _step_t >= STEP_LEN:
			_step_t -= STEP_LEN
			_step = (_step + 1) % STEPS
			_arp_idx = (_arp_idx + 1) % CHORD_NOTES.size()

		var mel_freq := _note_to_freq(MELODY_NOTES[_step] + 9 + 48)   # A4 base
		var bass_freq := _note_to_freq(BASS_NOTES[_step] + 9 + 36)
		var chord_freq := _note_to_freq(CHORD_NOTES[_arp_idx] + 9 + 48)

		# Lead: square wave with envelope
		var mel_env := 1.0 - clampf(_step_t / STEP_LEN, 0.0, 1.0) * 0.4
		var mel := (fmod(_mel_phase, 1.0) > 0.5) * 2.0 - 1.0
		mel *= mel_env * 0.18
		_mel_phase += mel_freq / SAMPLE_RATE

		# Bass: triangle wave
		var bass := abs(fmod(_bass_phase, 1.0) * 2.0 - 1.0) * 2.0 - 1.0
		bass *= 0.22
		_bass_phase += bass_freq / SAMPLE_RATE

		# Arpeggio: pulse wave
		var arp := (fmod(_chord_phases[_arp_idx], 1.0) > 0.3) * 2.0 - 1.0
		arp *= 0.10
		_chord_phases[_arp_idx] += chord_freq / SAMPLE_RATE

		# Hi-hat: noise burst on even steps
		var hat := 0.0
		if _step % 2 == 0 and _step_t < 0.02:
			hat = (randf() * 2.0 - 1.0) * 0.06 * (1.0 - _step_t / 0.02)

		var sample := mel + bass + arp + hat
		_playback.push_frame(Vector2(sample, sample))


func set_enabled(on: bool) -> void:
	_enabled = on
	if on:
		if not _player.playing:
			_player.play()
			_playback = _player.get_stream_playback()
	else:
		_player.stop()


func set_volume(db: float) -> void:
	_player.volume_db = db


func _note_to_freq(semitone: int) -> float:
	return 440.0 * pow(2.0, (semitone - 69) / 12.0)
