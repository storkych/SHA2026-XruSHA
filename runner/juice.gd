extends Node2D
const Art = preload("res://runner/scene_sprites.gd")
var effects: Array = []

func _ready() -> void:
	z_index = 3
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func emit(kind: int, pos: Vector2, width := 150.0, g := 1, life := 0.28) -> void:
	effects.append({"kind": kind, "p": pos, "width": width, "g": g, "life": life, "max": life})
	if effects.size() > 36:
		effects.pop_front()

func advance(dt: float) -> void:
	for effect in effects:
		effect.life -= dt
	effects = effects.filter(func(e): return e.life > 0)
	queue_redraw()

func _draw() -> void:
	for e in effects:
		var t: float = 1 - e.life / e.max
		var alpha := (1 - smoothstep(0.25, 1.0, t)) * smoothstep(0, 0.08, t)
		var grow := 0.7 + sin(minf(1, t * 2) * PI * 0.5) * 0.35
		var ratio := 0.5 if e.kind in [2, 3] else 0.9
		var p: Vector2 = e.p
		if e.kind == 2:
			p.y -= e.g * t * 20
		elif e.kind == 3:
			p.x -= t * 35
		var size := Vector2(e.width, e.width * ratio) * grow
		if e.kind == 0:
			# Authored C-shaped brush opens forward, matching the fist hitbox.
			size.x *= -1
			size.y *= e.g
		Art.effect(self, e.kind, p, size, Color(1, 1, 1, alpha))
