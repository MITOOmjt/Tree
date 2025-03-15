extends Node2D

var flower_scene = preload("res://scene/flower.tscn")
var tree_scene = preload("res://scene/direct_tree.tscn")

# 定义生成器类型枚举
enum GeneratorType {TREE = 0, FLOWER = 1}

# 变量定义
var current_generator = GeneratorType.FLOWER  # 默认选择花

# UI变量
var current_selection_label
var tree_button
var flower_button

func _ready():
	# 确保能接收输入
	set_process_input(true)
	
	# 设置生成器UI
	setup_generator_ui()
	
	print("初始生成器类型: ", "树" if current_generator == GeneratorType.TREE else "花")

# 设置生成器UI
func setup_generator_ui():
	print("设置生成器UI...")
	# 查找GeneratorUI节点
	if has_node("GeneratorUI"):
		var generator_ui = get_node("GeneratorUI")
		
		# 确保UI可见
		generator_ui.visible = true
		
		# 查找按钮
		tree_button = generator_ui.get_node("Control/GeneratorPanel/ScrollContainer/GeneratorList/TreeItem/HBoxContainer/TreeButton")
		flower_button = generator_ui.get_node("Control/GeneratorPanel/ScrollContainer/GeneratorList/FlowerItem/HBoxContainer/FlowerButton")
		
		if tree_button and flower_button:
			print("找到按钮，连接信号...")
			# 连接按钮信号
			tree_button.pressed.connect(_on_tree_button_pressed)
			flower_button.pressed.connect(_on_flower_button_pressed)
			
			# 获取当前选择标签
			current_selection_label = generator_ui.get_node("Control/GeneratorPanel/CurrentSelectionLabel")
			update_selection_label()
			update_button_styles()
			print("生成器UI设置完成")
		else:
			print("ERROR: 找不到按钮!")
	else:
		print("ERROR: 找不到GeneratorUI节点!")

# 更新按钮样式
func update_button_styles():
	if tree_button and flower_button:
		if current_generator == GeneratorType.TREE:
			tree_button.text = "已选择"
			flower_button.text = "选择"
		else:
			tree_button.text = "选择"
			flower_button.text = "已选择"

# 树按钮点击处理
func _on_tree_button_pressed():
	print("树按钮被点击!")
	current_generator = GeneratorType.TREE
	update_selection_label()
	update_button_styles()
	print("当前选择: 树")

# 花按钮点击处理
func _on_flower_button_pressed():
	print("花按钮被点击!")
	current_generator = GeneratorType.FLOWER
	update_selection_label()
	update_button_styles()
	print("当前选择: 花")

# 更新选择标签
func update_selection_label():
	if current_selection_label:
		var selection_text = "当前选择："
		if current_generator == GeneratorType.TREE:
			selection_text += "树"
		else:
			selection_text += "花"
		current_selection_label.text = selection_text

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 检查是否点击在树上，如果不是，则根据当前选择生成对应物体
		var click_position = event.position
		var is_on_tree = false
		
		# 获取所有树节点
		var trees = get_node("Trees").get_children() if has_node("Trees") else []
		for tree in trees:
			var tree_area = tree.get_node("ClickArea")
			if tree_area.get_global_transform().origin.distance_to(click_position) < 100:
				is_on_tree = true
				break
		
		# 如果没有点击在树上，则根据当前选择生成对应物体
		if not is_on_tree:
			# 检查当前选择的生成器类型并生成对应物体
			if current_generator == GeneratorType.TREE: # 树
				print("生成树木!")
				spawn_tree(click_position)
			else: # 花
				print("生成花朵!")
				spawn_flower(click_position)

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
