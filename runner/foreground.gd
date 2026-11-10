extends Node2D
const IMAGE = preload("res://assets/runner/v4/foreground.png")
const Props = preload("res://runner/scene_sprites.gd")
const Biomes = preload("res://runner/biomes.gd")
var world_x := 0.0
var camera := 0.0
var clock := 0.0
func _ready() -> void:
	z_index = 8
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
func present(x: float, time: float, rider_x := 0.0) -> void:
	camera = x
	clock = time
	world_x = rider_x
	queue_redraw()
func _draw() -> void:
	var size := get_viewport_rect().size
	# Bottom fringe never covers the route at y~755 or the next obstacle.
	var width := 1700.0
	var left := -fposmod(camera * 1.12, width)
	for i in range(2):
		var x := left + i * width
		draw_texture_rect(IMAGE, Rect2(x + sin(clock * 0.8) * 2, size.y - 200, width, 265), false, Color(0.95, 0.98, 1, 0.92))
	for i in range(floori(camera * 1.12 / 2100) - 1, ceili((camera * 1.12 + size.x) / 2100) + 1):
		var x := i * 2100.0 - camera * 1.12 + 280
		Props.prop(self, 3 if Biomes.night(world_x) > 0.5 else 0, Vector2(x, size.y + 30), 140, Color(0.75, 0.82, 0.88, 0.95))
