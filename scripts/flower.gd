extends Node2D

var colors = [
	Color(1, 0, 0, 1),   # 红色
	Color(1, 0.5, 0, 1), # 橙色
	Color(1, 1, 0, 1),   # 黄色
	Color(0, 1, 0, 1),   # 绿色
	Color(0, 0, 1, 1),   # 蓝色
	Color(0.5, 0, 0.5, 1), # 紫色
	Color(1, 0, 1, 1),   # 粉色
]

# 预加载浮动文本场景
var floating_text_scene = preload("res://scene/floating_text.tscn")
# 鼠标悬停获得金币的量（默认值，会尝试从GameConfig加载）
var hover_coin_reward = 2  # 默认悬停金币奖励
# 悬停冷却计时器
var hover_cooldown = 0  # 当前冷却计时
# 悬停冷却时间（秒）（默认值，会尝试从GameConfig加载）
var hover_cooldown_time = 1.5  # 默认悬停冷却时间(秒)
# 是否正在悬停
var is_hovering = false
# 碰撞检测半径
var detection_radius = 25.0
# 冷却可视节点
var cooldown_visual = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# 随机选择一种颜色
	var random_color = colors[randi() % colors.size()]
	$Polygon2D.color = random_color
	
	# 确保启用处理和输入处理
	set_process(true)
	set_process_input(true)
	
	# 创建冷却可视节点（如果不存在）
	if not has_node("CooldownVisual"):
		cooldown_visual = ColorRect.new()
		cooldown_visual.name = "CooldownVisual"
		cooldown_visual.color = Color(0.2, 0.2, 0.2, 0.5)  # 半透明灰色
		cooldown_visual.size = Vector2(30, 30)
		cooldown_visual.position = Vector2(-15, -15)  # 居中
		cooldown_visual.visible = false
		add_child(cooldown_visual)
	else:
		cooldown_visual = $CooldownVisual
	
	# 确保区域检测正常
	if has_node("Area2D"):
		$Area2D.connect("mouse_entered", Callable(self, "_on_area_2d_mouse_entered"))
		$Area2D.connect("mouse_exited", Callable(self, "_on_area_2d_mouse_exited"))
		print("为Area2D连接了鼠标信号")
	
	# 尝试从GameConfig加载配置
	_load_config()
	
	print("花已准备就绪，悬停奖励:", hover_coin_reward, "，冷却时间:", hover_cooldown_time, "秒")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# 计算冷却时间
	if hover_cooldown > 0:
		hover_cooldown -= delta
		
		# 更新可视化冷却指示器
		if cooldown_visual:
			cooldown_visual.visible = hover_cooldown > 0
			var scale_factor = hover_cooldown / hover_cooldown_time
			cooldown_visual.scale = Vector2(scale_factor, scale_factor)
	
	# 检查鼠标是否悬停在花朵上
	_check_mouse_hover()
	
	# 如果正在悬停且冷却结束，给予金币奖励
	if is_hovering and hover_cooldown <= 0:
		_give_hover_reward()
		hover_cooldown = hover_cooldown_time
		print("花朵悬停奖励触发，设置冷却时间:", hover_cooldown_time)

# 处理鼠标输入
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 获取鼠标位置
		var mouse_pos = get_global_mouse_position()
		
		# 检查点击是否在花朵范围内
		var distance = global_position.distance_to(mouse_pos)
		if distance <= detection_radius:
			# 点击花朵时增加金币
			Global.add_coins(1)
			print("点击花朵，增加1金币")
			
			# 显示浮动文本
			var floating_text = floating_text_scene.instantiate()
			floating_text.position = mouse_pos
			floating_text.text = "+1"
			get_tree().get_root().add_child(floating_text)

# 检查鼠标是否悬停在花朵上
func _check_mouse_hover():
	# 获取鼠标位置
	var mouse_pos = get_global_mouse_position()
	
	# 计算距离
	var distance = global_position.distance_to(mouse_pos)
	
	# 更新悬停状态
	var was_hovering = is_hovering
	is_hovering = distance <= detection_radius
	
	# 状态变化时执行相应操作
	if is_hovering and not was_hovering:
		_on_mouse_entered()
	elif not is_hovering and was_hovering:
		_on_mouse_exited()

# 给予悬停奖励
func _give_hover_reward():
	# 每次给予奖励前重新计算奖励值
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		hover_coin_reward = game_config.calculate_generator_reward(game_config.GeneratorType.FLOWER)
	
	# 增加金币
	Global.add_coins(hover_coin_reward)
	
	# 获取调试信息
	var debug_multiplier = 1.0
	if game_config:
		debug_multiplier = game_config.get_ability_effect_multiplier(
			game_config.GeneratorType.FLOWER, "efficiency")
	
	print("花产生", hover_coin_reward, "金币！当前总金币:", Global.get_coins(), 
		"，奖励配置值:", hover_coin_reward,
		"，效率乘数:", debug_multiplier,
		"，当前花朵设置:", self.hover_coin_reward)
	
	# 在花的位置显示浮动文本
	var floating_text = floating_text_scene.instantiate()
	floating_text.position = global_position + Vector2(0, -20)  # 在花朵上方显示
	floating_text.text = "+" + str(hover_coin_reward)
	get_tree().get_root().add_child(floating_text)
	
	# 让花朵轻微抖动作为视觉反馈
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	# 显示消息
	if has_node("/root/MessageBus"):
		MessageBus.get_instance().emit_signal("show_message", "鼠标悬停在花上获得" + str(hover_coin_reward) + "金币！", 1)

# 鼠标进入花朵区域
func _on_mouse_entered():
	# 鼠标形状变为手形
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	print("鼠标进入花朵区域")

# 鼠标离开花朵区域
func _on_mouse_exited():
	# 恢复默认鼠标形状
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	print("鼠标离开花朵区域")

# 保留原来的信号回调，但重定向到新的函数
func _on_area_2d_mouse_entered():
	print("收到Area2D鼠标进入信号")
	_on_mouse_entered()

func _on_area_2d_mouse_exited():
	print("收到Area2D鼠标离开信号")
	_on_mouse_exited()

# 从GameConfig加载配置
func _load_config():
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		print("花朵执行_load_config()...")
		
		# 使用通用方法计算奖励值
		var old_reward = hover_coin_reward
		hover_coin_reward = game_config.calculate_generator_reward(game_config.GeneratorType.FLOWER)
		
		# 获取调试信息
		var template = game_config.get_generator_template(game_config.GeneratorType.FLOWER)
		var base_amount = template.generation.amount if template and template.generation.has("amount") else 0
		var efficiency_multiplier = game_config.get_ability_effect_multiplier(
			game_config.GeneratorType.FLOWER, "efficiency")
		
		print("从GameConfig加载花悬停金币奖励:", hover_coin_reward,
			"(基础:", base_amount, "效率乘数:", efficiency_multiplier, 
			"旧值:", old_reward, ")")
		
		# 处理冷却时间
		if template and template.generation.has("cooldown"):
			var base_cooldown = template.generation.cooldown
			var cooldown_multiplier = game_config.get_ability_effect_multiplier(
				game_config.GeneratorType.FLOWER, "cooldown")
			
			var old_cooldown = hover_cooldown_time
			hover_cooldown_time = base_cooldown / cooldown_multiplier
			
			print("从GameConfig加载花悬停冷却时间:", hover_cooldown_time,
				"(基础:", base_cooldown, "冷却乘数:", cooldown_multiplier,
				"旧值:", old_cooldown, ")")
	else:
		print("GameConfig单例不可用，使用默认花悬停配置") 
