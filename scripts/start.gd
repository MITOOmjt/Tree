extends Control

# 确保Logger单例在编译时可见
@onready var _logger = get_node("/root/Logger")

# 按钮动画参数
var button_animation_time: float = 0.0
var button_animation_speed: float = 2.0
var button_original_position: Vector2

func _ready():
	# 确保"开始游戏"按钮连接到点击事件
	$StartButton.pressed.connect(_on_start_button_pressed)
	
	# 保存按钮原始位置用于动画
	button_original_position = $StartButton.position
	
	# 应用Ghibli风格
	_apply_ghibli_style()
	
	_logger.info("开始界面已加载，应用Ghibli风格")

func _process(delta):
	# 给标题和按钮添加简单的浮动动画
	button_animation_time += delta * button_animation_speed
	$StartButton.position.y = button_original_position.y + sin(button_animation_time) * 5.0
	
	# 让标题也有轻微的动画
	$TitleLabel.modulate.a = 0.8 + sin(button_animation_time * 0.5) * 0.2

# 当开始按钮被点击时，切换到主场景
func _on_start_button_pressed():
	_logger.info("用户点击了开始按钮")
	
	# 添加简单的过渡效果
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(Callable(self, "_change_scene"))

# 场景切换函数
func _change_scene():
	get_tree().change_scene_to_file("res://scene/main.tscn")

# 应用Ghibli风格到UI元素
func _apply_ghibli_style():
	# 获取GhibliTheme单例
	var ghibli_theme = get_node_or_null("/root/GhibliTheme")
	if not ghibli_theme:
		_logger.warning("无法获取GhibliTheme单例")
		return
	
	# 背景使用Ghibli风格的渐变
	var background = $Background
	if background:
		# 使用温暖的自然色调
		background.color = ghibli_theme.colors.background_light
		
		# 创建Ghibli风格的渐变背景
		var gradient_bg = TextureRect.new()
		gradient_bg.name = "GradientBackground"
		gradient_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gradient_bg.expand = true
		gradient_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		gradient_bg.anchor_right = 1.0
		gradient_bg.anchor_bottom = 1.0
		gradient_bg.show_behind_parent = true
		
		# 创建渐变纹理 - 使用新的吉卜力风格色彩
		var gradient = Gradient.new()
		gradient.add_point(0.0, ghibli_theme.colors.accent_blue.lightened(0.3))  # 浅蓝色顶部（天空）
		gradient.add_point(0.5, ghibli_theme.colors.background_light)  # 中间淡色
		gradient.add_point(1.0, ghibli_theme.colors.accent_green.lightened(0.2))  # 浅绿色底部（草地）
		
		var gradient_texture = GradientTexture2D.new()
		gradient_texture.gradient = gradient
		gradient_texture.fill_from = Vector2(0.5, 0)
		gradient_texture.fill_to = Vector2(0.5, 1)
		
		gradient_bg.texture = gradient_texture
		
		background.add_child(gradient_bg)
		
		# 添加装饰树和云朵
		_add_decorative_elements(background)
	
	# 标题标签
	var title_label = $TitleLabel
	if title_label:
		title_label.text = "小森林"
		ghibli_theme.apply_title_style(title_label, "dark", 48)
	
	# 副标题
	var subtitle_label = $SubtitleLabel
	if subtitle_label:
		ghibli_theme.apply_subtitle_style(subtitle_label, "medium", 20)
	
	# 开始按钮 - 使用新的吉卜力风格
	var start_button = $StartButton
	if start_button:
		ghibli_theme.apply_button_theme(start_button, "yellow", 26)
		
		# 调整按钮大小
		start_button.custom_minimum_size = Vector2(200, 60)

# 添加装饰元素 - 树木、云朵、小鸟等
func _add_decorative_elements(parent):
	# 创建装饰元素容器
	var elements_container = Control.new()
	elements_container.name = "DecorativeElements"
	elements_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	elements_container.anchor_right = 1.0
	elements_container.anchor_bottom = 1.0
	
	parent.add_child(elements_container)
	
	# 添加云朵
	_add_clouds(elements_container)
	
	# 添加树木
	_add_trees(elements_container)
	

# 添加云朵
func _add_clouds(parent):
	# 创建3-5个云朵
	var num_clouds = randi() % 3 + 3
	
	for i in range(num_clouds):
		var cloud = ColorRect.new()
		cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cloud.color = Color(1, 1, 1, 0.7)  # 半透明白色
		
		# 随机大小
		var width = randi() % 200 + 100
		var height = randi() % 30 + 20
		cloud.size = Vector2(width, height)
		
		# 随机位置（上半部分屏幕）
		var viewport_size = get_viewport().size
		var x_pos = randi() % int(viewport_size.x)
		var y_pos = randi() % int(viewport_size.y * 0.3)  # 只在屏幕上部
		cloud.position = Vector2(x_pos, y_pos)
		
		# 圆角效果
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = cloud.color
		style_box.corner_radius_top_left = height / 2
		style_box.corner_radius_top_right = height / 2
		style_box.corner_radius_bottom_left = height / 2
		style_box.corner_radius_bottom_right = height / 2
		cloud.add_theme_stylebox_override("panel", style_box)
		
		# 添加到容器
		parent.add_child(cloud)
		
		# 添加轻微动画
		var tween = create_tween()
		tween.set_loops()  # 循环
		tween.tween_property(cloud, "position:x", cloud.position.x + 50, 10.0)
		tween.tween_property(cloud, "position:x", cloud.position.x, 10.0)

# 添加树木
func _add_trees(parent):
	# 在左右两侧添加树木
	var viewport_size = get_viewport().size
	
	# 左侧树木
	_create_tree(parent, Vector2(50, viewport_size.y * 0.6), 1.0)
	_create_tree(parent, Vector2(150, viewport_size.y * 0.7), 0.8)
	
	# 右侧树木
	_create_tree(parent, Vector2(viewport_size.x - 100, viewport_size.y * 0.65), 0.9)
	_create_tree(parent, Vector2(viewport_size.x - 180, viewport_size.y * 0.75), 0.7)

# 创建单棵树
func _create_tree(parent, position, scale_factor):
	# 使用tree.png图片替换原来的树木
	var tree_sprite = Sprite2D.new()
	tree_sprite.texture = load("res://resource/tree.png")
	tree_sprite.position = position
	tree_sprite.scale = Vector2(scale_factor * 0.2, scale_factor * 0.2)  # 调整大小适合场景
	
	# 添加到父节点
	parent.add_child(tree_sprite)
	
	# 添加轻微动画 - 树轻微摇摆
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(tree_sprite, "rotation_degrees", 1, 3.0)
	tween.tween_property(tree_sprite, "rotation_degrees", -1, 3.0)
	tween.tween_property(tree_sprite, "rotation_degrees", 0, 3.0)
