extends Sprite3D


func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(self, "frame", 5, 0.1).from(0)
	tween.finished.connect(queue_free)
