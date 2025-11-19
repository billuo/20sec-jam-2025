extends Node3D


func activate(stance: Player.Stance):
	show()
	$Active.frame = int(stance)
