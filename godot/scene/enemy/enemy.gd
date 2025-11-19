class_name Enemy
extends Node3D

signal attack_issued(enemy: Enemy)
signal died

enum State {
	Init,
	Approaching,
	Ready,
	Attacking,
	Stun,
	Dead,
	Idle,
}

var state_enter_time: float = 0.0
var state := State.Init:
	set(value):
		print_debug("enemy state -> %s" % State.keys()[value])
		state = value
		state_enter_time = Time.get_ticks_msec() / 1000.0
		match state:
			State.Approaching:
				ap.play(&"Walk")
			State.Ready:
				ap.play(&"Sword_Idle")
				randomize_stance()
				stance_idc.activate(stance)
			State.Attacking:
				ap.play(&"Sword_Attack")
			State.Stun:
				ap.play(&"Idle")
			State.Dead:
				ap.play(&"Death01")
				died.emit()
			State.Idle:
				ap.play(&"Idle")
		stance_idc.visible = state == State.Ready or state == State.Attacking
		$StunIndicator.visible = state == State.Stun
var target_position: Vector3
var stance := Player.Stance.None
var walk_speed := 3.0
var health := 4

@onready var stance_idc: Node3D = $StanceIndicator
@onready var ap: AnimationPlayer = $Node3D/Mannequin/AnimationPlayer


func _ready() -> void:
	state = State.Approaching


func _process(delta: float) -> void:
	match state:
		State.Approaching:
			position = position.move_toward(target_position, walk_speed * delta)
			if position == target_position:
				state = State.Ready
		State.Ready:
			if time_since_current_state() >= 0.25:
				state = State.Attacking
		State.Attacking:
			if time_since_current_state() >= 0.45:
				attack_issued.emit(self)
		State.Stun:
			if time_since_current_state() >= 1.0:
				state = State.Ready
				randomize_stance()
				stance_idc.activate(stance)
		State.Dead:
			pass


func randomize_stance():
	stance = [Player.Stance.Left, Player.Stance.Up, Player.Stance.Right].pick_random()


func time_since_current_state() -> float:
	return Time.get_ticks_msec() / 1000.0 - state_enter_time


func can_take_damage():
	if state == State.Stun:
		return time_since_current_state() >= 0.2
	if state == State.Dead:
		return time_since_current_state() <= 0.5
	return false


func take_damage():
	# TODO: shake $Node3D a bit
	# TODO: floating damage number...?
	const VFX_SLASH := preload("res://scene/enemy/vfx_slash.tscn")
	health -= 1
	$SFX/SwordSlash.play()
	var vfx = VFX_SLASH.instantiate()
	add_child(vfx)
	vfx.position = stance_idc.position
	vfx.rotation_degrees.z = randf_range(-90.0, 90.0)
	if state != State.Dead and health <= 0:
		die()


func die():
	state = State.Dead
	await ap.animation_finished
	var tween = create_tween()
	tween.tween_property(self, "position", position - Vector3(0.0, 1.0, 0.0), 1.0)
	await tween.finished
	queue_free()
