#include "snake_bot.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <queue>
#include <vector>

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/vector2i.hpp>

namespace {

using godot::Vector2i;

/// A cell no board holds, for "there is none".
const Vector2i NO_CELL(-1, -1);

const std::array<Vector2i, 4> DIRECTIONS = { Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1),
	Vector2i(0, -1) };

/// The board as the bot sees it: which cells the snake blocks.
struct Board {
	Vector2i size;
	std::vector<bool> blocked;

	bool contains(Vector2i cell) const {
		return cell.x >= 0 && cell.y >= 0 && cell.x < size.x && cell.y < size.y;
	}

	size_t index(Vector2i cell) const {
		return static_cast<size_t>(cell.y) * static_cast<size_t>(size.x)
			+ static_cast<size_t>(cell.x);
	}

	bool is_free(Vector2i cell) const { return contains(cell) && !blocked[index(cell)]; }
};

/// The board with every cell of `body` blocked except the tail, which moves out of the way.
Board make_board(const godot::TypedArray<Vector2i> &body, Vector2i size) {
	Board board;
	board.size = size;
	board.blocked.assign(static_cast<size_t>(size.x) * static_cast<size_t>(size.y), false);
	for (int64_t i = 0; i + 1 < body.size(); i++) {
		const Vector2i cell = body[i];
		if (board.contains(cell)) {
			board.blocked[board.index(cell)] = true;
		}
	}
	return board;
}

/// The first step of a shortest path from `start` to `target` that does not turn back onto
/// `behind`, or (0, 0) when there is none. Breadth-first: every cell remembers which first step
/// reached it.
Vector2i first_step_toward(const Board &board, Vector2i start, Vector2i target, Vector2i behind) {
	std::vector<bool> seen(board.blocked.size(), false);
	std::vector<Vector2i> first(board.blocked.size());
	std::queue<Vector2i> waiting;
	for (const Vector2i &direction : DIRECTIONS) {
		const Vector2i cell = start + direction;
		if (cell != behind && board.is_free(cell)) {
			seen[board.index(cell)] = true;
			first[board.index(cell)] = direction;
			waiting.push(cell);
		}
	}
	while (!waiting.empty()) {
		const Vector2i cell = waiting.front();
		waiting.pop();
		if (cell == target) {
			return first[board.index(cell)];
		}
		for (const Vector2i &direction : DIRECTIONS) {
			const Vector2i next = cell + direction;
			if (board.is_free(next) && !seen[board.index(next)]) {
				seen[board.index(next)] = true;
				first[board.index(next)] = first[board.index(cell)];
				waiting.push(next);
			}
		}
	}
	return Vector2i(0, 0);
}

/// How many free cells can be reached from `start`, counting it.
int open_space_from(const Board &board, Vector2i start) {
	std::vector<bool> seen(board.blocked.size(), false);
	std::queue<Vector2i> waiting;
	seen[board.index(start)] = true;
	waiting.push(start);
	int count = 0;
	while (!waiting.empty()) {
		const Vector2i cell = waiting.front();
		waiting.pop();
		count++;
		for (const Vector2i &direction : DIRECTIONS) {
			const Vector2i next = cell + direction;
			if (board.is_free(next) && !seen[board.index(next)]) {
				seen[board.index(next)] = true;
				waiting.push(next);
			}
		}
	}
	return count;
}

/// The safe step that leads to the most open space, or `heading` when no step is safe.
Vector2i roomiest_step(const Board &board, Vector2i head, Vector2i behind, Vector2i heading) {
	Vector2i best = heading;
	int best_space = 0;
	for (const Vector2i &direction : DIRECTIONS) {
		const Vector2i cell = head + direction;
		if (cell == behind || !board.is_free(cell)) {
			continue;
		}
		const int space = open_space_from(board, cell);
		if (space > best_space) {
			best_space = space;
			best = direction;
		}
	}
	return best;
}

} // namespace

void SnakeBot::_bind_methods() {
	godot::ClassDB::bind_method(
		godot::D_METHOD("choose_direction", "body", "food", "size"), &SnakeBot::choose_direction);
}

godot::Vector2i SnakeBot::choose_direction(const godot::TypedArray<godot::Vector2i> &body,
	godot::Vector2i food, godot::Vector2i size) const {
	if (body.is_empty()) {
		return DIRECTIONS[0];
	}
	const Vector2i head = body[0];
	// With one cell there is no "behind", and the snake may go any way.
	const Vector2i behind = body.size() > 1 ? Vector2i(body[1]) : NO_CELL;
	const Vector2i heading = body.size() > 1 ? head - behind : DIRECTIONS[0];
	// A board with no cells has nowhere to go, and a negative size must not size the search.
	if (size.x <= 0 || size.y <= 0) {
		return heading;
	}
	const Board board = make_board(body, size);
	const Vector2i toward_food = first_step_toward(board, head, food, behind);
	if (toward_food != Vector2i(0, 0)) {
		return toward_food;
	}
	return roomiest_step(board, head, behind, heading);
}
