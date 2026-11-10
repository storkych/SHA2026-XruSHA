extends RefCounted
## Measured glyph bounds; original generated atlas is preserved unchanged.
const IMAGE = preload("res://assets/runner/v7/result-type.png")
const DIGITS := [Rect2(29,441,259,308), Rect2(344,443,198,305), Rect2(600,441,237,306), Rect2(873,441,240,308), Rect2(1153,440,266,309), Rect2(30,767,243,313), Rect2(313,767,254,315), Rect2(603,767,235,313), Rect2(866,767,262,315), Rect2(1163,764,254,317)]
const TITLE := Rect2(78,8,1289,219)
const ATTEMPT := Rect2(287,256,877,161)

static func heading(c: CanvasItem, center: Vector2, final: bool, height := 64.0) -> void:
	var region: Rect2 = TITLE if final else ATTEMPT
	var size := Vector2(region.size.x / region.size.y * height, height)
	c.draw_texture_rect_region(IMAGE, Rect2(center - size * 0.5, size), region)

static func number(c: CanvasItem, center: Vector2, value: int, height := 166.0) -> void:
	var string_value := str(maxi(0, value))
	var width := 0.0
	for ch in string_value:
		var rect: Rect2 = DIGITS[int(ch)]
		width += rect.size.x / rect.size.y * height
	width += (string_value.length() - 1) * 6
	var x := center.x - width * 0.5
	for ch in string_value:
		var rect: Rect2 = DIGITS[int(ch)]
		var w := rect.size.x / rect.size.y * height
		c.draw_texture_rect_region(IMAGE, Rect2(x, center.y - height * 0.5, w, height), rect)
		x += w + 6
