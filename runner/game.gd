extends Node2D
const Level = preload("res://runner/level.gd")
const Art = preload("res://runner/art.gd")
const UI = preload("res://runner/ui.gd")
const Hero = preload("res://runner/hero.gd")
const Backdrop = preload("res://runner/backdrop.gd")
const Scenery = preload("res://runner/environment.gd")
const Foreground = preload("res://runner/foreground.gd")
const ZIP_PROPS = preload("res://assets/runner/v4/zipline-props.png")
const Sound = preload("res://scripts/sound.gd")
const RunnerSprites = preload("res://runner/runner_sprites.gd")
const MENU_ART = preload("res://assets/runner/v5/menu-background.png")
const Biomes = preload("res://runner/biomes.gd")
const Ambience = preload("res://runner/ambience.gd")
const Juice = preload("res://runner/juice.gd")
const SceneArt = preload("res://runner/scene_sprites.gd")
const Reactive = preload("res://runner/reactive.gd")
const CableRig = preload("res://runner/cable_rig.gd")
const WorldLife = preload("res://runner/world_life.gd")
const START_X := 200.0
const GRAVITY := 2500.0
const JUMP_SPEED := 790.0
const MAX_RUN_SPEED := 680.0
const MAX_ZIP_SPEED := 760.0
const SAVE_PATH := "user://runner2026.json"

var level := Level.new()
var state := "menu"
var prior_state := "playing"
var player := Vector2(START_X, 755)
var vy := 0.0
var gravity := 1
var grounded := true
var jump_buffer := 0.0
var coyote := 0.0
var jump_age := 0.0
var bounce_time := 0.0
var jump_held_override := false
var hold_override_enabled := false
var camera_x := -260.0
var camera_y := 0.0
var camera_kick := Vector2.ZERO
var shake := 0.0
var rotation_visual := 0.0
var squash := 0.0
var happy := 0.0
var invulnerable := 0.0
var hurt_flash := 0.0
var hitstop := 0.0
var time := 0.0
var run_time := 0.0
var wheel := 0.0
var speed := 410.0
var wheel_sound_timer := 0.0
var health := 3
var apple_count := 0
var distance := 0
var score := 0
var attempt := 1
var results: Array = []
var record := 0
var history: Array = []
var countdown := 3.0
var finish_delay := 0.0
var result_reason := ""
var sector := 0
var sector_timer := 0.0
var last_gate := -1
var motion := true
var muted := false
var score_pop := 0.0
var apple_pop := 0.0
var particles: Array = []
var texts: Array = []
var fx := RandomNumberGenerator.new()
var sound: Node
var hero: Node2D
var backdrop: Node2D
var foreground: Node2D
var scenery: Node2D
var zipline := -1
var zipline_cooldown := 0.0
var ui: Control
var font: Font
var is_test := false
var capture := ""
var capture_frames := 0
var captured := false
var save_path := SAVE_PATH
var pending_death := false
var touch_held := false
var slope_angle := 0.0
var zip_swing := 0.0
var zip_swing_velocity := 0.0
var dust_timer := 0.0
var attack_buffer := 0.0
var attack_time := 0.0
var attack_cooldown := 0.0
var attack_serial := 0
var defeated := 0
var rings: Array = []
var echoes: Array = []
var echo_timer := 0.0
var menu_art: Sprite2D
var boost_time := 0.0
var wind_fx_timer := 0.0
var view_zoom := 1.0
var ambience: Node2D
var juice: Node2D
var reactive: Node2D
var active_pad := -1
var pad_jump_down: Dictionary = {}
var trigger_down: Dictionary = {}
var result_age := 0.0
var cable_rig: Node2D
var world_life: Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	Engine.physics_ticks_per_second = 120
	setup_controller_ui()
	Input.joy_connection_changed.connect(controller_connection)
	DisplayServer.window_set_min_size(Vector2i(960, 540))
	fx.randomize()
	backdrop = Backdrop.new()
	add_child(backdrop)
	ambience = Ambience.new()
	add_child(ambience)
	juice = Juice.new()
	add_child(juice)
	menu_art = Sprite2D.new()
	menu_art.texture = MENU_ART
	menu_art.centered = false
	menu_art.z_index = -10
	add_child(menu_art)
	foreground = Foreground.new()
	add_child(foreground)
	scenery = Scenery.new()
	add_child(scenery)
	reactive = Reactive.new()
	add_child(reactive)
	world_life = WorldLife.new()
	add_child(world_life)
	world_life.encounter.connect(world_encounter)
	is_test = "--test-runner" in OS.get_cmdline_user_args()
	if is_test:
		save_path = "user://runner2026-test.json"
	load_save()
	sound = Sound.new()
	add_child(sound)
	sound.set_muted(muted)
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = UI.new()
	ui.game = self
	layer.add_child(ui)
	font = ui.font
	hero = Hero.new()
	hero.z_index = 2
	add_child(hero)
	cable_rig = CableRig.new()
	cable_rig.game = self
	add_child(cable_rig)
	enter_menu()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runner-capture="):
			capture = arg.get_slice("=", 1)
	if capture != "":
		setup_capture()

func enter_menu() -> void:
	state = "menu"
	zipline = -1
	player = Vector2(1800, level.surface(1800, 1) - 6)
	camera_x = player.x - 540
	rotation_visual = 0
	gravity = 1
	vy = 0
	grounded = true
	particles.clear()
	texts.clear()
	level.reset()
	reactive.reset(level)
	world_life.reset(level)
	ui.sync()

func start_session() -> void:
	results.clear()
	attempt = 1
	start_attempt()

func start_attempt() -> void:
	level.reset()
	reactive.reset(level)
	world_life.reset(level)
	sound.restart_score()
	zipline = -1
	zipline_cooldown = 0
	if is_instance_valid(hero):
		hero.reset()
	player = Vector2(START_X, level.surface(START_X, 1) - 6)
	vy = 0
	gravity = 1
	grounded = true
	jump_buffer = 0
	coyote = 0
	jump_age = 0
	bounce_time = 0
	camera_x = START_X - 460
	camera_y = 0
	camera_kick = Vector2.ZERO
	rotation_visual = 0
	squash = 0
	happy = 0
	invulnerable = 0
	hurt_flash = 0
	hitstop = 0
	shake = 0
	run_time = 0
	wheel = 0
	speed = 410
	health = 3
	apple_count = 0
	distance = 0
	score = 0
	last_gate = -1
	sector = 0
	sector_timer = 0
	particles.clear()
	texts.clear()
	countdown = 3
	pending_death = false
	attack_buffer = 0
	attack_time = 0
	attack_cooldown = 0
	attack_serial = 0
	defeated = 0
	boost_time = 0
	wind_fx_timer = 0
	rings.clear()
	echoes.clear()
	juice.effects.clear()
	touch_held = false
	slope_angle = 0
	zip_swing = 0
	zip_swing_velocity = 0
	state = "countdown"
	ui.sync()
	sound.play("ready", 0.9)

