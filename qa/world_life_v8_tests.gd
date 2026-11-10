extends SceneTree
const Game = preload("res://runner/game.gd")
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func expect(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		push_error(reason)
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.start_session()
	game.state = "playing"
	game.invulnerable = 1.7
	game.hurt_flash = 0.22
	game.finish_attempt("hearts")
	for screen in ["result", "final"]:
		game.state = screen
		game.ui.sync()
		for i in range(250):
			game._physics_process(1.0 / 30)
			game._process(1.0 / 30)
			expect(game.hero.frame == 8 and game.hero.modulate == Color.WHITE, "Result hero stays open-eyed, opaque and untinted even after damage")
	game.start_session()
	game.state = "playing"
	var world: Node2D = game.world_life
	var signature := hash(world.objects.map(func(o): return [o.kind, o.p, o.g, o.phase]))
	var counts := {}
	for obj in world.objects:
		counts[obj.kind] = counts.get(obj.kind, 0) + 1
		if obj.kind not in ["chime", "fireflies"]:
			expect(not game.level.is_gap(obj.p.x, obj.g), "Ground encounters stand on real terrain")
	expect(counts.size() == 8, "All eight encounter families are present")
	var pod: Dictionary = world.objects.filter(func(o): return o.kind == "pod")[0]
	var bird: Dictionary = world.objects.filter(func(o): return o.kind == "bird")[0]
	var snail: Dictionary = world.objects.filter(func(o): return o.kind == "snail")[0]
	world.advance(0.1, bird.p - Vector2(100, 6), true, bird.g)
	expect(bird.age >= 0, "Bird flock takes off when the runner approaches")
	world.advance(0.1, snail.p, true, snail.g)
	expect(snail.pulse > 0.3, "Snail withdraws on approach")
	var before: int = game.apple_count
	world.activate(pod)
	expect(not pod.opened and game.apple_count == before, "Running near a cocoon does not harvest it")
	world.strike(pod.p - Vector2(250, pod.g * 6), pod.g, 1)
	expect(not pod.opened, "Cocoon respects the reach of a punch")
	world.strike(pod.p + Vector2(60, -pod.g * 6), pod.g, 2)
	expect(not pod.opened, "A cocoon behind the player is not hit")
	world.strike(pod.p - Vector2(80, pod.g * 6), pod.g, 3)
	expect(pod.opened and game.apple_count == before + 3 and world.fruits.size() == 3, "Forward punch opens a pod and grants exactly three apples with visual fruit")
	world.strike(pod.p - Vector2(80, pod.g * 6), pod.g, 3)
	world.advance(2, game.player, false, game.gravity)
	world.strike(pod.p - Vector2(80, pod.g * 6), pod.g, 4)
	expect(game.apple_count == before + 3, "An open pod cannot be farmed repeatedly")
	game._physics_process(1.0 / 120)
	expect(game.score == game.distance + 10 * game.apple_count, "Harvest preserves the distance-plus-apples score rule")
	game.state = "paused"
	var frozen: float = world.clock
	game._physics_process(0.5)
	expect(world.clock == frozen, "Pause freezes wildlife and scenery events")
	game.start_session()
	expect(hash(world.objects.map(func(o): return [o.kind, o.p, o.g, o.phase])) == signature, "Every attempt has identical encounter positions")
	expect(world.motes.is_empty() and world.fruits.is_empty() and world.objects.all(func(o): return not o.opened and o.age < 0 and o.pulse == 0), "New attempt resets every event and harvest")
	for obj in world.objects:
		world.activate(obj, true)
	expect(world.motes.size() <= 150, "Scenery particles have a fixed allocation limit")
	world.advance(4, Vector2.ZERO, false, 1)
	expect(world.motes.is_empty() and world.fruits.is_empty(), "Scenery particles and fruit animations expire")
	print("WORLD LIFE V8 ", "PASS" if failures == 0 else "FAIL", ": no result blinking/flashing, eight families ", counts, ", bird/snail proximity, punch reach, one-shot +3 apples, score, pause, deterministic reset, bounded particles")
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
