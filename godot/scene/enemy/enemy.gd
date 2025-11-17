class_name Enemy
extends Node3D

signal attack_issued(enemy: Enemy)
signal died

var stance := Player.Stance.None

# @onready var stm: STMInstance3D = $STMCachedInstance3D
@onready var stance_indicator: Sprite3D = $StanceIndicator


func _ready() -> void:
	stance = [Player.Stance.Left, Player.Stance.Up, Player.Stance.Right].pick_random()
	stance_indicator.frame = int(stance)
	var tween = create_tween()
	tween.tween_property(self, "global_position", global_position + Vector3.BACK * 3.0, 1.0)
	tween.finished.connect(func(): attack_issued.emit(self))


func take_damage():
	print_debug("enemy took damage")
	die()


func die():
	died.emit()
	stance_indicator.hide()
	var tween = create_tween()
	tween.tween_property(self, "rotation:x", -PI / 2.0, 0.3).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	await get_tree().create_timer(1.0).timeout
	queue_free()


func _tmp():
	# stm.smash_the_mesh()
	# _smash_mesh_impulse.call_deferred()
	# func _smash_mesh_impulse():
	# 	var pos = global_position
	# 	var callback = func(rb: RigidBody3D, _from):
	# 		var dir = (rb.global_position - pos).normalized()
	# 		var random = (Vector3(randf(), randf(), randf()) * 2.0 - Vector3.ONE).normalized()
	# 		rb.apply_impulse(dir * 2.0 + random * 0.5)
	# 		get_tree().create_timer(2.0).timeout.connect(rb.queue_free)
	# 	stm.chunks_iterate(callback)
	pass
