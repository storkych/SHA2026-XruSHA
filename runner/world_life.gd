extends Node2D
## Authored encounters. Visual reactions and optional harvests never block the route.
signal encounter(kind: String, pos: Vector2, apples: int)
const IMAGE = preload("res://assets/runner/v8/world-life.png")
const Props = preload("res://runner/scene_sprites.gd")
const Biomes = preload("res://runner/biomes.gd")
const REGIONS := [Rect2(50,88,352,284), Rect2(496,6,347,351), Rect2(910,100,398,250), Rect2(1410,100,290,249), Rect2(59,450,339,405), Rect2(483,452,350,406), Rect2(915,462,366,396), Rect2(1359,473,388,379)]
const KINDS := ["bird", "snail", "chime", "mushroom", "pod", "fireflies", "crystal", "puddle"]
var objects: Array = []
var motes: Array = []
var fruits: Array = []
var clock := 0.0
var camera := 0.0

func _ready() -> void:
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func reset(level: RefCounted) -> void:
	objects.clear()
	motes.clear()
	fruits.clear()
	clock = 0
	for i in range(120):
		var x := 1100.0 + i * 465
		var kind: String = KINDS[i % 8]
		var g: int = 1 if kind == "bird" else level.gravity_at(x)
		if level.is_gap(x - 75, g) or level.is_gap(x, g) or level.is_gap(x + 75, g):
			continue
		var crowded := false
		for enemy in level.enemies:
			if absf(enemy.p.x - x) < 170:
				crowded = true
		if crowded:
			continue
		var p := Vector2(x, level.surface(x, g) + g * 3)
		if kind == "chime":
			p.y += -240 if g == 1 else 70
		elif kind == "fireflies":
			p.y -= g * 100
		objects.append({"kind": kind, "p": p, "g": g, "phase": float(i) * 1.37, "age": -1.0, "pulse": 0.0, "cooldown": 0.0, "opened": false, "swing": 0.0, "v": 0.0, "last_strike": -1})

func spr(index: int, foot: Vector2, width: float, g := 1, color := Color.WHITE) -> void:
	var region: Rect2 = REGIONS[index]
	var h := width * region.size.y / region.size.x
	draw_texture_rect_region(IMAGE, Rect2(foot.x - width * 0.5, foot.y - h if g == 1 else foot.y, width, h * g), region, color)

func scatter(obj: Dictionary, count: int, color: Color, water := false) -> void:
	for i in range(count):
		var angle: float = -obj.g * (0.35 + i * 0.43)
		motes.append({"p": obj.p - Vector2(0, obj.g * 22), "v": Vector2.from_angle(angle) * (45 + i % 5 * 18), "life": 0.8 + i % 4 * 0.15, "max": 1.25, "color": color, "water": water})
	if motes.size() > 150:
		motes = motes.slice(motes.size() - 150)

func activate(obj: Dictionary, harvest := false) -> void:
	if obj.cooldown > 0 or (obj.kind == "pod" and (obj.opened or not harvest)):
		return
	if obj.kind == "bird" and obj.age >= 0:
		return
	obj.cooldown = 1.0
	obj.pulse = 1.0
	obj.v += 3.5
	if obj.age < 0:
		obj.age = 0
	match obj.kind:
		"pod":
			obj.opened = true
			scatter(obj, 14, Color("ffcf75"))
			for i in range(3):
				fruits.append({"p": obj.p - Vector2(0, obj.g * 40), "v": Vector2(100 + i * 65, -obj.g * (180 + i * 35)), "age": 0.0, "g": obj.g})
			encounter.emit("pod", obj.p, 3)
		"mushroom":
			scatter(obj, 12, Color("92f2e4"))
			encounter.emit("mushroom", obj.p, 0)
		"crystal":
			scatter(obj, 8, Color("ceaaff"))
			encounter.emit("crystal", obj.p, 0)
		"chime":
			scatter(obj, 5, Color("ffe4a0"))
			encounter.emit("chime", obj.p, 0)
		"bird":
			encounter.emit("bird", obj.p, 0)
		"puddle":
			scatter(obj, 9, Color("9de8ec"), true)
		_:
			pass

func strike(player: Vector2, g: int, serial: int) -> void:
	var fist := player - Vector2(0, g * 63)
	for obj in objects:
		var target: Vector2 = obj.p - Vector2(0, g * 30)
		if obj.kind == "chime":
			target = obj.p + Vector2(0, 65)
		if obj.g != g or obj.last_strike == serial or target.x < player.x - 8 or target.x > player.x + 155 or absf(target.y - fist.y) > 95:
			continue
		obj.last_strike = serial
		activate(obj, true)

