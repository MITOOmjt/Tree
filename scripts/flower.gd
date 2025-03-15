extends Node2D

var colors = [
	Color(1, 0, 0, 1),   # 红色
	Color(1, 0.5, 0, 1), # 橙色
	Color(1, 1, 0, 1),   # 黄色
	Color(0, 1, 0, 1),   # 绿色
	Color(0, 0, 1, 1),   # 蓝色
	Color(0.5, 0, 0.5, 1), # 紫色
	Color(1, 0, 1, 1),   # 粉色
]

func _ready():
	# 随机选择一种颜色
	var random_color = colors[randi() % colors.size()]
	$Polygon2D.color = random_color

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 点击花朵时增加金币
		if GameManager.coins != null:
			GameManager.add_coins(1) 