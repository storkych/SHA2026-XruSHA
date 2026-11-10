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
	DirAccess.make_dir_recursive_absolute("res://qa/captures/v7")
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
	game.result_age = 2.0
	await snapshot("results")
	game.state = "result"
	game.attempt = 2
	game.score = 2350
	game.results = [{"score":1820}, {"score":2350}]
	game.ui.sync()
	await snapshot("attempt")
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
	setup(19800)
	for i in range(80):
		Bot.drive(game)
		game._physics_process(1.0 / 120)
	await snapshot("grotto")
	setup(49700)
	for i in range(70):
		Bot.drive(game)
		game._physics_process(1.0 / 120)
	await snapshot("embers")
	setup(8910)
	for i in range(28):
		game._physics_process(1.0 / 120)
	await snapshot("wind")
	setup(2660)
	await snapshot("edges")
	setup(6300)
	game.zipline = 0
	game.grounded = false
	game.player.y = game.cable_y(0, game.player.x) + 168
	await snapshot("zipline")
	for trans in [0, 700, 1400, 2100, 2800]:
		setup(14400 + trans)
		await snapshot("transition-%d" % trans)
	if "--snapshots-only" in OS.get_cmdline_user_args():
		game.queue_free()
		viewport.queue_free()
		await process_frame
		quit()
		return
	DirAccess.make_dir_recursive_absolute("res://qa/captures/v7/frames")
	var video_index := 0
	game.state = "final"
	game.results = [{"score": 1820}, {"score": 2350}, {"score": 2110}]
	game.result_age = 0
	game.ui.sync()
	for frame in range(48):
		game._physics_process(1.0 / 30)
		game._process(1.0 / 30)
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_jpg("res://qa/captures/v7/frames/frame-%04d.jpg" % video_index, 0.97)
		video_index += 1
	var starts := [1460.0, 18200.0, 49100.0, 8730.0, 13035.0, 25200.0]
	for section in range(starts.size()):
		setup(starts[section])
		if section == 4:
			var ledge: Dictionary = game.level.bonus[1]
			game.player.y = game.track_height(ledge, game.player.x) - 6
		for frame in range(180 if section == 1 else 60):
			for tick in range(4):
				Bot.drive(game)
				game._physics_process(1.0 / 120)
			game._process(1.0 / 30)
			await process_frame
			await RenderingServer.frame_post_draw
			if section == 4 and frame == 34:
				viewport.get_texture().get_image().save_png("res://qa/captures/v7/crumble.png")
			if section == 1 and frame == 28:
				viewport.get_texture().get_image().save_png("res://qa/captures/v7/moving.png")
			viewport.get_texture().get_image().save_jpg("res://qa/captures/v7/frames/frame-%04d.jpg" % video_index, 0.97)
			video_index += 1
		print("HIDDEN V7 SEGMENT ", section, " health=", game.health, " defeated=", game.defeated, " zip=", game.zipline)
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
	game.level.advance(game.run_time, 0)
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
	var result := viewport.get_texture().get_image().save_png("res://qa/captures/v7/%s.png" % name)
	print("HIDDEN SNAPSHOT ", name, " = ", result)