func advance(dt: float, player: Vector2, grounded: bool, g: int) -> void:
	clock += dt
	for obj in objects:
		if obj.age >= 0:
			obj.age += dt
		obj.cooldown = maxf(0, obj.cooldown - dt)
		obj.pulse = maxf(0, obj.pulse - dt * 1.3)
		obj.v += (-obj.swing * 38 - obj.v * 4) * dt
		obj.swing = clampf(obj.swing + obj.v * dt, -0.55, 0.55)
		if obj.g != g or absf(obj.p.x - player.x) > 150:
			continue
		var near_surface: bool = absf(obj.p.y - player.y) < 100
		match obj.kind:
			"bird":
				if near_surface and obj.age < 0:
					activate(obj)
			"snail":
				if near_surface:
					obj.pulse = minf(1.0, obj.pulse + dt * 7)
			"chime":
				if absf(obj.p.x - player.x) < 65 and obj.age < 0:
					activate(obj)
			"mushroom", "puddle":
				if grounded and near_surface and absf(obj.p.x - player.x) < 38 and obj.age < 0:
					activate(obj)
			"fireflies":
				obj.pulse = 1.0
	for mote in motes:
		mote.life -= dt
		mote.p += mote.v * dt
		mote.v *= exp(-dt * 0.8)
		mote.v.y += dt * (190 if mote.water else -12)
	motes = motes.filter(func(m): return m.life > 0)
	for fruit in fruits:
		fruit.age += dt
		fruit.p += fruit.v * dt
		fruit.v.y += fruit.g * 420 * dt
	fruits = fruits.filter(func(f): return f.age < 0.6)

func present(x: float) -> void:
	camera = x
	queue_redraw()

func _draw() -> void:
	for obj in objects:
		if obj.p.x < camera - 500 or obj.p.x > camera + 2000:
			continue
		var p: Vector2 = obj.p
		match obj.kind:
			"bird":
				if obj.age > 2.4:
					continue
				for j in range(3):
					var age := maxf(0, obj.age - j * 0.09)
					var offset := Vector2(j * 31 - 20, -j % 2 * 7)
					if obj.age >= 0:
						offset += Vector2(age * 170, -age * 135 - sin(age * 5) * 17)
					var frame := 1 if obj.age >= 0 and int(clock * 13 + j) % 2 else 0
					spr(frame, p + offset, 37 + j * 3, 1, Color(1, 1, 1, 1 - smoothstep(1.8, 2.4, obj.age)))
			"snail":
				var hiding: bool = obj.pulse > 0.3
				spr(3 if hiding else 2, p + Vector2(-6 if hiding else sin(clock * 0.7 + obj.phase) * 3, 0), 35 if hiding else 48, obj.g)
			"chime":
				var points := PackedVector2Array()
				for j in range(20):
					var t := j / 19.0
					points.append(Vector2(p.x + sin(t * 4 + obj.phase) * 9 * sin(t * PI), lerpf(-100, p.y, t)))
				draw_polyline(points, Color("574c35"), 4, true)
				draw_polyline(points, Color("b4b273"), 1, true)
				draw_set_transform(p, obj.swing + sin(clock * 1.5 + obj.phase) * 0.05)
				spr(4, Vector2(0, 105), 88)
				draw_set_transform(Vector2.ZERO)
			"pod":
				draw_set_transform(p, obj.swing * 0.3, Vector2(1 + obj.pulse * 0.08, obj.g * (1 - obj.pulse * 0.1)))
				spr(6 if obj.opened else 5, Vector2.ZERO, 69)
				draw_set_transform(Vector2.ZERO)
			"mushroom":
				draw_set_transform(p, obj.swing * 0.08, Vector2(1 + obj.pulse * 0.12, obj.g * (1 - obj.pulse * 0.12)))
				spr(7, Vector2.ZERO, 78)
				draw_set_transform(Vector2.ZERO)
			"fireflies":
				for j in range(9):
					var angle: float = clock * 0.8 + j * TAU / 9 + obj.phase
					var radius: float = 32 + obj.pulse * 65
					var fly := p + Vector2(cos(angle) * radius, sin(angle * 1.5) * radius * 0.6)
					draw_circle(fly, 7, Color(0.65, 1, 0.7, 0.06), true, -1, true)
					draw_circle(fly, 2.2, Color(0.93, 1, 0.65, 0.6 + sin(clock * 4 + j) * 0.25), true, -1, true)
			"crystal":
				Props.prop(self, 3, p, 67, Color(1 + obj.pulse * 0.3, 1, 1 + obj.pulse * 0.2), obj.g)
				if obj.pulse > 0:
					draw_arc(p - Vector2(0, obj.g * 25), 18 + (1 - obj.pulse) * 50, 0, TAU, 28, Color(0.8, 0.7, 1, obj.pulse * 0.6), 1.5, true)
			"puddle":
				draw_set_transform(p, 0, Vector2(1, 0.16))
				draw_circle(Vector2.ZERO, 42, Color(0.3, 0.8, 0.9, 0.24), true, -1, true)
				for j in range(2):
					draw_arc(Vector2.ZERO, 16 + j * 12 + obj.pulse * 7, 0.1, 2.8, 24, Color(0.8, 0.98, 1, 0.3 + obj.pulse * 0.4), 2, true)
				draw_set_transform(Vector2.ZERO)
	for mote in motes:
		var color: Color = mote.color
		color.a *= minf(1, mote.life / 0.45)
		draw_circle(mote.p, 2.5 if mote.water else 1.8, color, true, -1, true)
	for fruit in fruits:
		PropsEffect.apple(self, fruit.p, 0.75, 1 - smoothstep(0.35, 0.6, fruit.age))

const PropsEffect = preload("res://runner/art.gd")
