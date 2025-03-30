extends CanvasLayer

# 信号定义，用于通知背景管理器选择的变化
signal generator_selected(type)

# 生成器类型枚举
enum GeneratorType {TREE = 0, FLOWER = 1, BIRD = 2}

# 变量
var current_selection_label
var current_generator = GeneratorType.FLOWER  # 默认选择花
var close_button
var show_button
var manual_close = false  # 记录是否是手动关闭
var allow_hide = false  # 控制是否允许面板隐藏

# 按钮和标签引用字典
var generator_ui_elements = {}  # {type: {button, cost_label, output_label, upgrade_button}}

# 默认标签颜色
var default_label_color = Color(0.807843, 0.807843, 0.807843, 1)
var insufficient_funds_color = Color(0.9, 0.2, 0.2, 1)

# GameConfig引用
var game_config
# 升级UI引用
var ability_upgrade_ui

func _ready():
	print("PopupUI脚本(_ready)：开始初始化...")
	
	# 获取GameConfig引用
	game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		print("PopupUI: 成功获取GameConfig引用")
	else:
		print("PopupUI: GameConfig不可用")
	
	# 连接到全局金币变化信号
	if get_node_or_null("/root/Global"):
		Global.coins_changed.connect(_on_coins_changed)
		print("PopupUI: 已连接到金币变化信号")
	
	# 调试当前信号
	var signal_list = get_signal_list()
	for sig in signal_list:
		print("PopupUI: 定义了信号 -", sig.name)
		
	# 获取节点引用
	var popup = $PopupPanel
	if popup:
		print("PopupUI: 找到PopupPanel节点")
	else:
		print("PopupUI: 错误 - 找不到PopupPanel节点")
		return
		
	# 连接PopupPanel的信号
	popup.popup_hide.connect(_on_popup_hide)
	popup.close_requested.connect(_on_popup_close_requested)
	print("PopupUI: 已连接PopupPanel信号")
	
	# 查找并获取所需的节点
	current_selection_label = popup.get_node("MarginContainer/VBoxContainer/CurrentSelectionLabel")
	
	# 获取生成器列表容器
	var generator_list = popup.get_node("MarginContainer/VBoxContainer/GeneratorList")
	
	# 清空生成器列表容器(以防有预设项)
	for child in generator_list.get_children():
		child.queue_free()
		
	# 预加载升级UI
	var ability_upgrade_scene = load("res://scene/ability_upgrade_ui.tscn")
	if ability_upgrade_scene:
		ability_upgrade_ui = ability_upgrade_scene.instantiate()
		get_tree().get_root().add_child(ability_upgrade_ui)
		ability_upgrade_ui.upgrade_completed.connect(_on_upgrade_completed)
		print("已加载能力升级界面")
	else:
		print("错误: 无法加载能力升级界面")
	
	# 动态创建生成物UI项
	_create_generator_ui_items(generator_list)
	
	# 创建关闭按钮
	close_button = Button.new()
	close_button.text = "关闭"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.custom_minimum_size = Vector2(120, 40)
	
	# Ghibli风格的按钮样式
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.add_theme_color_override("font_color", Color(0.25, 0.22, 0.2))  # 深棕色文字
	close_button.add_theme_color_override("font_color_hover", Color(0.4, 0.3, 0.2))  # 悬停时为温暖的棕色
	
	# 创建样式盒子
	close_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	var close_normal_style = close_button.get_theme_stylebox("normal")
	if close_normal_style is StyleBoxFlat:
		close_normal_style.bg_color = Color(0.9, 0.85, 0.78, 0.95)  # 淡棕色背景
		close_normal_style.corner_radius_top_left = 14
		close_normal_style.corner_radius_top_right = 14
		close_normal_style.corner_radius_bottom_left = 14
		close_normal_style.corner_radius_bottom_right = 14
		close_normal_style.border_width_top = 2
		close_normal_style.border_width_right = 2
		close_normal_style.border_width_bottom = 2
		close_normal_style.border_width_left = 2
		close_normal_style.border_color = Color(0.6, 0.5, 0.4, 0.7)  # 淡棕色边框
		close_normal_style.shadow_color = Color(0.2, 0.18, 0.15, 0.4)
		close_normal_style.shadow_size = 3
		close_normal_style.shadow_offset = Vector2(2, 2)
		
	# 创建悬停样式
	close_button.add_theme_stylebox_override("hover", StyleBoxFlat.new())
	var close_hover_style = close_button.get_theme_stylebox("hover")
	if close_hover_style is StyleBoxFlat:
		close_hover_style.bg_color = Color(0.82, 0.78, 0.7, 0.95)  # 更亮的淡棕色
		close_hover_style.corner_radius_top_left = 14
		close_hover_style.corner_radius_top_right = 14
		close_hover_style.corner_radius_bottom_left = 14
		close_hover_style.corner_radius_bottom_right = 14
		close_hover_style.border_width_top = 2
		close_hover_style.border_width_right = 2
		close_hover_style.border_width_bottom = 2
		close_hover_style.border_width_left = 2
		close_hover_style.border_color = Color(0.5, 0.45, 0.35, 0.7)
		close_hover_style.shadow_color = Color(0.2, 0.18, 0.15, 0.4)
		close_hover_style.shadow_size = 3
		close_hover_style.shadow_offset = Vector2(2, 2)
	
	popup.get_node("MarginContainer/VBoxContainer").add_child(close_button)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# 创建显示按钮（位于屏幕中间位置更容易看到）
	show_button = Button.new()
	show_button.text = "森林资源"
	show_button.custom_minimum_size = Vector2(120, 40)  # 使用固定大小
	show_button.visible = false  # 初始隐藏

	# 使用Control节点作为按钮容器以便固定位置
	var button_container = Control.new()
	button_container.name = "ShowButtonContainer"
	button_container.anchor_right = 1.0  # 占据整个Canvas宽度
	button_container.anchor_bottom = 1.0  # 占据整个Canvas高度
	button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 忽略鼠标事件

	# 将按钮添加到容器中并固定在右上角
	button_container.add_child(show_button)
	show_button.position = Vector2(get_viewport().size.x - show_button.custom_minimum_size.x - 20, 20)

	# 确保按钮层级在最上方
	show_button.z_index = 100

	# 添加Ghibli风格的样式
	var font = show_button.get_theme_font("font")
	if font:
		show_button.add_theme_font_size_override("font_size", 18)  # 较小的字体尺寸

	# Ghibli风格的柔和颜色
	show_button.add_theme_color_override("font_color", Color(0.25, 0.22, 0.2))  # 深棕色文字
	show_button.add_theme_color_override("font_color_hover", Color(0.4, 0.3, 0.2))  # 悬停时为温暖的棕色
	
	# 创建一个圆角边框的样式盒子
	show_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	var normal_style = show_button.get_theme_stylebox("normal")
	if normal_style is StyleBoxFlat:
		# 使用温暖的米色作为背景
		normal_style.bg_color = Color(0.95, 0.95, 0.9, 0.9)  # 半透明浅米色背景
		# 圆润的边角
		normal_style.corner_radius_top_left = 6
		normal_style.corner_radius_top_right = 6
		normal_style.corner_radius_bottom_left = 6
		normal_style.corner_radius_bottom_right = 6
		# 柔和的边框
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
		normal_style.border_width_left = 2
		normal_style.border_color = Color(0.7, 0.3, 0.3, 0.8)  # 红棕色边框
		# 柔和的阴影
		normal_style.shadow_color = Color(0.2, 0.18, 0.15, 0.4)
		normal_style.shadow_size = 4
		normal_style.shadow_offset = Vector2(2, 2)
		normal_style.content_margin_left = 10
		normal_style.content_margin_right = 10
		normal_style.content_margin_top = 5
		normal_style.content_margin_bottom = 5
		
	# 创建悬停样式
	show_button.add_theme_stylebox_override("hover", StyleBoxFlat.new())
	var hover_style = show_button.get_theme_stylebox("hover")
	if hover_style is StyleBoxFlat:
		# 悬停时背景为淡绿色
		hover_style.bg_color = Color(0.82, 0.9, 0.75, 0.95)  # 淡绿色，Ghibli常用的自然色调
		hover_style.corner_radius_top_left = 16
		hover_style.corner_radius_top_right = 16
		hover_style.corner_radius_bottom_left = 16
		hover_style.corner_radius_bottom_right = 16
		hover_style.border_width_top = 2
		hover_style.border_width_right = 2
		hover_style.border_width_bottom = 2
		hover_style.border_width_left = 2
		hover_style.border_color = Color(0.5, 0.6, 0.4, 0.7)  # 淡绿色边框
		hover_style.shadow_color = Color(0.2, 0.18, 0.15, 0.4)
		hover_style.shadow_size = 4
		hover_style.shadow_offset = Vector2(2, 2)

	# 将按钮添加到顶层，确保可见
	add_child(button_container)
	call_deferred("_position_show_button")  # 延迟设置位置
	show_button.pressed.connect(_on_show_button_pressed)
	
	# 初始UI状态
	update_selection_label()
	update_button_styles()
	
	# 设置PopupPanel位置（右侧）
	popup.position = Vector2(get_viewport().size.x - popup.size.x - 20, 250)
	
	# 显示PopupPanel
	popup.popup()
	
	# 初始更新UI信息
	update_ui_from_config()
	
	# 检查初始按钮状态
	call_deferred("_check_initial_button_state")
	
	# 设置PopupPanel的Ghibli风格
	# 创建Ghibli风格的面板背景
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.96, 0.95, 0.9, 0.98)  # 浅米色背景，接近白色但更温暖
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_color = Color(0.75, 0.7, 0.6, 0.8)  # 温暖的淡棕色边框
	panel_style.shadow_color = Color(0.2, 0.18, 0.15, 0.3)
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(3, 3)
	
	# 应用样式到面板
	popup.add_theme_stylebox_override("panel", panel_style)
	
	# 设置面板标题颜色
	var title_label = popup.get_node_or_null("MarginContainer/VBoxContainer/TitleLabel")
	if title_label:
		title_label.add_theme_color_override("font_color", Color(0.35, 0.3, 0.25))  # 深棕色文字
		title_label.add_theme_font_size_override("font_size", 24)
		
	# 设置当前选择标签样式
	if current_selection_label:
		current_selection_label.add_theme_color_override("font_color", Color(0.35, 0.3, 0.25))  # 深棕色文字
		current_selection_label.add_theme_font_size_override("font_size", 18)
	
	# 确保能够接收窗口大小改变事件
	get_viewport().size_changed.connect(_on_window_size_changed)
	print("连接了窗口大小改变信号")
	
	print("PopupUI: 初始化完成")

