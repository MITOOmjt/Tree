extends Node2D

# 点击鸟获得的金币奖励（默认值）
var coin_reward = 1
# 预加载浮动文本场景
var floating_text_scene = preload("res://scene/floating_text.tscn")

func _ready():
	# 使鸟可点击
	set_process_input(true)
	
	# 从GameConfig加载配置
	_load_config()
	
	print("鸟已准备就绪，点击奖励:", coin_reward)

# 从GameConfig加载配置
func _load_config():
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		print("鸟执行_load_config()...")
		
		# 使用通用方法计算奖励值
		var old_reward = coin_reward
		coin_reward = game_config.calculate_generator_reward(game_config.GeneratorType.BIRD)
		
		# 获取调试信息
		var template = game_config.get_generator_template(game_config.GeneratorType.BIRD)
		var base_amount = template.generation.amount if template and template.generation.has("amount") else 0
		var efficiency_multiplier = game_config.get_ability_effect_multiplier(
			game_config.GeneratorType.BIRD, "efficiency")
		
		print("从GameConfig加载鸟点击金币奖励:", coin_reward,
			"(基础:", base_amount, "效率乘数:", efficiency_multiplier,
			"旧值:", old_reward, ")")
	else:
		print("GameConfig单例不可用，使用默认鸟点击配置")

func _input(event):
	# 只处理鼠标左键点击
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 获取鼠标位置（全局坐标）
		var mouse_pos = get_global_mouse_position()
		
		# 获取形状的全局坐标
		var shape_global_rect = Rect2($BirdShape.global_position - Vector2(15, 20), Vector2(30, 20))
		
		# 检查点击是否在形状内
		if _is_point_in_bird_shape(mouse_pos):
			# 每次点击前重新计算奖励值
			var game_config = get_node_or_null("/root/GameConfig")
			if game_config:
				coin_reward = game_config.calculate_generator_reward(game_config.GeneratorType.BIRD)
			
			print("点击了鸟，获得", coin_reward, "金币，配置的奖励值:", coin_reward)
			
			# 增加金币
			Global.add_coins(coin_reward)
			
			# 显示浮动文本效果
			spawn_floating_text(mouse_pos)
			
			# 显示消息
			if has_node("/root/MessageBus"):
				MessageBus.get_instance().emit_signal("show_message", "点击鸟获得" + str(coin_reward) + "金币！", 1)
			
			# 阻止事件传递
			get_viewport().set_input_as_handled()

# 生成浮动文本动画
func spawn_floating_text(position):
	var floating_text = floating_text_scene.instantiate()
	floating_text.position = position
	floating_text.text = "+" + str(coin_reward)
	
	# 添加到场景
	get_tree().get_root().add_child(floating_text)

# 检查点是否在鸟的三角形形状内
func _is_point_in_bird_shape(global_point):
	# 转换为局部坐标
	var local_point = to_local(global_point)
	
	# 获取三角形的三个顶点
	var a = Vector2(-15, 0)
	var b = Vector2(15, 0)
	var c = Vector2(0, -20)
	
	# 使用三角形点包含算法
	return _point_in_triangle(local_point, a, b, c)

# 判断点是否在三角形内
func _point_in_triangle(p, a, b, c):
	var d1 = _sign(p, a, b)
	var d2 = _sign(p, b, c)
	var d3 = _sign(p, c, a)
	
	var has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
	var has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
	
	return !(has_neg and has_pos)

# 计算点p到线段ab的有符号距离（用于三角形点包含算法）
func _sign(p, a, b):
	return (p.x - b.x) * (a.y - b.y) - (a.x - b.x) * (p.y - b.y) 
