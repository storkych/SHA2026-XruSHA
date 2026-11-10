extends SceneTree
const Game = preload("res://runner/game.gd")
class Bot extends Node:
	var game: Node2D
	var elapsed := 0.0
	func _physics_process(dt: float) -> void:
		elapsed += dt
		if elapsed > 10:
			get_tree().quit()
		if game.state != "playing" or not game.grounded:
			return
		for gap in game.level.gaps:
			if gap.g == game.gravity and gap.a > game.player.x and gap.a - game.player.x < game.speed * 0.22:
				game.queue_jump()
		for enemy in game.level.enemies:
			if not enemy.dead and enemy.g == game.gravity and enemy.p.x > game.player.x and enemy.p.x - game.player.x < game.speed * 0.31:
				game.queue_jump()

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1600, 900)
	run.call_deferred()

func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.start_session()
	game.state = "playing"
	game.player = Vector2(5800, game.level.surface(5800, 1) - 6)
	game.camera_x = 5800 - 460
	game.hold_override_enabled = true
	game.jump_held_override = true
	var bot := Bot.new()
	bot.game = game
	bot.process_physics_priority = -10
	root.add_child(bot)
