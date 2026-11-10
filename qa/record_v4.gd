extends SceneTree
const Game = preload("res://runner/game.gd")
class Director extends Node:
	var game: Node2D
	var elapsed := 0.0
	var stage := -1
	var captured := false
	const STARTS := [3070.0, 5940.0, 15900.0, 25200.0, 38300.0]
	func _physics_process(dt: float) -> void:
		elapsed += dt
		if elapsed >= 20:
			get_tree().quit()
			return
		var next := floori(elapsed / 4.0)
		if next != stage:
			stage = next
			captured = false
			game.start_session()
			game.state = "playing"
			var x: float = STARTS[stage]
			var g: int = game.level.gravity_at(x)
			game.gravity = g
			game.rotation_visual = 0 if g == 1 else PI
			game.player = Vector2(x, game.level.surface(x, g) - g * 6)
			game.camera_x = x - 460
			game.run_time = (x - 200) / 500
			game.speed = 410 + 100 * smoothstep(0, 40, game.run_time) + 150 * smoothstep(40, 110, game.run_time)
			game.last_gate = -1
			for i in range(game.level.gates.size()):
				if game.level.gates[i].x < x:
					game.last_gate = i
		if fposmod(elapsed, 4.0) > 1.8 and not captured:
			captured = true
			save_frame.call_deferred(stage)
		if game.state != "playing" or not game.grounded:
			return
		for gap in game.level.gaps:
			if gap.g == game.gravity and gap.a > game.player.x and gap.a - game.player.x < game.speed * 0.22:
				game.queue_jump()
		for enemy in game.level.enemies:
			if not enemy.dead and enemy.g == game.gravity and enemy.p.x > game.player.x and enemy.p.x - game.player.x < game.speed * 0.31:
				game.queue_jump()
	func save_frame(index: int) -> void:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://qa/captures/v4/scene-%02d.png" % index)

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1600, 900)
	run.call_deferred()
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://qa/captures/v4")
	var game := Game.new()
	root.add_child(game)
	game.hold_override_enabled = true
	game.jump_held_override = true
	var director := Director.new()
	director.game = game
	director.process_physics_priority = -10
	root.add_child(director)
