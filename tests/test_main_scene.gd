extends GdUnitTestSuite
## The main scene (scenes/main.tscn) with its board view and HUD: it loads, plays, takes key
## presses, pauses, ends a game, saves the best score, restarts, and lets the bot play. The rules
## are test_snake_game.gd's; this proves the scene holds them together.
## Run with: mise run test -- test_main_scene

const BEST_PATH := "user://test_main_scene_best.cfg"

var _runner: GdUnitSceneRunner
var _main: Main
var _score: Label
var _best: Label
var _message: Label
var _tick: Timer
var _pause_menu: PauseMenu


func before_test() -> void:
	_remove_file()
	_main = auto_free(load("res://scenes/main.tscn").instantiate()) as Main
	_main.high_score_path = BEST_PATH
	# The runner adds the scene to the tree, which runs its `_ready`; `auto_free` above frees it
	# after the test, because a runner frees only a scene it loaded itself.
	_runner = scene_runner(_main)
	var hud := _main.get_node("Hud")
	_score = hud.get_node("%Score") as Label
	_best = hud.get_node("%Best") as Label
	_message = hud.get_node("%Message") as Label
	_tick = _main.get_node("Tick") as Timer
	_pause_menu = _main.get_node("PauseMenu") as PauseMenu
	# The test steps the game itself, so the clock must not.
	_tick.stop()


func after_test() -> void:
	# A failed test must not leave the tree paused for the tests after it.
	get_tree().paused = false
	_remove_file()


func test_the_scene_starts_with_the_score_and_the_best_shown() -> void:
	assert_str(_score.text).is_equal("Score: 0")
	assert_str(_best.text).is_equal("Best: 0")
	assert_str(_message.text).is_empty()


## The scene, not the script, names the settings: a `preload` in a script that the scene loader
## loads on another thread leaks an object when the engine exits.
func test_the_scene_carries_the_saved_settings() -> void:
	assert_object(_main.settings).is_same(load("res://resources/default_settings.tres"))


## Food right in front of the snake: eating it shows through the game's `score_changed` signal,
## and the game gets faster.
func test_eating_shows_the_new_score_and_speeds_the_game_up() -> void:
	_main.game.food = _main.game.body[0] + Vector2i.RIGHT
	_main.tick()
	assert_str(_score.text).is_equal("Score: 10")
	var expected := _main.settings.tick_seconds_after(1) * Preferences.tick_scale()
	assert_float(_tick.wait_time).is_equal_approx(expected, 0.0001)


## The input actions in project.godot turn arrow keys and W, A, S, D alike into turns.
func test_the_input_actions_take_arrow_keys_and_wasd() -> void:
	var head: Vector2i = _main.game.body[0]
	_runner.simulate_key_pressed(KEY_W)
	_main.tick()
	assert_vector(_main.game.body[0]).is_equal(head + Vector2i.UP)
	_runner.simulate_key_pressed(KEY_LEFT)
	_main.tick()
	assert_vector(_main.game.body[0]).is_equal(head + Vector2i.UP + Vector2i.LEFT)


## The actions take a gamepad too, whichever one is plugged in: its D-pad turns the snake. The
## press goes in through the viewport, as one from a real gamepad does.
func test_a_gamepad_d_pad_turns_the_snake() -> void:
	var head: Vector2i = _main.game.body[0]
	var press := InputEventJoypadButton.new()
	press.device = 1
	press.button_index = JOY_BUTTON_DPAD_UP
	press.pressed = true
	_main.get_viewport().push_input(press)
	_main.tick()
	assert_vector(_main.game.body[0]).is_equal(head + Vector2i.UP)


## The pause menu's own rules are test_pause_menu.gd's; this proves the game scene has one.
func test_p_pauses_the_game_and_p_resumes_it() -> void:
	_runner.simulate_key_pressed(KEY_P)
	assert_bool(get_tree().paused).is_true()
	assert_bool(_pause_menu.visible).is_true()
	_runner.simulate_key_pressed(KEY_P)
	assert_bool(get_tree().paused).is_false()
	assert_bool(_pause_menu.visible).is_false()


func test_a_game_that_is_over_cannot_be_paused() -> void:
	for _step in 20:
		_main.tick()
	_runner.simulate_key_pressed(KEY_P)
	assert_bool(get_tree().paused).is_false()


## The snake heads up and meets the wall: the HUD says so and the score is kept as the best.
func test_a_game_over_is_shown_and_the_score_is_saved_as_the_best() -> void:
	_main.game.food = _main.game.body[0] + Vector2i.RIGHT
	_main.tick()
	_runner.simulate_key_pressed(KEY_W)
	for _step in 20:
		_main.tick()
	assert_str(_message.text).contains("Game over")
	assert_str(_best.text).is_equal("Best: 10")
	assert_int(HighScore.new(BEST_PATH).best).is_equal(10)


func test_enter_starts_a_new_game_that_can_be_paused_again() -> void:
	for _step in 20:
		_main.tick()
	_runner.simulate_key_pressed(KEY_ENTER)
	assert_str(_score.text).is_equal("Score: 0")
	assert_str(_message.text).is_empty()
	assert_bool(_pause_menu.enabled).is_true()


## The bot's games set no record, so bot mode takes the best score off the screen.
func test_bot_mode_hides_the_best_score() -> void:
	assert_bool(_best.visible).is_true()
	_main.play_with_bot()
	assert_bool(_best.visible).is_false()


## In bot mode, a tick turns the snake toward the food without a key press.
func test_a_bot_turns_the_snake_toward_the_food() -> void:
	_main.play_with_bot()
	var head: Vector2i = _main.game.body[0]
	_main.game.food = head + Vector2i(0, 2)
	_main.tick()
	assert_vector(_main.game.body[0]).is_equal(head + Vector2i.DOWN)


func _remove_file() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BEST_PATH))
