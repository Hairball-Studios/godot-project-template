class_name HighScore
extends RefCounted
## The best score, kept between runs in a small config file.

const SECTION := "scores"
const KEY := "best"

var best := 0

var _path: String


## Loads the best score saved at `path` (a user:// path). A missing file means none yet.
func _init(path: String) -> void:
	_path = path
	var file := ConfigFile.new()
	if file.load(_path) == OK:
		best = int(file.get_value(SECTION, KEY, 0))


## Records `score` if it beats the best, saves it, and says whether it did.
func submit(score: int) -> bool:
	if score <= best:
		return false
	best = score
	var file := ConfigFile.new()
	file.set_value(SECTION, KEY, best)
	var error := file.save(_path)
	if error != OK:
		push_warning("Could not save the best score to %s: %s" % [_path, error_string(error)])
	return true
