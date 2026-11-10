extends SceneTree
const Game = preload("res://runner/game.gd")
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func expect(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func fresh(game: Node2D) -> void:
	game.start_session()
	game.state = "playing"
	game.hold_override_enabled = true
	game.jump_held_override = true
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	fresh(game)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	game._unhandled_input(event)
	game._physics_process(1.0 / 120)
	expect(game.vy < -700 and not game.grounded, "Jump must launch on first physics tick")
	fresh(game)
	game.grounded = false
	game.coyote = 0.075
	game.player.y -= 3
	game.queue_jump()
	game._physics_process(1.0 / 120)
	expect(game.vy < -700, "Late edge jump must use coyote grace")
	fresh(game)
	game.grounded = false
	game.player.y -= 1
	game.vy = 450
	game.queue_jump()
	game._physics_process(1.0 / 120)
	expect(game.vy < -700 and not game.grounded, "Buffered landing jump must launch on touchdown tick")
	for speed in [410.0, 660.0]:
		fresh(game)
		game.speed = speed
		var rock := {"p": Vector2(900, game.level.surface(900, 1)), "g": 1, "kind": "rock", "dead": false, "squash": 0.0, "phase": 0.0, "drop": 0.0, "triggered": false}
		game.level.enemies = [rock]
		game.player = Vector2(900 - maxf(820, speed * 1.65), rock.p.y - 6)
		for tick in range(84):
			var old: Vector2 = game.player
			game.player.x += speed / 120.0
			game.update_enemies(1.0 / 120, old)
		expect(rock.drop == 1 and rock.p.x - game.player.x > speed * 0.8, "Rock must settle at least 0.8 seconds ahead at speed %s" % speed)
		# A real held jump from the natural approach clears the settled rock.
		game.player = Vector2(900 - speed * 0.29, game.level.surface(900 - speed * 0.29, 1) - 6)
		game.queue_jump()
		for tick in range(100):
			var old: Vector2 = game.player
			game.player.x += speed / 120.0
			game.update_vertical(1.0 / 120, old)
			game.jump_age += 1.0 / 120
			game.update_enemies(1.0 / 120, old)
		expect(game.health == 3, "Settled rock must be jumpable at speed %s" % speed)
	fresh(game)
	game.zipline = 0
	game.player = Vector2(6200, game.cable_y(0, 6200) + 168)
	game.grounded = false
	var maximum := 0.0
	for tick in range(240):
		game._physics_process(1.0 / 120)
		maximum = maxf(maximum, game.speed)
	expect(maximum < 800, "Cable acceleration must remain bounded")
	print("FEEL ", "PASS" if failures == 0 else "FAIL", ": first-tick launch, 130ms edge grace, same-tick buffered touchdown, fair rocks at 410/660, bounded zip speed=", maximum)
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
