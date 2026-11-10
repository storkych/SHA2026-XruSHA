extends Node2D
## Native 2D arcade controller. Simulation runs at a fixed physics rate.
const Art = preload("res://scripts/art.gd")
const Meadow = preload("res://scripts/meadow.gd")
const Sound = preload("res://scripts/sound.gd")
const UI = preload("res://scripts/game_ui.gd")
const ARENA := Rect2(150, 220, 2100, 1300)
const ROUND_TIME := 60.0
const MAGAZINE := 6
const RELOAD_TIME := 1.35
const JUMP_TIME := 0.53
const JUMP_COOLDOWN := 1.5
const ROCKS := [Vector2(655, 535), Vector2(1785, 650), Vector2(1600, 1235), Vector2(670, 1190)]

var state := "menu"
var previous_state := "playing"
var time := 0.0
var remaining := ROUND_TIME
var countdown := 3.0
var attempt := 1
var scores: Array[int] = []
var record := 0
var records: Array = []
var score := 0
var caught := 0
var shots := 0
var hits := 0
var hp := 3
var ammo := MAGAZINE
var reload_timer := 0.0
var shot_timer := 0.0
var empty_timer := 0.0
var jump_timer := 0.0
var jump_cd := 0.0
var invulnerable := 0.0
var hurt_flash := 0.0
var recoil := 0.0
var footstep := 0.0
var combo := 0
var combo_timer := 0.0
var max_combo := 0
var hitstop := 0.0
var spawn_timer := 0.0
var spawn_count := 0
var wave := 0
var player := Vector2(1200, 850)
var velocity := Vector2.ZERO
var aim := Vector2.RIGHT
var facing := 1.0
var jump_dir := Vector2.ZERO
var camera_position := Vector2(1200, 850)
var camera_kick := Vector2.ZERO
var trauma := 0.0
var reduced_motion := false
var last_mouse := Vector2.ZERO
var use_gamepad := false
var enemies: Array = []
var bubbles: Array = []
var particles: Array = []
var texts: Array = []
var ripples: Array = []
var ambience: Array = []
var rng := RandomNumberGenerator.new()
var fx_rng := RandomNumberGenerator.new()
var camera: Camera2D
var sound: Node
var ui: Control
var layer: CanvasLayer
var menu_veil: Texture2D
var screenshot_done := false
var muted := false
var storage_path := "user://records.json"

func _ready() -> void:
	DisplayServer.window_set_min_size(Vector2i(960, 600))
	RenderingServer.set_default_clear_color(Color("6bdab4"))
	Engine.physics_ticks_per_second = 120
	fx_rng.randomize()
	if "--smoke" in OS.get_cmdline_user_args() or "--soak" in OS.get_cmdline_user_args():
		storage_path = "user://qa_records.json"
	load_records()
	var meadow := Meadow.new()
	meadow.z_index = -10
	add_child(meadow)
	camera = Camera2D.new()
	camera.position = Vector2(1100, 850)
	camera.position_smoothing_enabled = false
	add_child(camera)
	sound = Sound.new()
	add_child(sound)
	layer = CanvasLayer.new()
	add_child(layer)
	ui = UI.new()
	ui.game = self
	layer.add_child(ui)
	player = Vector2(1420, 920)
	camera_position = Vector2(1160, 850)
	for i in range(17):
		ambience.append({"p": Vector2(fx_rng.randf_range(100, 2300), fx_rng.randf_range(100, 1600)), "r": fx_rng.randf_range(5, 15), "phase": fx_rng.randf() * TAU})
	reset_demo()
	if "--smoke" in OS.get_cmdline_user_args():
		call_deferred("run_smoke_tests")
	if "--capture-play" in OS.get_cmdline_user_args():
		start_session()
		countdown = 0
		state = "playing"
		spawn_enemy(Vector2(1540, 850), 0)
		spawn_enemy(Vector2(1100, 500), 1)
		spawn_enemy(Vector2(1710, 1120), 2)

func reset_demo() -> void:
	enemies.clear()
	spawn_enemy(Vector2(1710, 700), 0)
	spawn_enemy(Vector2(1880, 1070), 2)
	spawn_enemy(Vector2(1300, 650), 1)
	enemies[0].state = "trapped"
	enemies[0].timer = 1000.0

