extends Node2D
const Art = preload("res://scripts/art.gd")
var tufts: Array = []
var props: Array = []
var patches: Array = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 8362
	for i in range(440):
		tufts.append({"p": Vector2(rng.randf_range(90, 2310), rng.randf_range(90, 1610)), "s": rng.randf_range(0.6, 1.3), "f": rng.randf() < 0.09})
	for i in range(38):
		patches.append({"p": Vector2(rng.randf_range(100, 2300), rng.randf_range(100, 1600)), "s": Vector2(rng.randf_range(45, 140), rng.randf_range(15, 45))})
	for i in range(19):
		props.append({"p": Vector2(70 + i * 126, 75 + sin(i) * 14), "s": rng.randf_range(0.9, 1.3)})
		props.append({"p": Vector2(70 + i * 126, 1650 + sin(i) * 12), "s": rng.randf_range(0.9, 1.3)})
	for i in range(13):
		props.append({"p": Vector2(20, 130 + i * 120), "s": rng.randf_range(0.8, 1.25)})
		props.append({"p": Vector2(2370, 130 + i * 120), "s": rng.randf_range(0.8, 1.25)})
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-2000, -2000, 6400, 5700), Color("37b995"))
	Art.ellipse(self, Vector2(1200, 880), Vector2(1600, 1150), Color("46cba6"), 0)
	draw_style_box(ground_box(), Rect2(40, 60, 2320, 1570))
	for patch in patches:
		Art.ellipse(self, patch.p, patch.s, Color(0.55, 0.91, 0.72, 0.16), 0)
	# A quiet winding dirt path under the action, never obstructs movement.
	var path := Curve2D.new()
	path.add_point(Vector2(90, 900), Vector2.ZERO, Vector2(250, -20))
	path.add_point(Vector2(1050, 1420), Vector2(-250, 50), Vector2(280, -30))
	path.add_point(Vector2(2300, 1150), Vector2(-280, -70), Vector2.ZERO)
	draw_polyline(path.get_baked_points(), Color("85dfb3"), 70, true)
	draw_polyline(path.get_baked_points(), Color("94e5b9"), 42, true)
	for tuft in tufts:
		var p: Vector2 = tuft.p
		var s: float = tuft.s
		if tuft.f:
			flower(p, s)
		else:
			Art.curve(self, [p + Vector2(-7, 0) * s, p + Vector2(-6, -5) * s, p + Vector2(-2, 0) * s], Color("4abe99"), 2.3)
			Art.curve(self, [p, p + Vector2(2, -8) * s, p + Vector2(4, -5) * s], Color("4abe99"), 2.3)
	# Fence and bushes form a legible arena perimeter.
	for y in [115.0, 1580.0]:
		Art.line(self, [Vector2(90, y - 30), Vector2(2310, y - 30)], Art.INK, 13)
		Art.line(self, [Vector2(90, y - 31), Vector2(2310, y - 31)], Color("e8a591"), 8)
		Art.line(self, [Vector2(90, y - 5), Vector2(2310, y - 5)], Art.INK, 11)
		Art.line(self, [Vector2(90, y - 6), Vector2(2310, y - 6)], Color("edb9a0"), 7)
		for x in range(95, 2340, 160):
			Art.poly(self, [Vector2(x - 7, y + 13), Vector2(x - 7, y - 47), Vector2(x, y - 54), Vector2(x + 8, y - 47), Vector2(x + 8, y + 13)], Color("efb29d"), 3)
	for prop in props:
		bush(prop.p, prop.s)
	# A few deliberate foreground props, all outside the playable boundary.
	rock(Vector2(310, 190), 1.1)
	rock(Vector2(2070, 1490), 1.4)
	rock(Vector2(2260, 300), 0.8)
	flower(Vector2(1860, 380), 1.5)
	flower(Vector2(750, 1270), 1.3)
	for p in [Vector2(655, 535), Vector2(1785, 650), Vector2(1600, 1235), Vector2(670, 1190)]:
		rock(p, 1.0)
		flower(p + Vector2(-48, 18), 0.9)

func ground_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("6bdab4")
	s.corner_radius_top_left = 140
	s.corner_radius_top_right = 140
	s.corner_radius_bottom_left = 140
	s.corner_radius_bottom_right = 140
	return s

func flower(p: Vector2, s: float) -> void:
	for i in range(5):
		Art.ellipse(self, p + Vector2.from_angle(i * TAU / 5.0) * 5 * s, Vector2(5, 4) * s, Color("fff8e0"), 0)
	Art.ellipse(self, p, Vector2.ONE * 3.5 * s, Color("ffd76c"), 0)

func bush(p: Vector2, s: float) -> void:
	Art.ellipse(self, p + Vector2(0, 14), Vector2(60, 17) * s, Color("3eb28e"), 0)
	var points: Array = []
	for i in range(49):
		var a := i * TAU / 48.0
		var r := 1.0 + sin(a * 7) * 0.12
		points.append(p + Vector2(cos(a) * 58, sin(a) * 38) * r * s)
	Art.poly(self, points, Color("31b68f"), 3, Color("319c85"))
	Art.curve(self, [p + Vector2(-31, -8) * s, p + Vector2(-21, -23) * s, p + Vector2(-7, -16) * s], Color("53cba0"), 4)
	Art.ellipse(self, p + Vector2(24, -5) * s, Vector2(4, 5), Color("f79cb2"), 0)
	Art.ellipse(self, p + Vector2(13, 4) * s, Vector2(4, 4), Color("f79cb2"), 0)

func rock(p: Vector2, s: float) -> void:
	Art.ellipse(self, p + Vector2(0, 8), Vector2(37, 11) * s, Color("54bda4"), 0)
	Art.poly(self, [p + Vector2(-35, 4) * s, p + Vector2(-25, -20) * s, p + Vector2(-4, -32) * s, p + Vector2(22, -23) * s, p + Vector2(35, 2) * s, p + Vector2(8, 10) * s], Color("b2b5d0"), 3)
	Art.poly(self, [p + Vector2(-25, -20) * s, p + Vector2(-4, -32) * s, p + Vector2(8, -25) * s, p + Vector2(-5, -5) * s], Color("d0cee1"), 0)