func finish_attempt(reason: String) -> void:
	if state != "playing":
		return
	result_reason = reason
	result_age = 0
	results.append({"score": score, "apples": apple_count, "distance": distance, "finished": reason == "finish"})
	finish_delay = 0.55
	state = "result" if attempt < 3 else "final"
	if state == "final":
		var best := best_score()
		record = maxi(record, best)
		history.push_front({"best": best, "date": Time.get_datetime_string_from_system(), "attempts": results.duplicate(true)})
		if history.size() > 30:
			history.resize(30)
		save_game()
	sound.play("win" if reason == "finish" else "hurt", 1.0, -3)
	ui.sync()

func best_score() -> int:
	var best := 0
	for item in results:
		best = maxi(best, int(item.score))
	return best

func next_attempt() -> void:
	if finish_delay > 0:
		return
	if state == "final":
		start_session()
	elif state == "result":
		attempt += 1
		start_attempt()

func pause_game() -> void:
	if state in ["playing", "countdown"]:
		prior_state = state
		state = "paused"
	elif state == "paused":
		state = prior_state
	else:
		return
	ui.sync()

func toggle_sound() -> void:
	muted = not muted
	sound.set_muted(muted)
	save_game()
	ui.sync()

func fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(ui) and capture == "" and not is_test and state in ["playing", "countdown"]:
		pause_game()

func _unhandled_input(event: InputEvent) -> void:
	var press := false
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_SPACE, KEY_UP, KEY_W:
				press = true
			KEY_J, KEY_X:
				queue_attack()
			KEY_ENTER, KEY_KP_ENTER:
				if state == "menu":
					start_session()
				elif state in ["result", "final"]:
					next_attempt()
				elif state == "playing":
					queue_attack()
			KEY_ESCAPE, KEY_P:
				pause_game()
			KEY_F, KEY_F11:
				fullscreen()
			KEY_M:
				toggle_sound()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			queue_attack()
		elif event.button_index == MOUSE_BUTTON_RIGHT and state == "playing":
			press = true
	if event is InputEventScreenTouch:
		touch_held = event.pressed
		if event.pressed and state == "playing":
			press = true
	if event is InputEventJoypadButton and event.pressed:
		active_pad = event.device
		if event.button_index == JOY_BUTTON_A:
			press = true
		elif event.button_index in [JOY_BUTTON_X, JOY_BUTTON_B]:
			if event.button_index == JOY_BUTTON_B and state == "paused":
				pause_game()
			else:
				queue_attack()
		elif event.button_index == JOY_BUTTON_START:
			if state == "menu":
				start_session()
			else:
				pause_game()
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT:
		var was_down: bool = trigger_down.get(event.device, false)
		var down: bool = event.axis_value > 0.55
		trigger_down[event.device] = down
		if down and not was_down:
			active_pad = event.device
			queue_attack()
	if press:
		if state == "menu":
			start_session()
		elif state == "playing":
			queue_jump()
		elif state in ["result", "final"]:
			next_attempt()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_A:
			pad_jump_down[event.device] = event.pressed
		if event.pressed:
			active_pad = event.device
			if state in ["menu", "result", "final", "paused"] and not get_viewport().gui_get_focus_owner():
				if state == "menu":
					ui.play_button.grab_focus()
				elif state == "paused":
					ui.resume_button.grab_focus()
				else:
					ui.next_button.grab_focus()
	if event is InputEventKey and event.pressed:
		active_pad = -1
	if event is InputEventMouseButton and event.pressed:
		active_pad = -1

func controller_connection(device: int, connected: bool) -> void:
	if not connected:
		pad_jump_down.erase(device)
		trigger_down.erase(device)
		if active_pad == device:
			active_pad = -1
			if state in ["playing", "countdown"]:
				pause_game()

