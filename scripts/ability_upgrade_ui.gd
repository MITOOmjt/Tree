extends CanvasLayer

# 信号定义
signal upgrade_completed  # 当升级完成时发送信号

# 变量
var current_generator_type = null
var game_config = null
var ability_ui_elements = {}  # 存储能力UI元素的引用

# 确保Logger单例在编译时可见
@onready var _logger = get_node("/root/Logger")

# 配置
var title_font_size = 20
var subtitle_font_size = 14
var normal_font_size = 14

# 当前选择的能力名称
var current_ability_name = null

# 生成器名称
var generator_names = {}

# 能力名称
var ability_display_names = {
	"efficiency": "效率",
	"speed": "速度",
	"cooldown": "冷却"
}

# 初始化
func _ready():
	# 获取GameConfig引用
	game_config = get_node_or_null("/root/GameConfig")
	if not game_config:
		_logger.error("无法找到GameConfig单例")
		return
		
	# 初始化UI元素
	var panel = $UpgradePanel
	
	# 连接关闭按钮
	var close_button = panel.get_node("MarginContainer/VBoxContainer/CloseButton")
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# 应用Ghibli风格
	_apply_ghibli_style()
	
	# 隐藏面板，等待调用show_for_generator显示
	panel.hide()
	
	_logger.info("能力升级UI已初始化并应用Ghibli风格")

# 为特定生成物显示升级面板
func show_for_generator(generator_type):
	if not game_config:
		print("错误: GameConfig不可用，无法显示升级面板")
		return
		
	current_generator_type = generator_type
	var panel = $UpgradePanel
	
	# 更新面板标题
	var title_label = panel.get_node("MarginContainer/VBoxContainer/TitleLabel")
	if title_label:
		var generator_name = game_config.get_generator_name(generator_type)
		title_label.text = generator_name + "升级"
	
	# 清空能力容器
	var abilities_container = panel.get_node("MarginContainer/VBoxContainer/AbilitiesContainer")
	for child in abilities_container.get_children():
		child.queue_free()
	
	ability_ui_elements.clear()
	
	# 获取生成物能力列表
	var abilities = game_config.get_generator_abilities(generator_type)
	if abilities.size() == 0:
		var label = Label.new()
		label.text = "该生成物没有可升级的能力"
		abilities_container.add_child(label)
	else:
		# 为每个能力创建UI元素
		for ability_name in abilities:
			_create_ability_ui(abilities_container, ability_name, abilities[ability_name])
	
	# 显示面板
	panel.popup_centered(Vector2(500, 400))

# 创建单个能力的UI元素
func _create_ability_ui(parent_container, ability_name, ability_data):
	# 获取GhibliTheme单例
	var ghibli_theme = get_node_or_null("/root/GhibliTheme")
	
	# 创建容器
	var ability_container = HBoxContainer.new()
	ability_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ability_container.add_theme_constant_override("separation", 15)
	
	# 添加左侧信息容器
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_theme_constant_override("separation", 5)
	
	# 能力名称
	var name_label = Label.new()
	name_label.text = _get_ability_display_name(ability_name)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.2))  # 深棕色文字
	
	# 能力描述
	var desc_label = Label.new()
	desc_label.text = game_config.get_ability_description(current_generator_type, ability_name)
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.3))  # 中棕色文字
	
	# 当前等级
	var level_label = Label.new()
	level_label.text = "当前等级: " + str(ability_data.level) + "/" + str(ability_data.max_level)
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.2))  # 深棕色文字
	
	# 添加到信息容器
	info_container.add_child(name_label)
	info_container.add_child(desc_label)
	info_container.add_child(level_label)
	
	# 创建升级按钮 - 类似参考图片中的按钮
	var upgrade_button = Button.new()
	upgrade_button.text = "升级"
	upgrade_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	upgrade_button.custom_minimum_size = Vector2(120, 40)
	
	# 应用按钮样式 - 参考图片中的淡黄色按钮风格
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.98, 0.92, 0.75, 0.98)  # 淡黄色背景
	button_style.corner_radius_top_left = 15
	button_style.corner_radius_top_right = 15
	button_style.corner_radius_bottom_left = 15
	button_style.corner_radius_bottom_right = 15
	button_style.border_width_top = 1
	button_style.border_width_right = 1
	button_style.border_width_bottom = 1
	button_style.border_width_left = 1
	button_style.border_color = Color(0.85, 0.75, 0.6, 0.8)  # 米棕色边框
	
	upgrade_button.add_theme_stylebox_override("normal", button_style)
	upgrade_button.add_theme_font_size_override("font_size", 16)
	upgrade_button.add_theme_color_override("font_color", Color(0.4, 0.3, 0.2))  # 深棕色文字
	
	# 悬停样式
	var hover_style = button_style.duplicate()
	hover_style.bg_color = hover_style.bg_color.lightened(0.05)
	upgrade_button.add_theme_stylebox_override("hover", hover_style)
	
	# 按下样式
	var pressed_style = button_style.duplicate()
	pressed_style.bg_color = pressed_style.bg_color.darkened(0.05)
	pressed_style.shadow_offset = Vector2(0, 0)
	upgrade_button.add_theme_stylebox_override("pressed", pressed_style)
	
	# 获取升级成本
	var upgrade_cost = game_config.calculate_ability_upgrade_cost(current_generator_type, ability_name)
	
	# 如果已达最大等级或无法升级
	if upgrade_cost < 0:
		upgrade_button.text = "已满级"
		upgrade_button.disabled = true
		
		# 禁用样式
		upgrade_button.add_theme_color_override("font_color_disabled", Color(0.6, 0.5, 0.4))
	else:
		upgrade_button.text = "升级 (" + str(upgrade_cost) + " 金币)"
		
		# 检查金币是否足够
		var current_coins = Global.get_coins()
		if current_coins < upgrade_cost:
			upgrade_button.disabled = true
			
			# 即使禁用也保持易读性
			upgrade_button.add_theme_color_override("font_color_disabled", Color(0.7, 0.3, 0.3))
		
		# 连接按钮信号
		var callable = Callable(self, "_on_upgrade_button_pressed").bind(ability_name)
		upgrade_button.pressed.connect(callable)
	
	# 添加到能力容器
	ability_container.add_child(info_container)
	ability_container.add_child(upgrade_button)
	
	# 添加到父容器
	parent_container.add_child(ability_container)
	
	# 保存UI元素引用
	ability_ui_elements[ability_name] = {
		"container": ability_container,
		"level_label": level_label,
		"upgrade_button": upgrade_button
	}
	
	# 添加分隔线
	var separator = HSeparator.new()
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 应用分隔线样式
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0.85, 0.75, 0.6, 0.4)  # 柔和的分隔线颜色
	sep_style.thickness = 1
	separator.add_theme_stylebox_override("separator", sep_style)
	
	parent_container.add_child(separator)

