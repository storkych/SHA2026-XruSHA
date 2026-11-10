extends RefCounted
const Base = preload("res://scripts/art.gd")
const INK := Color("122b4e")
const PAPER := Color("fff4d8")
const HEART = preload("res://assets/runner/v4/heart.png")
const Sprites = preload("res://runner/sprites.gd")

static func e(c: CanvasItem, p: Vector2, r: Vector2, color: Color, width := 3.0) -> void:
	Base.ellipse(c, p, r, color, width, INK)

static func p(c: CanvasItem, points: Array, color: Color, width := 3.0) -> void:
	Base.poly(c, points, color, width, INK)

static func line(c: CanvasItem, points: Array, color := INK, width := 3.0) -> void:
	Base.line(c, points, color, width)

static func round_rect(c: CanvasItem, rect: Rect2, color: Color, radius := 8, border := 3) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = INK
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border)
	c.draw_style_box(box, rect)

static func apple(c: CanvasItem, pos: Vector2, size := 1.0, alpha := 1.0) -> void:
	Sprites.prop(c, 0, pos + Vector2(0, 13 * size), 28 * size, 1, Color(1, 1, 1, alpha))

static func heart(c: CanvasItem, pos: Vector2, full: bool) -> void:
	c.draw_texture_rect_region(HEART, Rect2(pos - Vector2(19, 18), Vector2(38, 35)), Rect2(160, 250, 920, 810), Color.WHITE if full else Color(0.19, 0.22, 0.25, 0.55))

static func enemy(c: CanvasItem, pos: Vector2, kind: String, t: float, gravity: int, squash: float) -> void:
	pos.y -= gravity * 5
	if kind == "crate":
		Sprites.prop(c, 1, pos, 56, gravity)
		return
	if kind == "rock":
		Sprites.prop(c, 5, pos, 62, gravity)
		return
	var frame := 0
	if kind == "slime":
		var sequence := [0, 1, 0, 2]
		frame = 3 if squash > 0 else sequence[int(t * 4) % 4]
	else:
		frame = 4 + int(t * 9) % 4
	var alpha := clampf(squash * 2.5, 0, 1) if squash > 0 else 1.0
	Sprites.draw(c, "enemies", frame, pos, 1.0, gravity, Color(1, 1, 1, alpha))

static func rail(c: CanvasItem, track: Dictionary, camera_x: float, view_width: float, lava: bool) -> void:
	var a := maxf(track.a, camera_x - 100)
	var b := minf(track.b, camera_x + view_width + 100)
	if b <= a:
		return
	var g: int = track.g
	var ya := lerpf(track.y1, track.y2, (a - track.a) / maxf(1, track.b - track.a))
	var yb := lerpf(track.y1, track.y2, (b - track.a) / maxf(1, track.b - track.a))
	if track.bridge:
		p(c, [Vector2(a, ya + 12 * g), Vector2(b, yb + 12 * g), Vector2(b, yb + 31 * g), Vector2(a, ya + 31 * g)], Color("775b4c"), 3)
		for x in range(floori(a / 180) * 180, ceili(b), 180):
			if x < a:
				continue
			var y := lerpf(ya, yb, (x - a) / maxf(1, b - a))
			line(c, [Vector2(x, y + 30 * g), Vector2(x, 930 if g == 1 else -30)], INK, 14)
			line(c, [Vector2(x, y + 30 * g), Vector2(x, 930 if g == 1 else -30)], Color("775b4c"), 8)
	else:
		var edge := 940.0 if g == 1 else -40.0
		p(c, [Vector2(a, ya + 9 * g), Vector2(b, yb + 9 * g), Vector2(b, edge), Vector2(a, edge)], Color("2c4265"), 0)
		# Low polygon rock tiles form an actual repeatable foreground tileset.
		for row in range(3):
			var y := (maxf(ya, yb) + 35 + row * 63) if g == 1 else (minf(ya, yb) - 35 - row * 63)
			for col in range(floori(a / 95) - 1, ceili(b / 95) + 1):
				var x := col * 95.0 + (42 if row % 2 else 0)
				var left := maxf(a + 2, x)
				var right := minf(b - 2, x + 89)
				if right - left < 33:
					continue
				var color := Color("405679").lightened(sin(col * 13.4 + row * 4.7) * 0.06)
				Sprites.stone(c, 4 + (absi(col + row) % 2), Rect2(left, y - 28, right - left, 57), color.lightened(0.63))
		line(c, [Vector2(a, ya + 18 * g), Vector2(b, yb + 18 * g)], INK, 6)
	# Rail sleepers are on the solid side, never hovering in a gap.
	for ix in range(floori(a / 36) * 36, ceili(b), 36):
		if ix < a or ix + 23 > b:
			continue
		var y := lerpf(ya, yb, (ix - a) / maxf(1, b - a))
		round_rect(c, Rect2(ix, y + (5 if g == 1 else -18), 24, 13), Color("b8804b"), 2, 2)
	line(c, [Vector2(a, ya), Vector2(b, yb)], INK, 12)
	line(c, [Vector2(a, ya - 2 * g), Vector2(b, yb - 2 * g)], Color("b9ccde"), 6)
	line(c, [Vector2(a, ya - 4 * g), Vector2(b, yb - 4 * g)], Color("eef5e7"), 2)

static func gate(c: CanvasItem, pos: Vector2, to_gravity: int, from_gravity: int, t: float) -> void:
	var g := float(from_gravity)
	var color := Color("49e4e6") if to_gravity == -1 else Color("ffbc53")
	var center := pos - Vector2(0, 63 * g)
	e(c, center, Vector2(48, 57), color.darkened(0.45), 5)
	e(c, center, Vector2(36, 45), Color("183b55"), 4)
	c.draw_arc(center, 39, 0, TAU, 40, Color(color, 0.55 + sin(t * 4) * 0.15), 4, true)
	for x in [-48.0, 36.0]:
		round_rect(c, Rect2(pos.x + x, minf(pos.y - 47 * g, pos.y), 13, 47), Color("7c9bb5"), 4, 3)
	var direction := -1.0 if to_gravity == -1 else 1.0
	line(c, [center + Vector2(0, -16 * direction), center + Vector2(0, 15 * direction)], color, 7)
	line(c, [center + Vector2(-13, 2 * direction), center + Vector2(0, 16 * direction), center + Vector2(13, 2 * direction)], color, 7)
