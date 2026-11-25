class_name PauseMenu
extends CanvasLayer
## The pause menu, a scene to add to any scene that should be pausable. The `pause` action stops
## the whole scene tree and shows the menu; the action again, or Resume, carries on. The menu
## keeps running while the tree is paused (its process mode is Always); everything else stops,
## timers and input included.

## Emitted when the player chooses the title screen. The tree is running again by then; whoever
## owns the menu changes the scene.
signal title_pressed

## Whether the pause action does anything: a game that has ended turns it off.
var enabled := true

@onready var _resume: Button = %Resume
@onready var _title: Button = %Title


func _ready() -> void:
	hide()
	_resume.pressed.connect(set_paused.bind(false))
	_title.pressed.connect(_on_title_pressed)


func _exit_tree() -> void:
	# A scene that leaves while paused must not leave the next one frozen.
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


## Pauses the tree and shows the menu, or hides it and carries on. Pausing does nothing while
## `enabled` is false.
func set_paused(paused: bool) -> void:
	if paused and not enabled:
		return
	get_tree().paused = paused
	visible = paused
	if paused:
		# Focus lets the keyboard or a gamepad press a button.
		_resume.grab_focus()


func _on_title_pressed() -> void:
	set_paused(false)
	title_pressed.emit()
