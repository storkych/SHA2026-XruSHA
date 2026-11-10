extends SceneTree
const Game = preload("res://runner/game.gd")
const Level = preload("res://runner/level.gd")
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func expect(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func fresh(game: Node2D) -> void:
	game.level = Level.new()
	game.start_session()
	game.state = "playing"
	game.hold_override_enabled = true
	game.jump_held_override = true
func foe(game: Node2D, kind: String, x: float, g := 1) -> Dictionary:
	var enemy := {"p": Vector2(x, game.level.surface(x, g)), "g": g, "kind": kind, "dead": false, "squash": 0.0, "phase": 0.0, "drop": 0.0, "triggered": false, "hp": 2 if kind == "beetle" else 1}
	game.level.enemies = [enemy]
	return enemy
func ticks(game: Node2D, count: int) -> void:
	for i in range(count):
		game._physics_process(1.0 / 120)
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	fresh(game)
	var horse := foe(game, "horse", game.player.x + 110)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	game._unhandled_input(event)
	ticks(game, 12)
	expect(horse.dead and game.defeated == 1 and game.health == 3, "Mouse strike must defeat horse with recoil and no contact damage")
	expect(game.attack_serial == 1 and game.score == game.distance + game.apple_count * 10, "Strike counts once and preserves score rules")
	fresh(game)
	var armor := foe(game, "beetle", game.player.x + 110)
	game.queue_attack()
	ticks(game, 12)
	expect(armor.hp == 1 and not armor.dead, "Armor takes one hit per swing, never one hit each active frame")
	ticks(game, 34)
	game.queue_attack()
	ticks(game, 12)
	expect(armor.dead, "Second separate strike breaks armor after knockback")
	fresh(game)
	var behind := foe(game, "horse", game.player.x - 90)
	game.queue_attack()
	ticks(game, 12)
	expect(not behind.dead, "Punch only hits forward")
	fresh(game)
	var airborne := foe(game, "horse", game.player.x + 110)
	game.player.y -= 45
	game.grounded = false
	game.vy = 20
	game.jump_age = 0.3
	game.queue_attack()
	ticks(game, 12)
	expect(airborne.dead, "Punch works in the air")
	for g in [1, -1]:
		fresh(game)
		var pony := foe(game, "horse", 500, g)
		game.gravity = g
		game.player = Vector2(500, pony.p.y - g * 74 + g)
		game.vy = g * 400
		game.grounded = false
		game.update_enemies(1.0 / 120, Vector2(500, pony.p.y - g * 74 - g * 6))
		expect(pony.dead and game.vy * g < -750 and game.health == 3, "Horse stomp follows gravity, g=%s" % g)
	fresh(game)
	var charger := foe(game, "charger", game.player.x + 550)
	game.update_enemies(0.20, game.player)
	expect(not charger.get("charged", false) and charger.windup > 0 and charger.get("move", 0) == 0, "Horse must telegraph before charging")
	game.update_enemies(0.30, game.player)
	expect(charger.charged and charger.move < 0, "Charge starts after visible 480ms windup")
	fresh(game)
	game.level.enemies.clear()
	game.run_time = 50000
	game.speed = Game.MAX_RUN_SPEED
	ticks(game, 360)
	expect(game.speed <= Game.MAX_RUN_SPEED, "Running acceleration has hard upper cap even after hours")
	game.enter_menu()
	expect(game.ui.play_button.visible and not game.ui.next_button.visible and not game.ui.resume_button.visible, "Menu has one primary action")
	game.ui.play_button.pressed.emit()
	expect(game.state == "countdown" and not game.ui.play_button.visible, "Real play button starts a session")
	print("COMBAT V5 ", "PASS" if failures == 0 else "FAIL", ": mouse strike, single-hit window, armor follow-up, forward-only hitbox, air strike, normal/inverted pony stomp, charge telegraph, speed cap, UI flow")
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
