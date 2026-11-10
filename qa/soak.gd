extends SceneTree
## Deterministic automated integration run, exercises real simulation through three rounds.
const Game = preload("res://scripts/game.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.start_session()
	var total_caught := 0
	var rounds := 0
	var ticks := 0
	var elapsed := 0.0
	while rounds < 3 and ticks < 30000:
		ticks += 1
		var dt := 1.0 / 120
		elapsed += dt
		if game.state == "playing":
			var destination := Vector2(1200, 850) + Vector2(cos(elapsed * 0.55) * 355, sin(elapsed * 0.55) * 270)
			game.player = game.player.move_toward(destination, dt * 235)
			game.player = game.avoid_rocks(game.player, 18)
		game._physics_process(dt)
		if game.state == "playing":
			var target: Dictionary = {}
			var best := INF
			for e in game.enemies:
				if e.state in ["spawn", "trapped"]:
					continue
				var distance: float = game.player.distance_to(e.p)
				if distance < best:
					best = distance
					target = e
			if not target.is_empty():
				game.aim = (target.p + Vector2(0, -35) - (game.player + Vector2(43 * game.facing, -18))).normalized()
				game.facing = 1.0 if game.aim.x > 0 else -1.0
				game.shoot()
				if target.state == "charge" and best < 170:
					game.start_jump()
			assert(game.hp >= 0 and game.hp <= 3)
			assert(game.ammo >= 0 and game.ammo <= 6)
			assert(game.particles.size() <= 600)
			assert(game.player == game.clamp_position(game.player))
		if game.state in ["result", "final"]:
			rounds += 1
			total_caught += game.caught
			print("ROUND ", rounds, ": score=", game.score, " catches=", game.caught, " hearts=", game.hp, " remaining=", snappedf(game.remaining, 0.1))
			if rounds < 3:
				game.next_round()
	assert(rounds == 3 and game.state == "final")
	assert(game.scores.size() == 3 and total_caught > 10)
	assert(game.record >= int(game.scores.max()))
	print("SOAK PASS: ", ticks, " fixed ticks, three complete rounds, ", total_caught, " captured horses, final results and persistence")
	game.queue_free()
	await process_frame
	quit()
