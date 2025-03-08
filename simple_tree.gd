extends Node2D

var bird_scene = preload("res://bird.tscn")
var bird_cost = 10  # 生成鸟的成本

@onready var coin_timer = $CoinTimer
@onready var tree_button = $TreeButton

func _ready():
	print("简化树初始化，当前金币: ", Global.get_coins())
	
	# 连接按钮点击信号
	tree_button.pressed.connect(_on_tree_button_pressed)
	print("树按钮点击事件已连接")
	
	# 连接计时器的timeout信号
	coin_timer.timeout.connect(_on_coin_timer_timeout)
	print("金币计时器已连接")

func _on_tree_button_pressed():
	print("按钮点击：树被点击了！")
	
	# 获取鼠标相对于树的位置
	var local_pos = get_local_mouse_position()
	print("点击位置：", local_pos)
	
	# 尝试生成鸟
	if Global.spend_coins(bird_cost):
		print("成功消费金币，剩余: ", Global.get_coins())
		var bird = bird_scene.instantiate()
		add_child(bird)
		bird.position = local_pos
		
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