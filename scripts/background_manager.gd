extends Node2D

var flower_scene = preload("res://scene/flower.tscn")

func _ready():
	# 确保能接收输入
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 检查是否点击在树上，如果不是，则生成花
		var click_position = event.position
		var is_on_tree = false
		
		# 获取所有树节点
		var trees = get_node("Trees").get_children()
		for tree in trees:
			var tree_area = tree.get_node("ClickArea")
			if tree_area.get_global_transform().origin.distance_to(click_position) < 100:
				is_on_tree = true
				break
		
		# 如果没有点击在树上，则生成花
		if not is_on_tree:
			spawn_flower(click_position)

func spawn_flower(position):
	var flower = flower_scene.instantiate()
	flower.position = position
	
	# 如果Flowers节点不存在，则创建它
	if not has_node("Flowers"):
		var flowers_node = Node2D.new()
		flowers_node.name = "Flowers"
		add_child(flowers_node)
	
	get_node("Flowers").add_child(flower) 
