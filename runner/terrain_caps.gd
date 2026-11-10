extends Node2D
const IMAGE = preload("res://assets/runner/v7/terrain-caps.png")
const Biomes = preload("res://runner/biomes.gd")
var course: RefCounted
var camera := 0.0
var clock := 0.0
var paint: ShaderMaterial

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform float night_mix = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
varying float opacity;
void vertex() { opacity = COLOR.a; }
void fragment() {
    vec4 a = texture(TEXTURE, UV);
    vec4 b = texture(TEXTURE, UV + vec2(0.25, 0.0));
    vec4 color = mix(a, b, night_mix);
    color.a *= smoothstep(0.09, 0.24, fract(UV.x * 4.0));
    if (color.a < 0.045) discard;
    COLOR = color * tint * vec4(1.0, 1.0, 1.0, opacity);
}"""
	paint = ShaderMaterial.new()
	paint.shader = shader
	material = paint

func present(level: RefCounted, x: float, t: float, rider_x: float) -> void:
	course = level
	camera = x
	clock = t
	paint.set_shader_parameter("night_mix", Biomes.night(rider_x))
	paint.set_shader_parameter("tint", Biomes.ground_tint(rider_x))
	queue_redraw()

func _draw() -> void:
	if not course:
		return
	for track in course.platforms:
		if track.a > camera + 1900:
			break
		if track.b < camera - 300 or track.bridge or track.get("fade", 1.0) <= 0:
			continue
		if track.g == -1 and track.zone not in [3, 4, 7, 11]:
			continue
		if track.get("cap_start", false) and is_equal_approx(track.a, track.get("start", track.a)):
			edge(track, track.a, track.y1, true)
		if track.get("cap_end", false) and is_equal_approx(track.b, track.get("end", track.b)):
			edge(track, track.b, track.y2, false)

func edge(track: Dictionary, x: float, y: float, left: bool) -> void:
	var variant := 2 if int(x / 300) % 2 else 0
	var k := 0.48
	var source := Rect2(variant * 543, 0, 543, 724)
	# The painted moss lip meets the exact collision edge; roots extend into air.
	var pivot := Vector2(437, 247)
	var origin := Vector2(x - pivot.x * k, y - track.g * pivot.y * k)
	if track.g == -1:
		origin.y = y - (724 - pivot.y) * k
	if left:
		origin.x = x - (543 - pivot.x) * k
	draw_texture_rect_region(IMAGE, Rect2(origin, Vector2(-543 if left else 543, 724 * track.g) * k), source, Color(1, 1, 1, track.get("fade", 1.0)))
