extends GdUnitTestSuite
## The title screen (scenes/title.tscn): its buttons show and change the saved speed, and Start
## opens the game. The autoload is pointed at a file of its own, as in test_preferences.gd.
## Run with: mise run test -- test_title_screen

const PATH := "user://test_title_screen_preferences.cfg"

var _runner: GdUnitSceneRunner
var _title: Title


func before_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	Preferences.path = PATH
	Preferences.load_from_disk()
	_runner = scene_runner("res://scenes/title.tscn")
	_title = _runner.scene() as Title


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	Preferences.path = Preferences.DEFAULT_PATH
	Preferences.load_from_disk()


func test_the_title_shows_the_saved_speed_and_focuses_start() -> void:
	assert_str(_button("Speed").text).is_equal("Speed: Normal")
	assert_bool(_button("Start").has_focus()).is_true()


func test_the_speed_button_cycles_the_difficulty_and_shows_it() -> void:
	_button("Speed").pressed.emit()
	assert_str(_button("Speed").text).is_equal("Speed: Fast")
	assert_int(Preferences.difficulty).is_equal(Preferences.Difficulty.FAST)
	_button("Speed").pressed.emit()
	assert_str(_button("Speed").text).is_equal("Speed: Relaxed")


## Start asks the scene loader for the game's scene, which arrives behind a fade: the test waits,
## up to two seconds, for the loader to announce it. gdUnit4's `assert_signal` is not declared as
## a coroutine though awaiting it is how it waits, hence the ignored warning.
func test_start_opens_the_game() -> void:
	_button("Start").pressed.emit()
	@warning_ignore("redundant_await")
	await assert_signal(SceneLoader).wait_until(2000).is_emitted("changed", [Title.GAME_SCENE])
	assert_object(get_tree().current_scene).is_instanceof(Main)
	get_tree().current_scene.free()


func _button(button_name: String) -> Button:
	return _title.get_node("%" + button_name) as Button
