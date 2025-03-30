extends Node

# Ghibli Theme Manager
# 为游戏提供一致的吉卜力风格主题

# 吉卜力风格颜色 - 参考图片中的柔和风格
var colors = {
	# 背景色
	"background_light": Color(0.98, 0.95, 0.85, 0.98),  # 淡黄色背景
	"background_medium": Color(0.96, 0.92, 0.8, 0.95),  # 温暖的米色
	"background_dark": Color(0.94, 0.88, 0.75, 0.95),  # 深米色
	
	# 强调色
	"accent_green": Color(0.55, 0.75, 0.45, 0.9),  # 柔和的绿色
	"accent_pink": Color(0.9, 0.75, 0.8, 0.9),  # 淡粉色
	"accent_blue": Color(0.65, 0.8, 0.9, 0.9),  # 淡蓝色
	"accent_yellow": Color(0.98, 0.92, 0.7, 0.95),  # 淡黄色
	
	# 文字颜色
	"text_dark": Color(0.4, 0.3, 0.2),  # 深棕色文字
	"text_medium": Color(0.5, 0.4, 0.3),  # 中棕色文字
	"text_light": Color(0.6, 0.5, 0.4),  # 淡棕色文字
	
	# 边框颜色
	"border_dark": Color(0.7, 0.6, 0.45, 0.7),  # 深棕色边框
	"border_light": Color(0.85, 0.75, 0.6, 0.8),  # 淡棕色边框
	
	# 分隔线颜色
	"separator": Color(0.85, 0.8, 0.7, 0.5)  # 柔和的分隔线颜色
}

# 创建一个按钮的普通样式
func create_button_normal_style(color_variant = "medium"):
	var style = StyleBoxFlat.new()
	
	# 根据颜色变体选择背景色
	match color_variant:
		"light":
			style.bg_color = colors.background_light
		"dark":
			style.bg_color = colors.background_dark
		"green":
			style.bg_color = Color(0.8, 0.9, 0.75, 0.95)  # 淡绿色
		"pink":
			style.bg_color = Color(0.95, 0.85, 0.9, 0.95)  # 淡粉色
		"blue":
			style.bg_color = Color(0.8, 0.85, 0.95, 0.95)  # 淡蓝色
		"yellow":
			style.bg_color = Color(0.98, 0.92, 0.75, 0.95)  # 淡黄色
		_:  # medium 默认
			style.bg_color = colors.background_medium
	
	# 圆角设置 - 更接近参考图片中的圆角
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	
	# 边框设置 - 更细的边框
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_color = colors.border_dark
	
	# 阴影设置 - 更柔和的阴影
	style.shadow_color = Color(0.2, 0.18, 0.15, 0.2)
	style.shadow_size = 1
	style.shadow_offset = Vector2(1, 1)
	
	return style

# 创建一个按钮的悬停样式
func create_button_hover_style(color_variant = "medium"):
	var style = create_button_normal_style(color_variant)
	
	# 悬停时颜色稍微更亮
	style.bg_color = style.bg_color.lightened(0.05)
	
	return style

# 创建一个面板样式 - 更接近参考图中的风格
func create_panel_style():
	var style = StyleBoxFlat.new()
	
	# 背景设置
	style.bg_color = colors.background_light
	
	# 圆角设置
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	
	# 边框设置
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_color = colors.border_light
	
	# 阴影设置
	style.shadow_color = Color(0.2, 0.18, 0.15, 0.2)
	style.shadow_size = 3
	style.shadow_offset = Vector2(2, 2)
	
	return style

# 应用Ghibli主题到按钮
func apply_button_theme(button, color_variant = "medium", font_size = 15):
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", colors.text_dark)
	button.add_theme_color_override("font_color_hover", colors.text_medium)
	
	# 添加按钮样式
	button.add_theme_stylebox_override("normal", create_button_normal_style(color_variant))
	button.add_theme_stylebox_override("hover", create_button_hover_style(color_variant))
	
	# 添加按压样式
	var pressed_style = create_button_normal_style(color_variant)
	pressed_style.bg_color = pressed_style.bg_color.darkened(0.05)
	pressed_style.shadow_offset = Vector2(0, 0)
	button.add_theme_stylebox_override("pressed", pressed_style)

# 应用Ghibli主题到标签
func apply_label_theme(label, text_variant = "medium", font_size = 14):
	label.add_theme_font_size_override("font_size", font_size)
	
	# 根据变体应用文字颜色
	match text_variant:
		"dark":
			label.add_theme_color_override("font_color", colors.text_dark)
		"light":
			label.add_theme_color_override("font_color", colors.text_light)
		_:  # medium 默认
			label.add_theme_color_override("font_color", colors.text_medium)

# 应用Ghibli主题到面板
func apply_panel_theme(panel):
	panel.add_theme_stylebox_override("panel", create_panel_style())

# 创建一个分隔线样式
func create_separator_style():
	var style = StyleBoxLine.new()
	style.color = colors.separator
	style.thickness = 1
	return style

# 创建滑块样式 - 类似参考图片中的风格
func create_slider_style():
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = Color(0.7, 0.8, 0.65, 0.9)  # 柔和的绿色
	slider_style.corner_radius_top_left = 8
	slider_style.corner_radius_top_right = 8
	slider_style.corner_radius_bottom_left = 8
	slider_style.corner_radius_bottom_right = 8
	return slider_style

# 应用Ghibli主题到滑块
func apply_slider_theme(slider):
	slider.add_theme_stylebox_override("slider", create_slider_style())

# 应用标题样式到标签
func apply_title_style(label, text_variant = "dark", font_size = 32):
	label.add_theme_font_size_override("font_size", font_size)
	
	# 根据变体应用文字颜色
	match text_variant:
		"dark":
			label.add_theme_color_override("font_color", colors.text_dark)
		"light":
			label.add_theme_color_override("font_color", colors.text_light)
		_:  # medium 默认
			label.add_theme_color_override("font_color", colors.text_medium)
	
	# 为标题添加阴影效果
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_color_override("font_shadow_color", Color(0.2, 0.18, 0.15, 0.3))

# 应用副标题样式到标签
func apply_subtitle_style(label, text_variant = "medium", font_size = 18):
	# 基础应用与普通标签相同
	apply_label_theme(label, text_variant, font_size)
	
	# 为副标题添加轻微的阴影
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_color_override("font_shadow_color", Color(0.2, 0.18, 0.15, 0.2)) 