extends Node2D
## Eight painted run poses, airborne/strike poses and spring-driven impact response.
const Sprites = preload("res://runner/runner_sprites.gd")
var sample: Dictionary = {}
var frame := 8
var run_phase := 0.0
var compression := 0.0
var compression_velocity := 0.0
var lean := 0.0

func impact(strength: float) -> void:
	compression_velocity += -0.65 if strength < 0 else clampf(strength * 0.0012, 0.15, 0.8)

func reset() -> void:
	compression = 0
	compression_velocity = 0
	run_phase = 0
	lean = 0

func present(dt: float, data: Dictionary) -> void:
	sample = data
	dt = minf(dt, 0.08)
	for i in range(maxi(1, ceili(dt / 0.008))):
		var step := dt / maxi(1, ceili(dt / 0.008))
		compression_velocity += (-compression * 300 - compression_velocity * 24) * step
		compression += compression_velocity * step
	compression = clampf(compression, -0.10, 0.15)
	var running: bool = data.get("running", false)
	if running and data.grounded:
		run_phase += dt * clampf(float(data.get("speed", 410)) / 34.0, 11, 19)
		frame = int(run_phase) % 8
	else:
		frame = 9 if data.get("allow_blink", true) and fmod(float(data.time), 4.0) > 3.82 else 8
	if not data.grounded:
		frame = 10 if data.vy * data.gravity < -50 else 11
	var attack: float = data.get("attack", 0)
	if attack > 0:
		frame = 12 if attack > 0.255 else (13 if attack > 0.12 else 14)
	if data.get("ziplining", false):
		frame = 15
	var target := clampf(float(data.get("slope", 0)) * 0.35, -0.08, 0.08) if data.grounded else clampf(data.vy * data.gravity * 0.00010, -0.09, 0.08)
	if data.get("ziplining", false):
		target = data.get("swing", 0) * 0.08
	lean = lerpf(lean, target, 1 - exp(-dt * 15))
	rotation = data.angle + lean
	var alpha := 0.45 + absf(sin(data.time * 25)) * 0.55 if data.invulnerable > 0 else 1.0
	modulate = Color(1, 0.65 if data.hurt > 0 else 1.0, 0.65 if data.hurt > 0 else 1.0, alpha)
	queue_redraw()

func _draw() -> void:
	if sample.is_empty():
		return
	var vertical := 1 - compression
	var stretch := 0.045 if not sample.grounded and sample.vy * sample.gravity < -200 else 0.0
	Sprites.hero(self, frame, Vector2.ZERO, sample.angle > PI * 0.5, Vector2(1 + compression * 0.5 - stretch * 0.5, vertical + stretch))
