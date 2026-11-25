extends GdUnitTestSuite
## The tuning resource (scripts/game_settings.gd) and the saved one the game loads
## (resources/default_settings.tres).
## Run with: mise run test -- test_game_settings


func test_the_saved_settings_load_with_their_values() -> void:
	var settings := load("res://resources/default_settings.tres") as GameSettings
	assert_object(settings).is_not_null()
	assert_vector(settings.board_size).is_equal(Vector2i(20, 15))
	assert_int(settings.cell_pixels).is_equal(32)
	assert_int(settings.food_score).is_equal(10)


## Every second food shaves 0.02 seconds off the step, down to the fastest.
@warning_ignore("unused_parameter")
func test_the_game_speeds_up_as_food_is_eaten(
	foods_eaten: int,
	expected_seconds: float,
	# gdlint: ignore=unused-argument
	test_parameters := [[0, 0.2], [1, 0.2], [2, 0.18], [5, 0.16], [100, 0.1]],
) -> void:
	var settings := GameSettings.new()
	settings.start_tick_seconds = 0.2
	settings.fastest_tick_seconds = 0.1
	settings.foods_per_speedup = 2
	settings.speedup_seconds = 0.02
	assert_float(settings.tick_seconds_after(foods_eaten)).is_equal_approx(expected_seconds, 0.0001)
