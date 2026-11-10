extends Control
## Built from the three v5 UI references: artwork first, one primary action per screen.
const Art = preload("res://runner/art.gd")
const UI_ART = preload("res://assets/runner/v5/ui-art-clean.png")
const AWARD = preload("res://assets/runner/v7/award.png")
const ResultType = preload("res://runner/result_type.gd")
const CREAM := Color("fff0c9")
const GOLD := Color("ffd16b")
var game: Node2D
var font := SystemFont.new()
var button_font := SystemFont.new()
var play_button: Button
var next_button: Button
var back_button: Button
var resume_button: Button
var reset_button: Button
var sound_button: Button
var fullscreen_button: Button
var motion_button: Button
var quit_button: Button
var prior_screen := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font.font_names = PackedStringArray(["Segoe Print", "Trebuchet MS"])
	font.font_weight = 700
	button_font.font_names = PackedStringArray(["Trebuchet MS", "Verdana"])
	button_font.font_weight = 800
	play_button = button("ИГРАТЬ", func(): game.start_session(), true)
	next_button = button("ДАЛЬШЕ", func(): game.next_attempt(), true)
	back_button = button("В МЕНЮ", func(): game.enter_menu())
	resume_button = button("ПРОДОЛЖИТЬ", func(): game.pause_game(), true)
	reset_button = button("ЗАНОВО", func(): game.start_session())
	sound_button = button("", func(): game.toggle_sound(), false, true)
	fullscreen_button = button("", func(): game.fullscreen(), false, true)
	motion_button = button("Камера", func(): game.motion = not game.motion; game.save_game(); sync())
	quit_button = button("Выйти", func(): get_tree().quit())
	sound_button.tooltip_text = "Звук · M"
	fullscreen_button.tooltip_text = "Полный экран · F11"
	motion_button.tooltip_text = "Качание камеры"
	sync()