func setup_controller_ui() -> void:
	# Godot's built-in UI actions can contain keyboard events only; map all devices explicitly.
	var buttons := {"ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B, "ui_up": JOY_BUTTON_DPAD_UP, "ui_down": JOY_BUTTON_DPAD_DOWN, "ui_left": JOY_BUTTON_DPAD_LEFT, "ui_right": JOY_BUTTON_DPAD_RIGHT}
	for action in buttons:
		var event := InputEventJoypadButton.new()
		event.device = -1
		event.button_index = buttons[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
	for spec in [["ui_left", JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_AXIS_LEFT_X, 1.0], ["ui_up", JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_AXIS_LEFT_Y, 1.0]]:
		var event := InputEventJoypadMotion.new()
		event.device = -1
		event.axis = spec[1]
		event.axis_value = spec[2]
		if not InputMap.action_has_event(spec[0], event):
			InputMap.action_add_event(spec[0], event)

func queue_jump() -> void:
	jump_buffer = 0.16

func jump_held() -> bool:
	if hold_override_enabled:
		return jump_held_override
	for pad in Input.get_connected_joypads():
		if pad_jump_down.get(pad, false) or Input.is_joy_button_pressed(pad, JOY_BUTTON_A):
			return true
	return touch_held or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

func rumble(weak: float, strong: float, duration: float) -> void:
	if not is_test and active_pad in Input.get_connected_joypads():
		Input.start_joy_vibration(active_pad, weak, strong, duration)

func queue_attack() -> void:
	if state == "playing":
		attack_buffer = 0.12

func begin_attack() -> void:
	attack_time = 0.28
	attack_cooldown = 0.30
	attack_buffer = 0
	attack_serial += 1
	sound.play("swish", 1.0, -3)
	reactive.react(player, 180, 1.4, gravity)
	rumble(0.12, 0.0, 0.045)
	juice.emit(0, player + Vector2(70, -gravity * 67), 166, gravity, 0.23)
	camera_kick.x = -2 if motion else 0

func world_encounter(kind: String, pos: Vector2, apples: int) -> void:
	if apples > 0:
		apple_count += apples
		apple_pop = 1
		score_pop = 0.7
		juice.emit(1, pos - Vector2(0, gravity * 42), 110, gravity, 0.3)
		texts.append({"p": pos - Vector2(0, gravity * 90), "text": "+%d" % apples, "life": 0.8})
		sound.play("apple_2", 1.0, -5)
	elif kind in ["chime", "crystal"]:
		sound.play("chime", 0.9 if kind == "chime" else 1.2, -11)
	elif kind == "bird":
		sound.play("bird", 1.0, -14)
	elif kind == "mushroom":
		sound.play("pop", 1.4, -16)

func ring(pos: Vector2, color: Color, radius := 44.0, life := 0.3) -> void:
	rings.append({"p": pos, "color": color, "r": radius, "life": life, "max": life})

func perform_jump(bounce := false) -> void:
	vy = -gravity * (JUMP_SPEED * 1.04 if bounce else JUMP_SPEED)
	grounded = false
	jump_buffer = 0
	coyote = 0
	jump_age = 0
	squash = -0.12
	hero.impact(-80)
	reactive.react(player, 105, 0.7, gravity)
	ring(player, Color("f7dfaa"), 38, 0.23)
	juice.emit(2, player + Vector2(-16, -gravity * 10), 80, gravity, 0.22)
	if bounce:
		bounce_time = 0.20
		happy = 0.65
		shake = maxf(shake, 0.25)
		camera_kick.y = gravity * 3
		burst(player, Color("c4f895"), 12, 180)
		sound.play("pop", 1.05)
	else:
		burst(player, Color("b0d9df"), 5, 90)
		sound.play("jump", fx.randf_range(0.95, 1.08), -4)

func _physics_process(dt: float) -> void:
	if state == "paused":
		return
	time += dt
	if state in ["result", "final"]:
		result_age += dt
	update_fx(dt)
	finish_delay = maxf(0, finish_delay - dt)
	if state == "menu":
		wheel += dt * 4
		player.x = 1800 + sin(time * 0.4) * 32
		player.y = level.surface(player.x, 1) - 6
		return
	if state == "countdown":
		var tick := ceili(countdown)
		countdown -= dt
		if ceili(countdown) != tick:
			sound.play("tick", 1.2 if countdown < 1 else 1.0)
		if countdown <= 0:
			state = "playing"
		return
	if state != "playing":
		return
	if hitstop > 0:
		hitstop -= dt
		return
	run_time += dt
	reactive.advance(dt, player, speed, grounded, gravity)
	world_life.advance(dt, player, grounded, gravity)
	level.advance(run_time, dt)
	for ledge in level.bonus:
		if ledge.just_broke:
			var center := Vector2((ledge.a + ledge.b) * 0.5, ledge.home1)
			juice.emit(2, center, 190, 1, 0.38)
			burst(center, Color("e8b570"), 18, 180)
			sound.play("land", 0.6, -7)
	boost_time = maxf(0, boost_time - dt)
	wind_fx_timer -= dt
	if (boost_time > 0 or zipline >= 0) and wind_fx_timer <= 0:
		wind_fx_timer = 0.13
		juice.emit(3, player + Vector2(-60, -gravity * 58), 190, gravity, 0.28)
	attack_buffer = maxf(0, attack_buffer - dt)
	attack_time = maxf(0, attack_time - dt)
	attack_cooldown = maxf(0, attack_cooldown - dt)
	if attack_buffer > 0 and attack_cooldown <= 0:
		begin_attack()
	if attack_time > 0.12 and attack_time <= 0.255:
		world_life.strike(player, gravity, attack_serial)
	jump_buffer = maxf(0, jump_buffer - dt)
	coyote = maxf(0, coyote - dt)
	invulnerable = maxf(0, invulnerable - dt)
	jump_age += dt
	bounce_time = maxf(0, bounce_time - dt)
	zipline_cooldown = maxf(0, zipline_cooldown - dt)
	zip_swing_velocity += (-zip_swing * 26 - zip_swing_velocity * 3.8) * dt
	zip_swing += zip_swing_velocity * dt
	if zipline >= 0 and jump_buffer > 0:
		detach_cable(true)
	var old := player
	var slope := (level.surface(player.x + 15, gravity) - level.surface(player.x - 15, gravity)) / 30.0
	var target_speed := 410 + 100 * smoothstep(0, 40, run_time) + 150 * smoothstep(40, 110, run_time)
	target_speed += clampf(slope * gravity * 190, -25, 25)
	if boost_time > 0:
		target_speed += 105
	if zipline >= 0:
		target_speed *= 1.16
	target_speed = minf(target_speed, MAX_ZIP_SPEED if zipline >= 0 else MAX_RUN_SPEED)
	speed = move_toward(speed, target_speed, dt * (220 if boost_time > 0 else 48))
	speed = minf(speed, MAX_ZIP_SPEED)
	slope_angle = atan(slope) if grounded else 0.0
	player.x += speed * dt
	wheel += speed * dt / 16
	wheel_sound_timer -= dt
	if (grounded or zipline >= 0) and wheel_sound_timer <= 0:
		wheel_sound_timer = 0.13 if zipline >= 0 else 136.0 / speed
		sound.play("roll" if zipline >= 0 else "step", 1.5 if zipline >= 0 else 1.0, -12)
	# Gates have a fixed world coordinate; crossing works even at low frame rates.
	for i in range(last_gate + 1, level.gates.size()):
		var gate: Dictionary = level.gates[i]
		if old.x < gate.x and player.x >= gate.x:
			flip_gravity(gate.g)
			last_gate = i
	if zipline >= 0:
		player.y = cable_y(zipline, player.x) + 168
		vy = 0
		grounded = false
		jump_age = 1
		if player.x >= level.cables[zipline].b:
			detach_cable(false)
	else:
		update_vertical(dt, old)
		try_attach_cable()
	update_springs(dt, old)
	if grounded:
		level.touch_platform(player.x, player.y, gravity)
	for wind in level.wind_boosts:
		if not wind.used and old.x < wind.x and player.x >= wind.x:
			wind.used = true
			boost_time = 1.2
			juice.emit(3, player + Vector2(35, -gravity * 60), 220, gravity, 0.35)
			ring(player - Vector2(0, gravity * 55), Color("a1efef"), 100, 0.4)
			sound.play("swish", 0.7, -4)
	dust_timer -= dt
	if grounded and dust_timer <= 0:
		dust_timer = 0.075
		var life := 0.24
		particles.append({"p": player + Vector2(-45, -gravity * 4), "v": Vector2(-65, -gravity * 22), "life": life, "max": life, "color": Color("d3ba8e"), "r": 5.0, "star": false})
	update_enemies(dt, old)
	echo_timer -= dt
	if not grounded and zipline < 0 and speed > 480 and echo_timer <= 0:
		echo_timer = 0.065
		echoes.append({"p": player, "frame": hero.frame, "angle": rotation_visual, "life": 0.18})
	collect_apples(old)
	if player.y > 1090 or player.y < -180:
		fall_rescue()
	distance = mini(4800, maxi(0, floori((player.x - START_X) / Level.METER)))
	score = distance + apple_count * 10
	var next_sector := mini(11, floori(distance / 400.0))
	if next_sector != sector:
		sector = next_sector
		sector_timer = 2.2
	update_camera(dt)
	if player.x >= Level.LENGTH + START_X:
		finish_attempt("finish")
	elif health <= 0:
		finish_attempt("hearts")

func flip_gravity(new_gravity: int) -> void:
	if gravity == new_gravity:
		return
	gravity = new_gravity
	zipline = -1
	grounded = false
	coyote = 0
	vy = gravity * 180
	jump_age = 1
	shake = 0.3
	camera_kick.y = gravity * 6
	burst(player + Vector2(0, -40), Color("5eebee") if gravity == -1 else Color("ffda83"), 22, 200)
	sound.play("ready", 0.85 if gravity == -1 else 1.1)

func update_vertical(dt: float, old: Vector2) -> void:
	if grounded:
		var support := find_support(player.x, player.y, gravity)
		if is_nan(support):
			grounded = false
			coyote = 0.13
		else:
			player.y = support - gravity * 6
			vy = 0
	if jump_buffer > 0 and (grounded or coyote > 0):
		perform_jump()
	if not grounded:
		var factor := 0.62 if (jump_held() or bounce_time > 0) and jump_age < 0.16 and vy * gravity < 0 else 1.0
		if vy * gravity > 0:
			factor = 1.28
		vy += gravity * GRAVITY * factor * dt
		if not jump_held() and bounce_time <= 0 and vy * gravity < -540:
			vy = -gravity * 540
		vy = clampf(vy, -1150, 1150)
		player.y += vy * dt
		resolve_landing(old)

func try_attach_cable() -> void:
	if grounded or gravity != 1 or zipline_cooldown > 0 or jump_age < 0.035:
		return
	for i in range(level.cables.size()):
		var cable: Dictionary = level.cables[i]
		if player.x < cable.a or player.x > cable.b - 150:
			continue
		var target: float = cable_y(i, player.x) + 168
		if absf(player.y - target) < 43 and vy < 240:
			zipline = i
			player.y = target
			vy = 0
			zip_swing_velocity = 1.6
			happy = 0.8
			hero.impact(400)
			burst(player + Vector2(0, -168), Color("ffdfa0"), 9, 100)
			sound.play("ready", 1.25, -4)
			return

func detach_cable(jump: bool) -> void:
	zipline = -1
	zipline_cooldown = 0.55
	grounded = false
	if jump:
		perform_jump()
	else:
		vy = -180
		jump_age = 0.4

func find_support(x: float, y: float, g: int) -> float:
	for track in level.platforms:
		if track.get("disabled", false):
			continue
		if track.a > x + 10:
			break
		if track.g != g or track.b < x - 10:
			continue
		var surface := track_height(track, clampf(x, track.a, track.b))
		if absf(y + g * 6 - surface) < 26:
			return surface
	return NAN

func track_height(track: Dictionary, x: float) -> float:
	return lerpf(track.y1, track.y2, (x - track.a) / maxf(1, track.b - track.a))

func resolve_landing(old: Vector2) -> void:
	if vy * gravity < 0:
		return
	var best := INF if gravity == 1 else -INF
	for track in level.platforms:
		if track.get("disabled", false):
			continue
		if track.a > player.x + 12:
			break
		if track.g != gravity or track.b < player.x - 12:
			continue
		var surface := track_height(track, clampf(player.x, track.a, track.b)) - gravity * 6
		if gravity * (old.y - surface) <= 12 and gravity * (player.y - surface) >= 0:
			if gravity * surface < gravity * best:
				best = surface
	if not is_inf(best):
		var force := absf(vy)
		player.y = best
		vy = 0
		grounded = true
		jump_age = 0
		squash = minf(0.17, force / 4500)
		if force > 350:
			hero.impact(force)
			camera_kick.y = gravity * minf(4, force / 250)
			burst(player, Color("bed6dc"), 5, 75)
			sound.play("land", 0.95 + minf(0.15, force * 0.0001), -4)
			landing_puff(force)
			juice.emit(2, player - Vector2(0, gravity * 12), minf(170, 95 + force * 0.05), gravity, 0.32)
			ring(player, Color("ffe4ab"), minf(70, force * 0.06), 0.28)
		# A press just before touchdown launches in this same physics tick.
		if jump_buffer > 0:
			perform_jump()

func enemy_position(enemy: Dictionary) -> Vector2:
	var pos: Vector2 = enemy.p
	pos.x += float(enemy.get("move", 0))
	if enemy.kind in ["horse", "charger"] or float(enemy.get("move", 0)) != 0:
		pos.y = level.surface(pos.x, enemy.g)
	return pos

func update_springs(dt: float, old: Vector2) -> void:
	for spring in level.springs:
		spring.pulse = maxf(0, spring.pulse - dt * 2.5)
		if spring.g == gravity and grounded and old.x < spring.x and player.x >= spring.x:
			spring.pulse = 1.0
			perform_jump(true)
			vy = -gravity * 910
			juice.emit(3, player - Vector2(0, gravity * 55), 150, gravity, 0.3)
			bounce_time = 0.28
			ring(player, Color("8cf1c5"), 90, 0.42)
			sound.play("ready", 1.3, -7)

func hit_enemy(enemy: Dictionary, pos: Vector2, stomp := false) -> void:
	var center := pos - Vector2(0, enemy.g * 48)
	reactive.react(pos, 210, 1.8, enemy.g)
	rumble(0.3, 0.45, 0.09)
	juice.emit(1, center, 115 if stomp else 132, enemy.g, 0.22)
	var health_left := int(enemy.get("hp", 1)) - 1
	enemy.hp = health_left
	enemy.stun = 0.5
	enemy.last_hit = attack_serial
	if health_left > 0:
		enemy.move = float(enemy.get("move", 0)) + 160
		burst(center, Color("e7d4a2"), 12, 170)
		ring(center, Color("fff5cb"), 58, 0.26)
		sound.play("hit", 0.7, -6)
	else:
		enemy.dead = true
		enemy.squash = 1.0
		enemy.flight = Vector2.ZERO
		enemy.flight_v = Vector2(250, -enemy.g * (240 if stomp else 360))
		defeated += 1
		sound.play("thump", 1.0, -3)
		burst(center, Color("ffe4a0"), 20, 230)
		ring(center, Color("fff2c7"), 80, 0.32)
		sound.play("pop", 0.95 if stomp else 1.25, -3)
	hitstop = 0.032 if stomp else 0.045
	shake = maxf(shake, 0.40)
	camera_kick += Vector2(4, -2 * gravity)
	happy = 0.4

func update_enemies(dt: float, old: Vector2) -> void:
	for enemy in level.enemies:
		if enemy.p.x > player.x + 1100:
			break
		if enemy.p.x < player.x - 450:
			continue
		if enemy.dead:
			enemy.squash = maxf(0, enemy.squash - dt * 1.6)
			if enemy.has("flight_v"):
				enemy.flight_v.y += enemy.g * 900 * dt
				enemy.flight += enemy.flight_v * dt
			continue
		enemy.stun = maxf(0, float(enemy.get("stun", 0)) - dt)
		if enemy.stun <= 0:
			if enemy.kind == "horse":
				enemy.move = sin(run_time * 2.4 + float(enemy.get("phase", 0))) * 32
			elif enemy.kind == "charger":
				var approach: float = enemy.p.x + float(enemy.get("move", 0)) - player.x
				if not enemy.get("charged", false) and approach > 0 and approach < 640:
					if float(enemy.get("windup", 0)) == 0:
						sound.play("snort", 1.0, -4)
					enemy.windup = float(enemy.get("windup", 0)) + dt
					if enemy.windup >= 0.48:
						enemy.charged = true
				if enemy.get("charged", false):
					enemy.move = maxf(-145, float(enemy.get("move", 0)) - 220 * dt)
		var pos := enemy_position(enemy)
		if enemy.kind == "rock":
			if player.x > pos.x - maxf(820, speed * 1.65):
				enemy.triggered = true
			if enemy.triggered:
				var previous_drop: float = enemy.drop
				enemy.drop = minf(1.0, enemy.drop + dt * 1.45)
				if previous_drop < 1 and enemy.drop >= 1:
					burst(pos, Color("d7ba94"), 18, 125)
					ring(pos, Color("e5bd87"), 70, 0.3)
					sound.play("land", 0.7, -5)
			pos.y = lerpf(170, enemy.p.y, enemy.drop * enemy.drop)
			if enemy.drop < 0.20:
				continue
		if enemy.g != gravity and enemy.kind != "rock":
			continue
		var pony: bool = enemy.kind in ["horse", "charger"]
		var body := player + Vector2(0, -gravity * 55)
		var enemy_center := pos + Vector2(0, -enemy.g * (46 if pony else 23))
		var front: float = pos.x - player.x
		# Punch is directional, works airborne, and hits each enemy once per swing.
		if attack_time > 0.12 and attack_time <= 0.255 and enemy.kind != "rock" and int(enemy.get("last_hit", -1)) != attack_serial:
			if front > -12 and front < 146 and absf(body.y - enemy_center.y) < 75:
				hit_enemy(enemy, pos)
				continue
		var head := 74.0 if pony else 35.0
		var dx := absf(player.x - pos.x)
		var stomp: bool = enemy.kind in ["slime", "horse", "charger"] and dx < (56 if pony else 50) and vy * gravity > 10 and gravity * (old.y - (pos.y - gravity * head)) < 14 and gravity * (player.y - (pos.y - gravity * head)) >= -5
		if stomp:
			hit_enemy(enemy, pos, true)
			player.y = pos.y - gravity * (head + 7)
			perform_jump(true)
			hero.impact(800)
		elif dx < (40 if enemy.kind == "rock" else (52 if pony else 43)) and (player.y > pos.y - 44 and player.y < pos.y + 35 if enemy.kind == "rock" else absf(body.y - enemy_center.y) < (65 if pony else 57)):
			if enemy.stun > 0:
				continue
			if take_damage():
				enemy.dead = true
				enemy.squash = 1.0
				enemy.flight = Vector2.ZERO
				enemy.flight_v = Vector2(100, -enemy.g * 140)
				burst(enemy_center, Color("d6b1cd"), 15, 160)

func collect_apples(old: Vector2) -> void:
	var from := old + Vector2(0, -gravity * 68)
	var to := player + Vector2(0, -gravity * 68)
	for apple in level.apples:
		if apple.p.x > player.x + 110:
			break
		if apple.taken or apple.p.x < player.x - 100:
			continue
		if Geometry2D.get_closest_point_to_segment(apple.p, from, to).distance_to(apple.p) < 62:
			apple.taken = true
			apple_count += 1
			apple_pop = 1
			score_pop = 0.35
			burst(apple.p, Color("ffe085"), 7, 110)
			ring(apple.p, Color("ffe7a6"), 26, 0.18)
			sound.play("apple_%d" % (apple_count % 5), 1.0, -5)

func take_damage() -> bool:
	if invulnerable > 0 or health <= 0:
		return false
	health -= 1
	invulnerable = 1.7
	hurt_flash = 0.22
	shake = 0.7
	hitstop = 0.055
	happy = 0
	sound.play("hurt", 0.9, -2)
	return true

func fall_rescue() -> void:
	# Falling costs a heart and rescues to the next safe rail; no soft lock in pits.
	invulnerable = 0
	zipline = -1
	take_damage()
	for i in range(60):
		var x := player.x + i * 20
		var g := level.gravity_at(x)
		var ground := level.ground_at(x, g)
		if not is_nan(ground) and not level.is_gap(x + 100, g):
			player = Vector2(x, ground - g * 6)
			gravity = g
			grounded = true
			vy = 0
			for j in range(level.gates.size()):
				if level.gates[j].x <= x:
					last_gate = j
			camera_x = player.x - 460
			break

func update_camera(dt: float) -> void:
	# Follow forward motion without ever rotating the scene or the HUD.
	var target := player.x - 460 + (speed - 410) * 0.36 + (35 if zipline >= 0 else 0)
	camera_x = lerpf(camera_x, target, 1.0 - exp(-dt * 10))
	var desired_y := clampf((player.y - 500) * 0.07, -24, 24) if motion else 0.0
	camera_y = lerpf(camera_y, desired_y, 1.0 - exp(-dt * 3))

func burst(pos: Vector2, color: Color, count: int, force: float) -> void:
	for i in range(count):
		var life := fx.randf_range(0.25, 0.5)
		particles.append({"p": pos, "v": Vector2.from_angle(fx.randf() * TAU) * fx.randf_range(force * 0.3, force), "life": life, "max": life, "color": Biomes.leaf(player.x) if i % 4 == 1 else color, "r": fx.randf_range(2, 5), "star": i % 3 == 0, "leaf": i % 4 == 1})

func landing_puff(force: float) -> void:
	reactive.react(player, 160, clampf(force / 650, 0.5, 1.6), gravity)
	rumble(0.12, 0.14, 0.06)
	for direction in [-1.0, 1.0]:
		for i in range(4):
			var life := 0.22 + i * 0.035
			particles.append({"p": player + Vector2(direction * 27, -gravity * 6), "v": Vector2(direction * (50 + i * 28), -gravity * (18 + i * 10)), "life": life, "max": life, "color": Color("d1d6c7"), "r": 4.0 + i * 1.6, "star": false})

func update_fx(dt: float) -> void:
	if is_instance_valid(juice):
		juice.advance(dt)
	for item in rings:
		item.life -= dt
	rings = rings.filter(func(item): return item.life > 0)
	for item in echoes:
		item.life -= dt
	echoes = echoes.filter(func(item): return item.life > 0)
	squash = move_toward(squash, 0, dt * 0.95)
	happy = maxf(0, happy - dt)
	hurt_flash = maxf(0, hurt_flash - dt)
	shake = maxf(0, shake - dt * 1.6)
	sector_timer = maxf(0, sector_timer - dt)
	score_pop = maxf(0, score_pop - dt * 3)
	apple_pop = maxf(0, apple_pop - dt * 4)
	camera_kick = camera_kick.lerp(Vector2.ZERO, 1.0 - exp(-dt * 14))
	rotation_visual = lerpf(rotation_visual, 0.0 if gravity == 1 else PI, 1.0 - exp(-dt * 13))
	for item in particles:
		item.life -= dt
		item.p += item.v * dt
		item.v *= exp(-dt * 2)
	for item in texts:
		item.life -= dt
		item.p.y -= dt * 40
	particles = particles.filter(func(p): return p.life > 0)
	texts = texts.filter(func(t): return t.life > 0)
	if particles.size() > 350:
		particles = particles.slice(particles.size() - 350)

func _process(_dt: float) -> void:
	queue_redraw()
	ui.queue_redraw()
	backdrop.present(camera_x, player.x, time, speed)
	var menu_scene := state in ["menu", "result", "final"]
	var zoom_target := 1.0 + (0.028 if attack_time > 0.1 else (0.018 if boost_time > 0 else 0.0)) if motion and not menu_scene else 1.0
	if state != "paused":
		view_zoom = lerpf(view_zoom, zoom_target, 1 - exp(-_dt * 12))
	scale = Vector2.ONE * view_zoom
	position = get_viewport_rect().size * (1 - view_zoom) * 0.5
	menu_art.visible = menu_scene
	menu_art.scale = get_viewport_rect().size / MENU_ART.get_size()
	foreground.visible = not menu_scene
	ambience.visible = not menu_scene
	juice.visible = not menu_scene
	scenery.visible = not menu_scene
	reactive.visible = not menu_scene
	world_life.visible = not menu_scene
	foreground.present(camera_x, time, player.x)
	ambience.present(camera_x, time, player.x)
	scenery.position = Vector2(-camera_x, -camera_y) + (camera_kick if motion else Vector2.ZERO) + camera_shake()
	juice.position = scenery.position
	cable_rig.position = scenery.position
	cable_rig.queue_redraw()
	reactive.position = scenery.position
	world_life.position = scenery.position
	world_life.present(camera_x)
	reactive.present(camera_x, time)
	scenery.present(level, camera_x, time, player)
	sound.set_scene(state == "playing", clampf((speed - 410) / 300 + (0.35 if zipline >= 0 else 0.0) + (0.12 if gravity == -1 else 0.0), 0, 1))
	if is_instance_valid(hero):
		var jitter := camera_shake()
		hero.visible = true
		hero.position = player + Vector2(-camera_x, -camera_y) + (camera_kick if motion else Vector2.ZERO) + jitter
		hero.scale = Vector2.ONE
		if menu_scene:
			hero.position = get_viewport_rect().size * Vector2(0.77, 0.65)
			hero.scale = Vector2.ONE * 2.35
		hero.present(0.0 if state == "paused" else _dt, {"time": time, "wheel": wheel, "grounded": true if menu_scene else grounded, "vy": 0.0 if menu_scene else vy, "gravity": 1 if menu_scene else gravity, "angle": 0.0 if menu_scene else rotation_visual, "jump_age": jump_age, "happy": happy, "hurt": 0.0 if menu_scene else hurt_flash, "invulnerable": 0.0 if menu_scene else invulnerable, "allow_blink": state not in ["result", "final"], "ziplining": zipline >= 0 and not menu_scene, "slope": slope_angle, "swing": zip_swing, "running": state == "playing", "speed": speed, "attack": attack_time if not menu_scene else 0.0})
	if capture != "" and not captured:
		capture_frames += 1
		if capture_frames > 14:
			captured = true
			capture_frame.call_deferred()

func _draw() -> void:
	if state in ["menu", "result", "final"]:
		return
	var s := get_viewport_rect().size
	var zone := mini(11, maxi(0, floori((player.x - START_X) / Level.SECTION)))
	var jitter := camera_shake()
	var shift := Vector2(-camera_x, -camera_y) + (camera_kick if motion else Vector2.ZERO) + jitter
	draw_set_transform(shift)
	for echo in echoes:
		draw_set_transform(shift + echo.p, echo.angle)
		RunnerSprites.hero(self, echo.frame, Vector2.ZERO, echo.angle > PI * 0.5, Vector2.ONE, Color(1.0, 0.79, 0.69, echo.life * 0.55))
	draw_set_transform(shift)
	draw_supports(s.x)
	draw_cables(s.x)
	var biome_fade := smoothstep(0.0, 0.22, fmod(maxf(0, player.x - START_X), Level.SECTION) / Level.SECTION)
	var lava_strength := biome_fade if zone == 6 else (1 - biome_fade if zone == 7 else 0.0)
	var lava := lava_strength > 0.001
	for warning in level.warnings:
		if warning.x > camera_x and warning.x < camera_x + s.x:
			var p := Vector2(warning.x, 365)
			Art.p(self, [p + Vector2(-19, 17), p + Vector2(0, -18), p + Vector2(19, 17)], Color("ffd079"), 3)
			draw_string(font, p + Vector2(-4, 11), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Art.INK)
	for i in range(level.gates.size()):
		var gate: Dictionary = level.gates[i]
		if gate.x < camera_x - 140 or gate.x > camera_x + s.x + 140:
			continue
		var from_g := 1 if i == 0 else int(level.gates[i - 1].g)
		Art.gate(self, Vector2(gate.x, level.surface(gate.x, from_g) - 5 * from_g), gate.g, from_g, time)
		var warning_pos := Vector2(gate.x - 190, 430)
		draw_string(font, warning_pos, "↑" if gate.g == -1 else "↓", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("71f4ea") if gate.g == -1 else Color("ffdc8c"))
	for apple in level.apples:
		if apple.p.x > camera_x + s.x + 40:
			break
		if not apple.taken and apple.p.x > camera_x - 40:
			Art.apple(self, apple.p + Vector2(0, sin(time * 3 + apple.phase) * 3), 0.9)
	for spring in level.springs:
		if spring.x < camera_x - 80 or spring.x > camera_x + s.x + 80:
			continue
		var ground: float = level.surface(spring.x, spring.g)
		var pad := Vector2(spring.x, ground - 3 * spring.g)
		Art.e(self, pad - Vector2(0, spring.g * 24), Vector2(48, 24), Color(1, 0.72, 0.35, 0.12 + sin(time * 3 + spring.x) * 0.025 + spring.pulse * 0.1), 0)
		SceneArt.prop(self, 0, pad, 64 + spring.pulse * 10, Color.WHITE, spring.g)
	for wind in level.wind_boosts:
		if wind.x < camera_x - 160 or wind.x > camera_x + s.x + 160:
			continue
		var pad := Vector2(wind.x, level.surface(wind.x, wind.g) - 4 * wind.g)
		SceneArt.prop(self, 1, pad, 100 + sin(time * 2) * 1.5, Color.WHITE, wind.g)
		for j in range(3):
			var phase := fposmod(time * 1.5 + j * 0.4, 1.0)
			var p := pad + Vector2(50 + phase * 125, -wind.g * (50 + sin(phase * 5 + j) * 14))
			Art.line(self, [p, p + Vector2(30, -wind.g * 3)], Color(1, 0.92, 0.64, (1 - phase) * 0.3), 2)
	for ledge in level.bonus:
		if ledge.b < camera_x or ledge.a > camera_x + s.x or ledge.disabled:
			continue
		var mid: float = (ledge.a + ledge.b) * 0.5
		var y := track_height(ledge, mid)
		if ledge.mode == "moving":
			Art.e(self, Vector2(mid, y + ledge.g * 34), Vector2(34, 17), Color(0.3, 0.86, 1, 0.13 + sin(time * 3) * 0.03), 0)
			Art.Base.star(self, Vector2(mid, y + ledge.g * 38), 7, Color("baf6ff"), time * 0.3)
		else:
			for j in range(3):
				var p := Vector2(ledge.a + 80 + j * 160, track_height(ledge, ledge.a + 80 + j * 160) + ledge.g * 13)
				Art.line(self, [p + Vector2(-14, 0), p + Vector2(-3, 6), p + Vector2(5, 2), p + Vector2(17, 10)], Color("593f3b"), 2)
				if ledge.collapse > 0:
					draw_circle(p, 5 + sin(time * 30) * 2, Color(1, 0.73, 0.3, 0.6), true, -1, true)
	for enemy in level.enemies:
		if enemy.p.x > camera_x + s.x + 80:
			break
		if enemy.p.x < camera_x - 80 or (enemy.dead and enemy.squash <= 0):
			continue
		var p := enemy_position(enemy) + Vector2(enemy.get("flight", Vector2.ZERO))
		if enemy.kind == "rock":
			p.y = lerpf(170, p.y, enemy.drop * enemy.drop)
			draw_rock_warning(enemy)
		if enemy.kind in ["horse", "charger"]:
			var frame := int(run_time * 11 + enemy.phase) % 4
			if enemy.dead:
				frame = 7
			elif enemy.get("stun", 0) > 0:
				frame = 6
			elif enemy.get("charged", false):
				frame = 5
			elif enemy.get("windup", 0) > 0:
				frame = 4
			RunnerSprites.horse(self, frame, p - Vector2(0, enemy.g * 5), enemy.g, Color(1, 1, 1, minf(1, enemy.squash * 2) if enemy.dead else 1.0))
			if frame == 4:
				Art.e(self, p - Vector2(0, enemy.g * 104), Vector2(23, 7), Color(1, 0.75, 0.32, 0.45 + sin(time * 20) * 0.2), 0)
		else:
			Art.enemy(self, p, enemy.kind, run_time + enemy.phase, enemy.g, enemy.squash)
	# Contact shadow stays on the rail when the cart leaves it. Hero is a separate rig.
	if state != "menu":
		var shadow_y: float = level.surface(player.x, gravity)
		if grounded:
			var support := find_support(player.x, player.y, gravity)
			if not is_nan(support):
				shadow_y = support
		var height := absf(player.y - shadow_y)
		if grounded or not level.is_gap(player.x, gravity):
			Art.e(self, Vector2(player.x, shadow_y - gravity * 4), Vector2(49 - minf(18, height * 0.08), 7), Color(0.02, 0.08, 0.15, clampf(0.3 - height * 0.001, 0.07, 0.3)), 0)
		if grounded:
			for i in range(2):
				var trail_x := player.x - 70 - i * 35 - fmod(time * 170, 35)
				Art.line(self, [Vector2(trail_x, player.y - gravity * (12 + i * 10)), Vector2(trail_x + 19, player.y - gravity * (12 + i * 10))], Color(0.76, 0.88, 0.89, 0.22), 2)
	# Finish arch, visible well before crossing the finish.
	if camera_x + s.x > Level.LENGTH - 100:
		var x := Level.LENGTH + START_X
		var y: float = level.surface(x, 1)
		Art.line(self, [Vector2(x - 80, y), Vector2(x - 80, y - 190), Vector2(x + 80, y - 190), Vector2(x + 80, y)], Color("e9c780"), 12)
		for row in range(2):
			for col in range(8):
				draw_rect(Rect2(x - 80 + col * 20, y - 190 + row * 20, 20, 20), Art.PAPER if (row + col) % 2 else Art.INK)
	for item in rings:
		var t: float = 1 - item.life / item.max
		var color: Color = item.color
		color.a *= (1 - t) * 0.8
		draw_arc(item.p, maxf(1, item.r * (0.2 + t * 0.8)), 0, TAU, 40, color, 3 * (1 - t) + 0.5, true)
	for item in particles:
		var color: Color = item.color
		color.a *= item.life / item.max
		if item.star:
			var r: float = item.r * 1.5
			var p: Vector2 = item.p
			draw_colored_polygon(PackedVector2Array([p + Vector2(-r, 0), p + Vector2(-r * 0.2, -r * 0.2), p + Vector2(0, -r), p + Vector2(r * 0.2, -r * 0.2), p + Vector2(r, 0), p + Vector2(r * 0.2, r * 0.2), p + Vector2(0, r), p + Vector2(-r * 0.2, r * 0.2)]), color)
		elif item.get("leaf", false):
			var axis: Vector2 = Vector2.from_angle(time * 3 + item.p.x) * item.r * 1.6
			var side: Vector2 = axis.orthogonal() * 0.35
			draw_colored_polygon(PackedVector2Array([item.p - axis, item.p + side, item.p + axis, item.p - side]), color)
		else:
			draw_circle(item.p, item.r * item.life / item.max, color, true, -1, true)
	for item in texts:
		var color := Color(1, 0.9, 0.56, minf(1, item.life * 3))
		draw_string_outline(font, item.p, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, 4, Art.INK)
		draw_string(font, item.p, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, color)
	draw_set_transform(Vector2.ZERO)
	if hurt_flash > 0:
		draw_rect(Rect2(Vector2.ZERO, s), Color(1, 0.45, 0.5, hurt_flash * 0.5))

func draw_supports(width: float) -> void:
	# Painted background owns the canopy silhouette; only the hanging lamps animate.
	var alpha := 1 - Backdrop.outdoor_amount(player.x)
	for i in range(floori((camera_x - 200) / 1130), ceili((camera_x + width + 200) / 1130)):
		var x := i * 1130.0 + 450
		var length := 95 + sin(i * 2.7) * 32
		var sway := sin(time * 1.4 + i * 2.1) * 8
		var lamp := Vector2(x + sway, 115 + length)
		Art.line(self, [Vector2(x, -20), Vector2(x + sway * 0.5, 100), lamp], Color(Color("503e31"), alpha), 4)
		Art.line(self, [Vector2(x + 1, -20), Vector2(x + sway * 0.5 + 1, 100), lamp + Vector2(1, 0)], Color(Color("a38a59"), alpha), 1.5)
		for radius in [75, 53, 34, 22]:
			Art.e(self, lamp + Vector2(0, 20), Vector2.ONE * radius, Color(1, 0.65, 0.22, 0.028 * alpha), 0)
		Art.Sprites.prop(self, 2, lamp + Vector2(0, 45), 37, 1, Color(1, 1, 1, alpha))

func cable_y(index: int, x: float) -> float:
	var cable: Dictionary = level.cables[index]
	var t := clampf((x - cable.a) / (cable.b - cable.a), 0, 1)
	var load := 0.0
	if zipline == index:
		load = exp(-pow((x - player.x) / 180.0, 2)) * 5
	return level.cable_height(index, x) + sin(PI * t) * (sin(time * 2.4 + t * 8) * 2.5 + load)

func draw_cables(width: float) -> void:
	for i in range(level.cables.size()):
		var cable: Dictionary = level.cables[i]
		# The tree support extends over 600px beyond its cable anchor.
		if cable.b < camera_x - 900 or cable.a > camera_x + width + 900:
			continue
		var points := PackedVector2Array()
		var braid_a := PackedVector2Array()
		var braid_b := PackedVector2Array()
		var steps := ceili((cable.b - cable.a) / 5.0)
		for step in range(steps + 1):
			var x: float = lerpf(cable.a, cable.b, step / float(steps))
			var y := cable_y(i, x)
			points.append(Vector2(x, y))
			braid_a.append(Vector2(x, y + sin(x * 0.43) * 3))
			braid_b.append(Vector2(x, y - sin(x * 0.43) * 3))
		draw_polyline(points, Color("322b29"), 14, true)
		draw_polyline(points, Color("9b784a"), 10, true)
		draw_polyline(braid_a, Color("e0b778"), 3.2, true)
		draw_polyline(braid_b, Color("715133"), 2.2, true)
		for x in [cable.a, cable.b]:
			var y := cable_y(i, x)
			var scale := clampf((level.surface(x, 1) - y) / 657.0, 0.38, 0.72)
			var mirror: bool = x == cable.b
			var source := Rect2(0, 0, 887, 887)
			var left: float = x - (127 if mirror else 760) * scale
			draw_texture_rect_region(ZIP_PROPS, Rect2(left, y - 230 * scale, -887 * scale if mirror else 887 * scale, 887 * scale), source)
		var entry := Vector2(cable.a + 60, cable.ya + 65)
		Art.p(self, [entry + Vector2(-19, -16), entry + Vector2(19, -16), entry + Vector2(25, 0), entry + Vector2(19, 16), entry + Vector2(-19, 16)], Color("e9bd69"), 2)
		Art.line(self, [entry + Vector2(-7, 0), entry + Vector2(9, 0), entry + Vector2(3, -5)], Color("293c4b"), 3)

func zip_grips() -> PackedVector2Array:
	var lean_angle: float = hero.rotation
	return PackedVector2Array([player + Vector2(-24, -115).rotated(lean_angle), player + Vector2(20, -115).rotated(lean_angle)])

func draw_rock_warning(enemy: Dictionary) -> void:
	var x: float = enemy.p.x
	var ground: float = enemy.p.y
	if enemy.drop < 1:
		var alpha := 0.3 + 0.15 * sin(time * 12)
		Art.e(self, Vector2(x, ground - 3), Vector2(49, 7), Color(1, 0.62, 0.24, alpha), 0)
		Art.line(self, [Vector2(x - 40, 132), Vector2(x - 13, 150), Vector2(x - 4, 135), Vector2(x + 18, 158), Vector2(x + 39, 144)], Color("5b443d"), 5)
		for j in range(7):
			var phase := fposmod(time * 0.9 + j * 0.17, 1)
			draw_circle(Vector2(x + sin(j * 4.1) * 31, 165 + phase * 120), 1.5 + j % 3, Color(0.89, 0.72, 0.45, 1 - phase))
	var marker := Vector2(x - 95, ground - 24)
	Art.p(self, [marker + Vector2(-18, 0), marker + Vector2(0, -30), marker + Vector2(18, 0)], Color("e9b85e"), 2)
	draw_string(font, marker + Vector2(-3, -6), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Art.INK)

func camera_shake() -> Vector2:
	if not motion:
		return Vector2.ZERO
	return Vector2(sin(time * 57) * 0.7 + sin(time * 97) * 0.3, cos(time * 63) * 0.7 + cos(time * 109) * 0.3) * shake * shake * 7

func load_save() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Dictionary:
		record = maxi(0, int(data.get("record", 0)))
		muted = bool(data.get("muted", false))
		motion = bool(data.get("motion", true))
		if data.get("history") is Array:
			history = data.history

func save_game() -> void:
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"record": record, "history": history, "muted": muted, "motion": motion}, "  "))
		file.close()
		var error := DirAccess.rename_absolute(save_path + ".tmp", save_path)
		if error != OK:
			push_warning("Не удалось сохранить рекорд: " + error_string(error))

func setup_capture() -> void:
	if capture == "menu":
		return
	start_session()
	state = "playing"
	var x := 3070.0
	if capture == "gravity":
		x = 16400
		gravity = -1
		rotation_visual = PI
		last_gate = 0
	elif capture == "lava":
		x = 31000
	elif capture == "cable":
		x = 6700
		zipline = 0
	player = Vector2(x, level.surface(x, gravity) - gravity * 6)
	if capture == "cable":
		player.y = level.cable_height(0, x) + 168
		grounded = false
	camera_x = x - 460
	grounded = capture != "cable"
	apple_count = 12 if capture == "play" else 46
	distance = floori((x - START_X) / 12)
	score = distance + apple_count * 10
	if capture == "results":
		results = [{"score": 2340, "apples": 66, "distance": 1680, "finished": false}, {"score": 3290, "apples": 91, "distance": 2380, "finished": false}, {"score": 2870, "apples": 80, "distance": 2070, "finished": false}]
		state = "final"
		ui.sync()
	set_physics_process(false)

func capture_frame() -> void:
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("res://qa/captures/runner")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join(capture + ".png")
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE: ", path)
	get_tree().quit()


