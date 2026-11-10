extends Node
## Small original synthesized sound bank. No downloaded audio or runtime dependencies.
var muted := false
var voices: Array[AudioStreamPlayer] = []
var bank: Dictionary = {}
var music: AudioStreamPlayer
var rhythm: AudioStreamPlayer
var drive: AudioStreamPlayer
var playing_scene := false
var intensity := 0.0
var current_intensity := 0.0
const BASE_TRACK = preload("res://assets/runner/music/base.wav")
const RHYTHM_TRACK = preload("res://assets/runner/music/rhythm.wav")
const DRIVE_TRACK = preload("res://assets/runner/music/drive.wav")

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		muted = true
		return
	for i in range(20):
		var voice := AudioStreamPlayer.new()
		voice.bus = "Master"
		add_child(voice)
		voices.append(voice)
	bank["shoot"] = tone(610.0, 1120.0, 0.12, 0.22, 0.01)
	bank["hit"] = tone(1046.5, 1174.7, 0.16, 0.18, 0.0)
	bank["pop"] = tone(210.0, 92.0, 0.14, 0.32, 0.07)
	bank["jump"] = tone(160.0, 460.0, 0.15, 0.16, 0.01)
	bank["land"] = tone(104.0, 48.0, 0.13, 0.30, 0.12)
	bank["roll"] = tone(145.0, 85.0, 0.045, 0.09, 0.30)
	bank["step"] = tone(100.0, 60.0, 0.045, 0.12, 0.30)
	bank["swish"] = tone(550.0, 180.0, 0.11, 0.17, 0.22)
	bank["thump"] = tone(160.0, 65.0, 0.10, 0.30, 0.10)
	bank["snort"] = tone(130.0, 65.0, 0.16, 0.24, 0.20)
	bank["hurt"] = tone(230.0, 100.0, 0.24, 0.3, 0.08)
	bank["reload"] = tone(530.0, 340.0, 0.08, 0.16, 0.02)
	bank["ready"] = tone(650.0, 1000.0, 0.17, 0.22, 0.0)
	bank["tick"] = tone(650.0, 600.0, 0.06, 0.17, 0.0)
	bank["win"] = tone(390.0, 780.0, 0.7, 0.23, 0.0)
	bank["windup"] = tone(170.0, 230.0, 0.18, 0.12, 0.015)
	bank["bird"] = tone(2200.0, 3300.0, 0.11, 0.10, 0.0)
	bank["chime"] = tone(1320.0, 1760.0, 0.40, 0.13, 0.0)
	for i in range(5):
		var midi: int = [72, 74, 77, 79, 81][i]
		var hz := 440.0 * pow(2.0, (midi - 69) / 12.0)
		bank["apple_%d" % i] = tone(hz, hz, 0.17, 0.17, 0.0)
	music = score_player(BASE_TRACK, -5)
	rhythm = score_player(RHYTHM_TRACK, -20)
	drive = score_player(DRIVE_TRACK, -30)

func score_player(source: AudioStreamWAV, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream: AudioStreamWAV = source.duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	player.stream = stream
	player.volume_db = volume
	add_child(player)
	player.play()
	return player

func set_scene(active: bool, energy: float) -> void:
	playing_scene = active
	intensity = energy if active else 0.0

func _process(dt: float) -> void:
	if not is_instance_valid(music):
		return
	current_intensity = lerpf(current_intensity, intensity, 1.0 - exp(-dt * 1.7))
	var attenuation := 0.0 if playing_scene else -9.0
	music.volume_db = lerpf(music.volume_db, -5 + attenuation, 1 - exp(-dt * 2))
	rhythm.volume_db = lerpf(rhythm.volume_db, -9 + current_intensity * 5 + attenuation, 1 - exp(-dt * 2))
	drive.volume_db = lerpf(drive.volume_db, -26 + current_intensity * 22 + attenuation, 1 - exp(-dt * 2))

func tone(start: float, finish: float, duration: float, volume: float, noise: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	var rate := 22050
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 54
	for i in range(int(duration * rate)):
		var t := float(i) / rate
		var p := t / duration
		phase += TAU * lerpf(start, finish, p) / rate
		var envelope := minf(t * 100.0, 1.0) * pow(1.0 - p, 1.7)
		var wave := sin(phase) * 0.8 + sin(phase * 2.002) * 0.2
		var sample := int(clampf((wave + rng.randf_range(-noise, noise)) * envelope * volume, -1.0, 1.0) * 32767)
		data.append(sample & 255)
		data.append((sample >> 8) & 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream

func play(key: String, pitch := 1.0, volume := 0.0) -> void:
	if muted or not bank.has(key):
		return
	for voice in voices:
		if not voice.playing:
			voice.stream = bank[key]
			voice.pitch_scale = pitch
			voice.volume_db = volume
			voice.play()
			return

func set_muted(value: bool) -> void:
	muted = value
	for track in [music, rhythm, drive]:
		if is_instance_valid(track):
			track.stream_paused = value
	if value:
		for voice in voices:
			voice.stop()

func _exit_tree() -> void:
	for track in [music, rhythm, drive]:
		if is_instance_valid(track):
			track.stop()
			track.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null
	bank.clear()

func restart_score() -> void:
	for track in [music, rhythm, drive]:
		if is_instance_valid(track):
			track.play(0.0)
			track.stream_paused = muted
