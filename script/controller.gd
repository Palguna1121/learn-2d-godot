extends Node

var coin: int = 0

signal my_coin(coin: int)

func add_coin() -> void:
	coin += 1
	emit_signal("my_coin", coin)

func reset_coin() -> void:
	coin = 0
	emit_signal("my_coin", coin)
	
func dead() -> void:
	reset_coin()
	get_tree().reload_current_scene()
