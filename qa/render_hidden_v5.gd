extends SceneTree
const Game = preload("res://runner/game.gd")
const Bot = preload("res://qa/runner_bot.gd")
var viewport: SubViewport
var game: Node2D
func _initialize() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	root.hide()
	run.call_deferred()
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://qa/captures/v5")
	viewport = SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	game = Game.new()
	viewport.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	await snapshot("menu")
	game.results = [{"score": 1820}, {"score": 2350}, {"score": 2110}]
	game.state = "final"
	game.ui.sync()
	await snapshot("results")
	setup(1510)
	game.queue_attack()
	for i in range(10):
		game._physics_process(1.0 / 120)
	await snapshot("punch")
	game.state = "paused"
	game.ui.sync()
	await snapshot("pause")
	setup(25200)
	for i in range(110):
		Bot.drive(game)
		game._physics_process(1.0 / 120)
	await snapshot("bridge")
	if "--snapshots-only" in OS.get_cmdline_user_args():
		game.queue_free()
		viewport.queue_free()
		await process_frame
		quit()
		return
	DirAccess.make_dir_recursive_absolute("res://qa/captures/v5/frames")
	var starts := [1460.0, 39900.0, 16200.0, 5920.0, 25200.0]
	for section in range(starts.size()):
		setup(starts[section])
		for frame in range(60):
			for tick in range(4):
				Bot.drive(game)
				game._physics_process(1.0 / 120)
			game._process(1.0 / 30)
			await process_frame
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_jpg("res://qa/captures/v5/frames/frame-%04d.jpg" % (section * 60 + frame), 0.97)
		print("HIDDEN V5 SEGMENT ", section, " health=", game.health, " defeated=", game.defeated, " zip=", game.zipline)
	game.queue_free()
	viewport.queue_free()
	await process_frame
	quit()

func setup(x: float) -> void:
	game.start_session()
	game.state = "playing"
	game.gravity = game.level.gravity_at(x)
	game.rotation_visual = 0 if game.gravity == 1 else PI
	game.player = Vector2(x, game.level.surface(x, game.gravity) - game.gravity * 6)
	game.camera_x = x - 460
	game.run_time = (x - 200) / 500
	game.speed = 410 + 100 * smoothstep(0, 40, game.run_time) + 150 * smoothstep(40, 110, game.run_time)
	game.last_gate = -1
	for i in range(game.level.gates.size()):
		if game.level.gates[i].x < x:
			game.last_gate = i
	game.hold_override_enabled = true
	game.jump_held_override = true
	game.ui.sync()

func snapshot(name: String) -> void:
	game._process(1.0 / 30)
	await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image().save_png("res://qa/captures/v5/%s.png" % name)
	print("HIDDEN SNAPSHOT ", name, " = ", result)
