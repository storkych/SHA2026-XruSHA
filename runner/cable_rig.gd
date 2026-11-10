extends Node2D
const IMAGE = preload("res://assets/runner/v4/zipline-props.png")
var game: Node2D

func _ready() -> void:
	z_index = 4
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _draw() -> void:
	if not game or game.zipline < 0 or game.state not in ["playing", "paused"]:
		return
	var trolley := Vector2(game.player.x, game.cable_y(game.zipline, game.player.x))
	var grips: PackedVector2Array = game.zip_grips()
	var center := (grips[0] + grips[1]) * 0.5
	var hook := trolley + Vector2(0, 37)
	# Visible fork and short crossbar finish exactly at the two animated hooves.
	draw_polyline(PackedVector2Array([hook, center + Vector2(0, -9), grips[0], grips[1]]), Color("47382e"), 9, true)
	draw_polyline(PackedVector2Array([hook, center + Vector2(0, -9), grips[0], grips[1]]), Color("d6aa64"), 5, true)
	draw_texture_rect_region(IMAGE, Rect2(trolley + Vector2(-42, -29), Vector2(84, 75)), Rect2(1060, 240, 560, 500))
	for dx in [-18, 18]:
		var axle := trolley + Vector2(dx, -9)
		for j in range(3):
			var axis := Vector2.from_angle(game.wheel * 3 + j * TAU / 3) * 8
			draw_line(axle, axle + axis, Color("ffda80"), 1.5, true)
	var phase: float = fposmod(game.time * 8, 1)
	draw_line(trolley + Vector2(-38 - phase * 30, -4 - phase * 10), trolley + Vector2(-44 - phase * 30, -4 - phase * 10), Color(1, 0.86, 0.42, 1 - phase), 2, true)