func start_session() -> void:
	scores.clear()
	attempt = 1
	start_round()

func start_round() -> void:
	rng.seed = 20261105
	score = 0
	caught = 0
	shots = 0
	hits = 0
	hp = 3
	ammo = MAGAZINE
	remaining = ROUND_TIME
	countdown = 3.0
	reload_timer = 0
	shot_timer = 0
	jump_timer = 0
	jump_cd = 0
	invulnerable = 0
	hurt_flash = 0
	combo = 0
	combo_timer = 0
	max_combo = 0
	spawn_timer = 0.5
	spawn_count = 0
	wave = 0
	player = Vector2(1200, 850)
	velocity = Vector2.ZERO
	aim = Vector2.RIGHT
	facing = 1.0
	footstep = 0
	camera_position = player
	camera_kick = Vector2.ZERO
	trauma = 0
	hitstop = 0
	enemies.clear()
	bubbles.clear()
	particles.clear()
	texts.clear()
	ripples.clear()
	state = "countdown"
	ui.sync_buttons()
	sound.play("ready")

func finish_round() -> void:
	if state != "playing":
		return
	scores.append(score)
	state = "result" if attempt < 3 else "final"
	if state == "final":
		var best: int = scores.max()
		if best > record:
			record = best
		records.push_front({"score": best, "date": Time.get_datetime_string_from_system(false, true)})
		if records.size() > 20:
			records.resize(20)
		save_records()
	sound.play("win")
	ui.sync_buttons()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func next_round() -> void:
	if state == "final":
		start_session()
	elif state == "result":
		attempt += 1
		start_round()

func return_menu() -> void:
	state = "menu"
	player = Vector2(1420, 920)
	velocity = Vector2.ZERO
	aim = Vector2.RIGHT
	camera_position = Vector2(1160, 850)
	particles.clear()
	bubbles.clear()
	texts.clear()
	ripples.clear()
	reset_demo()
	ui.sync_buttons()

func toggle_pause() -> void:
	if state in ["playing", "countdown"]:
		previous_state = state
		state = "paused"
	elif state == "paused":
		state = previous_state
	else:
		return
	ui.sync_buttons()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state in ["playing", "countdown"] and is_instance_valid(ui):
		toggle_pause()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE, KEY_P:
				toggle_pause()
			KEY_R:
				if state == "playing":
					start_reload()
			KEY_SPACE:
				if state == "playing":
					start_jump()
			KEY_F, KEY_F11:
				toggle_fullscreen()
			KEY_M:
				toggle_sound()
	if event is InputEventJoypadButton and event.pressed:
		use_gamepad = true
		match event.button_index:
			JOY_BUTTON_A:
				if state == "playing":
					start_jump()
			JOY_BUTTON_X:
				if state == "playing":
					start_reload()
			JOY_BUTTON_START:
				toggle_pause()
	if event is InputEventMouseMotion:
		use_gamepad = false

func toggle_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func toggle_sound() -> void:
	muted = not muted
	sound.set_muted(muted)
	ui.sync_buttons()

