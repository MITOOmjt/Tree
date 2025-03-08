extends Node2D

var bird_scene = preload("res://bird.tscn")
var bird_cost = 10  # 生成鸟的成本

@onready var coin_timer = $CoinTimer
@onready var tree_button = $TreeButton

# 设置为可点击
func _ready():
	print("简化树初始化，当前金币: ", Global.get_coins())
	
	# 确保按钮可点击
	tree_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 多种方式连接点击事件
	tree_button.pressed.connect(_on_tree_button_pressed)
	tree_button.gui_input.connect(_on_tree_gui_input)
	print("树按钮点击事件已连接")
	
	# 连接计时器的timeout信号
	coin_timer.timeout.connect(_on_coin_timer_timeout)
	print("金币计时器已连接")

# 直接处理输入事件，作为备选方案
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("全局点击事件")
		var global_pos = get_global_mouse_position()
		var local_pos = to_local(global_pos)
		
		# 简单的点击检测，检查是否在树的范围内
		var in_tree_shape = (local_pos.y < 0 and local_pos.y > -120 and 
							abs(local_pos.x) < 60)
		var in_trunk = (local_pos.y >= 0 and local_pos.y <= 50 and 
						abs(local_pos.x) < 10)
		
		if in_tree_shape or in_trunk:
			print("全局检测到点击在树上")
			_handle_bird_creation(local_pos)
			get_viewport().set_input_as_handled()

# GUI输入处理
func _on_tree_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("GUI输入：树被点击了！")
		var local_pos = get_local_mouse_position()
		_handle_bird_creation(local_pos)

# 按钮点击事件
func _on_tree_button_pressed():
	print("按钮点击：树被点击了！")
	var local_pos = get_local_mouse_position()
	_handle_bird_creation(local_pos)

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