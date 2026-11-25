// The extension's entry point: the engine calls `game_library_init` (named in
// bin/game.gdextension) and the initializer below registers each class once.

#include "snake_bot.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

void initialize_game_module(godot::ModuleInitializationLevel level) {
	if (level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(SnakeBot);
}

void uninitialize_game_module(godot::ModuleInitializationLevel level) {
	if (level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	// SnakeBot holds nothing outside itself, so nothing is released here; a class
	// that opens a file or starts a thread would close it.
}

extern "C" {
GDExtensionBool GDE_EXPORT game_library_init(GDExtensionInterfaceGetProcAddress get_proc_address,
	GDExtensionClassLibraryPtr library, GDExtensionInitialization *initialization) {
	const godot::GDExtensionBinding::InitObject init_object(
		get_proc_address, library, initialization);
	init_object.register_initializer(initialize_game_module);
	init_object.register_terminator(uninitialize_game_module);
	init_object.set_minimum_library_initialization_level(godot::MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_object.init();
}
}
