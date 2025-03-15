extends Node2D

var bird_scene = preload("res://scene/bird.tscn")
var bird_cost = 10  # 生成鸟的成本

@onready var coin_timer = $CoinTimer

func _ready():
	print("树初始化，当前金币: ", Global.get_coins())
	
	# 使用正确的信号连接方式
	$TreeShape.connect("input_event", _on_tree_input)
	print("树的点击事件已连接")
	
	# 连接计时器的timeout信号
	coin_timer.connect("timeout", _on_coin_timer_timeout)
	print("金币计时器已连接")

# 添加处理所有输入的备用方法
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("收到全局点击")
		# 检查是否点击在树上
		var mouse_pos = get_global_mouse_position()
		var local_pos = to_local(mouse_pos)
		print("全局位置: ", mouse_pos, " 局部位置: ", local_pos)
		
		# 手动检查点击是否在树的范围内
		# 这是一个简单的碰撞检测，可以根据实际情况调整
		var tree_shape = $TreeShape/CollisionShape2D.shape
		var shape_pos = $TreeShape/CollisionShape2D.global_position
		
		# 简单判断是否在三角形区域内
		if local_pos.y < 0 and abs(local_pos.x) < 60 and local_pos.y > -120:
			print("点击在树上")
			_handle_bird_creation(local_pos)

func _on_tree_input(_viewport, event, _shape_idx):
	print("TreeShape收到输入事件类型: ", event.get_class())
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Area2D检测到点击树，尝试花费 ", bird_cost, " 金币")
		_handle_bird_creation(get_local_mouse_position())

# 抽取创建鸟的逻辑到单独的函数
func _handle_bird_creation(position):
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
