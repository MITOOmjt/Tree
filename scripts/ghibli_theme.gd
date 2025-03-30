extends Node

# Ghibli Theme Manager
# 为游戏提供一致的吉卜力风格主题

# 字体资源
var fonts = {
	"regular": null,
	"bold": null,
	"serif": null
}

# 字体路径
var font_paths = {
	"regular": "res://resource/fonts/NotoSansCJKsc-Regular.ttf",
	"bold": "res://resource/fonts/NotoSansCJKsc-Bold.ttf",
	"serif": "res://resource/fonts/NotoSerifCJKsc-Regular.ttf"
}

# 吉卜力风格颜色 - 更加接近宫崎骏电影的柔和自然色调
var colors = {
	# 背景色 - 更柔和的色调
	"background_light": Color(0.98, 0.96, 0.9, 0.95),  # 淡米黄色背景
	"background_medium": Color(0.96, 0.94, 0.85, 0.92),  # 温暖的奶油色
	"background_dark": Color(0.94, 0.91, 0.82, 0.9),  # 深奶油色
	
	# 强调色 - 更自然的色调
	"accent_green": Color(0.6, 0.78, 0.5, 0.9),  # 宫崎骏风格的草地绿
	"accent_blue": Color(0.7, 0.85, 0.95, 0.9),  # 天空蓝
	"accent_pink": Color(0.95, 0.8, 0.85, 0.85),  # 樱花粉
	"accent_yellow": Color(0.98, 0.94, 0.75, 0.9),  # 阳光黄
	"accent_brown": Color(0.75, 0.65, 0.48, 0.9),  # 树木棕
	
	# 文字颜色 - 更温暖的色调
	"text_dark": Color(0.35, 0.25, 0.18),  # 深棕色文字
	"text_medium": Color(0.45, 0.35, 0.25),  # 中棕色文字
	"text_light": Color(0.55, 0.45, 0.35),  # 淡棕色文字
	"text_white": Color(0.98, 0.96, 0.92),  # 温暖的白色文字
	
	# 边框颜色
	"border_dark": Color(0.65, 0.55, 0.4, 0.8),  # 深棕色边框
	"border_light": Color(0.8, 0.7, 0.55, 0.7),  # 淡棕色边框
	
	# 分隔线颜色
	"separator": Color(0.8, 0.75, 0.65, 0.5)  # 柔和的分隔线颜色
}

# 预设的样式变体
var style_variants = {
	"tree": "accent_green",
	"flower": "accent_pink",
	"bird": "accent_blue",
	"coin": "accent_yellow",
	"upgrade": "accent_brown"
}

func _ready():
	# 检查并加载字体
	check_font_files()
	load_fonts()

# 检查字体文件是否存在
func check_font_files():
	for font_name in font_paths:
		var path = font_paths[font_name]
		var file = FileAccess.open(path, FileAccess.READ)
		if file == null:
			printerr("警告: 无法找到字体文件 ", path, " - 错误代码: ", FileAccess.get_open_error())
		else:
			file.close()

# 加载所有字体
func load_fonts():
	for font_name in font_paths:
		var font = load_font(font_paths[font_name])
		fonts[font_name] = font
		if font == null:
			printerr("警告: 无法加载字体 ", font_name, " 从路径 ", font_paths[font_name])

# 加载单个字体文件
func load_font(path):
	if path.is_empty():
		return null
		
	var font = null
	if ResourceLoader.exists(path):
		font = ResourceLoader.load(path)
		if font:
			print("成功加载字体: ", path)
		else:
			printerr("警告: 字体资源加载失败: ", path)
	else:
		printerr("警告: 字体资源不存在: ", path)
	
	return font

# 获取字体
func get_font(font_type):
	if fonts.has(font_type) and fonts[font_type] != null:
		return fonts[font_type]
	else:
		# 返回常规字体作为后备，如果也不存在则返回null
		return fonts["regular"] if fonts["regular"] != null else null

# 创建一个按钮的普通样式
func create_button_normal_style(color_variant = "medium"):
	var style = StyleBoxFlat.new()
	
	# 根据颜色变体选择背景色
	match color_variant:
		"light":
			style.bg_color = colors.background_light
		"dark":
			style.bg_color = colors.background_dark
		"accent_green", "green":
			style.bg_color = colors.accent_green
		"accent_pink", "pink":
			style.bg_color = colors.accent_pink
		"accent_blue", "blue":
			style.bg_color = colors.accent_blue
		"accent_yellow", "yellow":
			style.bg_color = colors.accent_yellow
		"accent_brown", "brown":
			style.bg_color = colors.accent_brown
		_:  # medium 默认
			style.bg_color = colors.background_medium
	
	# 圆角设置 - 更大的圆角，更接近吉卜力风格
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	
	# 边框设置 - 更柔和的边框
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_color = colors.border_light
	
	# 阴影设置 - 更柔和的阴影
	style.shadow_color = Color(0.2, 0.18, 0.15, 0.15)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	
	return style

