extends Node2D
const Hero = preload("res://runner/hero.gd")
const Art = preload("res://runner/art.gd")
const Background = preload("res://assets/runner/mine-background.png")
var hero: Node2D
var t := 0.0
var phase := "ЕДЕМ"
var previous_phase := ""
var font := SystemFont.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	font.font_names = PackedStringArray(["Trebuchet MS", "Verdana", "Arial"])
	font.font_weight = 800
	hero = Hero.new()
	add_child(hero)

func set_time(value: float) -> void:
	t = value
	var y := 485.0
	var angle := 0.0
	var grounded := true
	var velocity := 0.0
	var g := 1
	var age := 1.0
	phase = "ЕДЕМ"
	if t >= 1.4 and t < 2.2:
		var p := (t - 1.4) / 0.8
		y -= sin(p * PI) * 100
		velocity = -cos(p * PI) * 550
		grounded = false
		age = t - 1.4
		phase = "ПРЫЖОК" if p < 0.5 else "ПАДЕНИЕ"
	elif t >= 2.2 and t < 2.55:
		phase = "ПРИЗЕМЛЕНИЕ"
	elif t >= 3.2 and t < 4.2:
		var p := (t - 3.2)
		p = p * p * (3 - 2 * p)
		y = lerpf(485, 138, p)
		angle = PI * p
		g = -1
		grounded = false
		velocity = -400
		phase = "ПЕРЕВОРОТ"
	elif t >= 4.2 and t < 6.5:
		y = 138
		angle = PI
		g = -1
		phase = "ВВЕРХ НОГАМИ"
		if t >= 5.4 and t < 6.0:
			var p := (t - 5.4) / 0.6
			y += sin(p * PI) * 55
			velocity = cos(p * PI) * 350
			grounded = false
			age = t - 5.4
			phase = "ПРЫЖОК С ПОТОЛКА"
	elif t >= 6.5 and t < 7.5:
		var p := t - 6.5
		p = p * p * (3 - 2 * p)
		y = lerpf(138, 485, p)
		angle = PI * (1 - p)
		grounded = false
		velocity = 400
		phase = "ВОЗВРАЩАЕМСЯ"
	if phase != previous_phase and phase in ["ПРИЗЕМЛЕНИЕ", "ВВЕРХ НОГАМИ", "ЕДЕМ"] and previous_phase != "":
		hero.impact(650)
	previous_phase = phase
	hero.position = Vector2(440, y)
	hero.scale = Vector2.ONE * 1.85
	hero.present(1.0 / 30, {"time": t, "wheel": t * 11, "grounded": grounded, "vy": velocity, "gravity": g, "angle": angle, "jump_age": age, "happy": 0.5 if t > 2.2 and t < 3 else 0.0, "hurt": 0.0, "invulnerable": 0.0})
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(Background, Rect2(-t * 25, 0, 1120, 540), false, Color(0.7, 0.8, 0.88))
	Art.rail(self, {"a": -20.0, "b": 850.0, "y1": 485.0, "y2": 485.0, "g": 1, "zone": 0, "bridge": false}, 0, 800, false)
	Art.rail(self, {"a": -20.0, "b": 850.0, "y1": 138.0, "y2": 138.0, "g": -1, "zone": 4, "bridge": false}, 0, 800, false)
	Art.e(self, Vector2(440, 480), Vector2(73, 9), Color(0.02, 0.08, 0.13, 0.25), 0)
	if t > 1 and t < 2.8:
		Art.enemy(self, Vector2(440 + (2.2 - t) * 160, 480), "slime", t, 1, 1.0 if t >= 2.2 else 0.0)
	if t > 2.2 and t < 2.65:
		var p := (t - 2.2) / 0.45
		for d in [-1, 1]:
			for i in range(4):
				Art.e(self, Vector2(440 + d * (55 + p * 105 + i * 10), 478 - sin(p * PI) * 9), Vector2(8, 5) * (1 - p), Color(0.8, 0.85, 0.75, (1 - p) * 0.5), 0)
	draw_string(font, Vector2(28, 44), "ХрюША2026", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("fff0d8"))
	var width := font.get_string_size(phase, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2(772 - width, 42), phase, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffda93"))
