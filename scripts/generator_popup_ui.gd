extends CanvasLayer

# 信号定义，用于通知背景管理器选择的变化
signal generator_selected(type)

# 生成器类型枚举
enum GeneratorType {TREE = 0, FLOWER = 1}

# 变量
var tree_button
var flower_button
var current_selection_label
var current_generator = GeneratorType.FLOWER  # 默认选择花
var close_button
var show_button
var manual_close = false  # 记录是否是手动关闭
var allow_hide = false  # 控制是否允许面板隐藏

func _ready():
	print("PopupUI脚本(_ready)：开始初始化...")
	
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
	
	# 获取按钮引用
	tree_button = popup.get_node("MarginContainer/VBoxContainer/GeneratorList/TreeItem/TreeButton")
	flower_button = popup.get_node("MarginContainer/VBoxContainer/GeneratorList/FlowerItem/FlowerButton")
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
	if tree_button and flower_button:
		tree_button.pressed.connect(_on_tree_button_pressed)
		flower_button.pressed.connect(_on_flower_button_pressed)
		print("PopupUI: 按钮信号已连接")
	
	# 初始UI状态
	update_selection_label()
	update_button_styles()
	
	# 设置PopupPanel位置（右侧）
	popup.position = Vector2(get_viewport().size.x - popup.size.x - 20, 250)
	
	# 连接关闭请求信号
	popup.popup_hide.connect(_on_popup_hide)
	
	# 显示PopupPanel
	popup.popup()
	
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

# 更新选择标签
func update_selection_label():
	if current_selection_label:
		var selection_text = "当前选择："
		if current_generator == GeneratorType.TREE:
			selection_text += "树"
		else:
			selection_text += "花"
		current_selection_label.text = selection_text

# 更新按钮样式
func update_button_styles():
	if tree_button and flower_button:
		if current_generator == GeneratorType.TREE:
			tree_button.text = "已选择"
			flower_button.text = "选择"
		else:
			tree_button.text = "选择"
			flower_button.text = "已选择"

# 设置当前生成器
func set_generator(type):
	current_generator = type
	update_selection_label()
	update_button_styles()

# 获取当前生成器
func get_current_generator():
	return current_generator 
