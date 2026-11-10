extends SceneTree
const Sprites = preload("res://runner/runner_sprites.gd")
class Probe extends Node2D:
	var frame := 0
	var g := 1
	var pony := false
	func _draw() -> void:
		if pony:
			Sprites.horse(self, frame, Vector2(100, 95), g)
		else:
			draw_set_transform(Vector2(100, 95), 0.0 if g == 1 else PI)
			Sprites.hero(self, frame, Vector2.ZERO, g == -1)
func _initialize() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	root.hide()
	run.call_deferred()
func run() -> void:
	var probes: Array = []
	for pony in [false, true]:
		for g in [1, -1]:
			for frame in range(8 if pony else 16):
				var viewport := SubViewport.new()
				viewport.size = Vector2i(220, 240)
				viewport.transparent_bg = true
				viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
				root.add_child(viewport)
				var probe := Probe.new()
				probe.frame = frame
				probe.g = g
				probe.pony = pony
				viewport.add_child(probe)
				probes.append({"v": viewport, "g": g, "frame": frame, "pony": pony})
	await process_frame
	await RenderingServer.frame_post_draw
	var failures := 0
	for item in probes:
		var image: Image = item.v.get_texture().get_image()
		var contact := 0 if item.g == 1 else 240
		for y in range(240):
			for x in range(220):
				if image.get_pixel(x, y).a > 0.8:
					contact = maxi(contact, y) if item.g == 1 else mini(contact, y)
		if abs(contact - 95) > 3:
			failures += 1
			push_error("V5 anchor: pony=%s frame=%s g=%s contact=%s" % [item.pony, item.frame, item.g, contact])
	print("V5 ANCHOR ", "PASS" if failures == 0 else "FAIL", ": 48 real rendered poses, both gravities, 3px tolerance")
	for item in probes:
		item.v.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
