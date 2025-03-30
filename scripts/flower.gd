extends Node2D

# 确保Logger单例在编译时可见
@onready var _logger = get_node("/root/Logger")

var colors = [
	Color(1, 0, 0, 1),   # 红色
	Color(1, 0.5, 0, 1), # 橙色
	Color(1, 1, 0, 1),   # 黄色
	Color(0, 1, 0, 1),   # 绿色
	Color(0, 0, 1, 1),   # 蓝色
	Color(0.5, 0, 0.5, 1), # 紫色
	Color(1, 0, 1, 1),   # 粉色
]

# Ghibli风格的柔和颜色
var ghibli_colors = [
	Color(0.95, 0.8, 0.8),  # 淡粉色
	Color(0.9, 0.9, 0.7),   # 淡黄色
	Color(0.8, 0.9, 0.8),   # 淡绿色
	Color(0.85, 0.75, 0.9), # 淡紫色
	Color(0.75, 0.85, 0.9)  # 淡蓝色
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
# 是否处于冷却状态
var is_on_cooldown = false
# 碰撞检测半径
var detection_radius = 25.0
# 冷却可视节点
var cooldown_visual = null
# 花朵精灵
var sprite = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# 使用Ghibli风格的颜色
	var random_color = ghibli_colors[randi() % ghibli_colors.size()]
	$Polygon2D.color = random_color
	
	# 保存对花朵精灵的引用
	sprite = $Polygon2D
	
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
		_logger.debug("为Area2D连接了鼠标信号")
	
	# 尝试从GameConfig加载配置
	_load_config()
	
	_logger.info("花已准备就绪，悬停奖励: %s，冷却时间: %s 秒" % [hover_coin_reward, hover_cooldown_time])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# 计算冷却时间
	if hover_cooldown > 0:
		hover_cooldown -= delta
		is_on_cooldown = hover_cooldown > 0
		
		# 更新可视化冷却指示器
		if cooldown_visual:
			cooldown_visual.visible = is_on_cooldown
			var scale_factor = hover_cooldown / hover_cooldown_time
			cooldown_visual.scale = Vector2(scale_factor, scale_factor)
			
		# 冷却结束时
		if hover_cooldown <= 0 and is_on_cooldown:
			is_on_cooldown = false
			_on_hover_cooldown_timeout()
	
	# 检查鼠标是否悬停在花朵上
	_check_mouse_hover()
	
	# 如果正在悬停且冷却结束，给予金币奖励
	if is_hovering and hover_cooldown <= 0:
		_give_hover_reward()
		hover_cooldown = hover_cooldown_time
		is_on_cooldown = true
		_logger.debug("花朵悬停奖励触发，设置冷却时间: %s" % [hover_cooldown_time])

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
			_logger.debug("点击花朵，增加1金币")
			
			# 显示Ghibli风格的点击效果
			_show_click_effect()

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
	
	_logger.info("花产生 %s 金币！当前总金币: %s，效率乘数: %s" % [
		hover_coin_reward, 
		Global.get_coins(), 
		debug_multiplier
	])
	
	# 显示Ghibli风格的奖励效果
	_show_reward_effect(hover_coin_reward)
	
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
	
	# Ghibli风格的悬停效果
	if sprite and not is_on_cooldown:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.05, 1.05), 0.2)
		
		# 添加轻微发光效果
		var glow = ColorRect.new()
		glow.name = "HoverGlow"
		glow.color = Color(1, 1, 0.8, 0.2)  # 温暖的黄色光晕
		glow.size = Vector2(60, 60)
		glow.position = Vector2(-30, -30)  # 居中
		glow.z_index = -1  # 确保在花朵后面
		add_child(glow)
	
	_logger.debug("鼠标进入花朵区域")

