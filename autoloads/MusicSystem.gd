extends Node

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _enabled: bool = true

# ── Timing ────────────────────────────────────────────────────────────────────
const SAMPLE_RATE := 44100.0
const TEMPO       := 138.0
const BEAT_LEN    := 60.0 / TEMPO
const STEP_LEN    := BEAT_LEN / 4.0   # 16th note
const INV_SR      := 1.0 / SAMPLE_RATE
const STEPS       := 16
const MEL_STEPS   := 64

var _step:     int   = 0
var _mel_step: int   = 0
var _step_t:   float = 0.0
var _t:        float = 0.0   # global time (seconds)

# ── Song data ─────────────────────────────────────────────────────────────────
# Semitones from A3 (MIDI 57).  -1 = rest.
# Lead: _note_to_freq(n + 9 + 48)  →  A4=440Hz at n=12
# Bass: _note_to_freq(n + 9 + 36)  →  A2=110Hz at n=-12
const MELODY := [
	12, -1, 19, -1,  24, -1, 19, 17,   15, -1, 12, -1,  15, 17, 19, -1,
	22, -1, 20, -1,  19, -1, 17, -1,   15, -1, 12, 14,  15, -1, 17, -1,
	19, -1, 22, -1,  24, 22, 19, 17,   15, 17, 19, -1,  22, -1, 24, -1,
	27, -1, 24, -1,  22, -1, 19, -1,   17, -1, 15, -1,  12, -1, -1, -1,
]
const BASS := [
	-12, -12, -5, -5,  -2, -2, -5, -7,  -12, -12, -5, -5,  -7, -7, -9, -5,
]
const ARP := [
	0, 3, 7, 12,  15, 19, 15, 12,  7, 3, 0, -9,  -5, 0, 7, 3,
]
# Drum patterns (1 = trigger, 0 = silence)
const KICK  := [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0]
const SNARE := [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0]
const CLAP  := [0,0,0,0, 0,0,1,0, 0,0,0,0, 0,0,1,0]
const HHAT  := [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0]
const OHAT  := [0,0,0,1, 0,0,0,1, 0,0,0,1, 0,0,0,1]

# ── Voice state ───────────────────────────────────────────────────────────────
# Lead (two detuned square waves)
var _lead_ph:   float = 0.0
var _lead_ph2:  float = 0.0
var _lead_env:  float = 0.0
var _lead_freq: float = 440.0
var _lead_on:   bool  = false

# Harmony (perfect 5th above lead)
var _harm_ph:   float = 0.0
var _harm_env:  float = 0.0
var _harm_freq: float = 660.0

# Bass (sawtooth + sub sine)
var _bass_ph:   float = 0.0
var _bass_sub:  float = 0.0
var _bass_env:  float = 0.0
var _bass_freq: float = 110.0

# Arpeggio (thin pulse)
var _arp_ph:    float = 0.0
var _arp_env:   float = 0.0
var _arp_freq:  float = 440.0

# Pad chord (3 sines: root, minor-3rd, 5th)
var _pad_ph0:   float = 0.0
var _pad_ph1:   float = 0.0
var _pad_ph2:   float = 0.0
var _pad_env:   float = 0.0
var _pad_tgt:   float = 0.0
var _pad_f0:    float = 110.0
var _pad_f1:    float = 130.8
var _pad_f2:    float = 164.8

# Kick (pitch-sweep sine)
var _kick_ph:   float = 0.0
var _kick_env:  float = 0.0
var _kick_freq: float = 120.0

# Snare / clap / hats
var _snare_env: float = 0.0
var _clap_env:  float = 0.0
var _hat_env:   float = 0.0
var _ohat_env:  float = 0.0

# Short reverb (comb filter delay line ~125 ms)
var _rev_buf := PackedFloat32Array()
const REV_LEN := 5513
var _rev_idx:   int   = 0


func _ready() -> void:
	_enabled = true
	_rev_buf.resize(REV_LEN)

	var gen := AudioStreamGenerator.new()
	gen.mix_rate    = SAMPLE_RATE
	gen.buffer_length = 0.15
	_player = AudioStreamPlayer.new()
	_player.stream    = gen
	_player.volume_db = -10.0
	_player.bus       = "Master"
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	if not _enabled or _playback == null:
		return
	var frames_available := _playback.get_frames_available()
	if frames_available <= 0:
		return

	for _i in frames_available:
		_t      += INV_SR
		_step_t += INV_SR
		if _step_t >= STEP_LEN:
			_step_t  -= STEP_LEN
			_step     = (_step     + 1) % STEPS
			_mel_step = (_mel_step + 1) % MEL_STEPS
			_trigger()

		var s: float = _synthesize()

		# Comb-filter reverb
		var rev: float = _rev_buf[_rev_idx] * 0.38
		s += rev
		_rev_buf[_rev_idx] = s * 0.40 + rev * 0.18
		_rev_idx = (_rev_idx + 1) % REV_LEN

		var out: float = clampf(s * 0.84, -0.95, 0.95)
		_playback.push_frame(Vector2(out, out))


