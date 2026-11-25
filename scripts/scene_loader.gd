extends CanvasLayer
## Changes the scene, reachable from any script as `SceneLoader`: an autoload, and the one place a
## scene change goes through. It fades to black, loads the next scene on another thread so a large
## one does not freeze the game, swaps it in and fades back; "Loading" shows if the load outlasts
## the fade. It keeps running while the tree is paused.
##
## [codeblock]
## SceneLoader.change_to("res://scenes/main.tscn")
## [/codeblock]

## Emitted once the new scene is in the tree and the fade back has finished, with its path.
signal changed(path: String)

## How long each fade takes, out and back, in seconds; 0 changes the scene with no fade.
@export_range(0.0, 2.0, 0.05) var fade_seconds := 0.2

var _busy := false

@onready var _cover: ColorRect = %Cover
@onready var _loading: Label = %Loading


func _ready() -> void:
	_cover.hide()
	_loading.hide()


## True from a call to `change_to` until its `changed`.
func is_busy() -> bool:
	return _busy


## Replaces the current scene with the one at `path`. A call made while a change is under way is
## ignored, so a button pressed twice changes the scene once.
func change_to(path: String) -> void:
	if _busy:
		return
	var error := ResourceLoader.load_threaded_request(path, "PackedScene")
	if error != OK:
		push_error("Could not load %s: %s" % [path, error_string(error)])
		return
	_busy = true
	_cover.show()
	await _fade_to(1.0)
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		_loading.show()
		await get_tree().process_frame
	_loading.hide()
	var scene := ResourceLoader.load_threaded_get(path) as PackedScene
	if scene == null:
		push_error("%s is not a scene that can be opened" % path)
	else:
		get_tree().change_scene_to_packed(scene)
		await get_tree().scene_changed
	await _fade_to(0.0)
	_cover.hide()
	_busy = false
	if scene != null:
		changed.emit(path)


## Brings the black cover to `alpha` over the fade time.
func _fade_to(alpha: float) -> void:
	if fade_seconds <= 0.0:
		_cover.modulate.a = alpha
		return
	var tween := create_tween()
	tween.tween_property(_cover, "modulate:a", alpha, fade_seconds)
	await tween.finished
