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
		background.color = Color(0.95, 0.92, 0.85, 1)  # 米色背景
		
		# 创建Ghibli风格的渐变背景
		var gradient_bg = TextureRect.new()
		gradient_bg.name = "GradientBackground"
		gradient_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gradient_bg.expand = true
		gradient_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		gradient_bg.anchor_right = 1.0
		gradient_bg.anchor_bottom = 1.0
		gradient_bg.show_behind_parent = true
		
		# 创建渐变纹理 - 使用参考图片中的浅绿色渐变
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color(0.85, 0.92, 0.8))  # 浅绿色顶部
		gradient.add_point(0.6, Color(0.92, 0.95, 0.85))  # 米绿色中部
		gradient.add_point(1.0, Color(0.95, 0.92, 0.82))  # 淡米色底部
		
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
		title_label.text = "小树生长记"
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", ghibli_theme.colors.text_dark)
		
		# 创建阴影效果
		var shadow = Label.new()
		shadow.text = title_label.text
		shadow.add_theme_font_size_override("font_size", 48)
		shadow.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 0.1))
		shadow.position = Vector2(2, 2)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_label.add_child(shadow)
		shadow.show_behind_parent = true
	
	# 开始按钮 - 使用参考图片中的风格
	var start_button = $StartButton
	if start_button:
		# 使用温暖的黄色调，类似参考图
		ghibli_theme.apply_button_theme(start_button, "yellow", 26)
		
		# 调整按钮大小
		start_button.custom_minimum_size = Vector2(200, 60)
		
		# 添加额外的样式，更接近参考图片
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.98, 0.92, 0.75, 0.95)  # 淡黄色背景
		normal_style.corner_radius_top_left = 15
		normal_style.corner_radius_top_right = 15
		normal_style.corner_radius_bottom_left = 15
		normal_style.corner_radius_bottom_right = 15
		normal_style.border_width_left = 1
		normal_style.border_width_top = 1
		normal_style.border_width_right = 1
		normal_style.border_width_bottom = 1
		normal_style.border_color = Color(0.8, 0.75, 0.6, 0.8)
		start_button.add_theme_stylebox_override("normal", normal_style)
		
		# 悬停样式
		var hover_style = normal_style.duplicate()
		hover_style.bg_color = hover_style.bg_color.lightened(0.05)
		start_button.add_theme_stylebox_override("hover", hover_style)
		
		# 按下样式
		var pressed_style = normal_style.duplicate()
		pressed_style.bg_color = pressed_style.bg_color.darkened(0.05)
		pressed_style.shadow_offset = Vector2(0, 0)
		start_button.add_theme_stylebox_override("pressed", pressed_style)

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
	
	# 添加小鸟 - 参考图片中的蓝色小鸟
	_add_birds(elements_container)

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

# 添加小鸟 - 参考图片中的蓝色小鸟
func _add_birds(parent):
	var viewport_size = get_viewport().size
	
	# 创建一只蓝色小鸟，类似参考图片
	var bird = ColorRect.new()
	bird.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bird.color = Color(0.5, 0.7, 0.9, 1.0)  # 蓝色
	bird.size = Vector2(25, 20)
	bird.position = Vector2(viewport_size.x * 0.85, viewport_size.y * 0.2)
	
	var bird_style = StyleBoxFlat.new()
	bird_style.bg_color = bird.color
	bird_style.corner_radius_top_left = 10
	bird_style.corner_radius_top_right = 12
	bird_style.corner_radius_bottom_left = 8
	bird_style.corner_radius_bottom_right = 8
	bird.add_theme_stylebox_override("panel", bird_style)
	
	parent.add_child(bird)
	
	# 添加鸟啄
	var beak = ColorRect.new()
	beak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beak.color = Color(0.9, 0.7, 0.2, 1.0)  # 橙黄色
	beak.size = Vector2(8, 5)
	beak.position = Vector2(bird.position.x + 20, bird.position.y + 8)
	parent.add_child(beak)
	
	# 添加眼睛
	var eye = ColorRect.new()
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eye.color = Color(0.1, 0.1, 0.1, 1.0)  # 黑色
	eye.size = Vector2(3, 3)
	eye.position = Vector2(bird.position.x + 18, bird.position.y + 6)
	parent.add_child(eye)
	
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