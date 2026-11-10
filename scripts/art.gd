extends RefCounted
## Resolution-independent, hand-built 2D character art. Every pose is drawn from moving parts.
const INK := Color("48294f")
const PINK := Color("f7a4c7")
const LIGHT := Color("ffd2df")

static func ellipse(c: CanvasItem, p: Vector2, r: Vector2, color: Color, border := 3.0, outline := INK) -> void:
	if minf(r.x, r.y) < 1.5:
		c.draw_circle(p, maxf(r.x, r.y), color, true, -1, true)
		return
	var points := PackedVector2Array()
	for i in range(48):
		var a := TAU * i / 48.0
		points.append(p + Vector2(cos(a) * r.x, sin(a) * r.y))
	c.draw_colored_polygon(points, color)
	if border > 0.0:
		points.append(points[0])
		c.draw_polyline(points, outline, border, true)

static func poly(c: CanvasItem, points: Array, color: Color, border := 3.0, outline := INK) -> void:
	var packed := PackedVector2Array(points)
	if packed.size() > 3 and packed[0].distance_to(packed[packed.size() - 1]) < 0.01:
		packed.resize(packed.size() - 1)
	c.draw_colored_polygon(packed, color)
	if border > 0:
		packed.append(packed[0])
		c.draw_polyline(packed, outline, border, true)

static func line(c: CanvasItem, points: Array, color := INK, width := 3.0) -> void:
	c.draw_polyline(PackedVector2Array(points), color, width, true)

static func curve(c: CanvasItem, points: Array, color := INK, width := 3.0) -> void:
	var path := Curve2D.new()
	for i in range(points.size()):
		var before: Vector2 = points[maxi(0, i - 1)]
		var after: Vector2 = points[mini(points.size() - 1, i + 1)]
		var tangent := (after - before) * 0.15
		path.add_point(points[i], -tangent, tangent)
	c.draw_polyline(path.get_baked_points(), color, width, true)

static func star(c: CanvasItem, p: Vector2, r: float, color: Color, angle := 0.0) -> void:
	var points: Array = []
	for i in range(10):
		points.append(p + Vector2.from_angle(angle + i * TAU / 10.0 - PI / 2.0) * r * (1.0 if i % 2 == 0 else 0.45))
	poly(c, points, color, 1.7)

static func bubble(c: CanvasItem, p: Vector2, r: float, alpha := 1.0, time := 0.0) -> void:
	var fill := Color(0.73, 0.91, 1.0, 0.2 * alpha)
	ellipse(c, p, Vector2.ONE * r, fill, 2.4, Color(0.9, 0.99, 1.0, 0.92 * alpha))
	c.draw_arc(p + Vector2(r * 0.03, 0), r * 0.88, 0.3, 1.9, 24, Color(1.0, 0.62, 0.85, 0.8 * alpha), maxf(2.0, r * 0.09), true)
	c.draw_arc(p, r * 0.9, 1.9, 3.0, 18, Color(0.67, 0.7, 1.0, 0.8 * alpha), maxf(2.0, r * 0.07), true)
	c.draw_arc(p, r * 0.87, 3.5, 4.6, 20, Color(0.87, 1.0, 0.84, 0.9 * alpha), maxf(2.0, r * 0.08), true)
	ellipse(c, p + Vector2(-0.3, -0.39) * r, Vector2(0.15, 0.24) * r, Color(1.0, 1.0, 1.0, 0.88 * alpha), 0)
	ellipse(c, p + Vector2(0.3, 0.48) * r, Vector2(0.08, 0.06) * r, Color(1.0, 1.0, 1.0, 0.65 * alpha), 0)
	if r > 40:
		c.draw_arc(p, r * 0.7, time * 0.3, time * 0.3 + 0.5, 10, Color(1.0, 1.0, 1.0, 0.3 * alpha), 2, true)

