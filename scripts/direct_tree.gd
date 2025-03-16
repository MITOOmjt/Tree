extends Node2D

# 树每次产生金币数量（默认值）
var coin_generation_amount = 1

@onready var coin_timer = $CoinTimer
@onready var click_area = $ClickArea

func _ready():
	print("直接实现树初始化，当前金币: ", Global.get_coins())
	
	# 连接计时器的timeout信号
	coin_timer.timeout.connect(_on_coin_timer_timeout)
	
	# 尝试从GameConfig加载配置
	_load_config()
	
	print("金币计时器已连接，产生金币:", coin_generation_amount, "，间隔:", coin_timer.wait_time, "秒")

# 从GameConfig加载配置
func _load_config():
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		# 加载树产生金币数量
		if game_config.coin_generation.has("tree_coin_generation"):
			coin_generation_amount = game_config.coin_generation.tree_coin_generation
			print("从GameConfig加载树产生金币量:", coin_generation_amount)
		
		# 加载树产生金币间隔
		if game_config.coin_generation.has("tree_coin_interval"):
			coin_timer.wait_time = game_config.coin_generation.tree_coin_interval
			print("从GameConfig加载树产生金币间隔:", coin_timer.wait_time)
	else:
		print("GameConfig单例不可用，使用默认配置")

# 检查点是否在树区域内（保留此函数供背景管理器调用）
func _is_point_in_tree(point: Vector2) -> bool:
	# 简单的点包含检测 - 三角形区域 + 矩形树干
	var in_triangle = _is_point_in_triangle(point, 
		Vector2(-50, 0), Vector2(50, 0), Vector2(0, -100))
	
	var in_trunk = (point.y >= 0 and point.y <= 50 and 
					abs(point.x) <= 10)
	
	return in_triangle or in_trunk

# 点在三角形中的检测
func _is_point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var area = 0.5 * (-b.y * c.x + a.y * (-b.x + c.x) + a.x * (b.y - c.y) + b.x * c.y)
	var s = 1.0 / (2.0 * area) * (a.y * c.x - a.x * c.y + (c.y - a.y) * p.x + (a.x - c.x) * p.y)
	var t = 1.0 / (2.0 * area) * (a.x * b.y - a.y * b.x + (a.y - b.y) * p.x + (b.x - a.x) * p.y)
	
	return s >= 0 and t >= 0 and (s + t) <= 1

func _on_coin_timer_timeout():
	# 每次计时器超时时增加配置的金币数量
	Global.add_coins(coin_generation_amount)
	print("树产生", coin_generation_amount, "金币，当前总金币: ", Global.get_coins()) 
