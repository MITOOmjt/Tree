extends CanvasLayer

@onready var _logger = get_node("/root/Logger")
@onready var coins_label = $Control/Panel/CoinsLabel
@onready var message_label = $Control/MessagePanel/MessageLabel

var default_message = "点击树生成鸟 (花费10金币)"
var message_timer: Timer

func _ready():
	_logger.info("UI初始化")
	# 连接到全局金币变化信号
	Global.coins_changed.connect(_on_coins_changed)
	
	# 连接到消息总线
	MessageBus.get_instance().show_message.connect(show_message)
	
	# 初始化显示
	update_coins_display(Global.get_coins())
	
	# 初始化消息
	show_message(default_message)
	
	# 创建定时器用于清除消息
	message_timer = Timer.new()
	message_timer.name = "MessageTimer"
	message_timer.wait_time = 3.0
	message_timer.one_shot = true
	add_child(message_timer)
	message_timer.timeout.connect(_on_message_timer_timeout)
	
	# 应用Ghibli风格到UI元素
	_apply_ghibli_style()
	
	_logger.info("UI已应用Ghibli风格")

func _on_coins_changed(amount):
	update_coins_display(amount)
	
func update_coins_display(amount):
	coins_label.text = "金币: " + str(amount)
	
func show_message(text, duration = 0):
	message_label.text = text
	
	# 如果指定了持续时间，设置定时器
	if duration > 0:
		message_timer.wait_time = duration
		message_timer.start()
	
func _on_message_timer_timeout():
	# 恢复默认消息
	message_label.text = default_message

# 应用Ghibli风格到UI元素
func _apply_ghibli_style():
	# 获取GhibliTheme单例
	var ghibli_theme = get_node_or_null("/root/GhibliTheme")
	if not ghibli_theme:
		_logger.warning("无法获取GhibliTheme单例")
		return
	
	# 金币面板
	var coins_panel = $Control/Panel
	if coins_panel:
		# 创建Ghibli风格的面板 - 类似参考图片中的米黄色面板
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.98, 0.92, 0.75, 0.98)  # 淡黄色背景
		panel_style.corner_radius_top_left = 15
		panel_style.corner_radius_top_right = 15
		panel_style.corner_radius_bottom_left = 15
		panel_style.corner_radius_bottom_right = 15
		panel_style.border_width_top = 1
		panel_style.border_width_right = 1
		panel_style.border_width_bottom = 1
		panel_style.border_width_left = 1
		panel_style.border_color = Color(0.85, 0.75, 0.6, 0.8)  # 米棕色边框
		panel_style.shadow_color = Color(0.2, 0.18, 0.15, 0.2)
		panel_style.shadow_size = 2
		panel_style.shadow_offset = Vector2(1, 1)
		coins_panel.add_theme_stylebox_override("panel", panel_style)
		
		# 移除原来的ColorRect，使用StyleBox作为背景
		var color_rect = coins_panel.get_node_or_null("ColorRect")
		if color_rect:
			color_rect.queue_free()
		
		# 设置金币标签样式
		if coins_label:
			coins_label.add_theme_font_size_override("font_size", 24)
			coins_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.2))  # 深棕色文字
			
			# 添加金币图标
			var coin_icon = TextureRect.new()
			coin_icon.name = "CoinIcon"
			coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			coin_icon.custom_minimum_size = Vector2(32, 32)
			coin_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
			# 尝试加载金币图标纹理
			var texture_path = "res://assets/coin.png"
			if ResourceLoader.exists(texture_path):
				coin_icon.texture = load(texture_path)
				
				# 创建水平容器来放置图标和文本
				var h_container = HBoxContainer.new()
				h_container.alignment = BoxContainer.ALIGNMENT_CENTER
				h_container.add_child(coin_icon)
				
				# 移动金币标签到容器中
				coins_label.get_parent().remove_child(coins_label)
				h_container.add_child(coins_label)
				
				# 将容器添加到面板
				coins_panel.add_child(h_container)
				h_container.anchor_right = 1.0
				h_container.anchor_bottom = 1.0
				h_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				h_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
				
				# 调整标签属性
				coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				coins_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 消息面板
	var message_panel = $Control/MessagePanel
	if message_panel:
		# 创建Ghibli风格的面板 - 类似参考图片中的风格
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.98, 0.92, 0.75, 0.98)  # 淡黄色背景
		panel_style.corner_radius_top_left = 15
		panel_style.corner_radius_top_right = 15
		panel_style.corner_radius_bottom_left = 15
		panel_style.corner_radius_bottom_right = 15
		panel_style.border_width_top = 1
		panel_style.border_width_right = 1
		panel_style.border_width_bottom = 1
		panel_style.border_width_left = 1
		panel_style.border_color = Color(0.85, 0.75, 0.6, 0.8)  # 米棕色边框
		panel_style.shadow_color = Color(0.2, 0.18, 0.15, 0.2)
		panel_style.shadow_size = 2
		panel_style.shadow_offset = Vector2(1, 1)
		message_panel.add_theme_stylebox_override("panel", panel_style)
		
		# 设置消息标签样式
		if message_label:
			message_label.add_theme_font_size_override("font_size", 16)
			message_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.2))  # 深棕色文字
			message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			message_label.anchor_right = 1.0
			message_label.anchor_bottom = 1.0
	
	# 添加装饰性元素
	_add_decorative_elements()

