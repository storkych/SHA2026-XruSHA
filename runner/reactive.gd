extends Node2D
## Deterministic scenery with damped spring reactions; never changes collision or scoring.
const Props = preload("res://runner/scene_sprites.gd")
const Biomes = preload("res://runner/biomes.gd")
var plants: Array = []
var flecks: Array = []
var camera := 0.0
var clock := 0.0

func _ready() -> void:
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func reset(level: RefCounted) -> void:
	plants.clear()
	flecks.clear()
	for i in range(170):
		var x := 480.0 + i * 337.0 + sin(i * 2.3) * 70
		var g: int = level.gravity_at(x)
		if level.is_gap(x, g) or level.is_gap(x - 55, g) or level.is_gap(x + 55, g):
			continue
		plants.append({"p": Vector2(x, level.surface(x, g) + g * 12), "g": g, "bend": 0.0, "v": 0.0, "cooldown": 0.0, "phase": float(i), "kind": i % 3, "width": 44.0 + i % 4 * 7})

func react(pos: Vector2, radius: float, strength: float, g: int) -> void:
	for plant in plants:
		if plant.g != g or plant.p.distance_to(pos) > radius:
			continue
		var direction := 1.0 if plant.p.x >= pos.x else -1.0
		plant.v += direction * strength * 9
		if plant.cooldown <= 0:
			plant.cooldown = 0.65
			for i in range(7 if plant.kind == 1 else 4):
				var angle := -g * (0.5 + i * 0.35)
				flecks.append({"p": plant.p - Vector2(0, g * 25), "v": Vector2.from_angle(angle) * (65 + i * 14) + Vector2(direction * 50, 0), "life": 0.9, "max": 0.9, "color": Biomes.leaf(pos.x), "seed": plant.kind == 1})
	if flecks.size() > 120:
		flecks = flecks.slice(flecks.size() - 120)

func advance(dt: float, player: Vector2, speed: float, grounded: bool, g: int) -> void:
	for plant in plants:
		plant.cooldown = maxf(0, plant.cooldown - dt)
		if absf(plant.p.x - player.x) > 1900:
			continue
		if grounded and plant.g == g and absf(plant.p.x - player.x) < 62 and absf(plant.p.y - player.y) < 60:
			plant.v += dt * speed * 0.16
			if plant.cooldown <= 0:
				react(player, 64, 0.25, g)
		plant.v += (-plant.bend * 65 - plant.v * 7) * dt
		plant.bend = clampf(plant.bend + plant.v * dt, -0.75, 0.75)
	for fleck in flecks:
		fleck.life -= dt
		fleck.p += fleck.v * dt
		fleck.v *= exp(-dt * 1.4)
		fleck.v.y += dt * 25
	flecks = flecks.filter(func(f): return f.life > 0)

func present(x: float, t: float) -> void:
	camera = x
	clock = t
	queue_redraw()

func _draw() -> void:
	for plant in plants:
		if plant.p.x < camera - 120 or plant.p.x > camera + 1750:
			continue
		var sway: float = plant.bend + sin(clock * 1.7 + plant.phase) * 0.045
		draw_set_transform(plant.p, sway * plant.g, Vector2(1, plant.g))
		if plant.kind == 1:
			# Seed heads bend and release little floating seeds when disturbed.
			for j in range(3):
				var tip := Vector2((j - 1) * 13, -25 - j % 2 * 12)
				draw_line(Vector2.ZERO, tip, Color("82ad70"), 2, true)
				for k in range(6):
					var end := tip + Vector2.from_angle(k * TAU / 6) * 6
					draw_line(tip, end, Color("fce6af"), 1.2, true)
		elif plant.kind == 2:
			Props.prop(self, 3, Vector2.ZERO, plant.width, Color(0.84, 0.93, 1.0))
		else:
			Props.prop(self, 0, Vector2.ZERO, plant.width, Color(0.94, 1.0, 0.88))
	draw_set_transform(Vector2.ZERO)
	for fleck in flecks:
		var color: Color = fleck.color
		color.a *= fleck.life / fleck.max
		if fleck.seed:
			draw_line(fleck.p, fleck.p + Vector2(2, 6), color, 1, true)
			draw_arc(fleck.p, 4, -PI, 0, 7, color, 1, true)
		else:
			var axis := Vector2.from_angle(clock * 4 + fleck.p.x) * 5
			draw_colored_polygon(PackedVector2Array([fleck.p - axis, fleck.p + axis.orthogonal() * 0.4, fleck.p + axis, fleck.p - axis.orthogonal() * 0.4]), color)
