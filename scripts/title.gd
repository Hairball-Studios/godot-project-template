class_name Title
extends Control
## The first screen: start the game, change the speed, or quit. It shows the saved choices in
## `Preferences` and changes them; the rules and the board are the game scene's.
##
## Started with `--bot` after the engine's own arguments (`mise run bot`), it skips straight to the
## game, where the C++ bot plays.

## The scene the Start button opens.
const GAME_SCENE := "res://scenes/main.tscn"

@onready var _start: Button = %Start
@onready var _speed: Button = %Speed
@onready var _quit: Button = %Quit


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--bot"):
		# Not now: the engine is still setting this scene up.
		start_game.call_deferred()
		return
	_start.pressed.connect(start_game)
	_speed.pressed.connect(Preferences.cycle_difficulty)
	_quit.pressed.connect(get_tree().quit)
	Preferences.changed.connect(_show_speed)
	_show_speed()
	# Focus lets the keyboard or a gamepad press a button; the first one is the likeliest.
	_start.grab_focus()


## Opens the game scene in place of this one.
func start_game() -> void:
	SceneLoader.change_to(GAME_SCENE)


func _show_speed() -> void:
	_speed.text = "Speed: %s" % Preferences.difficulty_name()