# 添加装饰性元素
func _add_decorative_elements():
	# 获取控制节点
	var control = $Control
	if not control:
		return
	
	# 创建小鸟装饰 - 类似参考图片中的蓝色小鸟
	var bird = ColorRect.new()
	bird.name = "DecorativeBird"
	bird.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bird.color = Color(0.5, 0.7, 0.9, 1.0)  # 蓝色
	bird.size = Vector2(25, 20)
	
	# 放在消息面板附近
	var message_panel = $Control/MessagePanel
	var bird_pos = Vector2(message_panel.position.x + message_panel.size.x + 20, message_panel.position.y)
	bird.position = bird_pos
	
	# 应用圆角样式
	var bird_style = StyleBoxFlat.new()
	bird_style.bg_color = bird.color
	bird_style.corner_radius_top_left = 10
	bird_style.corner_radius_top_right = 12
	bird_style.corner_radius_bottom_left = 8
	bird_style.corner_radius_bottom_right = 8
	bird.add_theme_stylebox_override("panel", bird_style)
	
	control.add_child(bird)
	
	# 添加鸟啄
	var beak = ColorRect.new()
	beak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beak.color = Color(0.9, 0.7, 0.2, 1.0)  # 橙黄色
	beak.size = Vector2(8, 5)
	beak.position = Vector2(bird.position.x + 20, bird.position.y + 8)
	control.add_child(beak)
	
	# 添加眼睛
	var eye = ColorRect.new()
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eye.color = Color(0.1, 0.1, 0.1, 1.0)  # 黑色
	eye.size = Vector2(3, 3)
	eye.position = Vector2(bird.position.x + 18, bird.position.y + 6)
	control.add_child(eye)
	
	# 添加轻微动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(bird, "position:y", bird.position.y - 5, 1.0)
	tween.tween_property(bird, "position:y", bird.position.y, 1.0)
	
	# 同步移动啄和眼睛
	var beak_tween = create_tween()
	beak_tween.set_loops()
	beak_tween.tween_property(beak, "position:y", beak.position.y - 5, 1.0)
	beak_tween.tween_property(beak, "position:y", beak.position.y, 1.0)
	
	var eye_tween = create_tween()
	eye_tween.set_loops()
	eye_tween.tween_property(eye, "position:y", eye.position.y - 5, 1.0)
	eye_tween.tween_property(eye, "position:y", eye.position.y, 1.0)
