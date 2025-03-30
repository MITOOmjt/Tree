extends Node2D

# 确保Logger单例在编译时可见
@onready var _logger = get_node("/root/Logger")
@onready var tree_visual = $TreeVisual
@onready var tree_sprite = $TreeVisual/TreeSprite

# 生成金币的数量
var coin_generation_amount = 1
# 金币计时器引用
var coin_timer

# 生成金币的间隔(秒)
var coin_generation_interval = 5.0  # 默认值

# 浮动文本场景
var floating_text_scene = preload("res://scene/floating_text.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	# 获取金币计时器引用
	coin_timer = $CoinTimer
	
	# 连接计时器的timeout信号
	coin_timer.timeout.connect(_on_coin_timer_timeout)
	
	# 从GameConfig加载配置
	_load_config()
	
	# 添加到trees组，以便背景管理器可以找到所有树木
	add_to_group("trees")
	
	# 设置树的纹理和缩放
	if tree_sprite:
		tree_sprite.texture = load("res://resource/tree.png")
		tree_sprite.scale = Vector2(0.2, 0.2)  # 调整大小适合场景
		_logger.info("已加载树木图片")

# 从GameConfig加载配置
func _load_config():
	var game_config = get_node_or_null("/root/GameConfig")
	if not game_config:
		_logger.warning("无法获取GameConfig单例")
		return
	
	_logger.debug("树执行_load_config()...")
	
	# 使用通用方法计算奖励值
	var old_amount = coin_generation_amount
	coin_generation_amount = game_config.calculate_generator_reward(game_config.GeneratorType.TREE)
	
	# 获取生成器模板
	var template = game_config.get_generator_template(game_config.GeneratorType.TREE)
	var efficiency_multiplier = game_config.get_ability_effect_multiplier(
		game_config.GeneratorType.TREE, "efficiency")
	
	_logger.debug("从GameConfig加载树产生金币数量: %s (原来: %s)" % [
		coin_generation_amount,
		old_amount
	])
	
	# 处理生成间隔
	if template and template.generation.has("interval") and coin_timer:
		var base_interval = template.generation.interval
		var speed_multiplier = game_config.get_ability_effect_multiplier(
			game_config.GeneratorType.TREE, "speed")
		
		var old_interval = coin_timer.wait_time
		# 计算新间隔时间并四舍五入到1位小数
		var new_interval = base_interval / speed_multiplier
		var rounded_interval = snapped(new_interval, 0.1)  # 四舍五入到0.1
		coin_timer.wait_time = rounded_interval
		
		_logger.debug("从GameConfig加载树产生金币间隔: %s (基础: %s, 速度乘数: %s, 旧值: %s)" % [
			coin_timer.wait_time,
			base_interval,
			speed_multiplier,
			old_interval
		])
		
		# 启动计时器
		coin_timer.start()
	
	_logger.info("树配置已加载: 间隔=%s秒, 金币数量=%s" % [coin_timer.wait_time, coin_generation_amount])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# 生成金币的方法
func _on_coin_timer_timeout():
	# 生成金币
	Global.add_coins(coin_generation_amount)
	
	# 显示浮动文本
	_show_floating_text("+" + str(coin_generation_amount))
	
	_logger.debug("树生成了 %s 个金币" % [coin_generation_amount])

# 显示浮动文本
func _show_floating_text(text):
	var floating_text = floating_text_scene.instantiate()
	floating_text.position = Vector2(0, -50)  # 在树上方显示
	floating_text.text = text
	add_child(floating_text)

# 当鼠标进入树的区域时
func _on_mouse_entered():
	# 显示互动提示或更改鼠标光标等
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	print("鼠标进入树的区域")

# 当鼠标离开树的区域时
func _on_mouse_exited():
	# 恢复正常状态
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	print("鼠标离开树的区域")

# Area2D信号连接
func _on_area_2d_mouse_entered():
	_on_mouse_entered()

func _on_area_2d_mouse_exited():
	_on_mouse_exited()

# 检查点是否在树区域内（保留此函数供背景管理器调用）
func is_point_in_tree_area(point: Vector2) -> bool:
	var click_area = $ClickArea
	if click_area and click_area is Area2D:
		var shape = click_area.get_node("CollisionShape2D")
		if shape and shape.shape:
			var local_point = click_area.to_local(point)
			if shape.shape is CircleShape2D:
				return local_point.length() <= shape.shape.radius
			# 可以扩展支持其他形状
	# 如果无法确定，返回基于点到树的距离的粗略估计
	var distance = global_position.distance_to(point)
	return distance < 50  # 默认检测半径

# 点在三角形中的检测
func _is_point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var area = 0.5 * (-b.y * c.x + a.y * (-b.x + c.x) + a.x * (b.y - c.y) + b.x * c.y)
	var s = 1.0 / (2.0 * area) * (a.y * c.x - a.x * c.y + (c.y - a.y) * p.x + (a.x - c.x) * p.y)
	var t = 1.0 / (2.0 * area) * (a.x * b.y - a.y * b.x + (a.y - b.y) * p.x + (b.x - a.x) * p.y)
	
	return s >= 0 and t >= 0 and (s + t) <= 1

# 删除此处的重复函数
