extends CanvasLayer

@onready var _logger = get_node("/root/Logger")
@onready var coins_label = $Control/Panel/CoinsLabel
@onready var message_label = $Control/MessagePanel/MessageLabel
@onready var help_label = $Control/HelpLabel

var default_message = "选择你想生成的风景，开始建立森林吧"
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
		# 应用吉卜力面板风格
		ghibli_theme.apply_panel_theme(coins_panel, "yellow")
		
		# 移除原来的ColorRect，使用StyleBox作为背景
		var color_rect = coins_panel.get_node_or_null("ColorRect")
		if color_rect:
			color_rect.queue_free()
		
		# 设置金币标签样式
		if coins_label:
			ghibli_theme.apply_label_theme(coins_label, "dark", 24, true, false)
			
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
			else:
				# 如果没有图标，直接应用样式
				ghibli_theme.apply_label_theme(coins_label, "dark", 24, true, false)
	
	# 消息面板
	var message_panel = $Control/MessagePanel
	if message_panel:
		# 创建Ghibli风格的面板
		ghibli_theme.apply_panel_theme(message_panel, "green")
		
		# 设置消息标签样式
		if message_label:
			ghibli_theme.apply_label_theme(message_label, "dark", 16)
			message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			message_label.anchor_right = 1.0
			message_label.anchor_bottom = 1.0
	
	# 帮助标签
	if help_label:
		ghibli_theme.apply_label_theme(help_label, "medium", 14, false, true)
		# 添加轻微的阴影效果
		help_label.add_theme_constant_override("shadow_offset_x", 1)
		help_label.add_theme_constant_override("shadow_offset_y", 1)
		help_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.2))
	
	# 添加装饰性元素
	_add_decorative_elements()

# 添加装饰性元素
func _add_decorative_elements():
	# 获取控制节点
	var control = $Control
	if not control:
		return
	
	# 移除旧的装饰元素
	var old_bird = control.get_node_or_null("DecorativeBird")
	if old_bird:
		old_bird.queue_free()
	var old_beak = control.get_node_or_null("DecorativeBeak")
	if old_beak:
		old_beak.queue_free()
	var old_eye = control.get_node_or_null("DecorativeEye")
	if old_eye:
		old_eye.queue_free()
	
	# 使用真实的鸟图片
	var bird_sprite = Sprite2D.new()
	bird_sprite.name = "DecorativeBird"
	bird_sprite.texture = load("res://resource/bird.png")
	
	# 放在消息面板附近
	var message_panel = $Control/MessagePanel
	var bird_pos = Vector2(message_panel.position.x + message_panel.size.x + 20, message_panel.position.y)
	bird_sprite.position = bird_pos
	bird_sprite.scale = Vector2(0.08, 0.08)  # 调整大小
	
	control.add_child(bird_sprite)
	
	# 添加轻微动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(bird_sprite, "position:y", bird_sprite.position.y - 5, 1.0)
	tween.tween_property(bird_sprite, "position:y", bird_sprite.position.y, 1.0)