func _physics_process(dt: float) -> void:
	if state == "paused":
		return
	time += dt
	update_effects(dt)
	if state == "menu":
		footstep += dt * 1.5
		aim = Vector2(1, sin(time * 0.4) * 0.15).normalized()
		for e in enemies:
			e.phase += dt * 2
		update_camera(dt, true)
		return
	if state == "countdown":
		var before := ceili(countdown)
		countdown -= dt
		if ceili(countdown) < before and countdown > 0:
			sound.play("tick", 1.0 + (3 - ceili(countdown)) * 0.15)
		if countdown <= 0:
			state = "playing"
			add_text(player + Vector2(0, -125), "ПУЗЫРИ ВПЕРЁД!", Color("fff0a8"), 27)
		update_camera(dt)
		return
	if state != "playing":
		update_camera(dt)
		return
	if hitstop > 0:
		hitstop -= dt
		return
	remaining = maxf(0, remaining - dt)
	shot_timer = maxf(0, shot_timer - dt)
	jump_cd = maxf(0, jump_cd - dt)
	invulnerable = maxf(0, invulnerable - dt)
	hurt_flash = maxf(0, hurt_flash - dt)
	combo_timer = maxf(0, combo_timer - dt)
	if combo_timer <= 0:
		combo = 0
	var movement := movement_input()
	if use_gamepad:
		var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
		if stick.length() > 0.2:
			aim = stick.normalized()
	else:
		var mouse_dir := get_global_mouse_position() - (player + Vector2(0, -36))
		if mouse_dir.length() > 6:
			aim = mouse_dir.normalized()
	if absf(aim.x) > 0.06:
		facing = signf(aim.x)
	if jump_timer > 0:
		jump_timer = maxf(0, jump_timer - dt)
		velocity = jump_dir * lerpf(400, 570, jump_timer / JUMP_TIME)
		if jump_timer == 0:
			burst(player, Color("e2fff2"), 10, 90)
			ripples.append({"p": player, "life": 0.4, "max": 0.4, "r": 18.0})
			sound.play("land")
	else:
		var target := movement * (240.0 if reload_timer > 0 else 285.0)
		velocity = velocity.move_toward(target, (1900.0 if movement.length() > 0 else 2300.0) * dt)
	player += velocity * dt
	player = clamp_position(player)
	if jump_timer <= 0:
		player = avoid_rocks(player, 18.0)
	footstep += velocity.length() * dt * 0.065
	if velocity.length() > 80 and jump_timer <= 0 and fx_rng.randf() < dt * 11:
		particles.append({"p": player + Vector2(fx_rng.randf_range(-12, 12), 3), "v": Vector2(-velocity.x * 0.06, -20), "life": 0.3, "max": 0.3, "r": 5.0, "color": Color("b2edd2"), "type": "dust"})
	if reload_timer > 0:
		reload_timer = maxf(0, reload_timer - dt)
		if reload_timer == 0:
			ammo = MAGAZINE
			sound.play("ready")
			burst(player + Vector2(20 * facing, -45), Color("fff0a8"), 5, 45)
	if ammo == 0 and reload_timer == 0:
		empty_timer -= dt
		if empty_timer <= 0:
			start_reload()
	var fire := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if use_gamepad:
		fire = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.2 or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER)
	if fire:
		shoot()
	spawn_timer -= dt
	if spawn_timer <= 0 and enemies.filter(func(e): return e.state != "trapped").size() < 15:
		var elapsed := ROUND_TIME - remaining
		var angle := rng.randf() * TAU
		var p := clamp_position(player + Vector2.from_angle(angle) * rng.randf_range(650, 800))
		if p.distance_to(player) < 400:
			p = clamp_position(player - Vector2.from_angle(angle) * 650)
		spawn_enemy(p, 1 if spawn_count > 5 and spawn_count % 4 == 0 else (2 if spawn_count % 3 == 0 else 0))
		spawn_count += 1
		spawn_timer = maxf(0.7, 2.0 - elapsed * 0.023)
	var next_wave := int((ROUND_TIME - remaining) / 20.0)
	if next_wave > wave:
		wave = next_wave
		add_text(player + Vector2(0, -140), "КОНИ РАЗОШЛИСЬ!" if wave == 1 else "ПОСЛЕДНИЙ РЫВОК!", Color("fff1a9"), 24)
	update_enemies(dt)
	update_bubbles(dt)
	update_camera(dt)
	if remaining <= 0 or hp <= 0:
		finish_round()

func movement_input() -> Vector2:
	var v := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if Input.get_connected_joypads().size() > 0:
		var joy := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
		if joy.length() > 0.18:
			v = joy.limit_length()
			use_gamepad = true
	return v.limit_length()

func clamp_position(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, ARENA.position.x, ARENA.end.x), clampf(p.y, ARENA.position.y, ARENA.end.y))

func shoot() -> bool:
	if state != "playing" or shot_timer > 0 or reload_timer > 0 or ammo <= 0:
		return false
	shot_timer = 0.185
	ammo -= 1
	shots += 1
	if ammo == 0:
		empty_timer = 0.32
	var lift := sin(PI * (1.0 - jump_timer / JUMP_TIME)) * 68 if jump_timer > 0 else 0.0
	var muzzle := player + Vector2(43 * facing, -18 - lift) + aim * 35
	bubbles.append({"p": muzzle, "old": muzzle, "v": aim * 700.0 + velocity * 0.16, "life": 1.25, "phase": fx_rng.randf() * TAU, "r": 15.0})
	recoil = 1
	camera_kick -= aim * 3.0
	trauma = minf(0.22, trauma + 0.07)
	ripples.append({"p": muzzle, "life": 0.18, "max": 0.18, "r": 6.0})
	burst(muzzle, Color("d9faff"), 4, 80)
	sound.play("shoot", fx_rng.randf_range(0.92, 1.12))
	return true

