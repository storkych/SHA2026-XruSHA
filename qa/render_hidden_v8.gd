extends "res://qa/render_hidden_v7.gd"
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://qa/captures/v8/frames")
	viewport = SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	game = Game.new()
	viewport.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.results = [{"score": 1820}, {"score": 2350}, {"score": 2110}]
	game.state = "final"
	game.time = 3.84
	game.invulnerable = 1.7
	game.hurt_flash = 0.22
	game.result_age = 2
	game.ui.sync()
	await snapshot("result-no-blink")
	var frame_index := 0
	for frame in range(90):
		game._physics_process(1.0 / 30)
		game._process(1.0 / 30)
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_jpg("res://qa/captures/v8/frames/frame-%04d.jpg" % frame_index, 0.97)
		frame_index += 1
	for kind in ["bird", "snail", "chime", "mushroom", "pod", "fireflies", "crystal", "puddle"]:
		var candidates: Array = game.world_life.objects.filter(func(o): return o.kind == kind)
		var target: Dictionary = candidates[0]
		var x: float = target.p.x
		setup(x - (125 if kind in ["bird", "snail", "pod", "crystal"] else 30))
		if kind in ["pod", "crystal"]:
			game.queue_attack()
		for frame in range(40):
			for tick in range(4):
				Bot.drive(game)
				game._physics_process(1.0 / 120)
			game._process(1.0 / 30)
			await process_frame
			await RenderingServer.frame_post_draw
			if frame == 10:
				viewport.get_texture().get_image().save_png("res://qa/captures/v8/%s.png" % kind)
			viewport.get_texture().get_image().save_jpg("res://qa/captures/v8/frames/frame-%04d.jpg" % frame_index, 0.97)
			frame_index += 1
		print("WORLD V8 CLIP ", kind, " x=", x, " hp=", game.health, " apples=", game.apple_count)
	game.queue_free()
	viewport.queue_free()
	await process_frame
	quit()

func snapshot(name: String) -> void:
	game._process(1.0 / 30)
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://qa/captures/v8/%s.png" % name)
	print("HIDDEN V8 SNAPSHOT ", name)
