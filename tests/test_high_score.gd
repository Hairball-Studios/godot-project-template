extends GdUnitTestSuite
## The saved best score (scripts/high_score.gd), written to a file under user://.
## Run with: mise run test -- test_high_score

const PATH := "user://test_high_score.cfg"


func before_test() -> void:
	_remove_file()


func after_test() -> void:
	_remove_file()


func test_with_no_file_there_is_no_best_score() -> void:
	assert_int(HighScore.new(PATH).best).is_equal(0)


func test_only_a_higher_score_is_a_record() -> void:
	var scores := HighScore.new(PATH)
	assert_bool(scores.submit(50)).is_true()
	assert_int(scores.best).is_equal(50)
	assert_bool(scores.submit(30)).is_false()
	assert_bool(scores.submit(50)).is_false()
	assert_int(scores.best).is_equal(50)


func test_the_best_score_survives_a_restart() -> void:
	HighScore.new(PATH).submit(50)
	assert_int(HighScore.new(PATH).best).is_equal(50)


func _remove_file() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