# 创建生成物UI项
func _create_generator_ui_items(parent_container):
	if not game_config:
		print("PopupUI: GameConfig不可用，无法创建生成物UI")
		return
	
	var generator_types = game_config.get_all_generator_types()
	var background_manager = get_node_or_null("/root/Main/BackgroundManager")
	
	for type in generator_types:
		var template = game_config.get_generator_template(type)
		if not template:
			continue
			
		# 创建项容器
		var item_container = HBoxContainer.new()
		item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_container.custom_minimum_size = Vector2(0, 75)  # 增加高度
		
		# Ghibli风格：添加美观的间距
		item_container.add_theme_constant_override("separation", 12)
		
		# 创建颜色标识 - 使用更柔和的Ghibli风格颜色
		var color_rect = ColorRect.new()
		color_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		color_rect.custom_minimum_size = Vector2(8, 0)
		
		# 根据生成器类型选择Ghibli风格的颜色
		match type:
			GeneratorType.TREE:
				color_rect.color = Color(0.45, 0.6, 0.35, 0.9)  # 柔和的绿色
			GeneratorType.FLOWER:
				color_rect.color = Color(0.85, 0.65, 0.75, 0.9)  # 淡粉色
			GeneratorType.BIRD:
				color_rect.color = Color(0.65, 0.75, 0.85, 0.9)  # 淡蓝色
			_:
				color_rect.color = template.color
		
		# 创建文本容器
		var text_container = VBoxContainer.new()
		text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_container.add_theme_constant_override("separation", 5)
		
		# 创建名称标签 - Ghibli风格的温暖文字
		var name_label = Label.new()
		name_label.text = template.name
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color(0.3, 0.25, 0.2))  # 温暖的棕色
		
		# 创建费用标签 - 柔和的Ghibli文字
		var cost_label = Label.new()
		cost_label.add_theme_font_size_override("font_size", 14)
		cost_label.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35))  # 淡棕色
		
		# 创建产出标签
		var output_label = Label.new()
		output_label.add_theme_font_size_override("font_size", 14)
		output_label.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35))  # 淡棕色
		
		# 创建按钮容器
		var button_container = VBoxContainer.new()
		button_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button_container.add_theme_constant_override("separation", 8)
		
		# 创建选择按钮 - Ghibli风格
		var button = Button.new()
		button.text = "选择"
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.custom_minimum_size = Vector2(100, 30)
		
		# Ghibli风格按钮样式
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_color", Color(0.25, 0.22, 0.2))
		button.add_theme_color_override("font_color_hover", Color(0.4, 0.3, 0.2))
		
		# 添加Ghibli风格的按钮背景
		button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
		var btn_normal_style = button.get_theme_stylebox("normal")
		if btn_normal_style is StyleBoxFlat:
			btn_normal_style.bg_color = Color(0.94, 0.91, 0.82, 0.95)  # 温暖的米色
			btn_normal_style.corner_radius_top_left = 12
			btn_normal_style.corner_radius_top_right = 12
			btn_normal_style.corner_radius_bottom_left = 12
			btn_normal_style.corner_radius_bottom_right = 12
			btn_normal_style.border_width_top = 1
			btn_normal_style.border_width_right = 1
			btn_normal_style.border_width_bottom = 1
			btn_normal_style.border_width_left = 1
			btn_normal_style.border_color = Color(0.6, 0.5, 0.4, 0.7)
			btn_normal_style.shadow_color = Color(0.2, 0.18, 0.15, 0.3)
			btn_normal_style.shadow_size = 2
			btn_normal_style.shadow_offset = Vector2(1, 1)
		
		# 添加悬停样式
		button.add_theme_stylebox_override("hover", StyleBoxFlat.new())
		var btn_hover_style = button.get_theme_stylebox("hover")
		if btn_hover_style is StyleBoxFlat:
			# 根据生成器类型选择悬停颜色
			match type:
				GeneratorType.TREE:
					btn_hover_style.bg_color = Color(0.8, 0.9, 0.75, 0.95)  # 淡绿色
				GeneratorType.FLOWER:
					btn_hover_style.bg_color = Color(0.95, 0.85, 0.9, 0.95)  # 淡粉色
				GeneratorType.BIRD:
					btn_hover_style.bg_color = Color(0.85, 0.9, 0.95, 0.95)  # 淡蓝色
				_:
					btn_hover_style.bg_color = Color(0.87, 0.87, 0.82, 0.95)
			
			btn_hover_style.corner_radius_top_left = 12
			btn_hover_style.corner_radius_top_right = 12
			btn_hover_style.corner_radius_bottom_left = 12
			btn_hover_style.corner_radius_bottom_right = 12
			btn_hover_style.border_width_top = 1
			btn_hover_style.border_width_right = 1
			btn_hover_style.border_width_bottom = 1
			btn_hover_style.border_width_left = 1
			btn_hover_style.border_color = Color(0.55, 0.5, 0.4, 0.7)
			btn_hover_style.shadow_color = Color(0.2, 0.18, 0.15, 0.3)
			btn_hover_style.shadow_size = 2
			btn_hover_style.shadow_offset = Vector2(1, 1)
		
		# 连接按钮信号
		var callable = Callable(self, "_on_generator_button_pressed").bind(type)
		button.pressed.connect(callable)
		
		# 创建升级按钮 - Ghibli风格
		var upgrade_button = Button.new()
		upgrade_button.text = "升级"
		upgrade_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		upgrade_button.visible = false  # 初始设置为隐藏，等数量达到2个时才显示
		upgrade_button.custom_minimum_size = Vector2(100, 30)
		
		# Ghibli风格按钮样式
		upgrade_button.add_theme_font_size_override("font_size", 15)
		upgrade_button.add_theme_color_override("font_color", Color(0.25, 0.22, 0.2))
		upgrade_button.add_theme_color_override("font_color_hover", Color(0.4, 0.3, 0.2))
		
		# 添加升级按钮样式
		upgrade_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
		var upg_normal_style = upgrade_button.get_theme_stylebox("normal")
		if upg_normal_style is StyleBoxFlat:
			upg_normal_style.bg_color = Color(0.9, 0.87, 0.75, 0.95)  # 温暖的金黄色
			upg_normal_style.corner_radius_top_left = 12
			upg_normal_style.corner_radius_top_right = 12
			upg_normal_style.corner_radius_bottom_left = 12
			upg_normal_style.corner_radius_bottom_right = 12
			upg_normal_style.border_width_top = 1
			upg_normal_style.border_width_right = 1
			upg_normal_style.border_width_bottom = 1
			upg_normal_style.border_width_left = 1
			upg_normal_style.border_color = Color(0.7, 0.6, 0.4, 0.7)  # 金色边框
			upg_normal_style.shadow_color = Color(0.2, 0.18, 0.15, 0.3)
			upg_normal_style.shadow_size = 2
			upg_normal_style.shadow_offset = Vector2(1, 1)
		
		# 添加悬停样式
		upgrade_button.add_theme_stylebox_override("hover", StyleBoxFlat.new())
		var upg_hover_style = upgrade_button.get_theme_stylebox("hover")
		if upg_hover_style is StyleBoxFlat:
			upg_hover_style.bg_color = Color(0.95, 0.9, 0.7, 0.95)  # 更亮的金黄色
			upg_hover_style.corner_radius_top_left = 12
			upg_hover_style.corner_radius_top_right = 12
			upg_hover_style.corner_radius_bottom_left = 12
			upg_hover_style.corner_radius_bottom_right = 12
			upg_hover_style.border_width_top = 1
			upg_hover_style.border_width_right = 1
			upg_hover_style.border_width_bottom = 1
			upg_hover_style.border_width_left = 1
			upg_hover_style.border_color = Color(0.75, 0.65, 0.35, 0.7)
			upg_hover_style.shadow_color = Color(0.2, 0.18, 0.15, 0.3)
			upg_hover_style.shadow_size = 2
			upg_hover_style.shadow_offset = Vector2(1, 1)
		
		# 连接升级按钮信号
		var upgrade_callable = Callable(self, "_on_upgrade_button_pressed").bind(type)
		upgrade_button.pressed.connect(upgrade_callable)
		
		# 添加按钮到容器
		button_container.add_child(button)
		button_container.add_child(upgrade_button)
		
		# 添加所有元素
		text_container.add_child(name_label)
		text_container.add_child(cost_label)
		text_container.add_child(output_label)
		
		item_container.add_child(color_rect)
		item_container.add_child(text_container)
		item_container.add_child(button_container)
		
		# 添加分隔线 - Ghibli风格的淡淡的分隔线
		var separator = HSeparator.new()
		separator.add_theme_stylebox_override("separator", StyleBoxLine.new())
		var sep_style = separator.get_theme_stylebox("separator")
		if sep_style is StyleBoxLine:
			sep_style.color = Color(0.8, 0.75, 0.7, 0.5)  # 柔和的分隔线颜色
			sep_style.thickness = 1
		
		# 添加到父容器
		parent_container.add_child(item_container)
		if type != generator_types[-1]:  # 如果不是最后一个，添加分隔线
			parent_container.add_child(separator)
		
		# 保存引用
		generator_ui_elements[type] = {
			"button": button,
			"cost_label": cost_label,
			"output_label": output_label,
			"upgrade_button": upgrade_button
		}
		
		print("已创建", template.name, "的UI元素")

