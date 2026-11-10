extends RefCounted
## This course is authored once with explicit formulas; gameplay never randomizes it.
const METER := 12.0
const SECTION := 4800.0
const LENGTH := 57600.0
const NAMES := ["ПЕРВЫЕ ШАГИ", "ЧЕРЕЗ ПРОВАЛЫ", "СЛИЗНИ В ШАХТЕ", "ВВЕРХ НОГАМИ", "КРИСТАЛЬНЫЙ ЗАЛ", "СТАРЫЙ МОСТ", "ГОРЯЧИЙ УЧАСТОК", "ВВЕРХ И ВНИЗ", "ОСТОРОЖНО, ОБВАЛ", "ЯБЛОЧНЫЙ СОБЛАЗН", "ПОЛНЫЙ ВПЕРЁД", "ФИНИШНЫЙ ПЕРЕПОЛОХ"]
var platforms: Array = []
var apples: Array = []
var enemies: Array = []
var gates: Array = []
var warnings: Array = []
var gaps: Array = []
var springs: Array = []
var bonus: Array = []
var wind_boosts: Array = []
var cables: Array = [
	{"a": 6060.0, "b": 7520.0, "ya": 455.0, "yb": 510.0},
	{"a": 25250.0, "b": 26750.0, "ya": 460.0, "yb": 505.0},
	{"a": 29900.0, "b": 31500.0, "ya": 445.0, "yb": 500.0},
	{"a": 49200.0, "b": 50600.0, "ya": 450.0, "yb": 520.0}
]

