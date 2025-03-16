extends CanvasLayer

# 信号定义，用于通知背景管理器选择的变化
signal generator_selected(type)

# 生成器类型枚举
enum GeneratorType {TREE = 0, FLOWER = 1, BIRD = 2}

# 变量
var tree_button
var flower_button
var bird_button
var current_selection_label
var current_generator = GeneratorType.FLOWER  # 默认选择花
var close_button
var show_button
var manual_close = false  # 记录是否是手动关闭
var allow_hide = false  # 控制是否允许面板隐藏

# 费用和产出标签
var tree_cost_label
var flower_cost_label 
var bird_cost_label
var tree_output_label
var flower_output_label
var bird_output_label

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
	
	# 获取按钮引用
	tree_button = popup.get_node("MarginContainer/VBoxContainer/GeneratorList/TreeItem/TreeButton")
	flower_button = popup.get_node("MarginContainer/VBoxContainer/GeneratorList/FlowerItem/FlowerButton")
	
	# 获取费用标签引用
	tree_cost_label = popup.get_node("MarginContainer/VBoxContainer/GeneratorList/TreeItem/VBoxContainer/CostLabel")
	flower_cost_label = popup.get_node("MarginContainer/VBoxContainer/GeneratorList/FlowerItem/VBoxContainer/CostLabel")
	
	# 创建树和花的产出标签
	var tree_container = popup.get_node("MarginContainer/VBoxContainer/GeneratorList/TreeItem/VBoxContainer")
	var flower_container = popup.get_node("MarginContainer/VBoxContainer/GeneratorList/FlowerItem/VBoxContainer")
	
	tree_output_label = Label.new()
	tree_output_label.add_theme_font_size_override("font_size", 12)
	tree_output_label.add_theme_color_override("font_color", default_label_color)
	tree_container.add_child(tree_output_label)
	
	flower_output_label = Label.new()
	flower_output_label.add_theme_font_size_override("font_size", 12)
	flower_output_label.add_theme_color_override("font_color", default_label_color)
	flower_container.add_child(flower_output_label)
	
	# 创建鸟按钮和项目
	var generator_list = popup.get_node("MarginContainer/VBoxContainer/GeneratorList")
	var bird_item = HBoxContainer.new()
	bird_item.name = "BirdItem"
	
	# 创建颜色方块
	var bird_color_rect = ColorRect.new()
	bird_color_rect.color = Color(0.87451, 0.443137, 0.14902, 1) # 鸟的橙色
	bird_color_rect.custom_minimum_size = Vector2(40, 40)
	bird_color_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# 创建文本信息容器
	var bird_text_container = VBoxContainer.new()
	bird_text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 创建名称标签
	var bird_name_label = Label.new()
	bird_name_label.text = "鸟"
	bird_name_label.add_theme_font_size_override("font_size", 16)
	
	# 创建费用标签
	bird_cost_label = Label.new()
	bird_cost_label.text = "花费: 10金币"
	bird_cost_label.add_theme_font_size_override("font_size", 12)
	bird_cost_label.add_theme_color_override("font_color", default_label_color)
	
	# 创建产出标签
	bird_output_label = Label.new()
	bird_output_label.add_theme_font_size_override("font_size", 12)
	bird_output_label.add_theme_color_override("font_color", default_label_color)
	
	# 创建选择按钮
	bird_button = Button.new()
	bird_button.text = "选择"
	bird_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# 添加所有元素
	bird_text_container.add_child(bird_name_label)
	bird_text_container.add_child(bird_cost_label)
	bird_text_container.add_child(bird_output_label)
	
	bird_item.add_child(bird_color_rect)
	bird_item.add_child(bird_text_container)
	bird_item.add_child(bird_button)
	
	# 设置间距与树和花一致
	bird_item.add_theme_constant_override("separation", 15)
	
	generator_list.add_child(bird_item)
	
	current_selection_label = popup.get_node("MarginContainer/VBoxContainer/CurrentSelectionLabel")
	
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
	
	# 连接按钮信号
	if tree_button and flower_button and bird_button:
		tree_button.pressed.connect(_on_tree_button_pressed)
		flower_button.pressed.connect(_on_flower_button_pressed)
		bird_button.pressed.connect(_on_bird_button_pressed)
		print("PopupUI: 按钮信号已连接")
	
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

# 树按钮点击处理
func _on_tree_button_pressed():
	print("PopupUI: 树按钮被点击")
	current_generator = GeneratorType.TREE
	update_selection_label()
	update_button_styles()
	emit_signal("generator_selected", current_generator)

# 花按钮点击处理
func _on_flower_button_pressed():
	print("PopupUI: 花按钮被点击")
	current_generator = GeneratorType.FLOWER
	update_selection_label()
	update_button_styles()
	emit_signal("generator_selected", current_generator)

# 鸟按钮点击处理
func _on_bird_button_pressed():
	print("PopupUI: 鸟按钮被点击")
	current_generator = GeneratorType.BIRD
	update_selection_label()
	update_button_styles()
	emit_signal("generator_selected", current_generator)