# 处理生成器按钮点击
func _on_generator_button_pressed(type):
	print("PopupUI: ", game_config.get_generator_name(type), "按钮被点击")
	current_generator = type
	update_selection_label()
	update_button_styles()
	emit_signal("generator_selected", current_generator)

# 处理PopupPanel关闭事件
func _on_popup_hide():
	print("PopupUI: 面板隐藏事件触发，manual_close=", manual_close, " allow_hide=", allow_hide)
	
	# 如果是手动关闭，我们显示显示按钮
	if manual_close:
		# 先重新定位按钮，确保在正确位置
		call_deferred("_position_show_button")
		# 然后显示按钮
		show_button.visible = true
		manual_close = false
		print("手动关闭：按钮已设置为可见")
	else:
		# 如果是自动关闭（点击外部），则重新显示面板
		if not allow_hide:
			print("自动关闭但不允许隐藏：重新显示面板")
			call_deferred("_reshow_popup")
		else:
			allow_hide = false
			# 先重新定位按钮，确保在正确位置
			call_deferred("_position_show_button")
			# 然后显示按钮
			show_button.visible = true
			print("自动关闭且允许隐藏：按钮已设置为可见")

# 处理右上角X按钮关闭请求
func _on_popup_close_requested():
	print("PopupUI: 右上角X按钮被点击")
	manual_close = true
	allow_hide = true  # 允许面板隐藏
	$PopupPanel.hide()
	
	# 先重新定位按钮，确保在正确位置
	call_deferred("_position_show_button")
	# 再显示按钮
	show_button.visible = true
	
	print("PopupUI: 用户通过右上角X按钮关闭了界面")