static func pig(c: CanvasItem, phase: float, speed: float, aim: Vector2, jump: float, recoil: float, time: float, reload: float, hurt: bool) -> void:
	var bob := sin(phase * 2) * speed * 2.0 + sin(time * 3.0) * 1.0
	var leg := sin(phase) * speed * 10.0
	var ear := sin(time * 5.0 + phase) * (2.0 + speed * 2.0)
	var pink := Color("ffc8d9") if hurt else PINK
	# Far limbs, backpack, and a small curled tail.
	curve(c, [Vector2(-27, -20 + bob), Vector2(-43, -23 + bob), Vector2(-45, -15 + bob), Vector2(-39, -12 + bob), Vector2(-36, -18 + bob)], INK, 3.5)
	ellipse(c, Vector2(-20, -25 + bob), Vector2(19, 23), Color("ad7b55"), 3)
	poly(c, [Vector2(-33, -43 + bob), Vector2(-11, -42 + bob), Vector2(-10, -22 + bob), Vector2(-33, -24 + bob)], Color("d9a067"), 2.5)
	poly(c, [Vector2(-24, -34 + bob), Vector2(-17, -34 + bob), Vector2(-17, -27 + bob), Vector2(-24, -27 + bob)], Color("ffe092"), 2)
	line(c, [Vector2(-8, -39 + bob), Vector2(-19, -5 + bob)], Color("946144"), 5)
	ellipse(c, Vector2(8 - leg, -1), Vector2(10, 13), Color("df81ac"), 3)
	ellipse(c, Vector2(10 - leg, 7), Vector2(9, 5), INK, 0)
	# Scarf tails trail behind the running character.
	poly(c, [Vector2(-11, -52 + bob), Vector2(-36, -53 + bob), Vector2(-59 - speed * 5, -62 + bob + ear), Vector2(-53, -48 + bob + ear), Vector2(-64, -46 + bob), Vector2(-36, -39 + bob), Vector2(-9, -41 + bob)], Color("f65c7c"), 3)
	ellipse(c, Vector2(0, -24 + bob), Vector2(25, 27), pink, 3.5)
	ellipse(c, Vector2(4, -21 + bob), Vector2(15, 19), Color("ffc0d7"), 0)
	# Forward leg rotates naturally through the walk cycle, tucks during jump.
	ellipse(c, Vector2(-10 + leg, -1 - jump * 8), Vector2(11, 14), pink, 3)
	ellipse(c, Vector2(-8 + leg, 8 - jump * 8), Vector2(10, 5), INK, 0)
	# Head, soft drooping ears, muzzle.
	ellipse(c, Vector2(5, -61 + bob), Vector2(32, 28), pink, 3.5)
	poly(c, [Vector2(-16, -79 + bob), Vector2(-37, -92 + bob + ear), Vector2(-36, -76 + bob + ear), Vector2(-26, -69 + bob), Vector2(-13, -73 + bob)], pink, 3)
	line(c, [Vector2(-29, -82 + bob + ear), Vector2(-27, -75 + bob)], Color("e77da9"), 3)
	poly(c, [Vector2(13, -85 + bob), Vector2(25, -99 + bob - ear), Vector2(31, -87 + bob), Vector2(27, -76 + bob)], pink, 3)
	ellipse(c, Vector2(31, -55 + bob), Vector2(20, 15), Color("f58bb4"), 3)
	ellipse(c, Vector2(26, -55 + bob), Vector2(2.8, 5.0), INK, 0)
	ellipse(c, Vector2(38, -55 + bob), Vector2(2.8, 5.0), INK, 0)
	ellipse(c, Vector2(-9, -54 + bob), Vector2(7.5, 5), Color("f47ca6"), 0)
	var blink := fmod(time + 0.12, 4.7) < 0.13
	if blink:
		line(c, [Vector2(8, -67 + bob), Vector2(17, -67 + bob)], INK, 3)
	else:
		ellipse(c, Vector2(13, -68 + bob), Vector2(6.5, 8.5), Color("fff9f1"), 0)
		ellipse(c, Vector2(15, -68 + bob) + aim * 2.2, Vector2(3.5, 5.0), INK, 0)
		ellipse(c, Vector2(15, -70 + bob) + aim * 2.2, Vector2(1.2, 1.8), Color.WHITE, 0)
	curve(c, [Vector2(6, -79 + bob), Vector2(13, -80 + bob), Vector2(20, -76 + bob)], INK, 3)
	curve(c, [Vector2(10, -44 + bob), Vector2(16, -39 + bob), Vector2(23, -41 + bob)], INK, 2.4)
	# Neck knot and a front hoof holding the gun.
	poly(c, [Vector2(-21, -42 + bob), Vector2(7, -37 + bob), Vector2(24, -43 + bob), Vector2(22, -34 + bob), Vector2(4, -28 + bob), Vector2(-18, -34 + bob)], Color("f65c7c"), 3)
	ellipse(c, Vector2(22 - recoil * 4, -27 + bob), Vector2(12, 8), pink, 3)
	ellipse(c, Vector2(31 - recoil * 4, -27 + bob), Vector2(6, 7), INK, 0)
	if reload > 0:
		c.draw_arc(Vector2(5, -52), 49, -PI / 2, -PI / 2 + TAU * reload, 36, Color("fff4ad"), 4, true)

