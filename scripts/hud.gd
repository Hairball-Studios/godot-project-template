class_name Hud
extends CanvasLayer
## The numbers and messages shown over the board. It holds no rules: whoever owns the game tells
## it what to show.

## What to press once a game has ended, on a keyboard or a gamepad.
const AGAIN_HINT := "Enter or A to play again, M or Back for the menu"

@onready var _score: Label = %Score
@onready var _best: Label = %Best
@onready var _message: Label = %Message


func show_score(value: int) -> void:
	_score.text = "Score: %d" % value


func show_best(value: int) -> void:
	_best.text = "Best: %d" % value


## Takes the best score off the screen, for a game that keeps none.
func hide_best() -> void:
	_best.hide()


## Shows what the player needs to know about how the game stands.
func show_state(state: SnakeGame.State) -> void:
	match state:
		SnakeGame.State.PLAYING:
			_message.text = ""
		SnakeGame.State.GAME_OVER:
			_message.text = "Game over\n" + AGAIN_HINT
		SnakeGame.State.WON:
			_message.text = "You filled the board!\n" + AGAIN_HINT
