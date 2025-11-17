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

static var state := State.Init

var time_left := TIME_LIMIT:
	set(value):
		time_left = value
		# update timer label
		time_left_label.text = "%.2f" % value
		const WARN_THRES := 10.0
		if time_left <= WARN_THRES:
			time_left_label.modulate = lerp(Color.WHITE, Color.RED, (time_left - WARN_THRES) / (1.0 - WARN_THRES))

@onready var time_left_label: Label = %TimeLeftLabel
@onready var player: Player = $Player


func _ready() -> void:
	%Transition.show()
	var tween = create_tween()
	tween.tween_property(%Transition, "modulate", Color(1.0, 1.0, 1.0, 0.0), TRANSITION_FADE_OUT).from(Color.WHITE)
	tween.finished.connect(func(): state = State.Ready)


func _process(delta: float) -> void:
	if state == State.InGame and time_left > 0:
		time_left = maxf(time_left - delta, 0.0)
		if time_left == 0.0:
			game_over(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart"):
		restart()


func restart():
	state = State.Aborted
	%Transition.show()
	var tween = create_tween()
	tween.tween_property(%Transition, "modulate", Color.WHITE, TRANSITION_FADE_IN).from(Color(1.0, 1.0, 1.0, 0.0))
	await tween.finished
	get_tree().change_scene_to_packed(load("res://scene/game/game.tscn"))


func game_start():
	print_debug("GAME START")
	state = State.InGame
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
	# TODO: enemies should approach from various directions
	enemy.position = Vector3(0.0, 0.0, -5.0)
	add_child(enemy)


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


func _on_player_died() -> void:
	game_over(true)