static func gun(c: CanvasItem, recoil: float, time: float, reload: float) -> void:
	var kick := recoil * 7.0
	# Handle and turquoise pressure chamber.
	poly(c, [Vector2(-6 - kick, 1), Vector2(7 - kick, 3), Vector2(4 - kick, 23), Vector2(-7 - kick, 21)], Color("f7ce71"), 3)
	ellipse(c, Vector2(7 - kick, -2), Vector2(24, 12), Color("38bfc6"), 3)
	poly(c, [Vector2(8 - kick, -12), Vector2(32 - kick, -12), Vector2(32 - kick, 9), Vector2(8 - kick, 9)], Color("57dce0"), 3)
	line(c, [Vector2(0 - kick, -7), Vector2(22 - kick, -7)], Color("abfcf0"), 3)
	# Soap bottle with visible sloshing liquid and stopper.
	ellipse(c, Vector2(-5 - kick, -29), Vector2(15, 19), Color("d9f9ff"), 3)
	ellipse(c, Vector2(-5 - kick, -24 + sin(time * 8.0) * reload * 2), Vector2(11, 10), Color("a5b7f6"), 0)
	ellipse(c, Vector2(-10 - kick, -35), Vector2(3, 6), Color.WHITE, 0)
	ellipse(c, Vector2(-1 - kick, -23), Vector2(2, 2), Color("f4ffff"), 0)
	poly(c, [Vector2(-14 - kick, -48), Vector2(4 - kick, -48), Vector2(4 - kick, -42), Vector2(-14 - kick, -42)], Color("f8d47a"), 2.5)
	# Golden bubble wand muzzle. This silhouette reads as a toy, not a firearm.
	ellipse(c, Vector2(34 - kick, -2), Vector2(8, 19), Color("ffe087"), 3)
	ellipse(c, Vector2(35 - kick, -2), Vector2(3.8, 12), Color("96e8db"), 2)
	ellipse(c, Vector2(-20 - kick, -2), Vector2(6, 7), Color("f8d47a"), 2)

