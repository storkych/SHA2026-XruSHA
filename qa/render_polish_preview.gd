extends SceneTree
const Stage = preload("res://qa/polish_preview_stage.gd")

func _initialize() -> void:
	root.size = Vector2i(800, 540)
	root.content_scale_size = Vector2i(800, 540)
	root.title = "ХрюША2026 — анимация персонажа"
	render.call_deferred()

func render() -> void:
	var directory := ProjectSettings.globalize_path("res://qa/captures/polish/frames")
	DirAccess.make_dir_recursive_absolute(directory)
	var stage := Stage.new()
	root.add_child(stage)
	for frame in range(240):
		stage.set_time(frame / 30.0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join("frame-%03d.png" % frame))
		if frame % 60 == 0:
			print("PREVIEW FRAME ", frame, "/240")
	print("PREVIEW CAPTURE COMPLETE: ", directory)
	quit()
