extends SceneTree
const Game = preload("res://runner/game.gd")
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.start_session()
	game.state = "playing"
	game.hold_override_enabled = true
	game.jump_held_override = true
	for tick in range(18000):
		if game.state != "playing":
			break
		if game.grounded:
			for gap in game.level.gaps:
				if gap.g == game.gravity and gap.a > game.player.x and gap.a - game.player.x < game.speed * 0.22:
					game.queue_jump()
			for enemy in game.level.enemies:
				if not enemy.dead and enemy.g == game.gravity and enemy.p.x > game.player.x and enemy.p.x - game.player.x < game.speed * 0.31:
					game.queue_jump()
		var before: Vector2 = game.player
		game._physics_process(1.0 / 120)
		if tick % 120 == 0 or game.player.x - before.x > 10:
			print(tick, " x=", snappedf(game.player.x, 1), " y=", snappedf(game.player.y, 1), " v=", game.speed, " g=", game.gravity, " zip=", game.zipline, " grounded=", game.grounded, " hp=", game.health)
	quit()
