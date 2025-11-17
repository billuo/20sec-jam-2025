extends Label

signal start_requested

var tween: Tween


func _ready() -> void:
	tween = create_tween()
	tween.set_loops()
	tween.tween_interval(0.25)
	tween.loop_finished.connect(func(_i): visible = not visible)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		start_requested.emit()
		if Game.state == Game.State.InGame:
			set_process_input(false)
			tween.stop()
			hide()
