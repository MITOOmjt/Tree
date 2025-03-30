extends Node2D

# 确保Logger单例在编译时可见
@onready var _logger = get_node("/root/Logger")

# 点击鸟获得的金币奖励（默认值）
var coin_reward = 1
# 预加载浮动文本场景
var floating_text_scene = preload("res://scene/floating_text.tscn")

func _ready():
	# 设置Area2D点击事件
	if $ClickArea:
		# 确保先断开所有可能的旧连接，避免重复连接
		if $ClickArea.input_event.is_connected(_on_click_area_input_event):
			$ClickArea.input_event.disconnect(_on_click_area_input_event)
		
		# 确保区域可点击
		$ClickArea.input_pickable = true
		
		# 设置监听优先级和碰撞属性
		$ClickArea.set_process_priority(100) # 设置更高的处理优先级
		$ClickArea.collision_layer = 1  # 设置碰撞层
		$ClickArea.collision_mask = 1   # 设置碰撞掩码
		$ClickArea.monitoring = true    # 启用监控
		$ClickArea.monitorable = true   # 可被监控
		
		# 重新连接信号
		$ClickArea.input_event.connect(_on_click_area_input_event)
		_logger.info("鸟的点击区域初始化成功: input_pickable=%s, 碰撞形状半径=%s, 处理优先级=%s, 碰撞层=%s, 监控=%s" % [
			$ClickArea.input_pickable,
			$ClickArea/CollisionShape2D.shape.radius if $ClickArea/CollisionShape2D else "未知",
			$ClickArea.get_process_priority(),
			$ClickArea.collision_layer,
			$ClickArea.monitoring
		])
	else:
		_logger.error("鸟的点击区域(ClickArea)不存在!")
	
	# 从GameConfig加载配置
	_load_config()
	
	_logger.info("鸟已准备就绪，点击奖励: %s" % [coin_reward])

# 从GameConfig加载配置
func _load_config():
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		_logger.debug("鸟执行_load_config()...")
		
		# 使用通用方法计算奖励值
		var old_reward = coin_reward
		coin_reward = game_config.calculate_generator_reward(game_config.GeneratorType.BIRD)
		
		# 获取调试信息
		var template = game_config.get_generator_template(game_config.GeneratorType.BIRD)
		var base_amount = template.generation.amount if template and template.generation.has("amount") else 0
		var efficiency_multiplier = game_config.get_ability_effect_multiplier(
			game_config.GeneratorType.BIRD, "efficiency")
		
		_logger.debug("从GameConfig加载鸟点击金币奖励: %s (基础: %s, 效率乘数: %s, 旧值: %s)" % [
			coin_reward,
			base_amount,
			efficiency_multiplier,
			old_reward
		])
	else:
		_logger.warning("GameConfig单例不可用，使用默认鸟点击配置")

# 处理Area2D的点击事件
func _on_click_area_input_event(_viewport, event, _shape_idx):
	# 添加更详细的调试输出
	if event is InputEventMouseButton:
		_logger.debug("鸟接收到鼠标事件: 按下=%s, 按钮=%s, 位置=%s" % [event.pressed, event.button_index, event.position])
	
	# 只处理鼠标左键点击
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_logger.info("点击鸟事件触发成功!")
		
		# 每次点击前重新计算奖励值
		var game_config = get_node_or_null("/root/GameConfig")
		if game_config:
			coin_reward = game_config.calculate_generator_reward(game_config.GeneratorType.BIRD)
		
		_logger.info("点击了鸟，尝试获得 %s 金币" % [coin_reward])
		
		# 记录点击前的金币数量
		var before_coins = Global.get_coins()
		
		# 增加金币
		Global.add_coins(coin_reward)
		
		# 记录点击后的金币数量并验证是否增加
		var after_coins = Global.get_coins()
		_logger.info("金币变化: %s -> %s (增加: %s)" % [before_coins, after_coins, after_coins - before_coins])
		
		# 显示浮动文本效果
		spawn_floating_text(get_global_mouse_position())
		
		# 显示消息
		if has_node("/root/MessageBus"):
			MessageBus.get_instance().emit_signal("show_message", "点击鸟获得" + str(coin_reward) + "金币！", 1)
		
		# 阻止事件传递
		get_viewport().set_input_as_handled()

