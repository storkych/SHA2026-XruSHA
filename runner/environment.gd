extends Node2D
## Painted strips are deformed along the real 120px collision samples.
## No vector replacement for wood, moss, stone, rails or roots.
const TERRAIN = preload("res://assets/runner/v5/terrain-strip.png")
const BRIDGE = preload("res://assets/runner/v5/bridge-strip.png")
const NIGHT = preload("res://assets/runner/v6/night-terrain.png")
const Biomes = preload("res://runner/biomes.gd")
const Caps = preload("res://runner/terrain_caps.gd")
const RAIL_ROW := 374.0
const REPEAT_WIDTH := 1260.0
const PIXEL_SCALE := REPEAT_WIDTH / 2172.0
var course: RefCounted
var camera := 0.0
var clock := 0.0
var rider := Vector2.ZERO
var paint: ShaderMaterial
var caps: Node2D

func _ready() -> void:
	z_index = -1
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform sampler2D night_texture : source_color, filter_linear_mipmap;
uniform float night_mix = 0.0;
uniform vec4 ground_tint : source_color = vec4(1.0);
varying vec4 paint_color;
void vertex() { paint_color = COLOR; }
void fragment() {
    float phase = mod(UV.x, 0.90);
    vec4 base = texture(TEXTURE, vec2(phase, UV.y));
    if (phase < 0.10) {
        base = mix(texture(TEXTURE, vec2(phase + 0.90, UV.y)), base, smoothstep(0.0, 0.10, phase));
    }
    vec2 night_uv = vec2(phase, UV.y - 3.0 / 724.0);
    vec4 moon = texture(night_texture, night_uv);
    if (phase < 0.10) {
        moon = mix(texture(night_texture, night_uv + vec2(0.90, 0.0)), moon, smoothstep(0.0, 0.10, phase));
    }
    base = mix(base, moon, night_mix * step(0.5, paint_color.r));
    COLOR = base * vec4(ground_tint.rgb, paint_color.a);
}"""
	paint = ShaderMaterial.new()
	paint.shader = shader
	paint.set_shader_parameter("night_texture", NIGHT)
	material = paint
	caps = Caps.new()
	add_child(caps)

func present(level: RefCounted, x: float, time: float, player: Vector2) -> void:
	course = level
	camera = x
	clock = time
	rider = player
	caps.present(level, x, time, player.x)
	paint.set_shader_parameter("night_mix", Biomes.night(player.x))
	paint.set_shader_parameter("ground_tint", Biomes.ground_tint(player.x))
	queue_redraw()

func _draw() -> void:
	if course:
		draw_tracks(self, course, camera, get_viewport_rect().size.x, clock, rider)

static func draw_tracks(c: CanvasItem, level: RefCounted, camera: float, width: float, clock: float, player: Vector2) -> void:
	for track in level.platforms:
		if track.get("fade", 1.0) <= 0:
			continue
		if track.a > camera + width + 160:
			break
		if track.b < camera - 160 or (track.g == -1 and track.zone not in [3, 4, 7, 11]):
			continue
		draw_piece(c, track, clock, player)

static func draw_piece(c: CanvasItem, track: Dictionary, clock: float, player: Vector2) -> void:
	# Red encodes material type for the shared day/night blending shader.
	var tint := PackedColorArray([Color(0 if track.bridge else 1, 1, 1, float(track.get("fade", 1.0)))])
	var texture: Texture2D = BRIDGE if track.bridge else TERRAIN
	var contact_row := 386.0 if track.bridge else RAIL_ROW
	var g: int = track.g
	var a: float = track.a
	var b: float = track.b
	# Rail is fixed to collision; only the lower suspended detail ripples under load.
	var top_a := Vector2(a, track.y1 - g * contact_row * PIXEL_SCALE)
	var top_b := Vector2(b, track.y2 - g * contact_row * PIXEL_SCALE)
	var low_a := Vector2(a, track.y1 + g * (724 - contact_row) * PIXEL_SCALE)
	var low_b := Vector2(b, track.y2 + g * (724 - contact_row) * PIXEL_SCALE)
	var contact_a := Vector2(a, track.y1)
	var contact_b := Vector2(b, track.y2)
	if track.bridge:
		low_a.y += g * sin(clock * 4 + a * 0.015) * 2.5
		low_b.y += g * sin(clock * 4 + b * 0.015) * 2.5
		low_a.y += g * exp(-pow((a - player.x) / 110.0, 2)) * sin(clock * 16) * 6
		low_b.y += g * exp(-pow((b - player.x) / 110.0, 2)) * sin(clock * 16) * 6
	if track.get("collapse", 0.0) > 0 and not track.get("disabled", false):
		var tremble: float = sin(clock * 51) * track.collapse * 2
		low_a.x += tremble
		low_b.x += tremble
	var u1 := a / REPEAT_WIDTH
	var u2 := b / REPEAT_WIDTH
	var rail_v := contact_row / 724.0
	# Two bands pin the exact rail row while allowing flexible roots/ropes below it.
	c.draw_polygon(PackedVector2Array([top_a, top_b, contact_b, contact_a]), tint, PackedVector2Array([Vector2(u1, 0), Vector2(u2, 0), Vector2(u2, rail_v), Vector2(u1, rail_v)]), texture)
	var start: float = track.get("start", a)
	var end: float = track.get("end", b)
	var amount := minf(10 if track.bridge else 58, (end - start) * 0.24)
	# Continuous taper across segment boundaries, including very short final pieces.
	var left_cap := 1.0 if track.get("cap_start", false) else 0.0
	var right_cap := 1.0 if track.get("cap_end", false) else 0.0
	var shift_a := amount * (left_cap * exp(-(a - start) / 90) - right_cap * exp(-(end - a) / 90))
	var shift_b := amount * (left_cap * exp(-(b - start) / 90) - right_cap * exp(-(end - b) / 90))
	low_a.x += shift_a
	low_b.x += shift_b
	var side_a := Vector2(a + shift_a * 0.18, track.y1 + g * 48)
	var side_b := Vector2(b + shift_b * 0.18, track.y2 + g * 48)
	var shape := PackedVector2Array([contact_a, contact_b, side_b, low_b, low_a, side_a])
	var uv := PackedVector2Array([Vector2(u1, rail_v), Vector2(u2, rail_v), Vector2(side_b.x / REPEAT_WIDTH, rail_v + 48 / PIXEL_SCALE / 724.0), Vector2(low_b.x / REPEAT_WIDTH, 1), Vector2(low_a.x / REPEAT_WIDTH, 1), Vector2(side_a.x / REPEAT_WIDTH, rail_v + 48 / PIXEL_SCALE / 724.0)])
	c.draw_polygon(shape, tint, uv, texture)