func start_reload() -> bool:
	if state != "playing" or ammo == MAGAZINE or reload_timer > 0:
		return false
	reload_timer = RELOAD_TIME
	sound.play("reload")
	return true

func start_jump() -> bool:
	if state != "playing" or jump_cd > 0 or jump_timer > 0:
		return false
	jump_timer = JUMP_TIME
	jump_cd = JUMP_COOLDOWN
	var movement := movement_input()
	jump_dir = movement.normalized() if movement.length() > 0.1 else aim
	burst(player, Color("e0ffed"), 8, 100)
	sound.play("jump")
	return true

func spawn_enemy(p: Vector2, variant: int) -> void:
	enemies.append({"p": avoid_rocks(p, 35.0), "v": Vector2.ZERO, "dir": Vector2.LEFT, "facing": -1.0, "variant": variant, "hp": 3 if variant == 1 else 2, "state": "spawn", "timer": 1.0, "phase": fx_rng.randf() * TAU, "hit": 0.0, "scale": 1.12 if variant == 1 else (0.86 if variant == 2 else 1.0), "lift": 0.0, "charge_cd": 1.1 + rng.randf() * 1.4})

func avoid_rocks(p: Vector2, radius: float) -> Vector2:
	for rock in ROCKS:
		var delta: Vector2 = p - rock
		if delta.length() < radius + 35:
			p = rock + (delta.normalized() if delta.length() > 0.01 else Vector2.RIGHT) * (radius + 35)
	return p

func update_enemies(dt: float) -> void:
	for e in enemies:
		e.timer -= dt
		e.hit = maxf(0, e.hit - dt * 4)
		var to_player: Vector2 = player - e.p
		var distance := to_player.length()
		var direction := to_player.normalized()
		match e.state:
			"spawn":
				if e.timer <= 0:
					e.state = "chase"
			"chase":
				e.charge_cd -= dt
				var speed: float = [100.0, 77.0, 132.0][e.variant] + (ROUND_TIME - remaining) * 0.7
				e.v = direction * speed
				if distance < 90:
					e.v *= 0.3
				e.p += e.v * dt
				if distance < 490 and e.charge_cd <= 0:
					e.state = "windup"
					e.timer = 0.85 if e.variant == 1 else 0.72
					e.dir = direction
					e.v = Vector2.ZERO
					if distance < 450:
						sound.play("windup", 0.9 if e.variant == 1 else 1.1, -5)
			"windup":
				e.v = Vector2.ZERO
				if e.timer > 0.28:
					e.dir = e.dir.lerp(direction, dt * 3).normalized()
				if e.timer <= 0:
					e.state = "charge"
					e.timer = 0.53
					e.v = e.dir * (750.0 if e.variant == 1 else 630.0)
			"charge":
				e.p += e.v * dt
				if distance < 45.0 * e.scale and absf(player.y - e.p.y) < 37 and jump_timer <= 0:
					take_damage(e.dir)
				if e.timer <= 0 or e.p != clamp_position(e.p):
					e.state = "recover"
					e.timer = 1.05 if e.variant == 1 else 0.85
			"recover":
				e.v = e.v.move_toward(Vector2.ZERO, dt * 1900)
				e.p += e.v * dt
				if e.timer <= 0:
					e.state = "chase"
					e.charge_cd = 1.25
			"trapped":
				e.lift += dt * 82
				e.p.x += sin(time * 3 + e.phase) * dt * 22
				e.v = Vector2.ZERO
		if e.state != "trapped":
			e.p = clamp_position(e.p)
			var corrected := avoid_rocks(e.p, 29.0)
			if e.state == "charge" and corrected.distance_to(e.p) > 0.1:
				e.state = "recover"
				e.timer = 1.1
				burst(e.p, Color("d9d5e7"), 7, 80)
			e.p = corrected
			e.phase += dt * (2.0 + e.v.length() * 0.065)
			if e.state in ["chase", "charge", "windup"] and absf(direction.x) > 0.05:
				e.facing = signf(e.dir.x if e.state in ["charge", "windup"] else direction.x)
	# Gentle separation avoids stacked horses and unreadable telegraphs.
	for i in range(enemies.size()):
		var a: Dictionary = enemies[i]
		if a.state not in ["chase", "recover"]:
			continue
		for j in range(i + 1, enemies.size()):
			var b: Dictionary = enemies[j]
			if b.state not in ["chase", "recover"]:
				continue
			var d: Vector2 = a.p - b.p
			if d.length() < 68 and d.length() > 0.01:
				var push := d.normalized() * (68 - d.length()) * dt * 3
				a.p = clamp_position(a.p + push)
				b.p = clamp_position(b.p - push)
	enemies = enemies.filter(func(e): return e.state != "trapped" or e.timer > 0)

