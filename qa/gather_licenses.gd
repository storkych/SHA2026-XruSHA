extends SceneTree
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://licenses")
	var engine_license := FileAccess.open("res://licenses/Godot.txt", FileAccess.WRITE)
	engine_license.store_string(Engine.get_license_text())
	engine_license.close()
	var notices := FileAccess.open("res://licenses/ThirdParty.txt", FileAccess.WRITE)
	notices.store_line("Third-party components included in the Godot engine used for this build.\n")
	for component in Engine.get_copyright_info():
		notices.store_line(str(component))
	var license_texts := Engine.get_license_info()
	for name in license_texts:
		notices.store_line("\n--- %s ---\n%s" % [name, license_texts[name]])
	notices.close()
	print("Saved notices from actual engine binary")
	quit()
