extends GdUnitTestSuite
## The pause menu (scenes/pause_menu.tscn): the pause action stops the scene tree and shows the
## menu, and the action again or either button carries on.
## Run with: mise run test -- test_pause_menu

var _runner: GdUnitSceneRunner
var _menu: PauseMenu


func before_test() -> void:
	_runner = scene_runner("res://scenes/pause_menu.tscn")
	_menu = _runner.scene() as PauseMenu


func after_test() -> void:
	# A failed test must not leave the tree paused for the tests after it.
	get_tree().paused = false


func test_the_menu_starts_hidden_with_the_tree_running() -> void:
	assert_bool(_menu.visible).is_false()
	assert_bool(get_tree().paused).is_false()


func test_the_pause_action_pauses_and_shows_the_menu_and_again_resumes() -> void:
	_runner.simulate_key_pressed(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_true()
	assert_bool(_menu.visible).is_true()
	assert_bool(_button("Resume").has_focus()).is_true()
	_runner.simulate_key_pressed(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_false()
	assert_bool(_menu.visible).is_false()


func test_resume_carries_on() -> void:
	_menu.set_paused(true)
	_button("Resume").pressed.emit()
	assert_bool(get_tree().paused).is_false()
	assert_bool(_menu.visible).is_false()


func test_a_menu_that_is_not_enabled_does_not_pause() -> void:
	_menu.enabled = false
	_runner.simulate_key_pressed(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_false()
	assert_bool(_menu.visible).is_false()


## The menu changes no scene itself: it resumes and says the title screen was chosen.
func test_title_screen_resumes_and_says_so() -> void:
	var presses: Array[bool] = []
	_menu.title_pressed.connect(
		func() -> void:
			presses.append(get_tree().paused),
	)
	_menu.set_paused(true)
	_button("Title").pressed.emit()
	assert_array(presses).contains_exactly([false])
	assert_bool(_menu.visible).is_false()


func test_leaving_the_tree_while_paused_resumes_it() -> void:
	_menu.set_paused(true)
	_menu.get_parent().remove_child(_menu)
	assert_bool(get_tree().paused).is_false()
	_menu.free()


func _button(button_name: String) -> Button:
	return _menu.get_node("%" + button_name) as Button
