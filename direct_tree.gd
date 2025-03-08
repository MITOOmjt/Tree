extends Node2D

var bird_scene = preload("res://bird.tscn")
var bird_cost = 10  # 生成鸟的成本

@onready var coin_timer = $CoinTimer
@onready var click_area = $ClickArea

func _ready():
	print("直接实现树初始化，当前金币: ", Global.get_coins())
	
	# 连接区域输入事件
	click_area.input_event.connect(_on_click_area_input_event)
	print("区域点击事件已连接")
	
	# 连接计时器的timeout信号
	coin_timer.timeout.connect(_on_coin_timer_timeout)
	print("金币计时器已连接")

# 重写 _input 方法直接处理点击
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var global_pos = event.global_position
		var local_pos = to_local(global_pos)
		
		# 检查是否点击在树区域内
		if _is_point_in_tree(local_pos):
			print("全局检测到直接点击在树上")
			_handle_bird_creation(local_pos)
			get_viewport().set_input_as_handled()

# 区域点击检测
func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("区域检测到点击")
		var local_pos = get_local_mouse_position()
		_handle_bird_creation(local_pos)

# 检查点是否在树区域内
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

# 处理鸟的创建逻辑
func _handle_bird_creation(position):
	print("尝试创建鸟，位置：", position)
	if Global.spend_coins(bird_cost):
		print("成功消费金币，剩余: ", Global.get_coins())
		var bird = bird_scene.instantiate()
		add_child(bird)
		bird.position = position
		
		# 发送成功消息
		MessageBus.get_instance().emit_signal("show_message", "成功生成一只鸟！", 2)
	else:
		# 显示提示消息
		print("金币不足！需要 ", bird_cost, " 金币，当前只有 ", Global.get_coins(), " 金币")
		
		# 发送失败消息
		MessageBus.get_instance().emit_signal("show_message", "金币不足！需要 " + str(bird_cost) + " 金币", 2)

func _on_coin_timer_timeout():
	# 每次计时器超时时增加1金币
	Global.add_coins(1)
	print("树产生1金币，当前总金币: ", Global.get_coins()) 