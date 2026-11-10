extends SceneTree
const Game = preload("res://runner/game.gd")
const Level = preload("res://runner/level.gd")
const Biomes = preload("res://runner/biomes.gd")
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func expect(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		push_error(reason)
func run() -> void:
	var level := Level.new()
	var signature := level.layout_signature()
	expect(level.bonus.size() == 10 and level.wind_boosts.size() == 3, "New authored content count")
	for wind in level.wind_boosts:
		expect(not level.is_gap(wind.x, wind.g), "Wind stand must be rooted on solid terrain")
	for i in range(40):
		level.advance(i * 0.15, 0.15)
		for ledge in level.bonus:
			if ledge.mode == "moving":
				expect(absf(ledge.y1 - ledge.home1) <= 24.001, "Moving island stays in authored corridor")
		for apple in level.apples:
			if apple.has("ledge"):
				var ledge: Dictionary = level.bonus[apple.ledge]
				expect(absf(apple.p.y - apple.base_y - ledge.y1 + ledge.home1) < 0.01, "Fruit follows its platform")
	var broken: Dictionary = level.bonus[1]
	level.touch_platform(broken.a + 20, broken.y1 - 6, 1)
	level.advance(6.2, 0.50)
	expect(not broken.disabled and broken.collapse > 0.49, "Crumble first gives visible warning")
	level.advance(6.6, 0.34)
	expect(broken.disabled and broken.just_broke, "Crumble collision switches off only after warning")
	level.wind_boosts[0].used = true
	level.reset()
	expect(level.layout_signature() == signature and not level.wind_boosts[0].used and not broken.disabled, "Next attempt restores moving paths and all one-shot objects")
	for i in range(1, 12):
		var x := i * 4800.0
		var a := Biomes.accent(x - 0.01)
		var b := Biomes.accent(x + 0.01)
		expect(Vector3(a.r, a.g, a.b).distance_to(Vector3(b.r, b.g, b.b)) < 0.001, "Biome transition continuous")
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.start_session()
	game.state = "playing"
	var moving: Dictionary = game.level.bonus[0]
	game.player = Vector2(moving.a + 140, game.track_height(moving, moving.a + 140) - 6)
	game.grounded = true
	for i in range(12):
		game._physics_process(1.0 / 120)
	expect(game.grounded and absf(game.player.y + 6 - game.track_height(moving, game.player.x)) < 1, "Rider remains attached to moving island")
	game.state = "paused"
	var frozen: float = moving.y1
	game._physics_process(0.5)
	expect(moving.y1 == frozen, "Pause freezes platform movement")
	game.start_session()
	game.state = "playing"
	var wind: Dictionary = game.level.wind_boosts[0]
	game.player = Vector2(wind.x - 4, game.level.surface(wind.x - 4, 1) - 6)
	for i in range(3):
		game._physics_process(1.0 / 120)
	expect(wind.used and game.boost_time > 0, "Wind field applies a bounded timed boost")
	game.juice.effects.clear()
	for i in range(100):
		game.juice.emit(1, Vector2.ZERO)
	expect(game.juice.effects.size() <= 36, "Effect allocation is bounded")
	game.juice.advance(1.0)
	expect(game.juice.effects.is_empty(), "Effect lifetime expires")
	print("WORLDS V6 ", "PASS" if failures == 0 else "FAIL", ": moving rider/fruit, crumble warning and collision, restart, pause, biome continuity, timed wind, bounded FX")
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