# 延迟重新显示弹窗(使用call_deferred避免冲突)
func _reshow_popup():
	$PopupPanel.popup()

# 关闭按钮点击处理
func _on_close_button_pressed():
	print("PopupUI: 关闭按钮被点击")
	manual_close = true
	allow_hide = true  # 允许面板隐藏
	$PopupPanel.hide()
	
	# 先重新定位按钮，确保在正确位置
	call_deferred("_position_show_button")
	# 再显示按钮
	show_button.visible = true
	
	print("PopupUI: 用户手动关闭了界面")

# 显示按钮点击处理
func _on_show_button_pressed():
	print("PopupUI: 显示按钮被点击")
	show_button.visible = false
	print("按钮已隐藏，准备显示面板")
	
	# 更新面板位置，避免面板位置也出现问题
	var popup = $PopupPanel
	var viewport_size = get_viewport().size
	popup.position = Vector2(viewport_size.x - popup.size.x - 20, 250)
	
	# 显示面板
	$PopupPanel.popup()
	
	# 显示界面时更新UI
	update_ui_from_config()
	
	print("PopupUI: 用户重新打开了界面")

# 更新选择标签
func update_selection_label():
	if current_selection_label:
		var selection_text = "当前选择："
		if game_config:
			selection_text += game_config.get_generator_name(current_generator)
		else:
			selection_text += _get_legacy_generator_name(current_generator)
		current_selection_label.text = selection_text

