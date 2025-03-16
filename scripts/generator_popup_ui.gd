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
var generator_ui_elements = {}  # {type: {button, cost_label, output_label}}

# 默认标签颜色
var default_label_color = Color(0.807843, 0.807843, 0.807843, 1)
var insufficient_funds_color = Color(0.9, 0.2, 0.2, 1)

# GameConfig引用
var game_config

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
		
	# 动态创建生成物UI项
	_create_generator_ui_items(generator_list)
	
	# 创建关闭按钮
	close_button = Button.new()
	close_button.text = "关闭"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	popup.get_node("MarginContainer/VBoxContainer").add_child(close_button)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# 创建显示按钮（位于屏幕底部）
	show_button = Button.new()
	show_button.text = "打开生成界面"
	show_button.position = Vector2(20, get_viewport().size.y - 60)
	show_button.size = Vector2(150, 40)
	show_button.visible = false  # 初始隐藏

	# 添加样式使按钮更明显
	var font = show_button.get_theme_font("font")
	if font:
		show_button.add_theme_font_size_override("font_size", 16)
	show_button.add_theme_color_override("font_color", Color(1, 1, 1))
	show_button.add_theme_color_override("font_color_hover", Color(1, 1, 0))
	show_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	var normal_style = show_button.get_theme_stylebox("normal")
	if normal_style is StyleBoxFlat:
		normal_style.bg_color = Color(0.2, 0.6, 0.3, 0.8)
		normal_style.corner_radius_top_left = 8
		normal_style.corner_radius_top_right = 8
		normal_style.corner_radius_bottom_left = 8
		normal_style.corner_radius_bottom_right = 8

	add_child(show_button)
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
	
	print("PopupUI: 初始化完成")

# 创建生成物UI项
func _create_generator_ui_items(parent_container):
	if not game_config:
		print("错误：GameConfig不可用，无法创建生成物UI")
		return
		
	# 获取所有生成物类型
	var generator_types = game_config.get_all_generator_types()
	
	# 按照类型ID排序
	generator_types.sort()
	
	# 为每种生成物类型创建UI项
	for type in generator_types:
		var template = game_config.get_generator_template(type)
		if template:
			# 创建生成物项容器
			var item_container = HBoxContainer.new()
			item_container.name = template.name + "Item"
			item_container.add_theme_constant_override("separation", 15)
			
			# 创建颜色方块
			var color_rect = ColorRect.new()
			color_rect.color = template.color
			color_rect.custom_minimum_size = Vector2(40, 40)
			color_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
			# 创建文本信息容器
			var text_container = VBoxContainer.new()
			text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			# 创建名称标签
			var name_label = Label.new()
			name_label.text = template.name
			name_label.add_theme_font_size_override("font_size", 16)
			
			# 创建费用标签
			var cost_label = Label.new()
			cost_label.add_theme_font_size_override("font_size", 12)
			cost_label.add_theme_color_override("font_color", default_label_color)
			
			# 创建产出标签
			var output_label = Label.new()
			output_label.add_theme_font_size_override("font_size", 12)
			output_label.add_theme_color_override("font_color", default_label_color)
			
			# 创建选择按钮
			var button = Button.new()
			button.text = "选择"
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
			# 连接按钮信号
			var callable = Callable(self, "_on_generator_button_pressed").bind(type)
			button.pressed.connect(callable)
			
			# 添加所有元素
			text_container.add_child(name_label)
			text_container.add_child(cost_label)
			text_container.add_child(output_label)
			
			item_container.add_child(color_rect)
			item_container.add_child(text_container)
			item_container.add_child(button)
			
			# 添加到父容器
			parent_container.add_child(item_container)
			
			# 保存引用
			generator_ui_elements[type] = {
				"button": button,
				"cost_label": cost_label,
				"output_label": output_label
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
	print("PopupUI: 面板隐藏")
	
	# 如果是手动关闭，我们显示显示按钮
	if manual_close:
		show_button.visible = true
		manual_close = false
	else:
		# 如果是自动关闭（点击外部），则重新显示面板
		if not allow_hide:
			call_deferred("_reshow_popup")
		else:
			allow_hide = false

# 处理右上角X按钮关闭请求
func _on_popup_close_requested():
	print("PopupUI: 右上角X按钮被点击")
	manual_close = true
	allow_hide = true  # 允许面板隐藏
	$PopupPanel.hide()
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
	print("PopupUI: 用户手动关闭了界面")

# 显示按钮点击处理
func _on_show_button_pressed():
	print("PopupUI: 显示按钮被点击")
	show_button.visible = false
	$PopupPanel.popup()
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

# 从GameConfig更新显示信息
func update_ui_from_config():
	if not game_config:
		return
	
	# 获取背景管理器引用，用于获取动态成本
	var background_manager = get_node_or_null("/root/Main")
	if not background_manager:
		print("PopupUI: 无法获取背景管理器引用，将使用GameConfig中的基础成本")
	
	# 更新所有生成物的UI信息
	for type in generator_ui_elements:
		var template = game_config.get_generator_template(type)
		if template:
			var ui_elements = generator_ui_elements[type]
			
			# 获取成本（从背景管理器或基础值）
			var cost = background_manager.generator_costs[type] if background_manager else template.base_cost
			
			# 获取计数和生成信息
			var count = background_manager.generator_counts[type] if background_manager else 0
			var output_info = template.generation
			
			# 更新成本显示
			ui_elements.cost_label.text = "花费: " + str(cost) + "金币"
			
			# 更新产出信息显示
			var output_text = ""
			match output_info.type:
				"interval":
					output_text = "产出: 每" + str(output_info.interval) + "秒 " + str(output_info.amount) + "金币"
				"hover":
					output_text = "产出: 悬停每" + str(output_info.cooldown) + "秒 " + str(output_info.amount) + "金币"
				"click":
					output_text = "产出: 点击获得" + str(output_info.amount) + "金币"
				_:
					output_text = "产出: 未知"
					
			output_text += "\n成本增长: x" + str(template.growth_factor)
			output_text += "\n已建造: " + str(count)
			
			ui_elements.output_label.text = output_text
	
	# 更新标签颜色
	update_cost_label_colors()

# 更新费用标签颜色
func update_cost_label_colors():
	if not game_config:
		return
		
	var current_coins = Global.get_coins()
	var background_manager = get_node_or_null("/root/Main")
	if not background_manager:
		return
	
	# 更新所有生成物的费用标签颜色
	for type in generator_ui_elements:
		var ui_elements = generator_ui_elements[type]
		var cost = background_manager.generator_costs[type]
		
		# 如果金币不足，显示红色
		if current_coins < cost:
			ui_elements.cost_label.add_theme_color_override("font_color", insufficient_funds_color)
		else:
			ui_elements.cost_label.add_theme_color_override("font_color", default_label_color)

# 处理金币变化事件
func _on_coins_changed(amount):
	update_cost_label_colors()

# 每帧更新
func _process(delta):
	if visible and not manual_close:
		update_ui_from_config()

# 设置当前生成器
func set_generator(type):
	current_generator = type
	update_selection_label()
	update_button_styles()

# 获取当前生成器
func get_current_generator():
	return current_generator
