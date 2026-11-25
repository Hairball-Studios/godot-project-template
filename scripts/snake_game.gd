class_name SnakeGame
extends RefCounted
## The rules of Snake, with no scene, input or timer in them, so a test can play a whole game in
## a few lines. The snake moves one cell each `step()`, grows and scores when it reaches the food,
## and the game ends when it hits a wall or itself, or fills the board. scripts/main.gd draws the
## game and turns key presses into `turn()` calls.

## Emitted each time the snake eats, with the new score.
signal score_changed(score: int)
## Emitted once, on the step that ends the game, with how it ended.
signal ended(result: State)

## Where a game stands.
enum State {
	PLAYING,
	## The snake hit a wall or itself.
	GAME_OVER,
	## The snake filled the board.
	WON,
}

## Cells the snake starts with.
const START_LENGTH := 3

## The board's width and height, in cells.
var size: Vector2i
## The snake's cells, head first.
var body: Array[Vector2i] = []
var food := Vector2i.ZERO
var score := 0
var foods_eaten := 0
var state := State.PLAYING

## The way the last step moved.
var _direction := Vector2i.RIGHT
## The way the next step moves: the latest turn.
var _next_direction := Vector2i.RIGHT
var _random := RandomNumberGenerator.new()
## Points for each piece of food.
var _food_score: int


## A game played by `settings`' board and scoring; the same `seed_value` places the food the same
## way.
func _init(settings := GameSettings.new(), seed_value := 1) -> void:
	size = settings.board_size
	_food_score = settings.food_score
	_random.seed = seed_value
	var head := size / 2
	for offset in START_LENGTH:
		body.append(head - Vector2i(offset, 0))
	_place_food()


## True once the game has ended, either way.
func is_over() -> bool:
	return state != State.PLAYING


## Asks for the next step to move in `direction` (a unit vector). A turn straight back into the
## snake is ignored.
func turn(direction: Vector2i) -> void:
	if direction + _direction != Vector2i.ZERO:
		_next_direction = direction


## Moves the snake one cell. Does nothing once the game is over.
func step() -> void:
	if is_over():
		return
	_direction = _next_direction
	var head := body[0] + _direction
	var grows := head == food
	# The tail's cell is free again this step, unless the snake grows into it.
	var occupied: Array[Vector2i] = body.slice(0, body.size() if grows else body.size() - 1)
	if not _on_board(head) or occupied.has(head):
		_finish(State.GAME_OVER)
		return
	body.push_front(head)
	if not grows:
		body.pop_back()
		return
	foods_eaten += 1
	score += _food_score
	score_changed.emit(score)
	if not _place_food():
		_finish(State.WON)


func _finish(result: State) -> void:
	state = result
	ended.emit(result)


func _on_board(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


## Puts the food on a random free cell, and says whether there was one: a snake that fills the
## board leaves none.
func _place_food() -> bool:
	var free: Array[Vector2i] = []
	for x in size.x:
		for y in size.y:
			if not body.has(Vector2i(x, y)):
				free.append(Vector2i(x, y))
	if free.is_empty():
		return false
	food = free[_random.randi_range(0, free.size() - 1)]
	return true