# 更新选择标签
func update_selection_label():
	if current_selection_label:
		var selection_text = "当前选择："
		if current_generator == GeneratorType.TREE:
			selection_text += "树"
		elif current_generator == GeneratorType.FLOWER:
			selection_text += "花"
		else:
			selection_text += "鸟"
		current_selection_label.text = selection_text

# 更新按钮样式
func update_button_styles():
	if tree_button and flower_button and bird_button:
		tree_button.text = "选择"
		flower_button.text = "选择"
		bird_button.text = "选择"
		
		if current_generator == GeneratorType.TREE:
			tree_button.text = "已选择"
		elif current_generator == GeneratorType.FLOWER:
			flower_button.text = "已选择"
		elif current_generator == GeneratorType.BIRD:
			bird_button.text = "已选择"

# 设置当前生成器
func set_generator(type):
	current_generator = type
	update_selection_label()
	update_button_styles()

# 获取当前生成器
func get_current_generator():
	return current_generator

# 从GameConfig更新显示信息
func update_ui_from_config():
	if not game_config:
		return
	
	# 获取背景管理器引用，用于获取动态成本
	var background_manager = get_node_or_null("/root/Main")
	if not background_manager:
		print("PopupUI: 无法获取背景管理器引用，将使用GameConfig中的基础成本")
		
	# 更新树木信息
	var tree_cost = background_manager.generator_costs[GeneratorType.TREE] if background_manager else game_config.get_generator_cost(GeneratorType.TREE)
	var tree_output = game_config.get_coin_generation("tree_coin_generation")
	var tree_interval = game_config.get_coin_generation("tree_coin_interval")
	var tree_factor = game_config.get_cost_growth_factor(GeneratorType.TREE)
	var tree_count = background_manager.generator_counts[GeneratorType.TREE] if background_manager else 0
	tree_cost_label.text = "花费: " + str(tree_cost) + "金币"
	tree_output_label.text = "产出: 每" + str(tree_interval) + "秒 " + str(tree_output) + "金币\n成本增长: x" + str(tree_factor) + "\n已建造: " + str(tree_count)
	
	# 更新花朵信息
	var flower_cost = background_manager.generator_costs[GeneratorType.FLOWER] if background_manager else game_config.get_generator_cost(GeneratorType.FLOWER)
	var flower_reward = game_config.get_coin_generation("flower_hover_reward")
	var flower_cooldown = game_config.get_coin_generation("flower_hover_cooldown")
	var flower_factor = game_config.get_cost_growth_factor(GeneratorType.FLOWER)
	var flower_count = background_manager.generator_counts[GeneratorType.FLOWER] if background_manager else 0
	flower_cost_label.text = "花费: " + str(flower_cost) + "金币"
	flower_output_label.text = "产出: 悬停每" + str(flower_cooldown) + "秒 " + str(flower_reward) + "金币\n成本增长: x" + str(flower_factor) + "\n已建造: " + str(flower_count)
	
	# 更新鸟类信息
	var bird_cost = background_manager.generator_costs[GeneratorType.BIRD] if background_manager else game_config.get_generator_cost(GeneratorType.BIRD)
	var bird_reward = game_config.get_coin_generation("bird_click_reward")
	var bird_factor = game_config.get_cost_growth_factor(GeneratorType.BIRD)
	var bird_count = background_manager.generator_counts[GeneratorType.BIRD] if background_manager else 0
	bird_cost_label.text = "花费: " + str(bird_cost) + "金币"
	bird_output_label.text = "产出: 点击获得" + str(bird_reward) + "金币\n成本增长: x" + str(bird_factor) + "\n已建造: " + str(bird_count)
	
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
	
	# 更新树木费用标签颜色
	var tree_cost = background_manager.generator_costs[GeneratorType.TREE]
	if current_coins < tree_cost:
		tree_cost_label.add_theme_color_override("font_color", insufficient_funds_color)
	else:
		tree_cost_label.add_theme_color_override("font_color", default_label_color)
	
	# 更新花朵费用标签颜色
	var flower_cost = background_manager.generator_costs[GeneratorType.FLOWER]
	if current_coins < flower_cost:
		flower_cost_label.add_theme_color_override("font_color", insufficient_funds_color)
	else:
		flower_cost_label.add_theme_color_override("font_color", default_label_color)
	
	# 更新鸟类费用标签颜色
	var bird_cost = background_manager.generator_costs[GeneratorType.BIRD]
	if current_coins < bird_cost:
		bird_cost_label.add_theme_color_override("font_color", insufficient_funds_color)
	else:
		bird_cost_label.add_theme_color_override("font_color", default_label_color)

# 处理金币变化事件
func _on_coins_changed(amount):
	update_cost_label_colors()

# 每帧更新
func _process(delta):
	if visible and not manual_close:
		update_ui_from_config()

# 处理右上角X按钮关闭请求
func _on_popup_close_requested():
	print("PopupUI: 右上角X按钮被点击")
	manual_close = true
	allow_hide = true  # 允许面板隐藏
	$PopupPanel.hide()
	print("PopupUI: 用户通过右上角X按钮关闭了界面")
