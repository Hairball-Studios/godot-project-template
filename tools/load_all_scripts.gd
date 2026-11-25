extends SceneTree
## Loads every GDScript under scripts/, tests/ and tools/, and says which the engine cannot parse.
## `mise run format` runs it headless after the formatter: the formatter can write a file the
## engine cannot parse, so the only proof a format left the tree loadable is to load it.
##
## Prints `UNLOADABLE <path>` for each and exits 1; the engine's own parse errors come before
## them. A script that names a class which cannot load is unloadable too, so read the first.

const FOLDERS: Array[String] = ["res://scripts", "res://tests", "res://tools"]


func _initialize() -> void:
	var broken: Array[String] = []
	var count := 0
	for folder in FOLDERS:
		for path in _scripts_under(folder):
			count += 1
			var script := load(path) as GDScript
			# A script with a parse error still loads, as an object that cannot be instantiated.
			if script == null or not script.can_instantiate():
				broken.append(path)
	for path in broken:
		print("UNLOADABLE ", path)
	print("loaded %d scripts, %d unloadable" % [count, broken.size()])
	quit(1 if not broken.is_empty() else 0)


func _scripts_under(folder: String) -> Array[String]:
	var found: Array[String] = []
	for name in DirAccess.get_directories_at(folder):
		found.append_array(_scripts_under(folder.path_join(name)))
	for name in DirAccess.get_files_at(folder):
		if name.ends_with(".gd"):
			found.append(folder.path_join(name))
	return found
