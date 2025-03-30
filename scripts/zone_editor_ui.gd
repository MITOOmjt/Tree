extends CanvasLayer

# UI元素引用
@onready var panel = $Panel
@onready var zone_list = $Panel/VBoxContainer/ZoneList
@onready var position_x = $Panel/VBoxContainer/PositionContainer/X
@onready var position_y = $Panel/VBoxContainer/PositionContainer/Y
@onready var size_x = $Panel/VBoxContainer/SizeContainer/X
@onready var size_y = $Panel/VBoxContainer/SizeContainer/Y
@onready var tree_toggle = $Panel/VBoxContainer/TypesContainer/TreeToggle
@onready var flower_toggle = $Panel/VBoxContainer/TypesContainer/FlowerToggle
@onready var bird_toggle = $Panel/VBoxContainer/TypesContainer/BirdToggle
@onready var color_picker = $Panel/VBoxContainer/ColorContainer/ColorPicker

# 获取日志记录器
@onready var _logger = get_node_or_null("/root/Logger")

# 当前选中的区域
var selected_zone = null

func _ready():
	# 初始隐藏面板
	panel.visible = false
	
	# 初始化UI
	refresh_zone_list()
	
	# 连接按钮信号
	$Panel/VBoxContainer/ButtonsContainer/VisibilityToggle.pressed.connect(_on_visibility_toggle_pressed)
	$Panel/VBoxContainer/ButtonsContainer/SaveButton.pressed.connect(_on_save_button_pressed)
	$Panel/VBoxContainer/ButtonsContainer/NewZoneButton.pressed.connect(_on_new_zone_button_pressed)
	$Panel/VBoxContainer/ButtonsContainer/DeleteZoneButton.pressed.connect(_on_delete_zone_button_pressed)
	$Panel/VBoxContainer/CloseButton.pressed.connect(_on_close_button_pressed)
	
	# 连接输入字段信号
	position_x.text_changed.connect(_on_position_changed)
	position_y.text_changed.connect(_on_position_changed)
	size_x.text_changed.connect(_on_size_changed)
	size_y.text_changed.connect(_on_size_changed)
	
	# 连接类型切换信号
	tree_toggle.toggled.connect(_on_type_toggled.bind(0))  # GeneratorType.TREE
	flower_toggle.toggled.connect(_on_type_toggled.bind(1))  # GeneratorType.FLOWER
	bird_toggle.toggled.connect(_on_type_toggled.bind(2))  # GeneratorType.BIRD
	
	# 连接颜色选择器信号
	color_picker.color_changed.connect(_on_color_changed)
	
	# 连接区域选择信号
	zone_list.item_selected.connect(_on_zone_selected)
	
	if _logger:
		_logger.debug("区域编辑器UI已初始化")
	else:
		print("区域编辑器UI已初始化")

# 处理输入事件，检测快捷键
func _input(event):
	# 按下Z键显示/隐藏编辑器
	if event is InputEventKey and event.pressed and event.keycode == KEY_Z:
		toggle_editor_visibility()

# 刷新区域列表
func refresh_zone_list():
	zone_list.clear()
	
	var zone_manager = get_node_or_null("/root/GenerationZoneManager")
	if not zone_manager:
		return
	
	for zone in zone_manager.zones:
		zone_list.add_item(zone.id)
	
	# 如果只有一个区域，默认选中它
	if zone_list.item_count == 1:
		zone_list.select(0)
		_on_zone_selected(0)

# 处理区域选择事件
func _on_zone_selected(index):
	var zone_manager = get_node_or_null("/root/GenerationZoneManager")
	if not zone_manager or index < 0 or index >= zone_manager.zones.size():
		selected_zone = null
		return
	
	selected_zone = zone_manager.zones[index]
	update_ui_for_selected_zone()

# 根据选中的区域更新UI
func update_ui_for_selected_zone():
	if not selected_zone:
		return
	
	# 更新位置和大小输入框
	position_x.text = str(selected_zone.position.x)
	position_y.text = str(selected_zone.position.y)
	size_x.text = str(selected_zone.size.x)
	size_y.text = str(selected_zone.size.y)
	
	# 更新类型切换
	tree_toggle.button_pressed = selected_zone.allowed_types.has(0)
	flower_toggle.button_pressed = selected_zone.allowed_types.has(1)
	bird_toggle.button_pressed = selected_zone.allowed_types.has(2)
	
	# 更新颜色选择器
	color_picker.color = selected_zone.color

