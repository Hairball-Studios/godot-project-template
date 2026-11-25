extends GdUnitTestSuite
## The saved choices (scripts/preferences.gd, the `Preferences` autoload). The tests point the
## autoload at a file of their own and put it back, so a player's real choices are never touched.
## Run with: mise run test -- test_preferences

const PATH := "user://test_preferences.cfg"


func before_test() -> void:
	_remove_file()
	Preferences.path = PATH
	Preferences.load_from_disk()


func after_test() -> void:
	_remove_file()
	Preferences.path = Preferences.DEFAULT_PATH
	Preferences.load_from_disk()


func test_with_no_file_the_difficulty_is_normal() -> void:
	assert_int(Preferences.difficulty).is_equal(Preferences.Difficulty.NORMAL)
	assert_str(Preferences.difficulty_name()).is_equal("Normal")


func test_cycling_goes_round_the_difficulties_and_announces_each() -> void:
	var seen: Array[String] = []
	var note := func() -> void:
		seen.append(Preferences.difficulty_name())
	Preferences.changed.connect(note)
	for _press in 3:
		Preferences.cycle_difficulty()
	# The autoload outlives the test, so the test takes its listener back.
	Preferences.changed.disconnect(note)
	assert_array(seen).contains_exactly(["Fast", "Relaxed", "Normal"])


## The slower the difficulty, the longer each step takes.
@warning_ignore("unused_parameter")
func test_each_difficulty_scales_the_step(
	difficulty: Preferences.Difficulty,
	expected_scale: float,
	# gdlint: ignore=unused-argument
	test_parameters := [
		[Preferences.Difficulty.RELAXED, 1.5],
		[Preferences.Difficulty.NORMAL, 1.0],
		[Preferences.Difficulty.FAST, 0.7],
	],
) -> void:
	Preferences.set_difficulty(difficulty)
	assert_float(Preferences.tick_scale()).is_equal_approx(expected_scale, 0.0001)


func test_the_choice_survives_a_restart() -> void:
	Preferences.set_difficulty(Preferences.Difficulty.FAST)
	Preferences.difficulty = Preferences.Difficulty.NORMAL
	Preferences.load_from_disk()
	assert_int(Preferences.difficulty).is_equal(Preferences.Difficulty.FAST)


func test_a_file_holding_nonsense_leaves_the_default() -> void:
	var file := ConfigFile.new()
	file.set_value(Preferences.SECTION, Preferences.KEY, 99)
	assert_int(file.save(PATH)).is_equal(OK)
	Preferences.load_from_disk()
	assert_int(Preferences.difficulty).is_equal(Preferences.Difficulty.NORMAL)


func _remove_file() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