# 创建一个按钮的悬停样式
func create_button_hover_style(color_variant = "medium"):
	var style = create_button_normal_style(color_variant)
	
	# 悬停时颜色变得更亮，更有活力
	style.bg_color = style.bg_color.lightened(0.08)
	style.border_color = colors.border_dark
	
	# 增加悬停时的阴影效果
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 3)
	
	return style

# 创建一个面板样式 - 吉卜力风格的圆角和柔和边框
func create_panel_style(color_variant = "light"):
	var style = StyleBoxFlat.new()
	
	# 背景设置
	match color_variant:
		"dark":
			style.bg_color = colors.background_dark
		"medium":
			style.bg_color = colors.background_medium
		"accent_green", "green":
			style.bg_color = colors.accent_green.lightened(0.2)
		"accent_pink", "pink":
			style.bg_color = colors.accent_pink.lightened(0.2)
		"accent_blue", "blue":
			style.bg_color = colors.accent_blue.lightened(0.2)
		"accent_yellow", "yellow":
			style.bg_color = colors.accent_yellow.lightened(0.2)
		"accent_brown", "brown":
			style.bg_color = colors.accent_brown.lightened(0.2)
		_:  # light 默认
			style.bg_color = colors.background_light
	
	# 圆角设置 - 更大的圆角
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	
	# 边框设置 - 柔和的边框
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_color = colors.border_light
	
	# 阴影设置 - 更柔和的阴影
	style.shadow_color = Color(0.2, 0.18, 0.15, 0.15)
	style.shadow_size = 5
	style.shadow_offset = Vector2(3, 3)
	
	return style

# 应用Ghibli主题到按钮
func apply_button_theme(button, color_variant = "medium", font_size = 16):
	# 设置字体，添加安全检查
	if fonts.regular != null:
		button.add_theme_font_override("font", fonts.regular)
	
	button.add_theme_font_size_override("font_size", font_size)
	
	# 设置文本颜色
	button.add_theme_color_override("font_color", colors.text_dark)
	button.add_theme_color_override("font_color_hover", colors.text_dark.lightened(0.2))
	button.add_theme_color_override("font_color_pressed", colors.text_dark.darkened(0.1))
	
	# 添加按钮样式
	button.add_theme_stylebox_override("normal", create_button_normal_style(color_variant))
	button.add_theme_stylebox_override("hover", create_button_hover_style(color_variant))
	
	# 添加按压样式
	var pressed_style = create_button_normal_style(color_variant)
	pressed_style.bg_color = pressed_style.bg_color.darkened(0.1)
	pressed_style.shadow_offset = Vector2(1, 1)
	pressed_style.shadow_size = 2
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# 禁用状态
	var disabled_style = create_button_normal_style(color_variant)
	disabled_style.bg_color = disabled_style.bg_color.darkened(0.2)
	disabled_style.border_color = colors.border_light.darkened(0.2)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_color_override("font_color_disabled", colors.text_light.darkened(0.2))

# 应用Ghibli主题到标签
func apply_label_theme(label, text_variant = "medium", font_size = 16, use_bold = false, use_serif = false):
	# 设置字体，添加安全检查
	if use_bold and fonts.bold != null:
		label.add_theme_font_override("font", fonts.bold)
	elif use_serif and fonts.serif != null:
		label.add_theme_font_override("font", fonts.serif)
	elif fonts.regular != null:
		label.add_theme_font_override("font", fonts.regular)
	# 不设置字体覆盖，使用默认字体
	
	label.add_theme_font_size_override("font_size", font_size)
	
	# 根据变体应用文字颜色
	match text_variant:
		"dark":
			label.add_theme_color_override("font_color", colors.text_dark)
		"light":
			label.add_theme_color_override("font_color", colors.text_light)
		"white":
			label.add_theme_color_override("font_color", colors.text_white)
		_:  # medium 默认
			label.add_theme_color_override("font_color", colors.text_medium)