# 升级按钮点击处理
func _on_upgrade_button_pressed(ability_name):
	if not game_config or current_generator_type == null:
		return
	
	# 计算升级成本
	var upgrade_cost = game_config.calculate_ability_upgrade_cost(current_generator_type, ability_name)
	if upgrade_cost < 0:
		_logger.warning("能力已达最大等级")
		return
	
	# 检查金币是否足够
	var current_coins = Global.get_coins()
	if current_coins < upgrade_cost:
		_logger.warning("金币不足! 需要 %d 金币，当前只有 %d 金币" % [upgrade_cost, current_coins])
		return
	
	# 获取升级前的效果乘数
	var pre_upgrade_multiplier = game_config.get_ability_effect_multiplier(current_generator_type, ability_name)
	_logger.debug("升级前 %s 的 %s 效果乘数: %s" % [
		game_config.get_generator_name(current_generator_type),
		ability_name,
		pre_upgrade_multiplier
	])
	
	# 扣除金币
	var success = Global.spend_coins(upgrade_cost)
	if not success:
		_logger.error("扣除金币失败")
		return
	
	# 升级能力
	var upgraded = game_config.upgrade_ability(current_generator_type, ability_name)
	if upgraded:
		_logger.info("成功升级 %s 能力" % [_get_ability_display_name(ability_name)])
		
		# 获取升级后的效果乘数
		var post_upgrade_multiplier = game_config.get_ability_effect_multiplier(current_generator_type, ability_name)
		_logger.debug("升级后 %s 的 %s 效果乘数: %s" % [
			game_config.get_generator_name(current_generator_type),
			ability_name,
			post_upgrade_multiplier
		])
		
		# 更新UI
		_update_ability_ui(ability_name)
		
		# 更新所有升级按钮状态（因为金币减少了）
		_update_all_upgrade_buttons()
		
		# 刷新所有生成物的配置
		var background_manager = get_node_or_null("/root/Main/BackgroundManager")
		if background_manager and background_manager.has_method("refresh_generators_config"):
			_logger.debug("调用刷新配置函数: refresh_generators_config()")
			background_manager.refresh_generators_config()
			
			# 额外的调试 - 打印升级后的状态
			if background_manager.has_method("debug_print_abilities"):
				_logger.debug("调用调试函数: debug_print_abilities()")
				background_manager.debug_print_abilities()
		else:
			_logger.warning("无法找到BackgroundManager或refresh_generators_config方法")
		
		# 发送通知信号
		if has_node("/root/MessageBus"):
			var message = "升级成功! " + _get_ability_display_name(ability_name) + "能力提升"
			MessageBus.get_instance().emit_signal("show_message", message, 2)
	
		# 发送升级完成信号
		emit_signal("upgrade_completed")

# 更新指定能力的UI
func _update_ability_ui(ability_name):
	if not ability_ui_elements.has(ability_name):
		return
	
	var ui = ability_ui_elements[ability_name]
	var ability_data = game_config.get_generator_abilities(current_generator_type)[ability_name]
	
	# 更新等级标签
	ui.level_label.text = "当前等级: " + str(ability_data.level) + "/" + str(ability_data.max_level)
	
	# 更新升级按钮
	var upgrade_cost = game_config.calculate_ability_upgrade_cost(current_generator_type, ability_name)
	if upgrade_cost < 0:
		ui.upgrade_button.text = "已满级"
		ui.upgrade_button.disabled = true
	else:
		ui.upgrade_button.text = "升级 (" + str(upgrade_cost) + " 金币)"

