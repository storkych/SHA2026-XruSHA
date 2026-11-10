extends RefCounted
## Original painted sprite atlases. Regions/pivots are measured, never hand-cropped.
const META = preload("res://assets/runner/v2/atlas_data.gd").DATA
const HERO = preload("res://assets/runner/v2/hero-atlas.png")
const ENEMIES = preload("res://assets/runner/v2/enemies-atlas.png")
const PROPS = preload("res://assets/runner/v2/props-atlas.png")

static func draw(c: CanvasItem, kind: String, frame: int, pos: Vector2, multiplier := 1.0, gravity := 1, color := Color.WHITE) -> void:
	var meta: Dictionary = META[kind][frame]
	var r: Array = meta.region
	var b: Array = meta.bounds
	var pivot: Array = meta.pivot
	var scale: float = meta.scale * multiplier
	if kind == "enemies":
		scale = META.enemies[0 if frame < 4 else 4].scale * multiplier
	var texture: Texture2D = HERO if kind == "hero" else (ENEMIES if kind == "enemies" else PROPS)
	var padding := 3.0
	var source := Rect2(r[0] + b[0] - padding, r[1] + b[1] - padding, b[2] - b[0] + padding * 2, b[3] - b[1] + padding * 2)
	# Godot flips a negative-height destination in-place, it does not move its origin.
	# Anchor the visible bottom edge explicitly when mirroring onto the ceiling.
	var top: float = b[1] - pivot[1] - padding if gravity == 1 else pivot[1] - b[3] - padding
	var destination := Rect2(pos + Vector2((b[0] - pivot[0] - padding) * scale, top * scale), Vector2(source.size.x * scale, source.size.y * scale * gravity))
	c.draw_texture_rect_region(texture, destination, source, color)

static func prop(c: CanvasItem, index: int, pos: Vector2, width: float, gravity := 1, color := Color.WHITE) -> void:
	# All props are normalized to 62px by atlas measurement.
	draw(c, "props", index, pos, width / 62.0, gravity, color)

static func stone(c: CanvasItem, index: int, rectangle: Rect2, color := Color.WHITE) -> void:
	var meta: Dictionary = META.props[index]
	var r: Array = meta.region
	var b: Array = meta.bounds
	c.draw_texture_rect_region(PROPS, rectangle, Rect2(r[0] + b[0], r[1] + b[1], b[2] - b[0], b[3] - b[1]), color)
