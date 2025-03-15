extends Node2D

# 调试路径
const POPUP_UI_PATH = "res://scene/generator_popup_ui.tscn"

var flower_scene = preload("res://scene/flower.tscn")
var tree_scene = preload("res://scene/direct_tree.tscn")
var popup_ui_scene = preload(POPUP_UI_PATH)

# 定义生成器类型枚举
enum GeneratorType {TREE = 0, FLOWER = 1}

# 变量定义
var current_generator = GeneratorType.FLOWER  # 默认选择花
var coins = 0

# 生成费用
var generator_costs = {
	GeneratorType.TREE: 3,  # 树木生成费用：3金币
	GeneratorType.FLOWER: 1  # 花朵生成费用：1金币
}

# UI变量
var popup_ui

func _ready():
	print("背景管理器：加载的弹出UI路径 =", POPUP_UI_PATH)
	
	# 确保能接收输入
	set_process_input(true)
	
	# 获取当前金币数量
	coins = Global.get_coins()
	
	# 实例化并设置弹出式UI
	setup_popup_ui()
	
	print("初始生成器类型: ", "树" if current_generator == GeneratorType.TREE else "花")
	print("当前金币: ", coins)

# 设置弹出式UI
func setup_popup_ui():
	# 实例化弹出UI
	popup_ui = popup_ui_scene.instantiate()
	add_child(popup_ui)
	
	# 连接选择器变更信号
	if popup_ui.has_signal("generator_selected"):
		popup_ui.generator_selected.connect(_on_generator_selected)
		print("成功连接generator_selected信号")
	else:
		print("错误：popup_ui没有generator_selected信号")
		# 列出所有可用信号
		var signal_list = popup_ui.get_signal_list()
		for sig in signal_list:
			print("可用信号: ", sig.name)
	
	print("弹出式UI设置完成")

# 处理生成器选择变更
func _on_generator_selected(type):
	print("生成器类型变更为: ", type)
	current_generator = type

# 处理输入事件
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 如果事件已经被处理（例如被UI处理）则跳过
		if get_viewport().is_input_handled():
			print("事件已被UI处理")
			return
		
		# 检查是否点击在显示按钮上
		if popup_ui and popup_ui.show_button and popup_ui.show_button.visible:
			# 简单检查点击位置是否在显示按钮的大致区域内
			var button = popup_ui.show_button
			var distance = event.position.distance_to(button.position + button.size/2)
			if distance < 75:  # 给一个宽松的判定范围
				print("点击在'打开生成界面'按钮附近")
				return
		
		# 检查是否点击在树上，如果不是，则根据当前选择生成对应物体
		var click_position = event.position
		var is_on_tree = false
		
		# 获取所有树节点
		var trees = get_node("Trees").get_children() if has_node("Trees") else []
		for tree in trees:
			var tree_area = tree.get_node("ClickArea")
			if tree_area and tree_area.get_global_transform().origin.distance_to(click_position) < 100:
				is_on_tree = true
				break
		
		# 如果没有点击在树上，则根据当前选择生成对应物体
		if not is_on_tree:
			print("点击空白区域，当前选择: ", "树" if current_generator == GeneratorType.TREE else "花")
			
			# 计算生成费用
			var cost = generator_costs[current_generator]
			coins = Global.get_coins()  # 获取最新的金币数量
			if coins >= cost:
				# 根据当前选择生成物体
				if current_generator == GeneratorType.TREE:
					print("生成树木! 花费 ", cost, " 金币")
					spawn_tree(click_position)
				else:
					print("生成花朵! 花费 ", cost, " 金币")
					spawn_flower(click_position)
				# 扣除金币
				Global.spend_coins(cost)
				print("剩余金币: ", Global.get_coins())
			else:
				print("金币不足! 需要 ", cost, " 金币，当前只有 ", coins, " 金币")

# 生成花朵
func spawn_flower(position):
	var flower = flower_scene.instantiate()
	flower.position = position
	
	# 如果Flowers节点不存在，则创建它
	if not has_node("Flowers"):
		var flowers_node = Node2D.new()
		flowers_node.name = "Flowers"
		add_child(flowers_node)
	
	get_node("Flowers").add_child(flower)

# 生成树木
func spawn_tree(position):
	var tree = tree_scene.instantiate()
	tree.position = position
	
	# 如果Trees节点不存在，则创建它
	if not has_node("Trees"):
		var trees_node = Node2D.new()
		trees_node.name = "Trees"
		add_child(trees_node)
	
	get_node("Trees").add_child(tree) 
