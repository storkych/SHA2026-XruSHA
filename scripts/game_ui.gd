extends Control
## Native Godot UI; text and controls stay sharp at any window resolution.
const Art = preload("res://scripts/art.gd")
const INK := Color("48294f")
const PAPER := Color("fffbed")
const PINK := Color("f9a4c5")
var game: Node2D
var font := SystemFont.new()
var bold := SystemFont.new()
var start_button: Button
var next_button: Button
var resume_button: Button
var menu_button: Button
var restart_button: Button
var confirm_button: Button
var pause_button: Button
var sound_button: Button
var fullscreen_button: Button
var motion_button: Button
var quit_button: Button
var gradient: GradientTexture2D
var confirm_restart := false
var score_shown := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font.font_names = PackedStringArray(["Trebuchet MS", "Verdana", "Arial"])
	bold.font_names = font.font_names
	bold.font_weight = 800
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.34, 0.68, 1.0])
	g.colors = PackedColorArray([Color("e9fff3"), Color(0.91, 1.0, 0.95, 0.97), Color(0.91, 1.0, 0.95, 0.06), Color(0.91, 1.0, 0.95, 0.0)])
	gradient = GradientTexture2D.new()
	gradient.gradient = g
	gradient.width = 1024
	gradient.height = 4
	gradient.fill_from = Vector2(0, 0)
	gradient.fill_to = Vector2(1, 0)
	start_button = button("Погнали!                         ↗", func(): game.start_session(), true)
	next_button = button("", func(): game.next_round(), true)
	resume_button = button("Продолжить                       ↗", func(): game.toggle_pause(), true)
	menu_button = button("На поляну", func(): game.return_menu(), false)
	restart_button = button("Новая сессия", func(): confirm_restart = not confirm_restart; sync_buttons(), false)
	confirm_button = button("Да, сбросить попытки", func(): game.start_session(), false)
	pause_button = button("Ⅱ", func(): game.toggle_pause(), false)
	sound_button = button("♫", func(): game.toggle_sound(), false)
	fullscreen_button = button("⛶", func(): game.toggle_fullscreen(), false)
	motion_button = button("", func(): game.reduced_motion = not game.reduced_motion; sync_buttons(), false)
	quit_button = button("Выйти из игры", func(): game.get_tree().quit(), false)
	pause_button.tooltip_text = "Пауза · Esc"
	sound_button.tooltip_text = "Звук · M"
	fullscreen_button.tooltip_text = "Полный экран · F11"
	sync_buttons()

func button(label: String, action: Callable, primary: bool) -> Button:
	var b := Button.new()
	b.text = label
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", bold)
	b.add_theme_font_size_override("font_size", 23 if primary else 14)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_stylebox_override("normal", box(PINK if primary else PAPER, 18 if primary else 11, 3 if primary else 2, 6 if primary else 2))
	b.add_theme_stylebox_override("hover", box(Color("ffbdd9") if primary else Color("fff1c2"), 18 if primary else 11, 3 if primary else 2, 6 if primary else 2))
	b.add_theme_stylebox_override("pressed", box(Color("f68eb6") if primary else Color("ffdda1"), 18 if primary else 11, 3 if primary else 2, 1))
	var focus := box(Color.TRANSPARENT, 18 if primary else 11, 3, 0)
	focus.border_color = Color("ec73a8")
	focus.expand_margin_left = 4
	focus.expand_margin_right = 4
	focus.expand_margin_top = 4
	focus.expand_margin_bottom = 4
	b.add_theme_stylebox_override("focus", focus)
	b.pressed.connect(action)
	add_child(b)
	return b

