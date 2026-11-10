extends RefCounted
## Uses only the same queued jump/strike inputs as the player; no health or position cheats.
static func drive(game: Node2D) -> void:
	game.hold_override_enabled = true
	game.jump_held_override = true
	for enemy in game.level.enemies:
		if enemy.p.x > game.player.x + 1000:
			break
		if enemy.dead or enemy.g != game.gravity:
			continue
		var pos: Vector2 = game.enemy_position(enemy)
		var front: float = pos.x - game.player.x
		var head: float = 46 if enemy.kind in ["horse", "charger"] else 23
		var plane := absf(game.player.y + game.vy * 0.04 - game.gravity * 55 - (pos.y - enemy.g * head))
		if enemy.kind != "rock" and front > -8 and front < 145 and plane < 70 and game.attack_cooldown < 0.10:
			game.queue_attack()
		if enemy.kind == "rock" and game.grounded and front > 0 and front < game.speed * 0.30:
			game.queue_jump()
	if game.grounded:
		for ledge in game.level.bonus:
			if ledge.mode == "crumble" and ledge.collapse > 0.48 and not ledge.disabled and game.player.x >= ledge.a and game.player.x <= ledge.b:
				if absf(game.player.y + game.gravity * 6 - game.track_height(ledge, game.player.x)) < 20:
					game.queue_jump()
		for gap in game.level.gaps:
			if gap.g == game.gravity and gap.a > game.player.x and gap.a - game.player.x < game.speed * 0.19:
				if not is_nan(game.find_support(gap.a + 15, game.player.y, game.gravity)):
					continue
				game.queue_jump()
