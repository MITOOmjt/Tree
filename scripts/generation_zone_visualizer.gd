extends Node2D

# 获取日志记录器
@onready var _logger = get_node_or_null("/root/Logger")

func _ready():
	set_process(true)
	if _logger:
		_logger.debug("区域可视化器已初始化")
	else:
		print("区域可视化器已初始化")

func _process(delta):
	# 每帧更新强制重绘
	queue_redraw()

func _draw():
	# 获取区域管理器
	var zone_manager = get_node_or_null("/root/GenerationZoneManager")
	if not zone_manager or not zone_manager.debug_draw_zones:
		return
	
	# 绘制所有区域
	for zone in zone_manager.zones:
		# 绘制填充区域
		draw_rect(Rect2(zone.position, zone.size), zone.color, true)
		
		# 绘制边框
		var border_color = Color(zone.color)
		border_color.a = 1.0  # 不透明边框
		draw_rect(Rect2(zone.position, zone.size), border_color, false, 2.0)
		
		# 绘制区域ID文本
		var font_color = Color.BLACK
		draw_string(ThemeDB.fallback_font, zone.position + Vector2(10, 20), zone.id, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, font_color)
		
		# 绘制区域尺寸信息
		var size_text = "Size: %.0f x %.0f" % [zone.size.x, zone.size.y]
		draw_string(ThemeDB.fallback_font, zone.position + Vector2(10, 40), size_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, font_color)
		
		# 绘制允许类型
		var types = []
		for type in zone.allowed_types:
			match type:
				0:
					types.append("树")
				1:
					types.append("花")
				2:
					types.append("鸟")
		var types_text = "允许类型: " + ", ".join(types)
		draw_string(ThemeDB.fallback_font, zone.position + Vector2(10, 60), types_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, font_color) 