static func horse(c: CanvasItem, phase: float, speed: float, time: float, variant: int, state: String, hit: float, eyes: Vector2) -> void:
	var coat: Color = [Color("c78a69"), Color("aaaccb"), Color("e6b97b")][variant]
	var mane: Color = [Color("6e435c"), Color("626584"), Color("ad695a")][variant]
	var light := coat.lightened(0.18)
	if hit > 0:
		coat = coat.lerp(Color.WHITE, hit * 0.8)
	var run := sin(phase) * speed
	var bob := absf(cos(phase)) * speed * 4 + sin(time * 2.5) * 1.2
	var trapped := state == "trapped"
	var windup := state == "windup"
	if trapped:
		run = sin(time * 8) * 0.4
	# Tail has follow-through rather than being fixed to the body.
	curve(c, [Vector2(-27, -39 + bob), Vector2(-42, -55 + bob + sin(time * 7) * 5), Vector2(-56, -48 + bob), Vector2(-51, -37 + bob)], mane, 10)
	# Four independently cycling legs.
	for i in range(4):
		var x := (-20.0 if i < 2 else 16.0)
		var side := 1.0 if i % 2 == 0 else -1.0
		var step := run * side * (14.0 if i < 2 else -14.0)
		var y := -22.0 + (4.0 if i % 2 == 0 else -4.0)
		var foot := Vector2(x + step, 6 - absf(run) * 5.0 * (1.0 if side > 0 else 0.3))
		if trapped:
			foot.y -= 7
		poly(c, [Vector2(x - 6, y), Vector2(x + 7, y), foot + Vector2(6, 0), foot + Vector2(-6, 0)], coat.darkened(0.12) if i % 2 else coat, 2.8)
		ellipse(c, foot, Vector2(8, 5), mane, 2)
	ellipse(c, Vector2(-3, -35 + bob), Vector2(34, 22), coat, 3.5)
	ellipse(c, Vector2(-12, -39 + bob), Vector2(19, 10), light, 0)
	# Long horse neck and recognizable elongated muzzle.
	poly(c, [Vector2(10, -37 + bob), Vector2(18, -74 + bob), Vector2(37, -78 + bob), Vector2(47, -40 + bob), Vector2(24, -20 + bob)], coat, 3.5)
	poly(c, [Vector2(14, -46 + bob), Vector2(8, -51 + bob), Vector2(15, -58 + bob), Vector2(9, -63 + bob), Vector2(19, -70 + bob), Vector2(12, -77 + bob), Vector2(27, -86 + bob), Vector2(39, -77 + bob), Vector2(26, -58 + bob)], mane, 2.5)
	poly(c, [Vector2(23, -78 + bob), Vector2(18, -100 + bob), Vector2(31, -93 + bob), Vector2(36, -78 + bob)], coat, 3)
	line(c, [Vector2(25, -92 + bob), Vector2(28, -82 + bob)], light, 3)
	poly(c, [Vector2(40, -79 + bob), Vector2(44, -99 + bob), Vector2(51, -88 + bob), Vector2(50, -73 + bob)], coat, 3)
	ellipse(c, Vector2(41, -63 + bob), Vector2(24, 25), coat, 3.5)
	poly(c, [Vector2(23, -80 + bob), Vector2(31, -94 + bob), Vector2(34, -86 + bob), Vector2(43, -97 + bob), Vector2(44, -86 + bob), Vector2(54, -90 + bob), Vector2(50, -76 + bob), Vector2(37, -72 + bob)], mane, 2.8)
	ellipse(c, Vector2(57, -48 + bob), Vector2(21, 16), Color("f5d5ab"), 3)
	ellipse(c, Vector2(65, -52 + bob), Vector2(2.5, 4), mane, 0)
	if trapped:
		ellipse(c, Vector2(44, -65 + bob), Vector2(8, 10), Color("fffcf4"), 2)
		ellipse(c, Vector2(46, -65 + bob), Vector2(3, 5), INK, 0)
		ellipse(c, Vector2(56, -37 + bob), Vector2(5, 4), INK, 0)
	elif fmod(time + variant * 0.7, 4.3) < 0.12:
		line(c, [Vector2(36, -66 + bob), Vector2(49, -65 + bob)], INK, 3)
	else:
		ellipse(c, Vector2(43, -65 + bob), Vector2(7, 9), Color("fff9ed"), 2)
		ellipse(c, Vector2(44, -65 + bob) + eyes * 2, Vector2(3, 4.5), INK, 0)
		line(c, [Vector2(33, -78 + bob), Vector2(49, -73 + bob)], INK, 3)
		curve(c, [Vector2(53, -38 + bob), Vector2(61, -37 + bob), Vector2(67, -40 + bob)], INK, 2.3)
	if windup:
		for i in range(3):
			var p := Vector2(16 + i * 15, -112 - (8 if i == 1 else 0))
			line(c, [p, p + Vector2(0, -10)], Color("fff3a9"), 4)
