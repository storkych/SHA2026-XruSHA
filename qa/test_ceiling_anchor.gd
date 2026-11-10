extends SceneTree
const Sprites = preload("res://runner/sprites.gd")
class Probe extends Node2D:
	var frame := 0
	var gravity := 1
	func _draw() -> void:
		Sprites.draw(self, "enemies", frame, Vector2(80, 80), 1.0, gravity)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var probes: Array = []
	for g in [1, -1]:
		for frame in range(8):
			var viewport := SubViewport.new()
			viewport.size = Vector2i(160, 160)
			viewport.transparent_bg = true
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(viewport)
			var probe := Probe.new()
			probe.frame = frame
			probe.gravity = g
			viewport.add_child(probe)
			probes.append({"viewport": viewport, "g": g, "frame": frame})
	await process_frame
	await RenderingServer.frame_post_draw
	var failed := false
	for item in probes:
		var image: Image = item.viewport.get_texture().get_image()
		var minimum := 160
		var maximum := -1
		for y in range(160):
			for x in range(160):
				if image.get_pixel(x, y).a > 0.6:
					minimum = mini(minimum, y)
					maximum = maxi(maximum, y)
		var contact: int = maximum if item.g == 1 else minimum
		if abs(contact - 80) > 3:
			failed = true
			push_error("Sprite contact regression: frame %d gravity %d y=%d expected 80" % [item.frame, item.g, contact])
	print("CEILING ANCHOR ", "FAIL" if failed else "PASS", ": 16 actual rendered sprites, contact within 3px of rail")
	quit(1 if failed else 0)
