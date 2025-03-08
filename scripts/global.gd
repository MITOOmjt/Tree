extends Node

signal coins_changed(amount: int)

var coins: int = 20  # 初始金币，给玩家一些起始资金

func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("coins_changed", coins)
	
func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		emit_signal("coins_changed", coins)
		return true
	return false
	
func get_coins() -> int:
	return coins 