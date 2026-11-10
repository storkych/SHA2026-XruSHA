extends SceneTree
const Game = preload("res://runner/game.gd")
const Bot = preload("res://qa/runner_bot.gd")
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.start_session()
	game.state = "playing"
	for tick in range(20000):
		if game.state != "playing":
			break
		Bot.drive(game)
		var hp: int = game.health
		var before: Vector2 = game.player
		game._physics_process(1.0 / 120)
		if game.health < hp:
			print("HIT at ", before, " after ", game.player, " g=", game.gravity, " speed=", game.speed, " grounded=", game.grounded, " attack=", game.attack_time)
			for enemy in game.level.enemies:
				if absf(enemy.p.x - before.x) < 250:
					print("  enemy ", enemy.kind, " p=", game.enemy_position(enemy), " dead=", enemy.dead, " hp=", enemy.get("hp"), " stun=", enemy.get("stun"))
	print("END ", game.result_reason, " distance=", game.distance, " defeated=", game.defeated)
	game.queue_free()
	await process_frame
	quit()
