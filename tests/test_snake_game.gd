extends GdUnitTestSuite
## The rules of Snake (scripts/snake_game.gd), played without a scene.
## Run with: mise run test -- test_snake_game

const GRID := Vector2i(8, 6)


func test_a_new_game_starts_playing_with_the_snake_in_the_middle() -> void:
	var game := _new_game(GRID)
	assert_int(game.body.size()).is_equal(SnakeGame.START_LENGTH)
	assert_vector(game.body[0]).is_equal(Vector2i(4, 3))
	assert_int(game.state).is_equal(SnakeGame.State.PLAYING)
	assert_int(game.score).is_equal(0)


func test_the_snake_moves_right_to_begin_with_and_turns_on_the_next_step() -> void:
	var game := _new_game(GRID)
	game.step()
	assert_vector(game.body[0]).is_equal(Vector2i(5, 3))
	assert_int(game.body.size()).is_equal(SnakeGame.START_LENGTH)
	game.turn(Vector2i.UP)
	game.step()
	assert_vector(game.body[0]).is_equal(Vector2i(5, 2))


func test_a_turn_straight_back_is_ignored() -> void:
	var game := _new_game(GRID)
	game.turn(Vector2i.UP)
	game.step()
	game.turn(Vector2i.DOWN)
	game.step()
	assert_vector(game.body[0]).is_equal(Vector2i(4, 1))


func test_eating_grows_the_snake_and_scores_once() -> void:
	var game := _new_game(GRID)
	var scores: Array[int] = []
	game.score_changed.connect(
		func(value: int) -> void:
			scores.append(value),
	)
	game.food = Vector2i(5, 3)
	game.step()
	assert_int(game.body.size()).is_equal(SnakeGame.START_LENGTH + 1)
	assert_int(game.foods_eaten).is_equal(1)
	assert_int(game.score).is_equal(GameSettings.new().food_score)
	assert_array(game.body).not_contains([game.food])
	assert_array(scores).contains_exactly([GameSettings.new().food_score])


func test_the_snake_dies_on_the_wall_and_the_end_is_announced_once() -> void:
	var game := _new_game(GRID)
	var results: Array[SnakeGame.State] = []
	game.ended.connect(
		func(result: SnakeGame.State) -> void:
			results.append(result),
	)
	for _step in 3:
		game.step()
	assert_int(game.state).is_equal(SnakeGame.State.PLAYING)
	game.step()
	assert_int(game.state).is_equal(SnakeGame.State.GAME_OVER)
	game.step()
	assert_vector(game.body[0]).is_equal(Vector2i(7, 3))
	assert_array(results).contains_exactly([SnakeGame.State.GAME_OVER])


func test_the_snake_dies_on_its_own_body() -> void:
	var game := _new_game(GRID)
	game.body = [Vector2i(2, 2), Vector2i(2, 3), Vector2i(3, 3), Vector2i(3, 2), Vector2i(3, 1)]
	game.step()
	assert_bool(game.is_over()).is_true()


func test_the_snake_may_move_into_the_cell_its_tail_leaves() -> void:
	var game := _new_game(GRID)
	game.body = [Vector2i(3, 3), Vector2i(3, 4), Vector2i(4, 4), Vector2i(4, 3)]
	game.step()
	assert_bool(game.is_over()).is_false()


func test_a_snake_that_fills_the_board_has_won() -> void:
	# A board of four cells in a row: the snake takes three and the food sits in the fourth.
	var game := _new_game(Vector2i(4, 1))
	game.food = Vector2i(3, 0)
	game.step()
	assert_int(game.state).is_equal(SnakeGame.State.WON)
	assert_bool(game.is_over()).is_true()


## Runs once for each row of `test_parameters`.
@warning_ignore("unused_parameter")
func test_food_is_placed_on_the_board_and_off_the_snake(
	seed_value: int,
	# gdlint: ignore=unused-argument
	test_parameters := [[0], [1], [2], [3], [4], [5], [6], [7]],
) -> void:
	var game := _new_game(GRID, seed_value)
	assert_array(game.body).not_contains([game.food])
	assert_bool(Rect2i(Vector2i.ZERO, GRID).has_point(game.food)).is_true()


## A game on a board of `grid` cells, with the default scoring.
func _new_game(grid: Vector2i, seed_value := 1) -> SnakeGame:
	var settings := GameSettings.new()
	settings.board_size = grid
	return SnakeGame.new(settings, seed_value)
