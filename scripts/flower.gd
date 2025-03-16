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

# 预加载浮动文本场景
var floating_text_scene = preload("res://scene/floating_text.tscn")
# 鼠标悬停获得金币的量
var hover_coin_reward = 1
# 悬停冷却计时器
var hover_cooldown = 0.0
# 悬停冷却时间（秒）
var hover_cooldown_time = 1.5
# 是否正在悬停
var is_hovering = false
# 碰撞检测半径
var detection_radius = 25.0

func _ready():
	# 随机选择一种颜色
	var random_color = colors[randi() % colors.size()]
	$Polygon2D.color = random_color
	
	# 确保启用处理和输入处理
	set_process(true)
	set_process_input(true)
	
	print("花的脚本初始化完成，冷却时间:", hover_cooldown_time, "检测半径:", detection_radius)

func _process(delta):
	# 处理悬停冷却
	if hover_cooldown > 0:
		hover_cooldown -= delta
	
	# 检查鼠标位置是否在花朵上方
	_check_mouse_hover()
	
	# 如果正在悬停且冷却结束，给予金币奖励
	if is_hovering and hover_cooldown <= 0:
		_give_hover_reward()
		hover_cooldown = hover_cooldown_time
		print("花给予金币奖励，剩余冷却:", hover_cooldown)

# 检查鼠标是否悬停在花朵上
func _check_mouse_hover():
	# 安全获取鼠标位置
	var viewport = get_viewport()
	if viewport == null:
		return
	
	var mouse_pos = viewport.get_mouse_position()
	if mouse_pos == null or global_position == null:
		return
	
	# 计算距离前确保值不为空
	var distance = 9999.0  # 默认一个很大的距离
	if typeof(global_position) != TYPE_NIL and typeof(mouse_pos) != TYPE_NIL:
		distance = global_position.distance_to(mouse_pos)
	
	var was_hovering = is_hovering
	# 确保所有值都不为空再进行比较
	if typeof(distance) != TYPE_NIL and typeof(detection_radius) != TYPE_NIL:
		is_hovering = distance <= detection_radius
	else:
		is_hovering = false
	
	# 状态变化时执行相应操作
	if is_hovering and not was_hovering:
		_on_mouse_entered()
	elif not is_hovering and was_hovering:
		_on_mouse_exited()

# 给予悬停奖励
func _give_hover_reward():
	# 增加金币
	Global.add_coins(hover_coin_reward)
	print("花增加金币:", hover_coin_reward, "当前总金币:", Global.get_coins())
	
	# 在花的位置显示浮动文本
	var floating_text = floating_text_scene.instantiate()
	floating_text.position = global_position + Vector2(0, -20)  # 在花朵上方显示
	floating_text.text = "+" + str(hover_coin_reward)
	get_tree().get_root().add_child(floating_text)
	
	# 让花朵轻微抖动作为视觉反馈
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	# 显示消息
	if has_node("/root/MessageBus"):
		MessageBus.get_instance().emit_signal("show_message", "鼠标悬停在花上获得" + str(hover_coin_reward) + "金币！", 1)

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 点击花朵时增加金币
		Global.add_coins(1)
		print("点击花朵，增加1金币")
		
		# 显示浮动文本
		var floating_text = floating_text_scene.instantiate()
		floating_text.position = get_global_mouse_position()
		floating_text.text = "+1"
		get_tree().get_root().add_child(floating_text)

# 鼠标进入花朵区域
func _on_mouse_entered():
	# 鼠标形状变为手形
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	print("鼠标进入花朵区域")

# 鼠标离开花朵区域
func _on_mouse_exited():
	# 恢复默认鼠标形状
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	print("鼠标离开花朵区域")

# 保留原来的信号回调，但重定向到新的函数
func _on_area_2d_mouse_entered():
	_on_mouse_entered()

func _on_area_2d_mouse_exited():
	_on_mouse_exited() 