# 处理位置改变事件
func _on_position_changed(new_text):
	if not selected_zone:
		return
	
	var zone_manager = get_node_or_null("/root/GenerationZoneManager")
	if not zone_manager:
		return
	
	var x = float(position_x.text) if position_x.text.is_valid_float() else selected_zone.position.x
	var y = float(position_y.text) if position_y.text.is_valid_float() else selected_zone.position.y
	
	zone_manager.update_zone_position(selected_zone.id, Vector2(x, y))

# 处理大小改变事件
func _on_size_changed(new_text):
	if not selected_zone:
		return
	
	var zone_manager = get_node_or_null("/root/GenerationZoneManager")
	if not zone_manager:
		return
	
	var x = float(size_x.text) if size_x.text.is_valid_float() else selected_zone.size.x
	var y = float(size_y.text) if size_y.text.is_valid_float() else selected_zone.size.y
	
	zone_manager.update_zone_size(selected_zone.id, Vector2(max(10, x), max(10, y)))

# 处理类型切换事件
func _on_type_toggled(pressed, type):
	if not selected_zone:
		return
	
	var zone_manager = get_node_or_null("/root/GenerationZoneManager")
	if not zone_manager:
		return
	
	var zone = zone_manager.get_zone_by_id(selected_zone.id)
	if not zone:
		return
	
	if pressed and not zone.allowed_types.has(type):
		zone.allowed_types.append(type)
	elif not pressed and zone.allowed_types.has(type):
		zone.allowed_types.erase(type)

# 处理颜色改变事件
func _on_color_changed(new_color):
	if not selected_zone:
		return
	
	var zone_manager = get_node_or_null("/root/GenerationZoneManager")
	if not zone_manager:
		return
	
	var zone = zone_manager.get_zone_by_id(selected_zone.id)
	if not zone:
		return
	
	zone.color = new_color

# 处理可视化切换按钮事件
func _on_visibility_toggle_pressed():
	var zone_manager = get_node_or_null("/root/GenerationZoneManager")
	if zone_manager:
		zone_manager.toggle_debug_zones_visibility()

# 处理保存按钮事件
func _on_save_button_pressed():
	var zone_manager = get_node_or_null("/root/GenerationZoneManager")
	if zone_manager:
		var success = zone_manager.save_zones_config()
		if success:
			var message_bus = get_node_or_null("/root/MessageBus")
			if message_bus and message_bus.has_signal("show_message"):
				message_bus.emit_signal("show_message", "区域配置已保存", 2)
			else:
				print("区域配置已保存")

# 处理新建区域按钮事件
func _on_new_zone_button_pressed():
	var zone_manager = get_node_or_null("/root/GenerationZoneManager")
	if not zone_manager:
		return
	
	# 创建一个新的区域ID
	var new_id = "zone_" + str(zone_manager.zones.size() + 1)
	
	# 检查ID是否已存在，如果存在则加上时间戳
	if zone_manager.get_zone_by_id(new_id):
		new_id = new_id + "_" + str(Time.get_unix_time_from_system())
	
	# 创建新区域 - 默认在屏幕中心，允许所有类型
	var success = zone_manager.create_new_zone(
		new_id,
		Vector2(300, 300),  # 默认位置
		Vector2(200, 150),  # 默认大小
		[0, 1, 2],  # 默认允许所有类型
		Color(0.2, 0.8, 0.2, 0.3)  # 默认颜色
	)
	
	if success:
		refresh_zone_list()
		
		# 选择新创建的区域
		for i in range(zone_list.item_count):
			if zone_list.get_item_text(i) == new_id:
				zone_list.select(i)
				_on_zone_selected(i)
				break

# 处理删除区域按钮事件
func _on_delete_zone_button_pressed():
	if not selected_zone:
		return
	
	var zone_manager = get_node_or_null("/root/GenerationZoneManager")
	if not zone_manager:
		return
	
	zone_manager.remove_zone(selected_zone.id)
	selected_zone = null
	
	refresh_zone_list()

# 处理关闭按钮事件
func _on_close_button_pressed():
	panel.visible = false

# 切换编辑器可见性
func toggle_editor_visibility():
	panel.visible = !panel.visible
	
	# 如果打开编辑器，刷新区域列表
	if panel.visible:
		refresh_zone_list() 
