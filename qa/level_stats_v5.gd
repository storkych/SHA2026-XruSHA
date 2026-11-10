extends SceneTree
const Level = preload("res://runner/level.gd")
func _initialize() -> void:
	var level := Level.new()
	var counts: Dictionary = {}
	for enemy in level.enemies:
		counts[enemy.kind] = int(counts.get(enemy.kind, 0)) + 1
	var stats := {"gaps": level.gaps.size(), "bonus_routes": level.platforms.filter(func(p): return p.extra).size(), "springs": level.springs.size(), "apples": level.apples.size(), "enemies": counts, "gates": level.gates.size(), "cables": level.cables.size()}
	FileAccess.open("res://qa/v5-level-stats.json", FileAccess.WRITE).store_string(JSON.stringify(stats, "  "))
	print(JSON.stringify(stats))
	quit()
