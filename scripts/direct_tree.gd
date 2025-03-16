extends Node2D

@onready var coin_timer = $CoinTimer
@onready var click_area = $ClickArea

func _ready():
	print("直接实现树初始化，当前金币: ", Global.get_coins())
	
	# 连接计时器的timeout信号
	coin_timer.timeout.connect(_on_coin_timer_timeout)
	print("金币计时器已连接")

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
	# 每次计时器超时时增加1金币
	Global.add_coins(1)
	print("树产生1金币，当前总金币: ", Global.get_coins()) 
