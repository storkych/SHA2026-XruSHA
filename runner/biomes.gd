extends RefCounted
const ORDER := [0, 0, 0, 0, 1, 1, 1, 1, 3, 3, 3, 3]
const ACCENTS := [Color("ffd26f"), Color("86f6ea"), Color("ff98ba"), Color("ffac60")]
const LEAVES := [Color("e8a557"), Color("96e7fa"), Color("f7a1c6"), Color("ffcf76")]

static func at(x: float) -> int:
	return ORDER[clampi(floori(maxf(0, x) / 4800), 0, 11)]

static func previous(x: float) -> int:
	return ORDER[clampi(floori(maxf(0, x) / 4800) - 1, 0, 11)]

static func blend(x: float) -> float:
	return smoothstep(0, 1200, fposmod(maxf(0, x), 4800))

static func accent(x: float) -> Color:
	return ACCENTS[previous(x)].lerp(ACCENTS[at(x)], blend(x))

static func leaf(x: float) -> Color:
	return LEAVES[previous(x)].lerp(LEAVES[at(x)], blend(x))

static func night(x: float) -> float:
	var a := 1.0 if previous(x) in [1, 3] else 0.0
	var b := 1.0 if at(x) in [1, 3] else 0.0
	return lerpf(a, b, blend(x))

static func ground_tint(x: float) -> Color:
	var colors := [Color.WHITE, Color.WHITE, Color("ffe3df"), Color("ffceaa")]
	return colors[previous(x)].lerp(colors[at(x)], blend(x))
