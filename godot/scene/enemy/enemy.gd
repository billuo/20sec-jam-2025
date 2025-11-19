class_name Enemy
extends Node3D

signal attack_issued(enemy: Enemy)
signal died

enum State {
	Approaching,
}

var dead := false
var target_position: Vector3
var stance := Player.Stance.None

@onready var stance_indicator: Sprite3D = $StanceIndicator
@onready var ap: AnimationPlayer = $Node3D/Mannequin/AnimationPlayer


func _ready() -> void:
	stance = [Player.Stance.Left, Player.Stance.Up, Player.Stance.Right].pick_random()
	stance_indicator.frame = int(stance)
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, 1.0)
	tween.finished.connect(_on_target_arrived)
	ap.play(&"Walk")


func take_damage():
	print_debug("enemy took damage")
	die()


func die():
	dead = true
	stance_indicator.hide()
	ap.play(&"Death01")
	died.emit()
	await ap.animation_finished
	var tween = create_tween()
	tween.tween_property(self, "position", position - Vector3(0.0, 1.0, 0.0), 1.0)
	await tween.finished
	queue_free()


func _on_target_arrived():
	ap.play(&"Idle")
	await get_tree().create_timer(0.2).timeout
	ap.play(&"Sword_Attack")
	await get_tree().create_timer(0.45).timeout
	if not dead:
		attack_issued.emit(self)
