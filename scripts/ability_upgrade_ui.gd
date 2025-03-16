extends CanvasLayer

# 信号定义
signal upgrade_completed  # 当升级完成时发送信号

# 变量
var current_generator_type = null
var game_config = null
var ability_ui_elements = {}  # 存储能力UI元素的引用

# 初始化
func _ready():
	# 获取GameConfig引用
	game_config = get_node_or_null("/root/GameConfig")
	if not game_config:
		print("错误: 无法找到GameConfig单例")
		return
		
	# 初始化UI元素
	var panel = $UpgradePanel
	
	# 连接关闭按钮
	var close_button = panel.get_node("MarginContainer/VBoxContainer/CloseButton")
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# 隐藏面板，等待调用show_for_generator显示
	panel.hide()

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
	# 创建容器
	var ability_container = HBoxContainer.new()
	ability_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 添加左侧信息容器
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 能力名称
	var name_label = Label.new()
	name_label.text = _get_ability_display_name(ability_name)
	name_label.add_theme_font_size_override("font_size", 16)
	
	# 能力描述
	var desc_label = Label.new()
	desc_label.text = game_config.get_ability_description(current_generator_type, ability_name)
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	# 当前等级
	var level_label = Label.new()
	level_label.text = "当前等级: " + str(ability_data.level) + "/" + str(ability_data.max_level)
	level_label.add_theme_font_size_override("font_size", 14)
	
	# 添加到信息容器
	info_container.add_child(name_label)
	info_container.add_child(desc_label)
	info_container.add_child(level_label)
	
	# 创建升级按钮
	var upgrade_button = Button.new()
	upgrade_button.text = "升级"
	upgrade_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# 获取升级成本
	var upgrade_cost = game_config.calculate_ability_upgrade_cost(current_generator_type, ability_name)
	
	# 如果已达最大等级或无法升级
	if upgrade_cost < 0:
		upgrade_button.text = "已满级"
		upgrade_button.disabled = true
	else:
		upgrade_button.text = "升级 (" + str(upgrade_cost) + " 金币)"
		
		# 检查金币是否足够
		var current_coins = Global.get_coins()
		if current_coins < upgrade_cost:
			upgrade_button.disabled = true
			upgrade_button.add_theme_color_override("font_color_disabled", Color(0.9, 0.2, 0.2))
		
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
	parent_container.add_child(separator)

# 升级按钮点击处理
func _on_upgrade_button_pressed(ability_name):
	if not game_config or current_generator_type == null:
		return
	
	# 计算升级成本
	var upgrade_cost = game_config.calculate_ability_upgrade_cost(current_generator_type, ability_name)
	if upgrade_cost < 0:
		print("能力已达最大等级")
		return
	
	# 检查金币是否足够
	var current_coins = Global.get_coins()
	if current_coins < upgrade_cost:
		print("金币不足! 需要", upgrade_cost, "金币，当前只有", current_coins, "金币")
		return
	
	# 获取升级前的效果乘数
	var pre_upgrade_multiplier = game_config.get_ability_effect_multiplier(current_generator_type, ability_name)
	print("升级前", game_config.get_generator_name(current_generator_type), "的", ability_name, "效果乘数:", pre_upgrade_multiplier)
	
	# 扣除金币
	var success = Global.spend_coins(upgrade_cost)
	if not success:
		print("扣除金币失败")
		return
	
	# 升级能力
	var upgraded = game_config.upgrade_ability(current_generator_type, ability_name)
	if upgraded:
		print("成功升级", _get_ability_display_name(ability_name), "能力")
		
		# 获取升级后的效果乘数
		var post_upgrade_multiplier = game_config.get_ability_effect_multiplier(current_generator_type, ability_name)
		print("升级后", game_config.get_generator_name(current_generator_type), "的", ability_name, "效果乘数:", post_upgrade_multiplier)
		
		# 更新UI
		_update_ability_ui(ability_name)
		
		# 更新所有升级按钮状态（因为金币减少了）
		_update_all_upgrade_buttons()
		
		# 刷新所有生成物的配置
		var background_manager = get_node_or_null("/root/Main/BackgroundManager")
		if background_manager and background_manager.has_method("refresh_generators_config"):
			print("调用刷新配置函数: refresh_generators_config()")
			background_manager.refresh_generators_config()
			
			# 额外的调试 - 打印升级后的状态
			if background_manager.has_method("debug_print_abilities"):
				print("调用调试函数: debug_print_abilities()")
				background_manager.debug_print_abilities()
		else:
			print("警告: 无法找到BackgroundManager或refresh_generators_config方法")
		
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
