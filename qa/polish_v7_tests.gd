extends SceneTree
const Game = preload("res://runner/game.gd")
const Backdrop = preload("res://runner/backdrop.gd")
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func expect(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		push_error(reason)
func pad_event(button: int, pressed := true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = 7
	event.button_index = button
	event.pressed = pressed
	return event
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.start_session()
	game.state = "playing"
	var enter := InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	game._unhandled_input(enter)
	game._physics_process(1.0 / 120)
	expect(game.attack_serial == 1 and game.state == "playing", "Enter strikes during play without restarting the attempt")
	game.attack_cooldown = 0
	game._input(pad_event(JOY_BUTTON_X))
	game._unhandled_input(pad_event(JOY_BUTTON_X))
	game._physics_process(1.0 / 120)
	expect(game.attack_serial == 2 and game.active_pad == 7, "X strikes on a nonzero controller device")
	game._input(pad_event(JOY_BUTTON_A))
	game._unhandled_input(pad_event(JOY_BUTTON_A))
	game._physics_process(1.0 / 120)
	expect(not game.grounded and game.vy < 0, "Controller A launches a jump")
	game._input(pad_event(JOY_BUTTON_A, false))
	expect(not game.pad_jump_down.get(7, true), "Controller release clears held state")
	game.attack_cooldown = 0
	var trigger := InputEventJoypadMotion.new()
	trigger.device = 7
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 0.8
	game._unhandled_input(trigger)
	game._physics_process(1.0 / 120)
	var serial: int = game.attack_serial
	game._unhandled_input(trigger)
	expect(game.attack_buffer == 0 and serial == 3, "Right trigger is edge-triggered, not repeated every axis event")
	game._unhandled_input(pad_event(JOY_BUTTON_START))
	expect(game.state == "paused" and game.ui.resume_button.has_focus(), "Controller Start pauses and focuses the primary action")
	game._unhandled_input(pad_event(JOY_BUTTON_START))
	expect(game.state == "playing", "Controller Start resumes")
	game.state = "final"
	game.results = [{"score": 1820}, {"score": 2350}, {"score": 2110}]
	game.ui.sync()
	expect(game.ui.next_button.has_focus() and game.ui.next_button.focus_neighbor_bottom != NodePath(), "Results have a focused action and explicit controller navigation")
	game.ui.next_button.pressed.emit()
	expect(game.state == "countdown" and game.attempt == 1, "Controller-accessible new-player action restarts the session")
	game.state = "playing"
	game.pause_game()
	root.push_input(pad_event(JOY_BUTTON_DPAD_DOWN))
	root.push_input(pad_event(JOY_BUTTON_DPAD_DOWN, false))
	expect(game.ui.reset_button.has_focus(), "Actual viewport D-pad event navigates to the next pause action")
	root.push_input(pad_event(JOY_BUTTON_A))
	root.push_input(pad_event(JOY_BUTTON_A, false))
	await process_frame
	expect(game.state == "countdown", "Actual viewport A press/release activates the focused restart button")
	for section in range(1, 12):
		var x := section * 4800.0
		expect(absf(Backdrop.panorama_position(x - 0.01) - Backdrop.panorama_position(x + 0.01)) < 0.0001, "Panorama is continuous at every section boundary")
	var last := Backdrop.panorama_position(0)
	for x in range(1, 57600, 13):
		var sample := Backdrop.panorama_position(x)
		expect(sample >= 0 and sample <= 0.50 and absf(sample - last) < 0.006, "Pan remains bounded and continuous throughout the course")
		expect(sample >= last, "Background never scrolls backwards when passing a biome boundary")
		last = sample
	var reactive: Node2D = game.reactive
	var count: int = reactive.plants.size()
	var plant: Dictionary = reactive.plants[0]
	reactive.react(plant.p, 100, 1, plant.g)
	expect(absf(plant.v) > 0 and not reactive.flecks.is_empty(), "Scenery springs and sheds petals on impact")
	reactive.advance(0.1, plant.p, 410, false, plant.g)
	expect(absf(plant.bend) > 0, "Impact evolves through damped spring motion")
	reactive.reset(game.level)
	expect(reactive.plants.size() == count and reactive.flecks.is_empty() and reactive.plants[0].bend == 0, "Attempt resets decorative reactions to identical positions")
	print("POLISH V7 ", "PASS" if failures == 0 else "FAIL", ": Enter strike, device-7 pad jump/strike/trigger/pause, UI navigation, continuous panorama, reactive scenery reset")
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