func update_bubbles(dt: float) -> void:
	for b in bubbles:
		b.old = b.p
		b.p += b.v * dt
		b.life -= dt
		b.phase += dt * 9
		for rock in ROCKS:
			if Geometry2D.get_closest_point_to_segment(rock + Vector2(0, -12), b.old, b.p).distance_to(rock + Vector2(0, -12)) < 42:
				b.life = -1
		if b.life <= 0:
			burst(b.p, Color("ddf9ff"), 5, 75)
			continue
		for e in enemies:
			if e.state in ["trapped", "spawn"]:
				continue
			var center: Vector2 = e.p + Vector2(6 * e.facing, -35)
			var closest := Geometry2D.get_closest_point_to_segment(center, b.old, b.p)
			if closest.distance_to(center) < 36 * e.scale + b.r:
				b.life = -1
				hits += 1
				e.hp -= 1
				e.hit = 1.0
				burst(b.p, Color("e9d5ff"), 9, 110)
				ripples.append({"p": b.p, "life": 0.25, "max": 0.25, "r": 10.0})
				sound.play("hit", fx_rng.randf_range(0.9, 1.2))
				if e.hp <= 0:
					catch_horse(e)
				break
		if b.life > 0 and fx_rng.randf() < dt * 35:
			particles.append({"p": b.p, "v": Vector2(-b.v.x * 0.04, -8), "life": 0.25, "max": 0.25, "r": fx_rng.randf_range(2, 5), "color": Color("e1f7ff"), "type": "bubble"})
		if b.life <= 0 and b.life > -0.5:
			burst(b.p, Color("ddf9ff"), 5, 75)
	bubbles = bubbles.filter(func(b): return b.life > 0)

func catch_horse(e: Dictionary) -> void:
	e.state = "trapped"
	e.timer = 1.65
	e.lift = 0.0
	e.v = Vector2.ZERO
	caught += 1
	combo += 1
	combo_timer = 4.5
	max_combo = maxi(combo, max_combo)
	var multiplier := mini(3, 1 + int(combo / 4.0))
	var points: int = (150 if e.variant == 1 else 100) * multiplier
	score += points
	add_text(e.p + Vector2(0, -105), "+%d" % points, Color("fff1a9"), 32)
	burst(e.p + Vector2(0, -35), Color("ffd5ee"), 18, 160)
	trauma = minf(0.45, trauma + 0.14)
	hitstop = 0.028
	sound.play("pop", 1.0 + minf(0.4, combo * 0.025))

func take_damage(direction: Vector2) -> bool:
	if invulnerable > 0 or jump_timer > 0 or state != "playing":
		return false
	hp -= 1
	invulnerable = 1.45
	hurt_flash = 0.18
	combo = 0
	combo_timer = 0
	player = clamp_position(player + direction * 40)
	velocity = direction * 300
	trauma = 0.7
	hitstop = 0.06
	burst(player + Vector2(0, -30), Color("ffd0e5"), 15, 180)
	add_text(player + Vector2(0, -110), "ОЙ!", Color("fff4ee"), 29)
	sound.play("hurt")
	return true

