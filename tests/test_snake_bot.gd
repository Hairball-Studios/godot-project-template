extends GdUnitTestSuite
## The C++ bot (native/src/snake_bot.cpp): the moves it picks, and a whole game it plays alone.
## Run with: mise run test -- test_snake_bot

const BOARD := Vector2i(8, 6)
## A snake of three cells heading right, its head at (2, 2).
const HEADING_RIGHT: Array[Vector2i] = [Vector2i(2, 2), Vector2i(1, 2), Vector2i(0, 2)]

var _bot := SnakeBot.new()


## Each row: where the food is, and the way the bot should turn to reach it.
@warning_ignore("unused_parameter")
func test_the_bot_heads_for_the_food_and_never_turns_back(
	food: Vector2i,
	expected: Vector2i,
	# gdlint: ignore=unused-argument
	test_parameters := [
		[Vector2i(5, 2), Vector2i.RIGHT],
		[Vector2i(2, 4), Vector2i.DOWN],
		[Vector2i(0, 1), Vector2i.UP],
	],
) -> void:
	assert_vector(_bot.choose_direction(HEADING_RIGHT, food, BOARD)).is_equal(expected)


## Food the snake cannot reach: it heads for open space instead, and never straight back.
func test_with_no_path_to_the_food_the_bot_heads_for_open_space() -> void:
	var walled: Array[Vector2i] = [
		Vector2i(2, 2),
		Vector2i(3, 2),
		Vector2i(3, 1),
		Vector2i(3, 0),
		Vector2i(2, 0),
	]
	var way := _bot.choose_direction(walled, Vector2i(4, 1), Vector2i(5, 3))
	assert_array([Vector2i.LEFT, Vector2i.UP]).contains([way])


## A size no board has comes from a caller's mistake; the bot answers instead of crashing.
func test_a_board_with_no_cells_keeps_the_heading() -> void:
	assert_vector(_bot.choose_direction(HEADING_RIGHT, Vector2i(1, 1), Vector2i(-1, 5))).is_equal(
		Vector2i.RIGHT
	)


## The bot plays a game with nobody else at the controls: it eats well and never turns back.
func test_the_bot_plays_a_whole_game_alone() -> void:
	var settings := GameSettings.new()
	settings.board_size = Vector2i(12, 10)
	var game := SnakeGame.new(settings, 3)
	var turned_back := false
	for _step in 2000:
		if game.is_over():
			break
		var way := _bot.choose_direction(game.body, game.food, game.size)
		turned_back = turned_back or way == game.body[1] - game.body[0]
		game.turn(way)
		game.step()
	assert_bool(turned_back).is_false()
	assert_int(game.foods_eaten).is_greater_equal(15)
