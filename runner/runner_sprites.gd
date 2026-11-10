extends RefCounted
const HERO = preload("res://assets/runner/v5/hero-atlas.png")
const HORSES = preload("res://assets/runner/v5/horses-atlas.png")
const DATA = preload("res://assets/runner/v5/atlas_data.gd").DATA

static func hero(c: CanvasItem, frame: int, pos: Vector2, mirror := false, scale := Vector2.ONE, color := Color.WHITE) -> void:
	var cell: Dictionary = DATA.hero[frame]
	var r: Array = cell.region
	var bounds: Array = cell.bounds
	var pivot: Array = cell.pivot
	var k: float = DATA.hero_scale
	var source := Rect2(r[0] + bounds[0] - 2, r[1] + bounds[1] - 2, bounds[2] - bounds[0] + 4, bounds[3] - bounds[1] + 4)
	var left: float = pivot[0] - bounds[2] - 2 if mirror else bounds[0] - pivot[0] - 2
	var size := Vector2(source.size.x * k * scale.x, source.size.y * k * scale.y)
	var destination := Rect2(pos + Vector2(left * k * scale.x, (bounds[1] - pivot[1] - 2) * k * scale.y), size)
	if mirror:
		destination.size.x = -destination.size.x
	c.draw_texture_rect_region(HERO, destination, source, color)

static func horse(c: CanvasItem, frame: int, pos: Vector2, gravity := 1, color := Color.WHITE) -> void:
	var cell: Dictionary = DATA.horse[frame]
	var r: Array = cell.region
	var b: Array = cell.bounds
	var k: float = DATA.horse_scale
	var source := Rect2(r[0] + b[0] - 2, r[1] + b[1] - 2, b[2] - b[0] + 4, b[3] - b[1] + 4)
	var top: float = b[1] - cell.pivot[1] - 2 if gravity == 1 else -2.0
	c.draw_texture_rect_region(HORSES, Rect2(pos + Vector2((b[0] - cell.pivot[0] - 2) * k, top * k), Vector2(source.size.x * k, source.size.y * k * gravity)), source, color)
