extends Node2D
const Biomes = preload("res://runner/biomes.gd")
const Art = preload("res://runner/scene_sprites.gd")
var camera := 0.0
var clock := 0.0
var player_x := 0.0

func _ready() -> void:
	z_index = -4
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func present(x: float, time: float, rider_x: float) -> void:
	camera = x
	clock = time
	player_x = rider_x
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var night := Biomes.night(player_x)
	var accent := Biomes.accent(player_x)
	# Large painted shapes are framing objects, never over the next landing.
	for i in range(floori(camera * 0.54 / 1050) - 1, ceili((camera * 0.54 + size.x) / 1050) + 1):
		var x := i * 1050.0 - camera * 0.54
		if night > 0:
			Art.prop(self, 3, Vector2(x + 490, size.y - 98), 180, Color(0.54, 0.67, 0.88, night))
	# Slow soft light shafts behind the route.
	for i in range(3):
		var x := fposmod(i * 670 - camera * 0.06, size.x + 400) - 200
		var color := accent
		color.a = (0.018 + sin(clock * 0.45 + i) * 0.006) * (1 - night * 0.65)
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 35, 0), Vector2(x + 310, size.y), Vector2(x + 110, size.y)]), color)
	# Petals / luminous spores have independent drift and tumble.
	for i in range(48):
		var x := fposmod(i * 143.7 - camera * 0.31 - clock * (18 + i % 4 * 4), size.x + 180) - 90
		var y := fposmod(i * 93.4 + clock * (8 + i % 3 * 2), size.y + 80) - 40
		var center := Vector2(x, y + sin(clock * 1.1 + i) * 16)
		var color := Biomes.leaf(player_x)
		color.a = 0.28 + sin(i * 1.7) * 0.14
		var angle := clock * 0.7 + i
		var radius := 2.0 + i % 3
		var axis := Vector2.from_angle(angle) * radius
		var side := axis.orthogonal() * 0.4
		draw_colored_polygon(PackedVector2Array([center - axis, center + side, center + axis, center - side]), color)
		if night > 0.1 and i % 3 == 0:
			draw_circle(center, 2, Color(accent, night * 0.35), true, -1, true)
	# Tiny two-wing butterflies make a few pockets feel alive.
	if night < 0.5:
		for i in range(3):
			var p := Vector2(fposmod(i * 691 - camera * 0.4 + clock * 12, size.x + 160) - 80, 270 + i * 115 + sin(clock * 1.7 + i) * 30)
			var flap := 2 + absf(sin(clock * 14 + i)) * 5
			draw_colored_polygon(PackedVector2Array([p, p + Vector2(-flap, -5), p + Vector2(-flap * 0.6, 5)]), Color("ffd797"))
			draw_colored_polygon(PackedVector2Array([p, p + Vector2(flap, -5), p + Vector2(flap * 0.6, 5)]), Color("ffb7cd"))
