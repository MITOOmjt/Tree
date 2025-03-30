extends Node

# 生成区域数据结构
class GenerationZone:
	var id: String
	var position: Vector2
	var size: Vector2
	var allowed_types: Array  # 可以在该区域生成的类型
	var visible: bool = false # 是否在游戏中可见(调试用)
	var color: Color  # 区域颜色

	func _init(p_id: String, p_position: Vector2, p_size: Vector2, p_types: Array, p_color: Color = Color.GREEN):
		id = p_id
		position = p_position
		size = p_size
		allowed_types = p_types
		color = p_color

	# 检查点是否在区域内
	func is_point_inside(point: Vector2) -> bool:
		return (point.x >= position.x and 
				point.x <= position.x + size.x and
				point.y >= position.y and
				point.y <= position.y + size.y)

# 全局区域列表
var zones: Array = []
var debug_draw_zones: bool = false  # 是否绘制区域边界(调试用)

# 获取日志记录器
@onready var _logger = get_node_or_null("/root/Logger")

func _ready():
	# 加载默认区域或从配置文件加载
	_initialize_default_zones()
	
	if _logger:
		_logger.info("GenerationZoneManager: 初始化完成")
	else:
		print("GenerationZoneManager: 初始化完成")

# 初始化默认区域
func _initialize_default_zones():
	# 尝试加载已保存的配置
	var loaded = load_zones_config()
	
	# 如果没有加载到配置，创建默认区域
	if not loaded:
		# 创建默认草地区域(占据屏幕下半部分，适合生成树木和花朵)
		var ground_zone = GenerationZone.new(
			"ground_zone",
			Vector2(0, 450),  # 区域开始位置
			Vector2(1152, 200), # 区域大小
			[0, 1],  # GeneratorType.TREE, GeneratorType.FLOWER
			Color(0.2, 0.8, 0.2, 0.3)  # 半透明绿色
		)
		add_zone(ground_zone)
		
		if _logger:
			_logger.info("GenerationZoneManager: 创建默认区域")
		else:
			print("GenerationZoneManager: 创建默认区域")

# 添加区域
func add_zone(zone):
	zones.append(zone)

# 删除区域
func remove_zone(zone_id: String):
	for i in range(zones.size()):
		if zones[i].id == zone_id:
			zones.remove_at(i)
			return

# 检查点是否在某个允许生成特定类型的区域内
func is_in_allowed_zone(point: Vector2, generator_type: int) -> bool:
	for zone in zones:
		if zone.allowed_types.has(generator_type) and zone.is_point_inside(point):
			return true
	return false

# 获取某个生成类型的所有允许区域
func get_zones_for_type(generator_type: int) -> Array:
	var result = []
	for zone in zones:
		if zone.allowed_types.has(generator_type):
			result.append(zone)
	return result

# 根据ID获取区域
func get_zone_by_id(zone_id: String):
	for zone in zones:
		if zone.id == zone_id:
			return zone
	return null

# 更新区域位置
func update_zone_position(zone_id: String, new_position: Vector2):
	var zone = get_zone_by_id(zone_id)
	if zone:
		zone.position = new_position

# 更新区域大小
func update_zone_size(zone_id: String, new_size: Vector2):
	var zone = get_zone_by_id(zone_id)
	if zone:
		zone.size = new_size

# 显示/隐藏所有区域边界
func toggle_debug_zones_visibility():
	debug_draw_zones = !debug_draw_zones
	for zone in zones:
		zone.visible = debug_draw_zones
	
	if _logger:
		_logger.info("GenerationZoneManager: 区域可视化 %s" % ["开启" if debug_draw_zones else "关闭"])
	else:
		print("GenerationZoneManager: 区域可视化 %s" % ["开启" if debug_draw_zones else "关闭"])

# 保存区域配置到文件
func save_zones_config() -> bool:
	var config_data = []
	for zone in zones:
		config_data.append({
			"id": zone.id,
			"position_x": zone.position.x,
			"position_y": zone.position.y,
			"size_x": zone.size.x,
			"size_y": zone.size.y,
			"allowed_types": zone.allowed_types,
			"color": {
				"r": zone.color.r,
				"g": zone.color.g,
				"b": zone.color.b,
				"a": zone.color.a
			}
		})
	
	var config_file = ConfigFile.new()
	config_file.set_value("zones", "data", config_data)
	var err = config_file.save("user://generation_zones.cfg")
	if err != OK:
		if _logger:
			_logger.error("GenerationZoneManager: 保存区域配置失败 - %d" % err)
		else:
			print("GenerationZoneManager: 保存区域配置失败 - %d" % err)
		return false
	
	if _logger:
		_logger.info("GenerationZoneManager: 区域配置已保存")
	else:
		print("GenerationZoneManager: 区域配置已保存")
	return true

# 从文件加载区域配置
func load_zones_config() -> bool:
	var config_file = ConfigFile.new()
	var err = config_file.load("user://generation_zones.cfg")
	if err != OK:
		if _logger:
			_logger.warning("GenerationZoneManager: 加载区域配置失败或配置文件不存在 - %d" % err)
		else:
			print("GenerationZoneManager: 加载区域配置失败或配置文件不存在 - %d" % err)
		return false
	
	zones.clear()
	var config_data = config_file.get_value("zones", "data", [])
	for zone_data in config_data:
		var color = Color(
			zone_data.color.r,
			zone_data.color.g,
			zone_data.color.b,
			zone_data.color.a
		)
		var zone = GenerationZone.new(
			zone_data.id,
			Vector2(zone_data.position_x, zone_data.position_y),
			Vector2(zone_data.size_x, zone_data.size_y),
			zone_data.allowed_types,
			color
		)
		zones.append(zone)
	
	if _logger:
		_logger.info("GenerationZoneManager: 已加载 %d 个区域配置" % zones.size())
	else:
		print("GenerationZoneManager: 已加载 %d 个区域配置" % zones.size())
	return true

# 创建新区域
func create_new_zone(id: String, position: Vector2, size: Vector2, allowed_types: Array, color: Color = Color(0.2, 0.8, 0.2, 0.3)) -> bool:
	# 检查ID是否已存在
	if get_zone_by_id(id):
		if _logger:
			_logger.warning("GenerationZoneManager: 无法创建区域，ID已存在 - %s" % id)
		else:
			print("GenerationZoneManager: 无法创建区域，ID已存在 - %s" % id)
		return false
	
	var zone = GenerationZone.new(id, position, size, allowed_types, color)
	add_zone(zone)
	
	if _logger:
		_logger.info("GenerationZoneManager: 已创建新区域 - %s" % id)
	else:
		print("GenerationZoneManager: 已创建新区域 - %s" % id)
	return true 