func update_camera(dt: float, menu := false) -> void:
	recoil = move_toward(recoil, 0.0, dt * 9)
	trauma = move_toward(trauma, 0.0, dt * 1.2)
	camera_kick = camera_kick.lerp(Vector2.ZERO, 1.0 - exp(-dt * 14))
	var desired := Vector2(1160, 850) if menu else player + aim * 82
	var difference := desired - camera_position
	var dead_zone := Vector2(45, 27)
	if menu:
		camera_position = camera_position.lerp(desired, 1.0 - exp(-dt * 3))
	else:
		var outside := Vector2(signf(difference.x) * maxf(0, absf(difference.x) - dead_zone.x), signf(difference.y) * maxf(0, absf(difference.y) - dead_zone.y))
		camera_position += outside * (1.0 - exp(-dt * 6))
	var size := get_viewport_rect().size * 0.5
	camera_position.x = clampf(camera_position.x, size.x - 15, 2400 - size.x + 15)
	camera_position.y = clampf(camera_position.y, size.y - 25, 1700 - size.y + 25)
	var shake := Vector2(sin(time * 97), cos(time * 113)) * trauma * trauma * (0 if reduced_motion else 15)
	camera.position = camera_position + shake + (Vector2.ZERO if reduced_motion else camera_kick)
	camera.zoom = Vector2.ONE * (1.0 + (0.005 * recoil if not reduced_motion else 0))

func burst(p: Vector2, color: Color, count: int, force: float) -> void:
	for i in range(count):
		var life := fx_rng.randf_range(0.2, 0.5)
		particles.append({"p": p, "v": Vector2.from_angle(fx_rng.randf() * TAU) * fx_rng.randf_range(force * 0.3, force), "life": life, "max": life, "r": fx_rng.randf_range(2, 6), "color": color, "type": "bubble" if i % 3 else "spark"})

func add_text(p: Vector2, text: String, color: Color, size: int) -> void:
	texts.append({"p": p, "text": text, "life": 1.1, "color": color, "size": size})

func update_effects(dt: float) -> void:
	for p in particles:
		p.life -= dt
		p.p += p.v * dt
		p.v *= exp(-dt * 3.0)
	for t in texts:
		t.life -= dt
		t.p.y -= dt * 38
	for r in ripples:
		r.life -= dt
		r.r += dt * 90
	particles = particles.filter(func(p): return p.life > 0)
	texts = texts.filter(func(t): return t.life > 0)
	ripples = ripples.filter(func(r): return r.life > 0)
	if particles.size() > 600:
		particles = particles.slice(particles.size() - 600)

func _process(_dt: float) -> void:
	queue_redraw()
	ui.queue_redraw()
	if not screenshot_done and Engine.get_process_frames() > 100 and ("--capture-menu" in OS.get_cmdline_user_args() or "--capture-play" in OS.get_cmdline_user_args()):
		screenshot_done = true
		capture_frame.call_deferred()

