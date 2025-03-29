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
	popup.get_node("MarginContainer/VBoxContainer").add_child(close_button)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# 创建显示按钮（位于屏幕中间位置更容易看到）
	show_button = Button.new()
	show_button.text = "打开生成界面"
	show_button.size = Vector2(250, 60)
	show_button.visible = false  # 初始隐藏
	
	# 确保按钮层级在最上方
	show_button.z_index = 100
	
	# 添加样式使按钮更明显
	var font = show_button.get_theme_font("font")
	if font:
		show_button.add_theme_font_size_override("font_size", 22)
	show_button.add_theme_color_override("font_color", Color(1, 1, 1))
	show_button.add_theme_color_override("font_color_hover", Color(1, 1, 0.3))
	show_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	var normal_style = show_button.get_theme_stylebox("normal")
	if normal_style is StyleBoxFlat:
		normal_style.bg_color = Color(0.3, 0.7, 0.4, 1.0)  # 完全不透明
		normal_style.corner_radius_top_left = 10
		normal_style.corner_radius_top_right = 10
		normal_style.corner_radius_bottom_left = 10
		normal_style.corner_radius_bottom_right = 10
		# 添加明显的边框
		normal_style.border_width_top = 4
		normal_style.border_width_right = 4
		normal_style.border_width_bottom = 4
		normal_style.border_width_left = 4
		normal_style.border_color = Color(1.0, 1.0, 0.3, 1.0)
		# 添加阴影
		normal_style.shadow_color = Color(0, 0, 0, 0.5)
		normal_style.shadow_size = 5
		normal_style.shadow_offset = Vector2(2, 2)

	# 将按钮添加到顶层，确保可见
	add_child(show_button)
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
		
		# 创建颜色标识
		var color_rect = ColorRect.new()
		color_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		color_rect.custom_minimum_size = Vector2(5, 0)
		color_rect.color = template.color
		
		# 创建文本容器
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
		
		# 创建按钮容器
		var button_container = VBoxContainer.new()
		button_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# 创建选择按钮
		var button = Button.new()
		button.text = "选择"
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# 连接按钮信号
		var callable = Callable(self, "_on_generator_button_pressed").bind(type)
		button.pressed.connect(callable)
		
		# 创建升级按钮
		var upgrade_button = Button.new()
		upgrade_button.text = "升级"
		upgrade_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		upgrade_button.visible = false  # 初始设置为隐藏，等数量达到2个时才显示
		
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
		
		# 添加到父容器
		parent_container.add_child(item_container)
		
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
		show_button.visible = true
		manual_close = false
		print("手动关闭：按钮已设置为可见")
		# 使用统一的方法设置按钮位置
		call_deferred("_position_show_button")
	else:
		# 如果是自动关闭（点击外部），则重新显示面板
		if not allow_hide:
			print("自动关闭但不允许隐藏：重新显示面板")
			call_deferred("_reshow_popup")
		else:
			allow_hide = false
			show_button.visible = true  # 确保按钮可见
			print("自动关闭且允许隐藏：按钮已设置为可见")
			call_deferred("_position_show_button")

# 处理右上角X按钮关闭请求
func _on_popup_close_requested():
	print("PopupUI: 右上角X按钮被点击")
	manual_close = true
	allow_hide = true  # 允许面板隐藏
	$PopupPanel.hide()
	
	# 确保显示按钮显示
	show_button.visible = true
	call_deferred("_position_show_button")
	
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
	
	# 确保显示按钮显示
	show_button.visible = true
	print("关闭面板，按钮已设置为可见")
	call_deferred("_position_show_button")
	
	print("PopupUI: 用户手动关闭了界面")

# 显示按钮点击处理
func _on_show_button_pressed():
	print("PopupUI: 显示按钮被点击")
	show_button.visible = false
	print("按钮已隐藏，准备显示面板")
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
		# 窗口大小改变时，重新定位按钮
		if show_button and show_button.visible:
			call_deferred("_position_show_button")
			
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
	# 放在屏幕中下方位置，更明显
	var viewport_size = get_viewport().size
	var old_position = show_button.position
	show_button.position = Vector2((viewport_size.x - show_button.size.x) / 2, viewport_size.y - 100)
	
	# 确保按钮在视图范围内
	if show_button.position.y < 0 or show_button.position.y > viewport_size.y:
		show_button.position.y = viewport_size.y - 100
	
	# 确保按钮添加到正确的父节点
	if show_button.get_parent() != self:
		print("警告：按钮父节点不正确，重新添加")
		if show_button.get_parent():
			show_button.get_parent().remove_child(show_button)
		add_child(show_button)
		show_button.visible = true
	
	# 调试输出
	print("按钮定位: ", 
		"旧位置=(", old_position.x, ",", old_position.y, ") ",
		"新位置=(", show_button.position.x, ",", show_button.position.y, ") ",
		"按钮大小=(", show_button.size.x, ",", show_button.size.y, ") ",
		"可见=", show_button.visible,
		"视口大小=(", viewport_size.x, ",", viewport_size.y, ")",
		"父节点=", show_button.get_parent().name)
		
# 在_ready函数最后添加检查
func _check_initial_button_state():
	print("初始检查按钮状态")
	
	# 确保按钮被正确添加到场景树
	if not show_button.is_inside_tree():
		print("按钮未在场景树中，重新添加")
		add_child(show_button)
	
	# 设置初始位置
	call_deferred("_position_show_button")