# 鼠标离开花朵区域
func _on_mouse_exited():
	# 恢复默认鼠标形状
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	# 恢复正常大小
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)
		
	# 移除悬停光晕
	if has_node("HoverGlow"):
		var glow = get_node("HoverGlow")
		var tween = create_tween()
		tween.tween_property(glow, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_callback(glow.queue_free)
	
	_logger.debug("鼠标离开花朵区域")

# 保留原来的信号回调，但重定向到新的函数
func _on_area_2d_mouse_entered():
	_logger.debug("收到Area2D鼠标进入信号")
	_on_mouse_entered()

func _on_area_2d_mouse_exited():
	_logger.debug("收到Area2D鼠标离开信号")
	_on_mouse_exited()

# 从GameConfig加载配置
func _load_config():
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		_logger.debug("花朵执行_load_config()...")
		
		# 使用通用方法计算奖励值
		var old_reward = hover_coin_reward
		hover_coin_reward = game_config.calculate_generator_reward(game_config.GeneratorType.FLOWER)
		
		# 获取调试信息
		var template = game_config.get_generator_template(game_config.GeneratorType.FLOWER)
		var base_amount = template.generation.amount if template and template.generation.has("amount") else 0
		var efficiency_multiplier = game_config.get_ability_effect_multiplier(
			game_config.GeneratorType.FLOWER, "efficiency")
		
		_logger.debug("从GameConfig加载花悬停金币奖励: %s (基础: %s, 效率乘数: %s, 旧值: %s)" % [
			hover_coin_reward,
			base_amount,
			efficiency_multiplier,
			old_reward
		])
		
		# 处理冷却时间
		if template and template.generation.has("cooldown"):
			var base_cooldown = template.generation.cooldown
			var cooldown_multiplier = game_config.get_ability_effect_multiplier(
				game_config.GeneratorType.FLOWER, "cooldown")
			
			var old_cooldown = hover_cooldown_time
			# 计算新冷却时间并四舍五入到1位小数
			var new_cooldown = base_cooldown / cooldown_multiplier
			var rounded_cooldown = snapped(new_cooldown, 0.1)  # 四舍五入到0.1
			hover_cooldown_time = rounded_cooldown
			
			_logger.debug("从GameConfig加载花悬停冷却时间: %s (基础: %s, 冷却乘数: %s, 旧值: %s)" % [
				hover_cooldown_time,
				base_cooldown,
				cooldown_multiplier,
				old_cooldown
			])
	else:
		_logger.warning("GameConfig单例不可用，使用默认花悬停配置")

# 显示点击效果
func _show_click_effect():
	# 创建Ghibli风格的粒子效果
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.lifetime = 1.0
	particles.amount = 12
	
	# 设置粒子纹理 - 使用简单圆形如果纹理不可用
	var texture_path = "res://assets/circle.png"
	if ResourceLoader.exists(texture_path):
		particles.texture = load(texture_path)
	
	# Ghibli风格的柔和颜色
	var flower_color = ghibli_colors[randi() % ghibli_colors.size()]
	
	particles.color = flower_color
	particles.color_ramp = Gradient.new()
	var color_ramp = particles.color_ramp
	color_ramp.add_point(0.0, flower_color)
	color_ramp.add_point(1.0, Color(flower_color.r, flower_color.g, flower_color.b, 0))
	
	# 设置粒子的运动属性
	particles.direction = Vector2(0, -1)
	particles.spread = 90
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 80
	
	# 设置粒子缩放
	particles.scale_amount_min = 0.2
	particles.scale_amount_max = 0.4
	# scale_amount_random属性在Godot 4中已不存在，使用min/max代替
	#particles.scale_amount_random = 0.2
	
	add_child(particles)
	
	# 延迟移除粒子系统
	await get_tree().create_timer(1.2).timeout
	particles.queue_free()
	
	# 添加Ghibli风格的文本飘动效果
	var floating_text = Label.new()
	floating_text.text = "+1"
	
	# 应用Ghibli风格
	var theme_manager = get_node_or_null("/root/GhibliTheme")
	if theme_manager:
		theme_manager.apply_label_theme(floating_text, "dark", 18)
	else:
		# 后备样式
		floating_text.add_theme_font_size_override("font_size", 18)
		floating_text.add_theme_color_override("font_color", Color(0.35, 0.3, 0.25))
	
	floating_text.position = Vector2(-20, -30)
	add_child(floating_text)
	
	# 创建动画
	var tween = create_tween()
	tween.tween_property(floating_text, "position", Vector2(-20, -70), 1.0)
	tween.parallel().tween_property(floating_text, "modulate", Color(1, 1, 1, 0), 1.0)
	
	# 动画结束后移除
	await tween.finished
	floating_text.queue_free()

# 显示奖励效果
func _show_reward_effect(amount):
	# 添加Ghibli风格的文本飘动效果
	var floating_text = Label.new()
	floating_text.text = "+" + str(amount)
	
	# 应用Ghibli风格
	var theme_manager = get_node_or_null("/root/GhibliTheme")
	if theme_manager:
		theme_manager.apply_label_theme(floating_text, "dark", 18)
	else:
		# 后备样式
		floating_text.add_theme_font_size_override("font_size", 18)
		floating_text.add_theme_color_override("font_color", Color(0.35, 0.3, 0.25))
	
	floating_text.position = Vector2(-20, -30)
	add_child(floating_text)
	
	# 创建动画
	var tween = create_tween()
	tween.tween_property(floating_text, "position", Vector2(-20, -70), 1.0)
	tween.parallel().tween_property(floating_text, "modulate", Color(1, 1, 1, 0), 1.0)
	
	# 动画结束后移除
	await tween.finished
	floating_text.queue_free()

# 冷却结束处理
func _on_hover_cooldown_timeout():
	# 更新视觉效果
	if sprite:
		# 创建一个简单的"准备好了"的动画
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.3)
		
		# 添加轻微的"弹跳"效果
		var original_scale = sprite.scale
		tween.tween_property(sprite, "scale", original_scale * 1.1, 0.15)
		tween.tween_property(sprite, "scale", original_scale, 0.15)
		
		# 添加Ghibli风格的光晕效果
		var glow = ColorRect.new()
		glow.color = Color(1, 1, 0.8, 0.4)  # 温暖的黄色光晕
		glow.size = Vector2(60, 60)
		glow.position = Vector2(-30, -30)  # 居中
		glow.z_index = -1  # 确保在花朵后面
		add_child(glow)
		
		var glow_tween = create_tween()
		glow_tween.tween_property(glow, "modulate", Color(1, 1, 0.8, 0), 1.0)
		
		await glow_tween.finished
		glow.queue_free()
