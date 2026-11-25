#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/vector2i.hpp>

/// Plays Snake: given the board, it answers which way the snake should head. It is C++ because
/// it searches the whole board every step, which is the kind of work worth moving out of script.
/// scripts/main.gd asks it for a direction each tick when the game starts in bot mode.
class SnakeBot : public godot::RefCounted {
	GDCLASS(SnakeBot, godot::RefCounted)

public:
	/// The direction (a unit vector) the snake should move next. `body` is the snake's cells, head
	/// first, on a board `size` cells across. The way is the shortest free path to `food`; with no
	/// path, it is toward the most open space. A snake with nowhere to go keeps heading as it was.
	godot::Vector2i choose_direction(const godot::TypedArray<godot::Vector2i> &body,
		godot::Vector2i food, godot::Vector2i size) const;

protected:
	static void _bind_methods();
};