func box(color: Color, radius: int, border: int, shadow: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = INK
	s.set_border_width_all(border)
	s.set_corner_radius_all(radius)
	s.shadow_color = INK if shadow > 3 else Color(0.28, 0.16, 0.31, 0.16)
	s.shadow_size = 0
	s.shadow_offset = Vector2(0, shadow)
	s.anti_aliasing = true
	return s

func place(b: Button, p: Vector2, s: Vector2, show_it: bool) -> void:
	b.position = p
	b.size = s
	b.visible = show_it

func sync_buttons() -> void:
	if not is_instance_valid(start_button):
		return
	var s := get_viewport_rect().size
	var middle := s * 0.5
	var menu: bool = game.state == "menu"
	var paused: bool = game.state == "paused"
	var result: bool = game.state in ["result", "final"]
	var active: bool = game.state in ["playing", "countdown"]
	var panel := middle - Vector2(280, 330)
	place(start_button, Vector2(86, 495), Vector2(320, 69), menu)
	place(next_button, panel + Vector2(38, 540), Vector2(484, 63), result)
	place(menu_button, panel + Vector2(190, 621), Vector2(180, 32), result)
	place(resume_button, middle + Vector2(-220, 15), Vector2(440, 65), paused)
	place(restart_button, middle + Vector2(-145, 105), Vector2(290, 37), paused)
	place(confirm_button, middle + Vector2(-145, 195), Vector2(290, 38), paused and confirm_restart)
	place(motion_button, middle + Vector2(-145, -40), Vector2(290, 35), paused)
	motion_button.text = "Качание камеры: " + ("выкл." if game.reduced_motion else "вкл.")
	place(pause_button, Vector2(s.x - 78, 32), Vector2(42, 42), active)
	place(sound_button, Vector2(s.x - 102, s.y - 46), Vector2(33, 29), true)
	place(fullscreen_button, Vector2(s.x - 61, s.y - 46), Vector2(33, 29), true)
	sound_button.text = "×♪" if game.muted else "♫"
	place(quit_button, Vector2(86, s.y - 67), Vector2(150, 31), menu)
	if result:
		next_button.text = "Следующая попытка                 ↗" if game.state == "result" else "Следующий игрок                    ↗"
	if not paused:
		confirm_restart = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if active else Input.MOUSE_MODE_VISIBLE

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		sync_buttons()

func text(p: Vector2, value: String, size: int, color := INK, heavy := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var f: Font = bold if heavy else font
	var width := f.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var offset := 0.0
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		offset = width / 2
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		offset = width
	draw_string(f, p - Vector2(offset, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func pill(rect: Rect2, color := PAPER, border := 2) -> void:
	draw_style_box(box(color, 17, border, 3), rect)

func key(p: Vector2, label: String, width := 45.0) -> void:
	draw_style_box(box(PAPER, 6, 1, 2), Rect2(p, Vector2(width, 27)))
	text(p + Vector2(width / 2, 18), label, 11, INK, true, HORIZONTAL_ALIGNMENT_CENTER)

func heart(p: Vector2, filled: bool) -> void:
	var points: Array = []
	for i in range(65):
		var a := TAU * i / 64.0
		points.append(p + Vector2(16 * pow(sin(a), 3), -(13 * cos(a) - 5 * cos(2 * a) - 2 * cos(3 * a) - cos(4 * a))) * 1.22)
	Art.poly(self, points, Color("fc82af") if filled else Color("8bbfae"), 2.8, INK if filled else Color("639b8e"))
	if filled:
		Art.ellipse(self, p + Vector2(-8, -6), Vector2(3, 4), Color("ffd9e9"), 0)

func _draw() -> void:
	if not is_instance_valid(game):
		return
	var s := get_viewport_rect().size
	if game.state == "menu":
		draw_menu(s)
	elif game.state in ["playing", "countdown", "paused"]:
		draw_hud(s)
	if game.state == "countdown":
		text(s * Vector2(0.5, 0.38), str(ceili(game.countdown)), 105, PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
		text(s * Vector2(0.5, 0.38) + Vector2(0, 42), "ПОПЫТКА %d ИЗ 3" % game.attempt, 16, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	if game.state in ["result", "final"]:
		draw_results(s)
	if game.state == "paused":
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.15, 0.35, 0.33, 0.35))
		var p := s * 0.5
		draw_style_box(box(PAPER, 29, 3, 8), Rect2(p - Vector2(280, 265), Vector2(560, 545)))
		text(p + Vector2(0, -200), "МОЖНО ВЫДОХНУТЬ", 12, Color("99758b"), true, HORIZONTAL_ALIGNMENT_CENTER)
		text(p + Vector2(0, -133), "Мыльная пауза", 43, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		text(p + Vector2(0, -95), "Кони тоже немного отдыхают.", 17, INK, false, HORIZONTAL_ALIGNMENT_CENTER)
		if confirm_restart:
			text(p + Vector2(0, 175), "Текущие попытки будут сброшены.", 14, Color("a15173"), false, HORIZONTAL_ALIGNMENT_CENTER)
	# Utility stays accessible in every screen.
	if game.record > 0:
		text(Vector2(38, s.y - 25), "РЕКОРД ЭТОГО КОМПЬЮТЕРА   %d" % game.record, 10, Color("477e71"), true)
	if game.state != "menu":
		text(Vector2(s.x - 126, s.y - 25), "ESC — ПАУЗА", 10, Color("477e71"), true, HORIZONTAL_ALIGNMENT_RIGHT)

func draw_menu(s: Vector2) -> void:
	draw_texture_rect(gradient, Rect2(Vector2.ZERO, s), false)
	Art.ellipse(self, Vector2(91, 171), Vector2(4, 4), Color("f875a4"), 0)
	text(Vector2(106, 176), "МАЛЕНЬКОЕ БОЛЬШОЕ ПРИКЛЮЧЕНИЕ", 12, INK, true)
	# The same lettering and palette as the chosen visual reference.
	text(Vector2(80, 307), "хрю", 112, INK, true)
	var prefix := bold.get_string_size("хрю", HORIZONTAL_ALIGNMENT_LEFT, -1, 112).x
	draw_string_outline(bold, Vector2(80 + prefix, 307), "ША", HORIZONTAL_ALIGNMENT_LEFT, -1, 112, 9, INK)
	draw_string(bold, Vector2(80 + prefix, 307), "ША", HORIZONTAL_ALIGNMENT_LEFT, -1, 112, PAPER)
	Art.star(self, Vector2(530, 212), 19, Color("ffdd83"), sin(game.time * 0.6) * 0.15)
	text(Vector2(86, 358), "Мыльный переполох", 31, INK, true)
	text(Vector2(87, 420), "Большие кони. Маленькая хрюшка.", 19, Color("6a566d"))
	text(Vector2(87, 451), "И совершенно несерьёзная пушка.", 19, Color("6a566d"))
	text(Vector2(89, 602), "3 попытки     ·     60 секунд     ·     лучший счёт", 13, INK, true)
	key(Vector2(87, 650), "W A S D", 83)
	text(Vector2(182, 670), "бегать", 14)
	key(Vector2(337, 650), "МЫШЬ", 68)
	text(Vector2(417, 670), "целиться и стрелять", 14)
	key(Vector2(87, 695), "R", 38)
	text(Vector2(137, 715), "перезаряжать", 14)
	key(Vector2(337, 695), "ПРОБЕЛ", 78)
	text(Vector2(427, 715), "прыгать через коней", 14)
	text(Vector2(88, 770), "Лови коней в пузыри, уворачивайся от наскоков.", 13, Color("7c7281"))
	text(Vector2(88, 793), "Все останутся целы. Даже их самолюбие. Почти.", 13, Color("7c7281"))
	pill(Rect2(Vector2(s.x - 370, 99), Vector2(296, 38)), Color("fffbed"), 2)
	text(Vector2(s.x - 222, 124), "100% МЫЛА. 0% ЖЕСТОКОСТИ.", 11, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	# Little illustrated aiming cue beside the pig's toy.
	Art.bubble(self, Vector2(s.x - 247 + sin(game.time) * 8, 465 + cos(game.time) * 12), 29, 0.9, game.time)
	Art.bubble(self, Vector2(s.x - 163 + sin(game.time * 0.8) * 12, 420), 16, 0.8, game.time)

func draw_hud(s: Vector2) -> void:
	text(Vector2(36, 66), "хрюША", 32, INK, true)
	text(Vector2(39, 83), "МЫЛЬНЫЙ ПЕРЕПОЛОХ", 7, INK, true)
	for i in range(3):
		heart(Vector2(213 + i * 47, 55), i < game.hp)
	var center := s.x * 0.5
	pill(Rect2(center - 85, 26, 170, 85), PAPER, 3)
	text(Vector2(center, 49), "СЧЁТ", 10, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	text(Vector2(center, 94), str(game.score), 40, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	if game.combo > 1 and game.combo_timer > 0:
		var multiplier := mini(3, 1 + int(game.combo / 4.0))
		pill(Rect2(center - 93, 124, 186, 31), Color("ffe49b"), 1)
		text(Vector2(center, 145), "СЕРИЯ %d  ·  ×%d" % [game.combo, multiplier], 12, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		var bar: float = game.combo_timer / 4.5 * 148
		draw_line(Vector2(center - 74, 159), Vector2(center - 74 + bar, 159), Color("f287b4"), 3, true)
	# Countdown ring, distinct from the three run attempts.
	var urgent: bool = game.remaining < 11
	var timer_color := Color("bd426d") if urgent else INK
	draw_arc(Vector2(s.x - 345, 55), 18, 0, TAU, 44, Color(0.28, 0.16, 0.31, 0.2), 3, true)
	draw_arc(Vector2(s.x - 345, 55), 18, -PI / 2, -PI / 2 + TAU * maxf(0.001, game.remaining / 60), 44, timer_color, 3, true)
	text(Vector2(s.x - 311, 67), "%02d" % ceili(game.remaining), 32, timer_color, true)
	text(Vector2(s.x - 251, 63), "СЕК", 10, timer_color, true)
	draw_line(Vector2(s.x - 223, 32), Vector2(s.x - 223, 77), Color(0.28, 0.16, 0.31, 0.25), 2)
	text(Vector2(s.x - 201, 45), "ПОПЫТКА", 9, INK, true)
	text(Vector2(s.x - 200, 73), "%d / 3" % game.attempt, 25, INK, true)
	var bottom := s.y - 61
	var rect := Rect2(center - 154, bottom - 90, 308, 90)
	pill(rect, PAPER, 3)
	var label := "ПУЗЫРЕМЁТ"
	if game.reload_timer > 0:
		label = "ДОЛИВАЕМ МЫЛО…"
	text(rect.position + Vector2(18, 21), label, 10, INK, true)
	key(rect.position + Vector2(264, 9), "R", 25)
	for i in range(6):
		var p := rect.position + Vector2(34 + i * 47, 49)
		if i < game.ammo:
			Art.bubble(self, p, 16, 1.0, game.time)
		else:
			Art.ellipse(self, p, Vector2.ONE * 13, Color("e2e9df"), 2, Color("b8bcb6"))
	var progress: float = 1 - game.reload_timer / game.RELOAD_TIME if game.reload_timer > 0 else 1.0
	draw_style_box(box(Color("ece8e0"), 3, 0, 0), Rect2(rect.position + Vector2(20, 75), Vector2(268, 4)))
	draw_style_box(box(Color("f494be") if game.reload_timer > 0 else Color("9dd8b6"), 3, 0, 0), Rect2(rect.position + Vector2(20, 75), Vector2(268 * progress, 4)))
	var dodge := Vector2(s.x - 214, bottom - 38)
	pill(Rect2(dodge - Vector2(26, 26), Vector2(52, 52)), PAPER, 2)
	text(dodge + Vector2(0, 11), "↗", 33, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	draw_arc(dodge, 31, -PI / 2, -PI / 2 + TAU * maxf(0.001, 1 - game.jump_cd / game.JUMP_COOLDOWN), 48, Color("f18db7"), 3, true)
	text(dodge + Vector2(45, -3), "ПРЫЖОК", 11, INK, true)
	text(dodge + Vector2(45, 17), "ПРОБЕЛ" if game.jump_cd == 0 else "%.1f сек" % game.jump_cd, 10, INK)
	var elapsed: float = 60 - game.remaining
	if elapsed < 12:
		text(Vector2(38, bottom - 43), "Зажми ЛКМ — стреляй пузырями.", 13, INK, true)
		text(Vector2(38, bottom - 20), "R — долить мыло. Пробел — отпрыгнуть.", 12, INK)
	elif elapsed < 23:
		text(Vector2(38, bottom - 43), "Оранжевая дорожка? Будет наскок!", 13, INK, true)
		text(Vector2(38, bottom - 20), "Просто касаться коней безопасно.", 12, INK)
	else:
		text(Vector2(38, bottom - 43), "Лови подряд — увеличивай множитель.", 13, INK, true)
		text(Vector2(38, bottom - 20), "Каждый четвёртый конь — больше очков.", 12, INK)
	if game.hurt_flash > 0:
		draw_rect(Rect2(Vector2.ZERO, s), Color(1, 0.45, 0.61, game.hurt_flash * 0.5))

func draw_results(s: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.18, 0.43, 0.37, 0.3))
	var p := s * 0.5 - Vector2(280, 330)
	draw_style_box(box(PAPER, 29, 3, 9), Rect2(p, Vector2(560, 680)))
	var final: bool = game.state == "final"
	text(p + Vector2(280, 43), "ВСЕ КОНИ ЦЕЛЫ. ПЕНЫ — МОРЕ.", 11, Color("967088"), true, HORIZONTAL_ALIGNMENT_CENTER)
	text(p + Vector2(280, 99), "Вот это переполох!" if final else "Неплохо намылили!", 35, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	text(p + Vector2(280, 139), "ЛУЧШИЙ СЧЁТ" if final else "СЧЁТ ЭТОЙ ПОПЫТКИ", 11, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	var best: int = game.scores.max() if not game.scores.is_empty() else 0
	text(p + Vector2(280, 217), str(best if final else game.score), 77, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	var best_index: int = game.scores.find(best)
	for i in range(3):
		var row := p + Vector2(38, 250 + i * 56)
		var played: bool = i < game.scores.size()
		var is_best: bool = played and i == best_index
		pill(Rect2(row, Vector2(484, 47)), Color("ffe69f") if is_best else Color("f4f2e6"), 1)
		text(row + Vector2(17, 30), ("★  " if is_best else "     ") + "ПОПЫТКА %d" % (i + 1), 13, INK if played else Color("adaba7"), true)
		text(row + Vector2(462, 32), str(game.scores[i]) if played else "впереди", 23 if played else 13, INK if played else Color("adaba7"), true, HORIZONTAL_ALIGNMENT_RIGHT)
	text(p + Vector2(280, 448), "В зачёт идёт лучший результат из трёх.", 14, INK, false, HORIZONTAL_ALIGNMENT_CENTER)
	if final:
		text(p + Vector2(280, 491), "Твой результат сохранён на этом компьютере.", 13, Color("8a7183"), false, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		var accuracy := roundi(float(game.hits) / maxf(1, game.shots) * 100)
		text(p + Vector2(280, 491), "Поймано: %d       Точность: %d%%       Серия: %d" % [game.caught, accuracy, game.max_combo], 13, Color("8a7183"), true, HORIZONTAL_ALIGNMENT_CENTER)
	text(p + Vector2(280, 520), "Следующий игрок начнёт с чистого листа." if final else "Та же поляна. Новый шанс на рекорд.", 12, Color("8a7183"), false, HORIZONTAL_ALIGNMENT_CENTER)
