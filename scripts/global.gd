extends Node

signal coins_changed(amount: int)

var coins: int = 5  # 默认初始金币，如果GameConfig不可用

func _ready():
	# 尝试从GameConfig加载初始金币数量
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config and game_config.initial_config.has("starting_coins"):
		coins = game_config.initial_config.starting_coins
		print("从GameConfig加载初始金币数量: ", coins)
	else:
		print("使用默认初始金币数量: ", coins)
	
	# 初始化时发射信号
	emit_signal("coins_changed", coins)

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