func _init() -> void:
	gates = [{"x": 15000.0, "g": -1}, {"x": 24300.0, "g": 1}, {"x": 34200.0, "g": -1}, {"x": 36500.0, "g": 1}, {"x": 53400.0, "g": -1}, {"x": 55500.0, "g": 1}]
	for zone in range(12):
		var start := zone * SECTION
		# A guaranteed clear runway surrounds every gravity gate and section start.
		for slot in range(5):
			var x := start + 1350 + slot * 760
			# Rockfall is a timing encounter; leave a clear landing/re-jump apron.
			if zone == 8:
				continue
			if zone == 0 and slot < 1:
				continue
			if gate_near(x, 730):
				continue
			if cable_exit_near(x, 540):
				continue
			var width := 165.0 + (zone % 3) * 20.0 + (25.0 if zone >= 8 else 0.0)
			gaps.append({"a": x, "b": x + width, "g": gravity_at(x), "zone": zone})
		# Continuous rails with deterministic holes, at both gravity surfaces.
		for gravity in [1, -1]:
			var cursor: float = start
			for gap in gaps:
				if gap.zone != zone or gap.g != gravity:
					continue
				add_track(cursor, gap.a, gravity, zone)
				cursor = gap.b
			add_track(cursor, start + SECTION, gravity, zone)
		for slot in range(5):
			var x := start + 850 + slot * 800
			var under_cable := false
			for cable in cables:
				if x > cable.a - 100 and x < cable.b + 150:
					under_cable = true
			if under_cable:
				continue
			if gate_near(x, 750) or (zone == 0 and slot < 1):
				continue
			if cable_exit_near(x, 540):
				continue
			var gravity := gravity_at(x)
			var kind: String = ["slime", "horse", "beetle", "charger", "horse"][(zone + slot) % 5]
			if zone == 8 and slot % 2 == 0:
				kind = "rock"
			if zone == 0 and slot == 3:
				kind = "crate"
			var p := Vector2(x, surface(x, gravity))
			enemies.append({"p": p, "g": gravity, "kind": kind, "phase": float(zone * 4 + slot), "dead": false, "squash": 0.0, "triggered": false, "drop": 0.0, "move": 0.0, "windup": 0.0, "charged": false, "stun": 0.0, "hp": 2 if kind == "beetle" else 1, "flight": Vector2.ZERO, "flight_v": Vector2.ZERO})
			if kind == "rock":
				warnings.append({"x": x - 360, "g": gravity, "kind": "rock"})
		# Apples form an exact, repeated route, including visible jump arcs over gaps.
		for slot in range(15):
			var x := start + 500 + slot * 280
			if not gate_near(x, 500) and not is_gap(x, gravity_at(x)):
				var gravity := gravity_at(x)
				apples.append({"p": Vector2(x, surface(x, gravity) - gravity * 68), "taken": false, "phase": x * 0.002})
		for gap in gaps:
			if gap.zone != zone:
				continue
			for k in range(5):
				var t := k / 4.0
				var x: float = lerpf(gap.a - 90, gap.b + 80, t)
				var y: float = surface(x, gap.g) - gap.g * (65 + sin(PI * t) * 97)
				apples.append({"p": Vector2(x, y), "taken": false, "phase": x * 0.002})
		if zone in [2, 4, 5, 9, 10]:
			# Optional high routes bridge a low gap and reward a committed high jump.
			for k in range(2):
				var x := start + 1880 + k * 1520
				if gate_near(x, 850):
					continue
				var route_g := gravity_at(x)
				var y := surface(x, route_g) - route_g * 100
				var ledge := {"a": x, "b": x + 520, "y1": y, "y2": y - route_g * 12, "home1": y, "home2": y - route_g * 12, "g": route_g, "zone": zone, "bridge": k == 1, "extra": true, "start": x, "end": x + 520, "cap_start": true, "cap_end": true, "mode": "moving" if k == 0 else "crumble", "collapse": 0.0, "disabled": false, "fade": 1.0, "phase": float(bonus.size()) * 1.7}
				var ledge_id := bonus.size()
				platforms.append(ledge)
				bonus.append(ledge)
				for j in range(6):
					apples.append({"p": Vector2(x + 40 + j * 85, y - route_g * 60), "taken": false, "phase": float(j), "ledge": ledge_id, "base_y": y - route_g * 60})
		if zone in [1, 5, 9]:
			var x := start + 1200
			if not gate_near(x, 900) and not cable_exit_near(x, 800):
				springs.append({"x": x, "g": gravity_at(x), "pulse": 0.0})
	# An unobstructed finish apron extends past the course.
	for enemy in enemies:
		if enemy.kind != "rock":
			continue
		var rock_x: float = enemy.p.x
		apples = apples.filter(func(apple): return absf(apple.p.x - rock_x) > 200)
		for j in range(5):
			var t := j / 4.0
			var x := rock_x - 165 + t * 330
			apples.append({"p": Vector2(x, surface(x, 1) - 70 - sin(PI * t) * 85), "taken": false, "phase": float(j)})
	for cable_index in range(cables.size()):
		var cable: Dictionary = cables[cable_index]
		for j in range(14):
			var x: float = lerpf(cable.a + 100, cable.b - 100, j / 13.0)
			apples.append({"p": Vector2(x, cable_height(cable_index, x) + 100), "taken": false, "phase": float(j)})
	for x in [8970.0, 20200.0, 47380.0]:
		wind_boosts.append({"x": x, "g": gravity_at(x), "used": false})
	advance(0, 0)
	add_track(LENGTH, LENGTH + 1800, 1, 11)
	platforms.sort_custom(func(a, b): return a.a < b.a)
	apples.sort_custom(func(a, b): return a.p.x < b.p.x)
	enemies.sort_custom(func(a, b): return a.p.x < b.p.x)

func add_track(a: float, b: float, gravity: int, zone: int) -> void:
	if b - a < 1:
		return
	var x := a
	while x < b - 0.1:
		var end := minf(b, (floorf(x / 120.0) + 1) * 120)
		platforms.append({"a": x, "b": end, "y1": surface(x, gravity), "y2": surface(end, gravity), "g": gravity, "zone": zone, "bridge": zone == 5 or zone == 6, "extra": false, "start": a, "end": b, "cap_start": is_gap(a - 1, gravity), "cap_end": is_gap(b + 1, gravity)})
		x = end