func _draw() -> void:
	# Telegraphs are drawn beneath all characters, with visible directional chevrons.
	for e in enemies:
		if e.state in ["windup", "charge"]:
			var dir: Vector2 = e.dir
			var perp := dir.orthogonal() * (25.0 if e.variant != 1 else 34.0)
			var start: Vector2 = e.p
			var finish: Vector2 = start + dir * (400 if e.variant == 1 else 335)
			var opacity := 0.22 + sin(time * 18) * 0.06
			Art.poly(self, [start + perp, finish + perp, finish + dir * 28, finish - perp, start - perp], Color(1, 0.57, 0.38, opacity), 2, Color(1, 0.53, 0.3, 0.75))
			for k in range(3):
				var mid: Vector2 = start + dir * (100 + k * 65)
				Art.line(self, [mid - dir * 9 + perp * 0.35, mid + dir * 4, mid - dir * 9 - perp * 0.35], Color(1, 0.86, 0.53, 0.85), 4)
	# Draw contact shadows before bodies. Actual draw order is sorted by ground Y.
	var actors: Array = []
	for e in enemies:
		var alpha := clampf(1.0 - e.lift / 180, 0.1, 1.0)
		Art.ellipse(self, e.p + Vector2(0, 5), Vector2(39, 11) * e.scale, Color(0.16, 0.48, 0.45, 0.22 * alpha), 0)
		actors.append({"y": e.p.y, "enemy": e})
	var jump_height := sin(PI * (1.0 - jump_timer / JUMP_TIME)) * 68 if jump_timer > 0 else 0.0
	Art.ellipse(self, player + Vector2(0, 5), Vector2(27, 9) * (1.0 - jump_height * 0.004), Color(0.16, 0.48, 0.45, 0.26), 0)
	actors.append({"y": player.y, "pig": true})
	actors.sort_custom(func(a, b): return a.y < b.y)
	for actor in actors:
		if actor.has("pig"):
			var menu := state == "menu"
			var scale_factor := 2.15 if menu else 1.0
			if invulnerable > 0 and fmod(time, 0.16) < 0.055:
				continue
			var body_p := player + Vector2(0, -jump_height)
			var stretch := Vector2(1.0 - recoil * 0.04, 1.0 + recoil * 0.04)
			draw_set_transform(body_p, 0, Vector2(facing, 1) * scale_factor * stretch)
			Art.pig(self, footstep, clampf(velocity.length() / 285, 0, 1), Vector2(absf(aim.x), aim.y), jump_height / 68, recoil, time, 1 - reload_timer / RELOAD_TIME if reload_timer > 0 else 0.0, hurt_flash > 0)
			draw_set_transform(body_p + Vector2(43 * facing, -18) * scale_factor, aim.angle(), Vector2(1, facing) * scale_factor)
			Art.gun(self, recoil, time, reload_timer / RELOAD_TIME)
			modulate.a = 1.0
		else:
			var e: Dictionary = actor.enemy
			var appear := clampf((1 - e.timer) * 4, 0, 1) if e.state == "spawn" else 1.0
			var jitter := sin(time * 55) * 2 if e.state == "windup" else 0.0
			var p: Vector2 = e.p + Vector2(jitter, -e.lift)
			if state == "menu" and e.state == "trapped":
				p.y += sin(time * 2) * 15
			draw_set_transform(p, 0, Vector2(e.facing, 1) * e.scale * maxf(0.01, appear))
			Art.horse(self, e.phase, clampf(e.v.length() / 150, 0, 1.3), time, e.variant, e.state, e.hit, Vector2(absf((player - e.p).normalized().x), (player - e.p).normalized().y))
			draw_set_transform(Vector2.ZERO)
			if e.state == "trapped":
				Art.bubble(self, p + Vector2(10 * e.facing, -38) * e.scale, 73 * e.scale, clampf(e.timer, 0, 1) if state != "menu" else 1.0, time)
			elif e.state == "recover":
				for k in range(3):
					var orbit := Vector2(cos(time * 4 + k * TAU / 3) * 24, sin(time * 4 + k * TAU / 3) * 7)
					Art.star(self, p + Vector2(25 * e.facing, -111) + orbit, 6, Color("ffe28b"), time)
			elif e.state == "spawn":
				draw_arc(e.p, 43 + sin(time * 5) * 3, 0, TAU, 40, Color(1, 1, 0.8, 0.65), 2, true)
			# Small soap beads indicate remaining hits without health bars.
			if e.hp < (3 if e.variant == 1 else 2) and e.state != "trapped":
				Art.bubble(self, p + Vector2(-19, -76), 9, 0.9, time)
		draw_set_transform(Vector2.ZERO)
	for b in bubbles:
		Art.bubble(self, b.p + Vector2(0, sin(b.phase) * 3), b.r * (1 + sin(b.phase) * 0.07), minf(1, b.life * 4), time)
	for r in ripples:
		draw_arc(r.p, r.r, 0, TAU, 32, Color(0.94, 1, 0.96, r.life / r.max * 0.8), 2, true)
	for p in particles:
		var alpha: float = p.life / p.max
		var color: Color = p.color
		color.a *= alpha
		if p.type == "spark":
			Art.star(self, p.p, p.r * alpha + 1, color, time * 2)
		elif p.type == "bubble":
			Art.bubble(self, p.p, p.r, alpha, time)
		else:
			Art.ellipse(self, p.p, Vector2(p.r, p.r * 0.6) * alpha, color, 0)
	for a in ambience:
		var p: Vector2 = a.p + Vector2(sin(time * 0.25 + a.phase) * 35, -fmod(time * 10 + a.phase * 30, 120))
		Art.bubble(self, p, a.r, 0.3, time)
	for text in texts:
		var font: Font = ui.bold
		var size: int = text.size
		var width := font.get_string_size(text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var color: Color = text.color
		color.a = minf(1, text.life * 3)
		draw_string_outline(font, text.p - Vector2(width / 2, 0), text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(0.28, 0.16, 0.31, color.a))
		draw_string(font, text.p - Vector2(width / 2, 0), text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	# A bespoke animated aim reticle with four separated petals.
	if state == "playing" and not use_gamepad:
		var p := get_global_mouse_position()
		for i in range(4):
			var angle := i * PI / 2 + PI / 4
			var d := Vector2.from_angle(angle)
			Art.line(self, [p + d * (10 + recoil * 3), p + d * (16 + recoil * 3)], Art.INK, 4)
		Art.ellipse(self, p, Vector2.ONE * 2.5, Color("fffced"), 1.5)

func load_records() -> void:
	if not FileAccess.file_exists(storage_path):
		return
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if not file:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		record = maxi(0, int(parsed.get("best", 0)))
		if parsed.get("sessions") is Array:
			records = parsed.sessions

func save_records() -> void:
	var file := FileAccess.open(storage_path + ".tmp", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"best": record, "sessions": records}, "  "))
		file.close()
		var error := DirAccess.rename_absolute(storage_path + ".tmp", storage_path)
		if error != OK:
			push_warning("Не удалось сохранить результат: " + error_string(error))

