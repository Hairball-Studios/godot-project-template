class_name BoardView
extends Node2D
## Draws a SnakeGame's board: the snake and the food on a plain background. It holds no rules;
## whoever owns the game calls `queue_redraw()` after each step.

@export var background := Color(0.1, 0.12, 0.16)
@export var snake_color := Color(0.35, 0.8, 0.4)
@export var food_color := Color(0.9, 0.3, 0.3)

var _game: SnakeGame
var _cell_pixels := 32


## Shows `game`, with cells `cell_pixels` wide.
func show_game(game: SnakeGame, cell_pixels: int) -> void:
	_game = game
	_cell_pixels = cell_pixels
	queue_redraw()


func _draw() -> void:
	if _game == null:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(_game.size * _cell_pixels)), background)
	for cell in _game.body:
		_draw_cell(cell, snake_color)
	_draw_cell(_game.food, food_color)


## One cell, inset by a pixel so neighbours show a seam.
func _draw_cell(cell: Vector2i, color: Color) -> void:
	var corner := Vector2(cell * _cell_pixels) + Vector2.ONE
	draw_rect(Rect2(corner, Vector2.ONE * (_cell_pixels - 2)), color)