# 获取生成器类型名称(备用方法)
func _get_legacy_generator_name(type):
	match type:
		GeneratorType.TREE:
			return "树"
		GeneratorType.FLOWER:
			return "花"
		GeneratorType.BIRD:
			return "鸟"
		_:
			return "未知类型"

# 更新按钮样式
func update_button_styles():
	# 更新所有按钮的样式
	for type in generator_ui_elements:
		var button = generator_ui_elements[type].button
		button.text = "选择"
		
		# 如果是当前选中的生成器，更新样式
		if current_generator == type:
			button.text = "已选择"

# 从配置更新UI
func update_ui_from_config():
	if not game_config:
		return
	
	# 尝试不同的路径获取背景管理器	
	var background_manager = get_node_or_null("/root/Main/BackgroundManager")
	if not background_manager:
		background_manager = get_node_or_null("/root/BackgroundManager")
	if not background_manager:
		background_manager = get_parent()
		if not background_manager.has_method("_load_and_instantiate_generator"):
			background_manager = null
			
	if background_manager:
		print("成功获取背景管理器引用，当前生成器数量:")
		for type in background_manager.generator_counts:
			print("- ", game_config.get_generator_name(type), ": ", background_manager.generator_counts[type])
	else:
		print("警告: 无法获取背景管理器引用，将使用默认配置")
		
	for type in generator_ui_elements:
		var ui = generator_ui_elements[type]
		var template = game_config.get_generator_template(type)
		var cost = background_manager.generator_costs[type] if background_manager else template.base_cost
		
		# 更新成本标签
		ui.cost_label.text = "成本: " + str(cost) + " 金币"
		
		# 更新产出信息
		var output_text = ""
		var generation = template.generation
		var generation_type = generation.type
		
		# 考虑能力的影响
		var efficiency_multiplier = game_config.get_ability_effect_multiplier(type, "efficiency")
		var amount = generation.amount * efficiency_multiplier
		
		match generation_type:
			"interval":
				var speed_multiplier = game_config.get_ability_effect_multiplier(type, "speed")
				var interval = generation.interval / speed_multiplier  # 减少间隔时间
				# 格式化为只保留一位小数
				var formatted_interval = "%.1f" % interval
				output_text = "每 " + formatted_interval + " 秒产出 " + str(amount) + " 金币"
			"hover":
				var cooldown_multiplier = game_config.get_ability_effect_multiplier(type, "cooldown")
				var cooldown = generation.cooldown / cooldown_multiplier  # 减少冷却时间
				# 格式化为只保留一位小数
				var formatted_cooldown = "%.1f" % cooldown
				output_text = "悬停产出 " + str(amount) + " 金币，冷却 " + formatted_cooldown + " 秒"
			"click":
				output_text = "点击获得 " + str(amount) + " 金币"
			_:
				output_text = "产出: 未知"
		
		# 添加已建造数量 - 确保背景管理器存在，并且generator_counts包含该类型
		var count = 0
		if background_manager and background_manager.generator_counts.has(type):
			count = background_manager.generator_counts[type]
		output_text += "\n已建造: " + str(count)
		
		ui.output_label.text = output_text
		
		# 检查金币是否足够
		var current_coins = Global.get_coins()
		if current_coins < cost:
			ui.cost_label.add_theme_color_override("font_color", insufficient_funds_color)
		else:
			ui.cost_label.add_theme_color_override("font_color", default_label_color)
		
		# 更新升级按钮可见性 - 当生成物数量达到2个或以上时才显示
		if count >= 2:
			ui.upgrade_button.visible = true
		else:
			ui.upgrade_button.visible = false
			
	# 更新当前选择
	update_selection_label()
	update_button_styles()

