extends Node
## The player's saved choices, reachable from any script as `Preferences`: an autoload, which the
## engine creates once at start-up from the [autoload] section of project.godot. It has no
## `class_name`, because an autoload's name is the global it becomes.

## Emitted after the difficulty changes.
signal changed

## How fast the snake moves: each step takes the settings' time times the difficulty's scale.
enum Difficulty {
	RELAXED,
	NORMAL,
	FAST,
}

## Where the choices are kept between runs.
const DEFAULT_PATH := "user://preferences.cfg"
const SECTION := "preferences"
const KEY := "difficulty"

## The file the choices are read from and saved to; a test points it somewhere of its own.
var path := DEFAULT_PATH
var difficulty := Difficulty.NORMAL


func _ready() -> void:
	load_from_disk()


## Reads the saved choices; with no file, or one that holds nonsense, the defaults stand.
func load_from_disk() -> void:
	difficulty = Difficulty.NORMAL
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	var saved: Variant = file.get_value(SECTION, KEY, Difficulty.NORMAL)
	if saved is int and Difficulty.values().has(saved):
		difficulty = saved as Difficulty


## Chooses a difficulty, saves it and announces the change.
func set_difficulty(value: Difficulty) -> void:
	difficulty = value
	var file := ConfigFile.new()
	file.set_value(SECTION, KEY, difficulty)
	var error := file.save(path)
	if error != OK:
		push_warning("Could not save %s: %s" % [path, error_string(error)])
	changed.emit()


## Moves to the next difficulty, and from the last back to the first.
func cycle_difficulty() -> void:
	set_difficulty(((difficulty + 1) % Difficulty.size()) as Difficulty)


## How much longer than the settings' time each step takes: more than 1 is slower.
func tick_scale() -> float:
	match difficulty:
		Difficulty.RELAXED:
			return 1.5
		Difficulty.FAST:
			return 0.7
		_:
			return 1.0


## The difficulty as the title screen shows it.
func difficulty_name() -> String:
	return Difficulty.keys()[difficulty].capitalize()