# 应用Ghibli主题到面板
func apply_panel_theme(panel, color_variant = "light"):
	panel.add_theme_stylebox_override("panel", create_panel_style(color_variant))

# 创建一个分隔线样式
func create_separator_style():
	var style = StyleBoxLine.new()
	style.color = colors.separator
	style.thickness = 1
	return style

# 创建滑块样式 - 吉卜力风格
func create_slider_style(color_variant = "green"):
	var slider_style = StyleBoxFlat.new()
	
	# 根据颜色变体选择背景色
	match color_variant:
		"blue":
			slider_style.bg_color = colors.accent_blue
		"pink":
			slider_style.bg_color = colors.accent_pink
		"yellow":
			slider_style.bg_color = colors.accent_yellow
		"brown":
			slider_style.bg_color = colors.accent_brown
		_:  # green 默认
			slider_style.bg_color = colors.accent_green
	
	slider_style.corner_radius_top_left = 10
	slider_style.corner_radius_top_right = 10
	slider_style.corner_radius_bottom_left = 10
	slider_style.corner_radius_bottom_right = 10
	
	return slider_style

# 应用Ghibli主题到滑块
func apply_slider_theme(slider, color_variant = "green"):
	slider.add_theme_stylebox_override("slider", create_slider_style(color_variant))
	slider.add_theme_stylebox_override("grabber_area", create_slider_style(color_variant))
	
	# 设置滑块抓取区域样式
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(1, 1, 1, 0.9)
	grabber_style.corner_radius_top_left = 8
	grabber_style.corner_radius_top_right = 8
	grabber_style.corner_radius_bottom_left = 8
	grabber_style.corner_radius_bottom_right = 8
	grabber_style.shadow_size = 2
	grabber_style.shadow_color = Color(0, 0, 0, 0.2)
	
	slider.add_theme_stylebox_override("grabber_area_highlight", grabber_style)

# 应用标题样式 - 大标题文本
func apply_title_style(label, color_variant = "dark", font_size = 28):
	# 先应用基础标签样式
	apply_label_theme(label, color_variant, font_size, true, false)
	
	# 添加描边效果
	if label:
		label.add_theme_color_override("font_outline_color", colors.background_light)
		label.add_theme_constant_override("outline_size", 1)
		
		# 添加阴影效果
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.2))

# 应用子标题样式
func apply_subtitle_style(label, color_variant = "medium", font_size = 20):
	# 先应用基础标签样式
	apply_label_theme(label, color_variant, font_size, false, true)

# 创建带有吉卜力风格的图标按钮 (使用颜色代替图标)
func create_icon_button(parent, icon_color, size = Vector2(32, 32), tooltip = ""):
	if not is_instance_valid(parent):
		push_warning("吉卜力主题: 无法创建图标按钮，父节点无效")
		return null
		
	var btn = Button.new()
	var icon = ColorRect.new()
	
	# 设置按钮属性
	btn.size = size
	btn.tooltip_text = tooltip
	btn.focus_mode = Control.FOCUS_NONE
	
	# 设置图标属性
	icon.color = icon_color
	icon.size = Vector2(size.x * 0.6, size.y * 0.6)
	icon.position = Vector2((size.x - icon.size.x) / 2, (size.y - icon.size.y) / 2)
	
	# 应用主题
	apply_button_theme(btn, "light", 14)
	
	# 添加图标到按钮
	btn.add_child(icon)
	
	# 添加按钮到父节点
	parent.add_child(btn)
	
	return btn

# 应用Ghibli主题到全局主题
func apply_to_theme(theme):
	# 设置默认字体和颜色，添加安全检查
	if fonts.regular != null:
		theme.set_font("font", "Label", fonts.regular)
		theme.set_font("font", "Button", fonts.regular)
		theme.set_font("font", "LineEdit", fonts.regular)
	
	# 设置默认颜色
	theme.set_color("font_color", "Label", colors.text_dark)
	theme.set_color("font_color", "Button", colors.text_dark)
	
	# 设置默认样式
	theme.set_stylebox("normal", "Button", create_button_normal_style())
	theme.set_stylebox("hover", "Button", create_button_hover_style())
	theme.set_stylebox("panel", "Panel", create_panel_style())

# 根据生成器类型获取合适的颜色变体
func get_color_variant_for_generator(generator_type):
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		match generator_type:
			game_config.GeneratorType.TREE:
				return "accent_green"
			game_config.GeneratorType.FLOWER:
				return "accent_pink"
			game_config.GeneratorType.BIRD:
				return "accent_blue"
	
	return "medium" 
