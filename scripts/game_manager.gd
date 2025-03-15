extends Node

# 游戏货币
var coins = 0

# 信号
signal coins_changed(amount)

# 添加金币
func add_coins(amount):
	coins += amount
	emit_signal("coins_changed", coins)

# 消费金币
func spend_coins(amount):
	if coins >= amount:
		coins -= amount
		emit_signal("coins_changed", coins)
		return true
	return false 