func _synthesize() -> float:
	var s: float = 0.0

	# ── Lead: two detuned squares + vibrato ──────────────────────────────────
	if _lead_env > 0.0005:
		var env_sq: float = _lead_env * _lead_env   # squared = punchier attack
		var vib: float    = 1.0 + sin(_t * TAU * 5.5) * 0.004 * maxf(0.0, 1.0 - _lead_env * 2.5)
		var sq1: float    = 1.0 if fmod(_lead_ph,  1.0) < 0.5 else -1.0
		var sq2: float    = 1.0 if fmod(_lead_ph2, 1.0) < 0.5 else -1.0
		s += (sq1 * 0.6 + sq2 * 0.4) * env_sq * 0.14
		_lead_ph  += _lead_freq * vib * INV_SR
		_lead_ph2 += _lead_freq * 1.013 * vib * INV_SR
		_lead_env *= (0.9998 if _lead_on else 0.9920)

	# ── Harmony: square 5th above ──────────────────────────────────────────
	if _harm_env > 0.0005:
		var sq: float = 1.0 if fmod(_harm_ph, 1.0) < 0.5 else -1.0
		s += sq * _harm_env * _harm_env * 0.055
		_harm_ph  += _harm_freq * INV_SR
		_harm_env *= (0.9998 if _lead_on else 0.9920)

	# ── Bass: sawtooth + sub-octave sine ──────────────────────────────────
	if _bass_env > 0.0005:
		var saw: float = fmod(_bass_ph,  1.0) * 2.0 - 1.0
		var sub: float = sin(_bass_sub * TAU)
		s += (saw * 0.55 + sub * 0.45) * _bass_env * 0.22
		_bass_ph  += _bass_freq * INV_SR
		_bass_sub += _bass_freq * 0.5 * INV_SR   # sub-octave
		_bass_env *= 0.9994

	# ── Arpeggio: thin pulse ──────────────────────────────────────────────
	if _arp_env > 0.0005:
		var pulse: float = 1.0 if fmod(_arp_ph, 1.0) < 0.28 else -1.0
		s += pulse * _arp_env * 0.07
		_arp_ph  += _arp_freq * INV_SR
		_arp_env *= 0.9988

	# ── Pad: 3-voice sine chord ───────────────────────────────────────────
	if _pad_env > 0.0005:
		var p0: float = sin(_pad_ph0 * TAU)
		var p1: float = sin(_pad_ph1 * TAU)
		var p2: float = sin(_pad_ph2 * TAU)
		s += (p0 + p1 * 0.6 + p2 * 0.4) * _pad_env * 0.042
		_pad_ph0 += _pad_f0 * INV_SR
		_pad_ph1 += _pad_f1 * INV_SR
		_pad_ph2 += _pad_f2 * INV_SR
	# Slow attack / release
	_pad_env += (_pad_tgt - _pad_env) * 0.00018

	# ── Kick: pitch-sweeping sine ─────────────────────────────────────────
	if _kick_env > 0.0005:
		s += sin(_kick_ph * TAU) * _kick_env * 0.30
		_kick_ph   += _kick_freq * INV_SR
		_kick_freq  = maxf(28.0, _kick_freq * 0.9997)
		_kick_env  *= 0.9982

	# ── Snare: noise + sine body ──────────────────────────────────────────
	if _snare_env > 0.0005:
		var body: float  = sin(_kick_ph * TAU * 2.3) * 0.22
		s += (randf_range(-1.0, 1.0) + body) * _snare_env * 0.16
		_snare_env *= 0.9975

	# ── Closed hi-hat ─────────────────────────────────────────────────────
	if _hat_env > 0.0005:
		s += randf_range(-1.0, 1.0) * _hat_env * 0.062
		_hat_env *= 0.9905

	# ── Open hi-hat ───────────────────────────────────────────────────────
	if _ohat_env > 0.0005:
		s += randf_range(-1.0, 1.0) * _ohat_env * 0.055
		_ohat_env *= 0.9968

	# ── Clap: layered noise bursts ────────────────────────────────────────
	if _clap_env > 0.0005:
		s += randf_range(-1.0, 1.0) * _clap_env * 0.09
		_clap_env *= 0.9952

	return s


func _trigger() -> void:
	var mn: int = int(MELODY[_mel_step])
	var bn: int = int(BASS[_step])
	var an: int = int(ARP[_step])

	# ── Lead + harmony ────────────────────────────────────────────────────
	if mn >= 0:
		_lead_freq = _note_to_freq(mn + 9 + 48)
		_harm_freq = _note_to_freq(mn + 7 + 9 + 48)   # perfect 5th
		_lead_env  = 1.0
		_harm_env  = 1.0
		_lead_on   = true
	else:
		_lead_on = false

	# ── Bass (retrigger every step for rhythmic drive) ────────────────────
	_bass_freq = _note_to_freq(bn + 9 + 36)
	if KICK[_step] == 1:
		_bass_env  = 1.0
		_bass_ph   = 0.0    # hard sync on kick for punch
		_bass_sub  = 0.0
	else:
		_bass_env  = maxf(_bass_env, 0.65)   # bump without full reset

	# ── Arpeggio ──────────────────────────────────────────────────────────
	_arp_freq = _note_to_freq(an + 9 + 48)
	_arp_env  = 0.72

	# ── Pad: chord changes every 8 steps (half-bar) ───────────────────────
	if _step % 8 == 0:
		_pad_f0   = _note_to_freq(bn + 9 + 36) * 2.0   # one octave up from bass
		_pad_f1   = _pad_f0 * 1.18921                   # minor 3rd
		_pad_f2   = _pad_f0 * 1.49831                   # perfect 5th
		_pad_env  = 0.0                                  # brief retrigger dip
		_pad_tgt  = 1.0

	# ── Drums ──────────────────────────────────────────────────────────────
	if KICK[_step] == 1:
		_kick_env  = 1.0
		_kick_freq = 168.0
		_kick_ph   = 0.0

	if SNARE[_step] == 1:
		_snare_env = 1.0

	if HHAT[_step] == 1:
		_hat_env   = 1.0
		_ohat_env *= 0.04   # choke open hat on closed

	if OHAT[_step] == 1:
		_ohat_env  = 1.0

	if CLAP[_step] == 1:
		_clap_env  = 1.0


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
