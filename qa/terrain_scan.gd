extends SceneTree
const Game = preload("res://runner/game.gd")
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.start_session()
	game.state = "playing"
	game.set_physics_process(false)
	for x in range(200, 57800, 500):
		game.player.x = x
		game.camera_x = x - 460
		await process_frame
		await RenderingServer.frame_post_draw
	print("GPU TERRAIN SCAN: entire 4800m at 500px intervals rendered")
	game.queue_free()
	await process_frame
	quit()
