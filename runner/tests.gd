extends SceneTree
const Game = preload("res://runner/game.gd")
const Level = preload("res://runner/level.gd")
const Bot = preload("res://qa/runner_bot.gd")
const Backdrop = preload("res://runner/backdrop.gd")
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("TEST FAIL: " + message)

func simulate(game: Node2D, seconds: float, held: bool) -> void:
	game.hold_override_enabled = true
	game.jump_held_override = held
	for i in range(ceili(seconds * 120)):
		game._physics_process(1.0 / 120)

func fresh(game: Node2D, x := 500.0, g := 1) -> void:
	game.start_session()
	game.state = "playing"
	game.hold_override_enabled = true
	game.jump_held_override = false
	game.player = Vector2(x, game.level.surface(x, g) - g * 6)
	game.gravity = g
	game.grounded = true
	game.vy = 0
	game.invulnerable = 0

func run() -> void:
	var a := Level.new()
	var b := Level.new()
	expect(a.layout_signature() == b.layout_signature(), "Course must be identical across independent instances")
	expect(a.gaps.size() >= 30 and a.apples.size() > 300 and a.gates.size() == 6, "Full authored course content")
	for section in range(1, 12):
		var x := 200.0 + section * 4800
		var before := Backdrop.biome_color(x - 0.01)
		var after := Backdrop.biome_color(x + 0.01)
		expect(Vector3(before.r, before.g, before.b).distance_to(Vector3(after.r, after.g, after.b)) < 0.001, "No biome color cut at section border")
	var game := Game.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	fresh(game)
	game.queue_jump()
	var bottom: float = game.player.y
	var minimum := bottom
	for i in range(100):
		game._physics_process(1.0 / 120)
		minimum = minf(minimum, game.player.y)
	var short_height := bottom - minimum
	fresh(game)
	game.jump_held_override = true
	game.queue_jump()
	bottom = game.player.y
	minimum = bottom
	for i in range(100):
		game._physics_process(1.0 / 120)
		minimum = minf(minimum, game.player.y)
	var full_height := bottom - minimum
	expect(full_height > short_height * 1.5, "Holding jump gives meaningful extra height")
	expect(game.grounded, "A held jump returns to the rail")
	print("JUMP: short=", snappedf(short_height, 1), " full=", snappedf(full_height, 1))
	fresh(game, 14600)
	simulate(game, 2.0, false)
	expect(game.gravity == -1 and game.last_gate == 0, "Crossing gate reverses gravity")
	expect(game.grounded and game.player.y < 270, "Pig must actually attach to ceiling rail")
	fresh(game, 16020, -1)
	var old_y: float = game.player.y
	game.queue_jump()
	simulate(game, 0.15, true)
	expect(game.player.y > old_y + 50, "Reversed jump goes away from ceiling")
	fresh(game, 6200)
	game.player.y = game.level.cable_height(0, 6200) + 168 + 8
	game.grounded = false
	game.jump_age = 0.12
	game.vy = -150
	game.try_attach_cable()
	expect(game.zipline == 0, "Jumping into cable corridor attaches trolley")
	game.queue_jump()
	simulate(game, 0.025, true)
	expect(game.zipline == -1 and game.vy < -500 and game.zipline_cooldown > 0, "Jump releases cable and prevents immediate reattachment")
	# A stomp is valid only from the gravity-relative head side, and adds no points.
	fresh(game, 500)
	var slime := {"p": Vector2(500, game.level.surface(500, 1)), "g": 1, "kind": "slime", "dead": false, "squash": 0.0, "phase": 0.0, "drop": 0.0, "triggered": false}
	game.level.enemies = [slime]
	var top: float = slime.p.y - 35
	game.player.y = top + 1
	game.vy = 400
	game.grounded = false
	game.update_enemies(1.0 / 120, Vector2(500, top - 6))
	expect(slime.dead and game.vy < -650 and game.health == 3, "Stomp kills slime and gives an automatic strong bounce")
	expect(game.score == 0, "Enemies do not give extra score")
	simulate(game, 0.1, false)
	expect(game.vy < -450, "Bounce is not cancelled when jump button is released")
	fresh(game)
	expect(game.take_damage() and game.health == 2, "Contact damage costs one heart")
	expect(not game.take_damage() and game.health == 2, "Damage grace prevents stacked damage")
	game.state = "paused"
	var saved_position: Vector2 = game.player
	var saved_time: float = game.run_time
	simulate(game, 0.5, false)
	expect(game.player == saved_position and game.run_time == saved_time, "Pause freezes simulation")
	game.pause_game()
	expect(game.state == "playing", "Pause resumes previous state")
	# The bot uses actual jump input and physics, without teleporting or invulnerability.
	game.level = Level.new()
	fresh(game, Game.START_X)
	var ticks := 0
	var flips := 0
	var cable_rides := 0
	var last_cable := -1
	var last_gravity := 1
	while game.state == "playing" and ticks < 22000:
		ticks += 1
		Bot.drive(game)
		game._physics_process(1.0 / 120)
		if game.zipline >= 0 and game.zipline != last_cable:
			cable_rides += 1
		last_cable = game.zipline
		if game.gravity != last_gravity:
			flips += 1
			last_gravity = game.gravity
		expect(game.health >= 0 and game.health <= 3, "Health bounds")
		expect(game.score == game.distance + 10 * game.apple_count, "Score is distance plus apples")
	print("COURSE: ticks=", ticks, " distance=", game.distance, " apples=", game.apple_count, " hearts=", game.health, " flips=", flips, " cables=", cable_rides, " reason=", game.result_reason)
	expect(game.result_reason == "finish" and game.distance == 4800 and flips == 6, "Complete fixed course is traversable through every gravity gate")
	expect(cable_rides == 4, "Complete course includes all four cable routes")
	# Session bookkeeping and save/load are tested with isolated data.
	game.start_session()
	game.state = "playing"
	game.score = 100
	game.finish_attempt("hearts")
	game.finish_delay = 0
	game.next_attempt()
	expect(game.attempt == 2 and game.results.size() == 1 and game.apple_count == 0, "Second attempt starts clean")
	game.state = "playing"
	game.score = 300
	game.finish_attempt("hearts")
	game.finish_delay = 0
	game.next_attempt()
	game.state = "playing"
	game.score = 200
	game.finish_attempt("hearts")
	expect(game.state == "final" and game.results.size() == 3 and game.best_score() == 300, "Maximum of three attempts, not sum or latest")
	var best: int = game.record
	game.record = 0
	game.load_save()
	expect(game.record == best and game.record >= 300, "Record persists")
	game.finish_delay = 0
	game.next_attempt()
	expect(game.attempt == 1 and game.results.is_empty() and game.state == "countdown", "Next player gets fresh session")
	if failures == 0:
		print("RUNNER TESTS PASS: deterministic level, short/held/reversed jumps, gravity gates, stomp and bounce, damage grace, pause, full course, score, 3 attempts, persistence, next player")
	else:
		print("RUNNER TESTS FAILED: ", failures)
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
