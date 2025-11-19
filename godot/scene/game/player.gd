class_name Player
extends Node3D

signal died
signal attack_issued

enum Stance {
	None,
	Left,
	Up,
	Right,
	Down,
}

var stance_enter_ms := 0
var stance := Stance.None


func _unhandled_input(event: InputEvent) -> void:
	var ticks = Time.get_ticks_msec()
	if event.is_action(&"guard_left"):
		if event.is_pressed():
			stance = Stance.Left
			stance_enter_ms = ticks
		else:
			stance = Stance.None
	elif event.is_action_pressed(&"guard_up"):
		if event.is_pressed():
			stance = Stance.Up
			stance_enter_ms = ticks
		else:
			stance = Stance.None
	elif event.is_action_pressed(&"guard_right"):
		if event.is_pressed():
			stance = Stance.Right
			stance_enter_ms = ticks
		else:
			stance = Stance.None
	elif event.is_action_pressed(&"guard_down"):
		if event.is_pressed():
			stance = Stance.Down
			stance_enter_ms = ticks
		else:
			stance = Stance.None
	elif event.is_action_pressed(&"attack"):
		attack_issued.emit()


func check_guard(enemy: Enemy):
	if stance == enemy.stance:
		$SFX/SwordClash.play()
		enemy.state = Enemy.State.Stun
	else:
		enemy.state = Enemy.State.Idle
		$SFX/SwordSlash.play()
		self.take_damage()


func take_damage():
	die()


func die():
	$SFX/DeathGroan.play()
	var tween = create_tween()
	tween.tween_property($Camera3D, "rotation:x", PI / 2.0, 0.3).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	$SFX/DeathFall.play()
	died.emit()