# 更新费用标签颜色
func update_cost_label_colors():
	if not game_config:
		return
		
	var current_coins = Global.get_coins()
	var background_manager = get_node_or_null("/root/Main/BackgroundManager")
	if not background_manager:
		return
	
	# 更新所有生成物的费用标签颜色
	for type in generator_ui_elements:
		var ui = generator_ui_elements[type]
		var cost = background_manager.generator_costs[type]
		
		# 如果金币不足，显示红色
		if current_coins < cost:
			ui.cost_label.add_theme_color_override("font_color", insufficient_funds_color)
		else:
			ui.cost_label.add_theme_color_override("font_color", default_label_color)

# 处理金币变化事件
func _on_coins_changed(new_amount):
	# 仅当界面可见时才更新UI
	if $PopupPanel.visible:
		update_ui_from_config()

# 确保按钮位于正确位置
func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		# 窗口大小改变时，重新定位按钮，无论其是否可见
		if show_button:
			call_deferred("_position_show_button")
			print("窗口大小改变，重新定位按钮")
			
# 每帧更新
func _process(delta):
	# 我们使用_position_show_button方法，这里不需要再进行按钮位置更新
	pass

# 设置当前生成器
func set_generator(type):
	current_generator = type
	update_selection_label()
	update_button_styles()

