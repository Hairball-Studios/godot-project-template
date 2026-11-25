extends GdUnitTestSuite
## The scene loader (scripts/scene_loader.gd, the `SceneLoader` autoload): it swaps the current
## scene for another behind a fade, and one change at a time.
## Run with: mise run test -- test_scene_loader

## Two small scenes to change to.
const HUD_SCENE := "res://scenes/hud.tscn"
const BOARD_SCENE := "res://scenes/board_view.tscn"


func after_test() -> void:
	# The scene a test changed to is the tree's, not the test's, so the test frees it.
	if get_tree().current_scene != null:
		get_tree().current_scene.free()


func test_a_change_swaps_the_scene_in_and_is_idle_afterwards() -> void:
	await SceneLoader.change_to(HUD_SCENE)
	assert_object(get_tree().current_scene).is_instanceof(Hud)
	assert_bool(SceneLoader.is_busy()).is_false()


func test_the_screen_is_covered_only_while_the_scene_changes() -> void:
	var cover := SceneLoader.get_node("%Cover") as ColorRect
	assert_bool(cover.visible).is_false()
	SceneLoader.change_to(HUD_SCENE)
	assert_bool(cover.visible).is_true()
	assert_bool(SceneLoader.is_busy()).is_true()
	await _changed(HUD_SCENE)
	assert_bool(cover.visible).is_false()


func test_a_finished_change_is_announced_with_its_path() -> void:
	var paths: Array[String] = []
	var note := func(path: String) -> void:
		paths.append(path)
	SceneLoader.changed.connect(note)
	await SceneLoader.change_to(HUD_SCENE)
	SceneLoader.changed.disconnect(note)
	assert_array(paths).contains_exactly([HUD_SCENE])


## A button pressed twice asks twice: the second call must not start a second change.
func test_a_call_during_a_change_is_ignored() -> void:
	SceneLoader.change_to(HUD_SCENE)
	SceneLoader.change_to(BOARD_SCENE)
	await _changed(HUD_SCENE)
	assert_object(get_tree().current_scene).is_instanceof(Hud)


func test_with_no_fade_time_the_scene_still_changes() -> void:
	var seconds := SceneLoader.fade_seconds
	SceneLoader.fade_seconds = 0.0
	await SceneLoader.change_to(BOARD_SCENE)
	SceneLoader.fade_seconds = seconds
	assert_object(get_tree().current_scene).is_instanceof(BoardView)


## Waits, up to two seconds, for the loader to announce the change to `path`. gdUnit4's
## `assert_signal` is not declared as a coroutine though awaiting it is how it waits, hence the
## ignored warning.
func _changed(path: String) -> void:
	@warning_ignore("redundant_await")
	await assert_signal(SceneLoader).wait_until(2000).is_emitted("changed", [path])