func button(text: String, action: Callable, primary := false, round_icon := false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", button_font)
	b.add_theme_font_size_override("font_size", 46 if primary else 30)
	b.add_theme_color_override("font_color", Color("3d210c") if primary else CREAM)
	b.add_theme_color_override("font_hover_color", Color("613309") if primary else GOLD)
	b.add_theme_color_override("font_pressed_color", Color("783a10") if primary else GOLD)
	for state in ["normal", "hover", "pressed"]:
		var style: StyleBox
		if primary:
			var painted := StyleBoxTexture.new()
			var texture := AtlasTexture.new()
			texture.atlas = UI_ART
			texture.region = Rect2(172, 491, 1430, 358)
			painted.texture = texture
			painted.modulate_color = Color(1.08, 1.04, 0.92) if state == "hover" else (Color(0.84, 0.81, 0.75) if state == "pressed" else Color.WHITE)
			style = painted
		elif round_icon:
			var circle := StyleBoxFlat.new()
			circle.bg_color = Color.TRANSPARENT
			circle.border_color = GOLD if state != "pressed" else CREAM
			circle.set_border_width_all(2)
			circle.set_corner_radius_all(32)
			style = circle
		else:
			style = StyleBoxEmpty.new()
		b.add_theme_stylebox_override(state, style)
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color.TRANSPARENT
	focus_style.border_color = Color("fff0c9")
	focus_style.set_border_width_all(3)
	focus_style.set_corner_radius_all(40 if primary else 14)
	focus_style.expand_margin_left = 4
	focus_style.expand_margin_right = 4
	focus_style.expand_margin_top = 4
	focus_style.expand_margin_bottom = 4
	b.add_theme_stylebox_override("focus", focus_style)
	b.pressed.connect(action)
	add_child(b)
	return b

func place(b: Button, rect: Rect2, show_it: bool) -> void:
	b.position = rect.position
	b.size = rect.size
	b.visible = show_it

func sync() -> void:
	if not is_instance_valid(play_button):
		return
	var s := get_viewport_rect().size
	var menu: bool = game.state == "menu"
	var result: bool = game.state in ["result", "final"]
	var paused: bool = game.state == "paused"
	var center := s * Vector2(0.43, 0.5)
	place(play_button, Rect2(350, 475, 440, 110), menu)
	place(next_button, Rect2(center.x - 282, 577, 564, 134), result)
	place(back_button, Rect2(center.x - 130, 733, 260, 55) if result else Rect2(s.x * 0.5 - 130, 620, 260, 55), result or paused)
	place(resume_button, Rect2(s.x * 0.5 - 250, 385, 500, 118), paused)
	place(reset_button, Rect2(s.x * 0.5 - 100, 545, 200, 45), paused)
	place(quit_button, Rect2(42, s.y - 64, 145, 42), menu)
	place(sound_button, Rect2(s.x - 191, s.y - 111, 62, 62), menu or paused)
	place(fullscreen_button, Rect2(s.x - 105, s.y - 111, 62, 62), menu or paused)
	place(motion_button, Rect2(s.x * 0.5 - 90, 710, 180, 45), paused)
	motion_button.modulate.a = 1 if game.motion else 0.45
	next_button.text = "НОВЫЙ ИГРОК" if game.state == "final" else "ДАЛЬШЕ"
	if prior_screen != game.state:
		var focused := get_viewport().gui_get_focus_owner()
		if focused:
			focused.release_focus()
		if game.active_pad >= 0:
			if menu:
				play_button.grab_focus()
			elif result:
				next_button.grab_focus()
			elif paused:
				resume_button.grab_focus()
		prior_screen = game.state
	# Directional navigation has a stable loop, including results and pause.
	var navigation: Array[Button] = []
	for b in [play_button, next_button, back_button, resume_button, reset_button, motion_button, sound_button, fullscreen_button, quit_button]:
		if b.visible:
			navigation.append(b)
	for i in range(navigation.size()):
		var b := navigation[i]
		b.focus_neighbor_bottom = b.get_path_to(navigation[(i + 1) % navigation.size()])
		b.focus_neighbor_top = b.get_path_to(navigation[(i - 1 + navigation.size()) % navigation.size()])
		b.focus_neighbor_left = b.focus_neighbor_top
		b.focus_neighbor_right = b.focus_neighbor_bottom
	if not game.is_test:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if game.state in ["playing", "countdown"] else Input.MOUSE_MODE_VISIBLE
	queue_redraw()

func label(pos: Vector2, value: String, size: int, color := CREAM, centered := true) -> void:
	var p := pos
	if centered:
		p.x -= font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	draw_string_outline(font, p + Vector2(0, 2), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0.08, 0.15, 0.14, color.a * 0.6))
	draw_string(font, p, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func icons() -> void:
	if not sound_button.visible:
		return
	var c := sound_button.position + Vector2(31, 31)
	draw_circle(c, 30, Color(0.13, 0.13, 0.10, 0.75), true, -1, true)
	Art.p(self, [c + Vector2(-16, -7), c + Vector2(-7, -7), c + Vector2(4, -16), c + Vector2(4, 16), c + Vector2(-7, 7), c + Vector2(-16, 7)], CREAM, 0)
	if game.muted:
		Art.line(self, [c + Vector2(10, -8), c + Vector2(21, 8)], CREAM, 3)
		Art.line(self, [c + Vector2(10, 8), c + Vector2(21, -8)], CREAM, 3)
	else:
		draw_arc(c, 15, -0.8, 0.8, 14, CREAM, 3, true)
		draw_arc(c, 23, -0.7, 0.7, 14, CREAM, 3, true)
	c = fullscreen_button.position + Vector2(31, 31)
	draw_circle(c, 30, Color(0.13, 0.13, 0.10, 0.75), true, -1, true)
	for x in [-1, 1]:
		for y in [-1, 1]:
			Art.line(self, [c + Vector2(x * 7, y * 16), c + Vector2(x * 16, y * 16), c + Vector2(x * 16, y * 7)], CREAM, 3)

func _draw() -> void:
	if not is_instance_valid(game):
		return
	var s := get_viewport_rect().size
	if game.state == "menu":
		draw_texture_rect_region(UI_ART, Rect2(230, 277, 720, 164), Rect2(140, 72, 1508, 350))
		for i in range(3):
			draw_circle(Vector2(366 + i * 25, 632), 8, GOLD, true, -1, true)
		label(Vector2(460, 641), "3 попытки · лучший счёт", 19, CREAM, false)
		icons()
		return
	if game.state in ["playing", "countdown", "paused"]:
		for i in range(3):
			Art.heart(self, Vector2(57 + i * 47, 43), i < game.health)
		label(Vector2(s.x * 0.5, 65), str(game.score), 46 + int(game.score_pop * 6))
		Art.apple(self, Vector2(s.x - 130, 44), 1.2 + game.apple_pop * 0.1)
		label(Vector2(s.x - 73, 61), str(game.apple_count), 34)
	if game.state == "playing" and game.run_time < 7:
		var alpha := 1 - smoothstep(5, 7, game.run_time)
		label(Vector2(42, s.y - 80), "A  прыжок" if game.active_pad >= 0 else "ПРОБЕЛ  прыжок", 22, Color(CREAM, alpha), false)
		label(Vector2(42, s.y - 45), "X / B / RT  удар" if game.active_pad >= 0 else "ENTER / ЛКМ / J  удар", 22, Color(CREAM, alpha), false)
	if game.state == "countdown":
		label(s * 0.5 + Vector2(0, 35), str(ceili(game.countdown)), 108)
	if game.state == "paused":
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.03, 0.09, 0.10, 0.7))
		label(Vector2(s.x * 0.5, 295), "ПАУЗА", 59)
		icons()
	if game.state in ["result", "final"]:
		var x := s.x * 0.43
		var final: bool = game.state == "final"
		var reveal := smoothstep(0.0, 0.75, game.result_age)
		var value: int = game.best_score() if final else game.score
		if final:
			ResultType.heading(self, Vector2(x, 190), true)
		else:
			ResultType.heading(self, Vector2(x - 63, 190), false, 53)
			label(Vector2(x + 183, 210), "%d / 3" % game.attempt, 43)
		# Short tapered paint strokes follow the reference's title underline.
		for i in range(3):
			var pts := PackedVector2Array()
			for j in range(25):
				var t := j / 24.0
				pts.append(Vector2(x - 112 + t * 224, 237 - sin(t * PI) * (8 - i * 2) + i * 2))
			draw_polyline(pts, Color(GOLD, 0.9 - i * 0.2), 3.2 - i * 0.7, true)
		ResultType.number(self, Vector2(x, 350), roundi(value * reveal))
		var best_index := -1
		for i in range(game.results.size()):
			if best_index < 0 or game.results[i].score > game.results[best_index].score:
				best_index = i
		for i in range(3):
			var col := x + (i - 1) * 235
			var played: bool = i < game.results.size()
			label(Vector2(col, 523), "%d · %s" % [i + 1, str(game.results[i].score) if played else "—"], 40, GOLD if i == best_index else CREAM)
			if i == best_index:
				draw_award(Vector2(col, 458), 86 * (0.8 + reveal * 0.2))

func draw_award(center: Vector2, size: float) -> void:
	draw_texture_rect(AWARD, Rect2(center - Vector2.ONE * size * 0.5, Vector2.ONE * size), false)
