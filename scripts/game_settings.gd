class_name GameSettings
extends Resource
## The numbers that tune a game, kept in a resource (resources/default_settings.tres) so they are
## edited in the inspector instead of in code. A test builds its own with the numbers it needs.

## The board's width and height, in cells.
@export var board_size := Vector2i(20, 15)
## The width and height of a cell, in pixels.
@export var cell_pixels := 32
## Points for each piece of food.
@export var food_score := 10
## Seconds between steps at the start.
@export_range(0.03, 1.0, 0.01) var start_tick_seconds := 0.15
## The fewest seconds between steps: the game gets no faster than this.
@export_range(0.03, 1.0, 0.01) var fastest_tick_seconds := 0.06
## The game speeds up once for every this many pieces of food eaten.
@export_range(1, 20) var foods_per_speedup := 3
## How many seconds each speed-up takes off a step.
@export_range(0.0, 0.1, 0.005) var speedup_seconds := 0.01


## Seconds between steps once `foods_eaten` pieces of food have been eaten.
func tick_seconds_after(foods_eaten: int) -> float:
	# Whole speed-ups only, so the division is meant to drop the remainder.
	@warning_ignore("integer_division")
	var speedups := foods_eaten / foods_per_speedup
	return maxf(fastest_tick_seconds, start_tick_seconds - speedups * speedup_seconds)
