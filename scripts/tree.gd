extends Node2D

# 确保Logger单例在编译时可见
@onready var _logger = get_node("/root/Logger")
@onready var tree_sprite = $TreeSprite

var bird_scene = preload("res://scene/bird.tscn")
var bird_cost = 10  # 生成鸟的成本

@onready var coin_timer = $CoinTimer

func _ready():
	_logger.info("树初始化，当前金币: %s", [Global.get_coins()])
	
	# 使用正确的信号连接方式
	$TreeShape.input_event.connect(_on_tree_input)
	_logger.debug("树的点击事件已连接")
	
	# 连接计时器的timeout信号
	coin_timer.timeout.connect(_on_coin_timer_timeout)
	_logger.debug("金币计时器已连接")
	
	# 设置树的纹理和缩放
	if tree_sprite:
		tree_sprite.texture = load("res://resource/tree.png")
		tree_sprite.scale = Vector2(0.2, 0.2)  # 调整大小适合场景
		_logger.info("已加载树木图片")

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

func _on_tree_input(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_logger.info("树被点击")
			_try_create_bird()

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
	# 从GameConfig获取生成金币的数量
	var game_config = get_node_or_null("/root/GameConfig")
	var amount = 1  # 默认值
	
	if game_config:
		amount = game_config.calculate_generator_reward(game_config.GeneratorType.TREE)
	
	# 生成金币
	Global.add_coins(amount)
	
	# 显示浮动文本
	var floating_text_scene = preload("res://scene/floating_text.tscn")
	if floating_text_scene:
		var floating_text = floating_text_scene.instantiate()
		floating_text.position = Vector2(0, -50)  # 在树上方显示
		floating_text.text = "+" + str(amount)
		add_child(floating_text)
	
	_logger.info("树生成了 %s 个金币" % [amount])

# 尝试创建一只鸟
func _try_create_bird():
	if Global.get_coins() >= bird_cost:
		# 从玩家金币中扣除成本
		if Global.spend_coins(bird_cost):
			_logger.info("成功支付 %s 金币创建鸟" % [bird_cost])
			
			# 创建一只鸟
			var bird = bird_scene.instantiate()
			
			# 设置鸟的位置（在树的上方随机位置）
			var random_x = randf_range(-30, 30)
			bird.position = Vector2(random_x, -80)
			
			# 将鸟添加为当前节点的子节点
			add_child(bird)
			
			_logger.info("鸟已创建在位置: %s" % [bird.position])
			
			# 显示消息
			MessageBus.get_instance().emit_signal("show_message", "成功创建一只鸟！", 2)
		else:
			_logger.error("扣除金币失败")
	else:
		_logger.warning("金币不足，需要 %s 金币，当前只有 %s 金币" % [bird_cost, Global.get_coins()])
		MessageBus.get_instance().emit_signal("show_message", "金币不足！需要 " + str(bird_cost) + " 金币", 2) 