func surface(x: float, gravity: int) -> float:
	# Broad rolling curves; visual terrain and collision share these 120px samples.
	var height := sin(x * 0.00122) * 65 + sin(x * 0.0031) * 14
	if floori(x / SECTION) in [5, 6]:
		height += sin(PI * fposmod(x, 1000.0) / 1000.0) * 17
	return (675.0 if gravity == 1 else 210.0) + height

func gravity_at(x: float) -> int:
	var result := 1
	for gate in gates:
		if gate.x > x:
			break
		result = gate.g
	return result

func gate_near(x: float, distance: float) -> bool:
	for gate in gates:
		if absf(x - gate.x) < distance:
			return true
	return false

func is_gap(x: float, gravity: int) -> bool:
	for gap in gaps:
		if gap.g == gravity and x > gap.a and x < gap.b:
			return true
	return false

func ground_at(x: float, gravity: int) -> float:
	return NAN if is_gap(x, gravity) else surface(x, gravity)

func reset() -> void:
	for ledge in bonus:
		ledge.just_broke = false
		ledge.collapse = 0.0
		ledge.disabled = false
		ledge.fade = 1.0
	for wind in wind_boosts:
		wind.used = false
	for spring in springs:
		spring.pulse = 0.0
	for apple in apples:
		apple.taken = false
	for enemy in enemies:
		enemy.dead = false
		enemy.squash = 0.0
		enemy.triggered = false
		enemy.drop = 0.0
		enemy.move = 0.0
		enemy.windup = 0.0
		enemy.charged = false
		enemy.stun = 0.0
		enemy.hp = 2 if enemy.kind == "beetle" else 1
		enemy.flight = Vector2.ZERO
		enemy.flight_v = Vector2.ZERO
		enemy.last_hit = -1
	advance(0, 0)

func advance(time: float, dt: float) -> void:
	for ledge in bonus:
		var was_disabled: bool = ledge.disabled
		ledge.just_broke = false
		var offset := 0.0
		if ledge.mode == "moving":
			offset = sin(time * 1.45 + ledge.phase) * 24
		elif ledge.collapse > 0:
			ledge.collapse += dt
			ledge.disabled = ledge.collapse >= 0.82
			offset = pow(maxf(0, ledge.collapse - 0.82), 2) * 850
			ledge.fade = 1 - smoothstep(0.82, 1.22, ledge.collapse)
		ledge.y1 = ledge.home1 + offset
		ledge.y2 = ledge.home2 + offset
		ledge.just_broke = not was_disabled and ledge.disabled
	for apple in apples:
		if apple.has("ledge"):
			var ledge: Dictionary = bonus[apple.ledge]
			apple.p.y = apple.base_y + ledge.y1 - ledge.home1
			if ledge.disabled:
				apple.taken = true

func touch_platform(x: float, foot_y: float, g: int) -> void:
	for ledge in bonus:
		if ledge.mode != "crumble" or ledge.disabled or ledge.g != g or x < ledge.a or x > ledge.b:
			continue
		var top := lerpf(ledge.y1, ledge.y2, (x - ledge.a) / (ledge.b - ledge.a))
		if absf(foot_y + g * 6 - top) < 12 and ledge.collapse == 0:
			ledge.collapse = 0.001

func layout_signature() -> int:
	return hash([platforms, apples.map(func(a): return a.p), enemies.map(func(e): return [e.p, e.g, e.kind]), gates, cables, springs.map(func(p): return [p.x, p.g]), wind_boosts.map(func(p): return [p.x, p.g])])

func cable_height(index: int, x: float) -> float:
	var cable: Dictionary = cables[index]
	var t := clampf((x - cable.a) / (cable.b - cable.a), 0, 1)
	return minf(lerpf(cable.ya, cable.yb, t) + sin(PI * t) * 72, surface(x, 1) - 205) + 10

func cable_exit_near(x: float, distance: float) -> bool:
	for cable in cables:
		if absf(x - cable.b) < distance:
			return true
	return false
