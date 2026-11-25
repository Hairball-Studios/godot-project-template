class_name Main
extends Node2D
## Puts the game together: it runs a SnakeGame on a timer, turns key presses into turns, keeps the
## best score, and tells the board and the HUD what to show. The rules are SnakeGame's.
##
## Started with `--bot` after the engine's own arguments (`mise run bot`), the C++ SnakeBot plays
## instead of a person and starts a new game each time one ends. The bot is looked up by name
## when it is asked for, so the game loads and plays where the C++ library has not been built.

## How long the bot waits after a game ends before it starts another, in seconds.
const BOT_RESTART_SECONDS := 1.5
## The C++ class that plays in bot mode (native/src/snake_bot.cpp).
const BOT_CLASS := &"SnakeBot"
## The scene the menu key goes back to.
const TITLE_SCENE := "res://scenes/title.tscn"

## The numbers that tune the game. scenes/main.tscn sets it to resources/default_settings.tres;
## the inspector is where to point it at another.
@export var settings: GameSettings
## Where the best score is kept between runs.
@export var high_score_path := "user://best.cfg"

## The game being played; a new one each time a game starts.
var game: SnakeGame

var _high_score: HighScore
## The bot when it plays, and null when a person does.
var _bot: RefCounted

@onready var _board: BoardView = $BoardView
@onready var _hud: Hud = $Hud
@onready var _tick: Timer = $Tick
@onready var _pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	if settings == null:
		settings = GameSettings.new()
	_high_score = HighScore.new(high_score_path)
	_hud.show_best(_high_score.best)
	if OS.get_cmdline_user_args().has("--bot"):
		play_with_bot()
	_tick.timeout.connect(tick)
	_pause_menu.title_pressed.connect(_go_to_title)
	_start()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left"):
		game.turn(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		game.turn(Vector2i.RIGHT)
	elif event.is_action_pressed("move_up"):
		game.turn(Vector2i.UP)
	elif event.is_action_pressed("move_down"):
		game.turn(Vector2i.DOWN)
	elif event.is_action_pressed("restart") and game.is_over():
		_start()
	elif event.is_action_pressed("menu"):
		_go_to_title()


## Hands the game to the C++ bot, which is what `--bot` does. The bot's games set no record, so
## the best score comes off the screen. Where the C++ library is not built, a person still plays.
func play_with_bot() -> void:
	_bot = _new_bot()
	if _bot != null:
		_hud.hide_best()


## Moves the game one step, as the timer does; the bot picks the direction first.
func tick() -> void:
	if _bot != null:
		var way: Vector2i = _bot.call(&"choose_direction", game.body, game.food, game.size)
		game.turn(way)
	game.step()
	_board.queue_redraw()


func _start() -> void:
	game = SnakeGame.new(settings, randi())
	game.score_changed.connect(_on_score_changed)
	game.ended.connect(_on_ended)
	_board.show_game(game, settings.cell_pixels)
	_tick.wait_time = _step_seconds(0)
	_pause_menu.enabled = true
	_hud.show_score(0)
	_hud.show_state(SnakeGame.State.PLAYING)


## A SnakeBot, or null (after saying why) where the C++ library is not built.
func _new_bot() -> RefCounted:
	if not ClassDB.class_exists(BOT_CLASS):
		push_error("--bot needs the C++ library, which is not built: run `mise run build`")
		return null
	return ClassDB.instantiate(BOT_CLASS) as RefCounted


func _go_to_title() -> void:
	SceneLoader.change_to(TITLE_SCENE)


func _on_score_changed(value: int) -> void:
	_hud.show_score(value)
	_tick.wait_time = _step_seconds(game.foods_eaten)


## How long a step takes once `foods_eaten` pieces are eaten: the settings' time, stretched or
## shortened by the player's choice of speed.
func _step_seconds(foods_eaten: int) -> float:
	return settings.tick_seconds_after(foods_eaten) * Preferences.tick_scale()


func _on_ended(result: SnakeGame.State) -> void:
	_hud.show_state(result)
	# There is nothing left to pause.
	_pause_menu.enabled = false
	if _bot != null:
		_restart_after_delay()
	elif _high_score.submit(game.score):
		_hud.show_best(_high_score.best)


## Starts a new game after a pause, so a person watching the bot sees how the last one ended.
func _restart_after_delay() -> void:
	await get_tree().create_timer(BOT_RESTART_SECONDS).timeout
	_start()
