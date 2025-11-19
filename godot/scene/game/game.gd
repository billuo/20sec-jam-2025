class_name Game
extends Node3D

enum State {
	Init,
	Ready,
	InGame,
	Over,
	Aborted,
}

const TIME_LIMIT := 20.0
const TRANSITION_FADE_IN := 0.5
const TRANSITION_FADE_OUT := 0.5
const RESTART_HOLD_THRESHOLD := 0.5

static var state := State.Init

var restarting := false
var restart_held := 0.0
var time_left := TIME_LIMIT:
	set(value):
		time_left = value
		# update timer label
		time_left_label.text = "%.2f" % value
		const WARN_THRES := 10.0
		if time_left <= WARN_THRES:
			time_left_label.modulate = lerp(Color.WHITE, Color.RED, (time_left - WARN_THRES) / (1.0 - WARN_THRES))
var current_enemy: Enemy

@onready var time_left_label: Label = %TimeLeftLabel
@onready var player: Player = $Player


func _ready() -> void:
	%Transition.show()
	player.attack_issued.connect(_on_player_attack_issued)
	var tween = create_tween()
	tween.tween_property(%Transition, "modulate", Color(1.0, 1.0, 1.0, 0.0), TRANSITION_FADE_OUT).from(Color.WHITE)
	tween.finished.connect(func(): state = State.Ready)


func _process(delta: float) -> void:
	if state == State.InGame and time_left > 0:
		time_left = maxf(time_left - delta, 0.0)
		if time_left == 0.0:
			game_over(false)
	if restarting:
		if state == State.Over:
			restart()
		else:
			restart_held += delta
			if restart_held >= RESTART_HOLD_THRESHOLD:
				restart()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action(&"restart"):
		restarting = event.is_pressed()
		if not restarting:
			restart_held = 0.0


func restart():
	state = State.Aborted
	restart_held = 0.0
	%Transition.show()
	var tween = create_tween()
	tween.tween_property(%Transition, "modulate", Color.WHITE, TRANSITION_FADE_IN).from(Color(1.0, 1.0, 1.0, 0.0))
	await tween.finished
	get_tree().change_scene_to_packed(load("res://scene/game/game.tscn"))


func game_start():
	# TODO: show tutorial tips as game progresses, at least during first run
	print_debug("GAME START")
	state = State.InGame
	%HelpLabel.show()
	var tween = create_tween()
	tween.tween_property(%HelpLabel, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.0).from(Color.WHITE)
	tween.finished.connect(%HelpLabel.hide)
	get_tree().create_timer(1.0).timeout.connect(func(): spawn_enemy())


func spawn_enemy():
	if state != State.InGame:
		return
	if time_left <= 10.0:
		# TODO: boss
		pass
	var enemy: Enemy = preload("res://scene/enemy/enemy.tscn").instantiate()
	enemy.attack_issued.connect(_on_enemy_attack_issued)
	enemy.died.connect(func(): get_tree().create_timer(0.5).timeout.connect(func(): spawn_enemy()))
	var pos = Vector3(randf_range(-1.0, 1.0), 0.0, -5.0)
	var dir_xz = (Vector3(player.position.x, 0.0, player.position.z) - pos).normalized()
	enemy.position = pos
	enemy.target_position = Vector3(player.position.x, 0.0, player.position.z) - dir_xz * 1.5
	enemy.look_at_from_position(pos, player.position)
	add_child(enemy)
	current_enemy = enemy


func game_over(player_died: bool):
	if state == State.Over:
		return
	state = State.Over
	if player_died:
		await get_tree().create_timer(1.0).timeout
		%DeathMessage.show()
		var tween = create_tween()
		tween.tween_property(%DeathMessage, "modulate", Color.WHITE, 2.0).from(Color(1.0, 1.0, 1.0, 0.0))
		tween.finished.connect(func(): %GameRestartLabel.show())
		$SFX/GameOver.play()
	else:
		for child in get_children():
			if child is Enemy:
				child.die()
		await get_tree().create_timer(1.0).timeout
		%WinMessage.show()
		var tween = create_tween()
		tween.tween_property(%WinMessage, "modulate", Color.WHITE, 2.0).from(Color(1.0, 1.0, 1.0, 0.0))
		tween.finished.connect(func(): %GameRestartLabel.show())
		$SFX/YouWin.play()


func _on_game_start_label_start_requested() -> void:
	if state == State.Ready:
		game_start()


func _on_enemy_attack_issued(enemy: Enemy) -> void:
	player.check_guard(enemy)


func _on_player_attack_issued() -> void:
	if not current_enemy:
		return
	if current_enemy.can_take_damage():
		# TODO: player swing weapon
		current_enemy.take_damage()


func _on_player_died() -> void:
	game_over(true)