# 添加临时调试功能
func _input(event):
	# 按下F6键时检查点击区域状态
	if event is InputEventKey and event.pressed and event.keycode == KEY_F6:
		debug_click_area()
		
		# 检查鼠标位置是否在点击区域内
		var mouse_pos = get_viewport().get_mouse_position()
		var local_pos = $ClickArea.to_local(mouse_pos)
		var in_area = false
		if $ClickArea/CollisionShape2D and $ClickArea/CollisionShape2D.shape:
			# 使用不同的方法检测点是否在圆形内
			var shape_radius = $ClickArea/CollisionShape2D.shape.radius
			in_area = local_pos.length() <= shape_radius
		
		_logger.info("调试信息: 鼠标位置=%s, 本地位置=%s, 在区域内=%s" % [
			mouse_pos, 
			local_pos,
			in_area
		])

# 如果需要，我们可以作为备选添加一个直接的点击处理
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 获取鸟精灵的全局位置和尺寸
		var sprite = $BirdSprite
		if sprite and sprite.texture:
			var sprite_global_pos = sprite.global_position
			var sprite_size = sprite.texture.get_size() * sprite.scale
			
			# 创建一个矩形区域表示精灵的实际视觉范围
			var sprite_rect = Rect2(
				sprite_global_pos - sprite_size/2,  # 左上角位置
				sprite_size                          # 尺寸
			)
			
			# 检查点击是否在精灵的矩形区域内
			if sprite_rect.has_point(event.position):
				_logger.info("增强版检测: 通过精灵矩形区域检测到鸟被点击: 点击位置=%s, 精灵位置=%s, 精灵尺寸=%s" % [
					event.position,
					sprite_global_pos,
					sprite_size
				])
				_handle_bird_click()
				get_viewport().set_input_as_handled()
				return
		
		# 如果矩形检测不成功，再尝试使用圆形区域检测
		var distance = event.position.distance_to(global_position + Vector2(0, -16)) # 修正为鸟的实际位置
		if distance < 25:  # 与碰撞形状半径相同
			_logger.info("备选方案: 通过圆形区域检测到鸟被点击: 点击位置=%s, 距离=%s, 阈值=25" % [
				event.position,
				distance
			])
			_handle_bird_click()
			get_viewport().set_input_as_handled()

# 抽取点击处理逻辑到单独函数
func _handle_bird_click():
	# 每次点击前重新计算奖励值
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		coin_reward = game_config.calculate_generator_reward(game_config.GeneratorType.BIRD)
	
	_logger.info("点击了鸟，获得 %s 金币" % [coin_reward])
	
	# 增加金币
	Global.add_coins(coin_reward)
	
	# 显示浮动文本效果
	spawn_floating_text(get_global_mouse_position())
	
	# 显示消息
	if has_node("/root/MessageBus"):
		MessageBus.get_instance().emit_signal("show_message", "点击鸟获得" + str(coin_reward) + "金币！", 1)

# 生成浮动文本动画
func spawn_floating_text(position):
	var floating_text = floating_text_scene.instantiate()
	floating_text.position = position
	floating_text.text = "+" + str(coin_reward)
	
	# 添加到场景
	get_tree().get_root().add_child(floating_text)

# 额外添加一个用于调试的函数，可以直接在编辑器中通过远程标签调用
func debug_click_area():
	if $ClickArea:
		_logger.info("点击区域调试信息: input_pickable=%s, 碰撞形状=%s" % [
			$ClickArea.input_pickable,
			$ClickArea/CollisionShape2D.shape if $ClickArea/CollisionShape2D else "无碰撞形状"
		])
		return true
	else:
		_logger.error("点击区域不存在")
		return false

# 不再需要这些三角形点击检测函数
# 由Area2D和CollisionShape2D自动处理点击检测 