# 更新所有升级按钮状态
func _update_all_upgrade_buttons():
	var current_coins = Global.get_coins()
	
	for ability_name in ability_ui_elements:
		var ui = ability_ui_elements[ability_name]
		var upgrade_cost = game_config.calculate_ability_upgrade_cost(current_generator_type, ability_name)
		
		if upgrade_cost < 0:
			ui.upgrade_button.text = "已满级"
			ui.upgrade_button.disabled = true
		else:
			ui.upgrade_button.text = "升级 (" + str(upgrade_cost) + " 金币)"
			ui.upgrade_button.disabled = current_coins < upgrade_cost

# 关闭按钮点击处理
func _on_close_button_pressed():
	$UpgradePanel.hide()
	emit_signal("upgrade_completed")

# 获取能力的显示名称
func _get_ability_display_name(ability_name):
	match ability_name:
		"efficiency":
			return "效率"
		"speed":
			return "速度"
		"cooldown":
			return "冷却"
		_:
			return ability_name.capitalize()

# 直接更新UI (当金币变化时调用)
func update_ui():
	if current_generator_type != null and $UpgradePanel.visible:
		_update_all_upgrade_buttons() 

# 应用Ghibli风格到UI元素
func _apply_ghibli_style():
	# 获取GhibliTheme单例
	var ghibli_theme = get_node_or_null("/root/GhibliTheme")
	if not ghibli_theme:
		_logger.warning("无法获取GhibliTheme单例")
		return
	
	# 升级面板
	var panel = $UpgradePanel
	if panel:
		# 应用Ghibli风格的面板背景 - 类似参考图片中的风格
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.98, 0.92, 0.75, 0.98)  # 淡黄色背景
		panel_style.corner_radius_top_left = 15
		panel_style.corner_radius_top_right = 15
		panel_style.corner_radius_bottom_left = 15
		panel_style.corner_radius_bottom_right = 15
		panel_style.border_width_top = 1
		panel_style.border_width_right = 1
		panel_style.border_width_bottom = 1
		panel_style.border_width_left = 1
		panel_style.border_color = Color(0.85, 0.75, 0.6, 0.8)  # 米棕色边框
		panel_style.shadow_color = Color(0.2, 0.18, 0.15, 0.2)
		panel_style.shadow_size = 3
		panel_style.shadow_offset = Vector2(2, 2)
		panel.add_theme_stylebox_override("panel", panel_style)
		
		# 标题标签
		var title_label = panel.get_node("MarginContainer/VBoxContainer/TitleLabel")
		if title_label:
			title_label.add_theme_font_size_override("font_size", 28)
			title_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.2))  # 深棕色文字
		
		# 分隔线
		var separator = panel.get_node("MarginContainer/VBoxContainer/HSeparator")
		if separator:
			separator.add_theme_constant_override("separation", 20)
			
			var sep_style = StyleBoxLine.new()
			sep_style.color = Color(0.85, 0.75, 0.6, 0.4)  # 柔和的分隔线颜色
			sep_style.thickness = 1
			separator.add_theme_stylebox_override("separator", sep_style)
		
		# 关闭按钮
		var close_button = panel.get_node("MarginContainer/VBoxContainer/CloseButton")
		if close_button:
			# 使用参考图片中的淡黄色按钮风格
			var button_style = StyleBoxFlat.new()
			button_style.bg_color = Color(0.98, 0.92, 0.75, 0.98)  # 淡黄色背景
			button_style.corner_radius_top_left = 15
			button_style.corner_radius_top_right = 15
			button_style.corner_radius_bottom_left = 15
			button_style.corner_radius_bottom_right = 15
			button_style.border_width_top = 1
			button_style.border_width_right = 1
			button_style.border_width_bottom = 1
			button_style.border_width_left = 1
			button_style.border_color = Color(0.85, 0.75, 0.6, 0.8)  # 米棕色边框
			
			close_button.add_theme_stylebox_override("normal", button_style)
			close_button.add_theme_font_size_override("font_size", 18)
			close_button.add_theme_color_override("font_color", Color(0.4, 0.3, 0.2))  # 深棕色文字
			close_button.custom_minimum_size = Vector2(120, 40)
			
			# 悬停样式
			var hover_style = button_style.duplicate()
			hover_style.bg_color = hover_style.bg_color.lightened(0.05)
			close_button.add_theme_stylebox_override("hover", hover_style)
			
			# 按下样式
			var pressed_style = button_style.duplicate()
			pressed_style.bg_color = pressed_style.bg_color.darkened(0.05)
			pressed_style.shadow_offset = Vector2(0, 0)
			close_button.add_theme_stylebox_override("pressed", pressed_style)
