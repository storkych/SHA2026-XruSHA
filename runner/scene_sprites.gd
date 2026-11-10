extends RefCounted
const PROPS = preload("res://assets/runner/v6/props-atlas.png")
const EFFECTS = preload("res://assets/runner/v6/effects-atlas.png")
const DATA = preload("res://assets/runner/v6/atlas_data.gd").DATA

static func prop(c: CanvasItem, index: int, foot: Vector2, width: float, color := Color.WHITE, g := 1) -> void:
	var r: Array = DATA.props[index]
	var h: float = width * r[3] / r[2]
	var y := foot.y - h if g == 1 else foot.y
	c.draw_texture_rect_region(PROPS, Rect2(foot.x - width * 0.5, y, width, h * g), Rect2(r[0], r[1], r[2], r[3]), color)

static func effect(c: CanvasItem, index: int, center: Vector2, size: Vector2, color := Color.WHITE) -> void:
	var r: Array = DATA.effects[index]
	c.draw_texture_rect_region(EFFECTS, Rect2(center - size.abs() * 0.5, size), Rect2(r[0], r[1], r[2], r[3]), color)
