extends Node2D
## One continuous painted panorama: moving through it never dissolves separate pictures.
const Biomes = preload("res://runner/biomes.gd")
const PANORAMA = preload("res://assets/runner/v7/world-panorama.png")
var sprite: Sprite2D
var paint: ShaderMaterial
var scroll := 0.0
var clock := 0.0
var world_x := 0.0

func _ready() -> void:
	z_index = -20
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform float pan = 0.0;
uniform float view_width = 0.50;
uniform float clock = 0.0;
void fragment() {
    float x = clamp(UV.x * view_width + pan, 0.0, 1.0);
    float y = clamp(UV.y * 0.844 + 0.078 + sin(clock * 0.24 + UV.x * 5.0) * 0.0012, 0.0, 1.0);
    vec3 color = texture(TEXTURE, vec2(x, y)).rgb;
    color = mix(color, vec3(0.24, 0.38, 0.43), 0.10 * smoothstep(0.2, 0.8, UV.y));
    float warm = smoothstep(0.15, 0.45, color.r - color.b);
    color *= 1.0 + warm * sin(clock * 1.7 + UV.y * 9.0) * 0.018;
    COLOR = vec4(color * 0.98, 1.0);
}"""
	paint = ShaderMaterial.new()
	paint.shader = shader
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.material = paint
	sprite.texture = PANORAMA
	add_child(sprite)

static func biome_color(x: float) -> Color:
	return Biomes.accent(x)

static func outdoor_amount(x: float) -> float:
	return 1.0 - Biomes.night(x)

func present(camera_x: float, player_x: float, t: float, _speed: float) -> void:
	world_x = player_x
	clock = t
	sprite.scale = get_viewport_rect().size / PANORAMA.get_size()
	paint.set_shader_parameter("view_width", 0.50)
	paint.set_shader_parameter("pan", panorama_position(player_x))
	paint.set_shader_parameter("clock", t)

static func panorama_position(x: float) -> float:
	# A physical far-distance layer, always moving in the same direction.
	# No per-zone camera pan, texture replacement, crossfade, or parallax reversal.
	return clampf(x / 57600.0 * 0.50, 0, 0.50)