func capture_frame() -> void:
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("res://qa/captures")
	DirAccess.make_dir_recursive_absolute(directory)
	var image := get_viewport().get_texture().get_image()
	var filename := "gameplay.png" if "--capture-play" in OS.get_cmdline_user_args() else "menu.png"
	image.save_png(directory.path_join(filename))
	print("CAPTURE: ", directory.path_join(filename))
	get_tree().quit()

func run_smoke_tests() -> void:
	set_physics_process(false)
	start_session()
	assert(state == "countdown" and scores.is_empty() and hp == 3)
	state = "playing"
	assert(not start_reload(), "Full magazine must not reload")
	assert(shoot() and ammo == 5)
	assert(not shoot(), "Fire-rate gate")
	assert(start_reload())
	assert(not shoot(), "No shooting during reload")
	reload_timer = 0
	ammo = 6
	assert(start_jump())
	assert(not start_jump(), "Dodge cooldown gate")
	assert(not take_damage(Vector2.RIGHT), "Jump protects from charge")
	jump_timer = 0
	assert(take_damage(Vector2.RIGHT) and hp == 2)
	assert(not take_damage(Vector2.RIGHT), "Damage grace period")
	enemies.clear()
	spawn_enemy(player + Vector2(150, 0), 0)
	var e: Dictionary = enemies[0]
	e.state = "chase"
	e.hp = 1
	var target: Vector2 = e.p + Vector2(6 * e.facing, -35)
	bubbles.clear()
	bubbles.append({"p": target - Vector2(90, 0), "old": target, "v": Vector2(18000, 0), "life": 1.0, "phase": 0.0, "r": 15.0})
	update_bubbles(0.01)
	assert(e.state == "trapped", "Swept projectile collision must not tunnel")
	assert(caught == 1 and score == 100)
	combo = 3
	catch_horse({"state": "chase", "timer": 0.0, "lift": 0.0, "v": Vector2.ZERO, "p": player, "variant": 0})
	assert(score == 300, "Fourth catch doubles points")
	finish_round()
	assert(scores.size() == 1 and state == "result")
	next_round()
	assert(attempt == 2 and scores.size() == 1 and score == 0 and hp == 3)
	state = "playing"
	finish_round()
	next_round()
	assert(attempt == 3 and state == "countdown")
	state = "playing"
	previous_state = state
	toggle_pause()
	assert(state == "paused")
	toggle_pause()
	assert(state == "playing")
	assert(clamp_position(Vector2(-1000, 9000)) == Vector2(150, 1520))
	var previous_record := record
	score = 250
	finish_round()
	assert(state == "final" and scores == [300, 0, 250])
	assert(record == maxi(previous_record, 300), "Session records use maximum, not sum or final attempt")
	var saved_record := record
	record = 0
	load_records()
	assert(record == saved_record, "Record survives save/load")
	next_round()
	assert(attempt == 1 and scores.is_empty() and state == "countdown", "Next player has a fresh session")
	print("SMOKE PASS: session, fire-rate, reload, jump, invulnerability, swept collision, scoring, combo, three attempts, best score, persistence, next player, pause, boundaries")
	get_tree().quit()