# 获取当前生成器
func get_current_generator():
	return current_generator

# 处理升级按钮点击
func _on_upgrade_button_pressed(type):
	print("PopupUI: ", game_config.get_generator_name(type), "升级按钮被点击")
	
	# 检查升级UI是否可用
	if ability_upgrade_ui:
		# 关闭当前面板
		$PopupPanel.hide()
		# 显示升级界面
		ability_upgrade_ui.show_for_generator(type)
	else:
		print("错误: 能力升级界面不可用")

# 处理升级完成
func _on_upgrade_completed():
	print("升级完成，重新显示生成器界面")
	# 重新显示当前面板
	$PopupPanel.popup()
	
	# 更新产出信息
	update_ui_from_config()

# 公开方法，允许其他脚本在需要时刷新UI
func refresh_ui():
	update_ui_from_config()

# 添加全局快捷键支持和父节点检查
func _input(event):
	# 按G键快速打开生成器界面
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		if not $PopupPanel.visible and show_button.visible:
			print("按下G键，触发显示生成界面")
			_on_show_button_pressed()
		elif $PopupPanel.visible:
			print("按下G键，触发关闭生成界面")
			_on_close_button_pressed()

# 设置显示按钮位置（延迟调用，确保视口大小已准备好）
func _position_show_button():
	# 保存当前可见状态
	var was_visible = show_button.visible
	
	# 获取视口大小
	var viewport_size = get_viewport().size
	
	# 固定位置到右上角，不随窗口大小变化而相对变化
	show_button.position = Vector2(viewport_size.x - show_button.custom_minimum_size.x - 20, 20)
	
	# 输出调试信息
	print("按钮定位: ", 
		"位置=(", show_button.position.x, ",", show_button.position.y, ") ",
		"按钮大小=(", show_button.custom_minimum_size.x, ",", show_button.custom_minimum_size.y, ") ",
		"可见=", show_button.visible,
		"视口大小=(", viewport_size.x, ",", viewport_size.y, ")",
		"父节点=", show_button.get_parent().name if show_button.get_parent() else "无")
		
	# 确保按钮添加到CanvasLayer（自身）作为直接子节点
	if show_button.get_parent() != self:
		print("按钮父节点不正确，重新添加到CanvasLayer")
		if show_button.get_parent():
			show_button.get_parent().remove_child(show_button)
		add_child(show_button)
		show_button.visible = was_visible  # 恢复之前的可见状态

# 在_ready函数最后添加检查
func _check_initial_button_state():
	print("初始检查按钮状态")
	
	# 确保按钮被正确添加到场景树
	if not show_button.is_inside_tree():
		print("按钮未在场景树中，重新添加")
		add_child(show_button)
	
	# 设置初始位置
	call_deferred("_position_show_button")

# 添加窗口大小改变的处理函数
func _on_window_size_changed():
	print("检测到窗口大小改变")
	call_deferred("_position_show_button")
	
	# 如果面板可见，同时更新面板位置
	if $PopupPanel.visible:
		var viewport_size = get_viewport().size
		$PopupPanel.position = Vector2(viewport_size.x - $PopupPanel.size.x - 20, 250)
