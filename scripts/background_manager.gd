extends Node2D

# 调试路径
const POPUP_UI_PATH = "res://scene/generator_popup_ui.tscn"

# 场景缓存字典 - 动态加载以支持扩展
var scene_cache = {}
var popup_ui_scene = preload(POPUP_UI_PATH)

# 定义生成器类型枚举
enum GeneratorType {TREE = 0, FLOWER = 1, BIRD = 2}

# 变量定义
var current_generator = GeneratorType.FLOWER  # 默认选择花
var coins = 0

# 生成费用
var generator_costs = {}

# 跟踪已生成物体数量
var generator_counts = {}

# 费用增长系数
var cost_growth_factors = {}

# 初始基础费用
var base_generator_costs = {}

# UI变量
var popup_ui

# 容器节点引用缓存
var container_nodes = {}

# 预加载树场景
var tree_scene = preload("res://scene/direct_tree.tscn")
# 预加载花场景
var flower_scene = preload("res://scene/flower.tscn")
# 预加载鸟场景
var bird_scene = preload("res://scene/bird.tscn")

func _ready():
	print("背景管理器：加载的弹出UI路径 =", POPUP_UI_PATH)
	
	# 确保能接收输入
	set_process_input(true)
	
	# 获取当前金币数量
	coins = Global.get_coins()
	
	# 尝试从GameConfig加载配置
	_try_load_config()
	
	# 确保所有必要的容器节点都存在
	_ensure_container_nodes()
	
	# 实例化并设置弹出式UI
	setup_popup_ui()
	
	print("初始生成器类型: ", _get_generator_name(current_generator))
	print("当前金币: ", coins)

# 确保所有必要的容器节点都存在
func _ensure_container_nodes():
	var game_config = get_node_or_null("/root/GameConfig")
	if not game_config:
		print("找不到GameConfig，无法确保容器节点")
		return
		
	# 获取所有生成物类型
	var generator_types = game_config.get_all_generator_types()
	
	# 为每个需要容器的生成物类型创建容器节点
	for type in generator_types:
		var template = game_config.get_generator_template(type)
		if template and template.container_node != "":
			var container_name = template.container_node
			
			# 检查容器节点是否已存在
			if not has_node(container_name):
				# 创建容器节点
				var container = Node2D.new()
				container.name = container_name
				add_child(container)
				print("为生成物类型", template.name, "创建容器节点:", container_name)
			
			# 缓存容器节点引用
			container_nodes[type] = get_node(container_name)

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

# 获取生成器类型名称
func _get_generator_name(type):
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		return game_config.get_generator_name(type)
	
	# 备用方式 - 如果找不到GameConfig
	match type:
		GeneratorType.TREE:
			return "树"
		GeneratorType.FLOWER:
			return "花"
		GeneratorType.BIRD:
			return "鸟"
		_:
			return "未知类型"

# 处理生成器选择变更
func _on_generator_selected(type):
	print("生成器类型变更为: ", _get_generator_name(type))
	current_generator = type

# 处理输入事件
func _input(event):
	# 如果按下F3键，打印调试信息
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		debug_print_abilities()
		refresh_generators_config()
		print("已刷新所有生成物配置")
	
	# 如果按下F4键，强制刷新所有花朵
	if event is InputEventKey and event.pressed and event.keycode == KEY_F4:
		print("尝试强制刷新所有花朵...")
		var flowers_container = get_node_or_null("Flowers")
		if flowers_container:
			for flower in flowers_container.get_children():
				if flower.has_method("_load_config"):
					var old_reward = flower.hover_coin_reward
					flower._load_config()
					print("刷新花朵，奖励从", old_reward, "变为", flower.hover_coin_reward)
		else:
			print("没有找到Flowers容器节点")
	
	# 处理鼠标点击
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
		
		# 获取点击位置
		var click_position = event.position
		
		# 根据当前选择的生成器类型处理点击
		_handle_click(click_position, current_generator)

# 处理点击事件的通用函数
func _handle_click(click_position, generator_type):
	# 根据生成物的放置类型处理放置逻辑
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		var template = game_config.get_generator_template(generator_type)
		if template:
			if template.placement == "on_tree":
				# 需要放在树上的生成物
				_handle_on_tree_placement(click_position, generator_type)
			else:
				# 放在地面/背景的生成物
				_handle_ground_placement(click_position, generator_type)
		else:
			print("错误：未找到生成物模板, 类型:", generator_type)
	else:
		# 回退到旧的处理方式
		if generator_type == GeneratorType.BIRD:
			_handle_bird_generation(click_position)
		else:
			# 处理普通生成（树和花）
			_handle_normal_generation(click_position)

# 处理需要放在树上的生成物
func _handle_on_tree_placement(click_position, generator_type):
	# 获取所有树节点
	var trees_container = get_node_or_null("Trees")
	if not trees_container:
		print("错误：找不到树的容器节点")
		return
		
	var trees = trees_container.get_children()
	var clicked_tree = null
	
	# 检查点击位置是否在某棵树上
	for tree in trees:
		var tree_position = tree.global_position
		var distance = click_position.distance_to(tree_position)
		
		# 简单距离检查 - 如果点击位置在树的100像素范围内，认为点击在树上
		if distance < 100:
			clicked_tree = tree
			break
	
	# 如果找到被点击的树
	if clicked_tree:
		print("点击在树上，当前选择: ", _get_generator_name(generator_type))
		
		# 计算生成费用 - 使用动态成本
		var cost = calculate_current_cost(generator_type)
		coins = Global.get_coins()  # 获取最新的金币数量
		
		# 检查是否有足够金币
		if coins >= cost:
			print("生成", _get_generator_name(generator_type), "! 花费 ", cost, " 金币")
			
			# 加载场景
			var scene_instance = _load_and_instantiate_generator(generator_type)
			if scene_instance:
				# 计算在树上的相对位置
				var local_pos = clicked_tree.to_local(click_position)
				scene_instance.position = local_pos
				clicked_tree.add_child(scene_instance)
				
				# 更新数量
				generator_counts[generator_type] += 1
				
				# 更新动态成本
				update_generator_cost(generator_type)
				
				# 扣除金币
				Global.spend_coins(cost)
				
				# 通知UI更新
				_on_generator_created(generator_type)
				
				print("剩余金币: ", Global.get_coins())
			else:
				print("错误：无法实例化场景")
		else:
			print("金币不足! 需要 ", cost, " 金币，当前只有 ", coins, " 金币")
			MessageBus.get_instance().emit_signal("show_message", "金币不足! 需要 " + str(cost) + " 金币", 2)
	else:
		print("没有点击在树上，无法生成" + _get_generator_name(generator_type))
		MessageBus.get_instance().emit_signal("show_message", "请点击在树上生成" + _get_generator_name(generator_type), 2)

# 处理放在地面/背景的生成物
func _handle_ground_placement(click_position, generator_type):
	# 检查是否点击在树上，如果在树上则不生成新物体
	var is_on_tree = false
	
	# 获取所有树节点
	var trees_container = get_node_or_null("Trees")
	if trees_container:
		var trees = trees_container.get_children()
		for tree in trees:
			var tree_position = tree.global_position
			var distance = click_position.distance_to(tree_position)
			
			# 简单距离检查
			if distance < 100:
				is_on_tree = true
				break
	
	# 如果没有点击在树上，则生成对应物体
	if not is_on_tree:
		print("点击空白区域，当前选择: ", _get_generator_name(generator_type))
		
		# 计算动态生成费用
		var cost = calculate_current_cost(generator_type)
		coins = Global.get_coins()  # 获取最新的金币数量
		
		print("【调试】当前选择的生成物：", _get_generator_name(generator_type), 
			"，需要消耗金币：", cost, "，当前金币：", coins)
		
		if coins >= cost:
			# 加载场景并放置
			var scene_instance = _load_and_instantiate_generator(generator_type)
			if scene_instance:
				scene_instance.position = click_position
				
				# 获取合适的容器节点
				var container = null
				if container_nodes.has(generator_type):
					container = container_nodes[generator_type]
				
				# 添加到容器或直接添加到背景
				if container:
					container.add_child(scene_instance)
				else:
					add_child(scene_instance)
				
				print("生成", _get_generator_name(generator_type), "! 花费 ", cost, " 金币")
				
				# 更新数量
				generator_counts[generator_type] += 1
				
				# 更新成本
				update_generator_cost(generator_type)
				
				# 扣除金币
				print("【调试】扣除前金币：", Global.get_coins())
				var result = Global.spend_coins(cost)
				print("【调试】扣除结果：", result, "，扣除后金币：", Global.get_coins())
				
				# 通知UI更新
				_on_generator_created(generator_type)
				
				print("剩余金币: ", Global.get_coins())
			else:
				print("错误：无法实例化场景")
		else:
			print("金币不足! 需要 ", cost, " 金币，当前只有 ", coins, " 金币")
			MessageBus.get_instance().emit_signal("show_message", "金币不足! 需要 " + str(cost) + " 金币", 2)
	else:
		print("点击在树上，不生成" + _get_generator_name(generator_type))
		MessageBus.get_instance().emit_signal("show_message", "请点击空白区域生成" + _get_generator_name(generator_type), 2)

# 加载并实例化生成物场景
func _load_and_instantiate_generator(type):
	# 如果场景已经缓存，则使用缓存版本
	if scene_cache.has(type):
		return scene_cache[type].instantiate()
	
	# 如果未缓存，则尝试加载
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		var template = game_config.get_generator_template(type)
		if template and template.scene_path != "":
			var scene = load(template.scene_path)
			if scene:
				# 缓存场景资源
				scene_cache[type] = scene
				return scene.instantiate()
	
	# 回退方式 - 使用旧的预加载场景
	match type:
		GeneratorType.TREE:
			if not scene_cache.has(type):
				scene_cache[type] = tree_scene
			return scene_cache[type].instantiate()
		GeneratorType.FLOWER:
			if not scene_cache.has(type):
				scene_cache[type] = flower_scene
			return scene_cache[type].instantiate()
		GeneratorType.BIRD:
			if not scene_cache.has(type):
				scene_cache[type] = bird_scene
			return scene_cache[type].instantiate()
	
	print("错误：无法加载生成物场景，类型:", type)
	return null

# 以下函数为向后兼容保留
func _handle_bird_generation(click_position):
	_handle_on_tree_placement(click_position, GeneratorType.BIRD)

func _handle_normal_generation(click_position):
	# 根据当前选择调用相应的处理函数
	_handle_ground_placement(click_position, current_generator)

func spawn_flower(pos):
	var flower = _load_and_instantiate_generator(GeneratorType.FLOWER)
	if flower:
		flower.position = pos
		
		# 获取合适的容器节点
		var container = container_nodes.get(GeneratorType.FLOWER)
		if container:
			container.add_child(flower)
		else:
			add_child(flower)

func spawn_tree(pos):
	var tree = _load_and_instantiate_generator(GeneratorType.TREE)
	if tree:
		tree.position = pos
		
		# 获取合适的容器节点
		var container = container_nodes.get(GeneratorType.TREE)
		if container:
			container.add_child(tree)
		else:
			add_child(tree)

# 计算当前生成物的动态成本
func calculate_current_cost(type):
	var base_cost = base_generator_costs[type]
	var count = generator_counts[type]
	var factor = cost_growth_factors[type]
	
	# 如果是首次生成，使用基础成本
	if count == 0:
		return base_cost
	
	# 根据已生成数量和增长系数计算动态成本
	# 公式: base_cost * (factor ^ count)
	var dynamic_cost = base_cost * pow(factor, count)
	
	# 向上取整，避免小数
	return int(ceil(dynamic_cost))

# 更新生成物成本
func update_generator_cost(type):
	var new_cost = calculate_current_cost(type)
	generator_costs[type] = new_cost
	print("更新", _get_generator_name(type), "的生成成本为:", new_cost, "金币")
	
	# 如果UI存在，通知UI更新
	if popup_ui:
		popup_ui.update_ui_from_config()
		
# 成功创建生成物后更新UI
func _on_generator_created(type):
	# 生成物数量已在各自的处理函数中更新
	
	# 通知UI更新
	if popup_ui:
		popup_ui.update_ui_from_config()

# 尝试从GameConfig加载配置
func _try_load_config():
	var game_config = get_node_or_null("/root/GameConfig")
	if game_config:
		print("成功找到GameConfig单例")
		
		# 初始化所有生成物的计数器
		var generator_types = game_config.get_all_generator_types()
		for type in generator_types:
			generator_counts[type] = 0
		
		# 初始化生成费用和增长系数
		for type in generator_types:
			var template = game_config.get_generator_template(type)
			if template:
				base_generator_costs[type] = template.base_cost
				generator_costs[type] = template.base_cost
				cost_growth_factors[type] = template.growth_factor
		
		print("已从GameConfig更新生成费用配置:")
		for type in generator_costs:
			print("- ", _get_generator_name(type), ": ", generator_costs[type], " 金币")
		
		print("已从GameConfig更新费用增长系数:")
		for type in cost_growth_factors:
			print("- ", _get_generator_name(type), ": x", cost_growth_factors[type])
		
		# 尝试更新默认生成器
		if game_config.initial_config.has("default_generator"):
			var default_type = game_config.initial_config.default_generator
			if generator_counts.has(default_type):
				current_generator = default_type
				print("已从GameConfig更新默认生成器类型: ", _get_generator_name(current_generator))
	else:
		print("GameConfig单例不可用，使用默认配置")

# 刷新已有生成物的配置
func refresh_generators_config():
	print("刷新所有生成物配置...")
	
	# 更新树配置
	var trees_container = get_node_or_null("Trees")
	if trees_container:
		for tree in trees_container.get_children():
			if tree.has_method("_load_config"):
				tree._load_config()
	
	# 更新花配置
	var flowers_container = get_node_or_null("Flowers")
	if flowers_container:
		for flower in flowers_container.get_children():
			if flower.has_method("_load_config"):
				flower._load_config()
	
	# 更新鸟配置
	var trees = get_tree().get_nodes_in_group("trees")
	for tree in trees:
		for bird in tree.get_children():
			if bird.has_method("_load_config"):
				bird._load_config()
	
	print("所有生成物配置已刷新")

# 打印所有能力状态（便于调试）
func debug_print_abilities():
	var game_config = get_node_or_null("/root/GameConfig")
	if not game_config:
		print("错误: GameConfig不可用")
		return
		
	print("=============== 能力系统调试信息 ===============")
	
	var generator_types = game_config.get_all_generator_types()
	for type in generator_types:
		var type_name = game_config.get_generator_name(type)
		var abilities = game_config.get_generator_abilities(type)
		
		print(type_name, "能力状态:")
		
		for ability_name in abilities:
			var ability = abilities[ability_name]
			var level = ability.level
			var max_level = ability.max_level
			var effect_per_level = ability.effect_per_level
			var effect_multiplier = game_config.get_ability_effect_multiplier(type, ability_name)
			
			print("- ", ability_name, ": 等级 ", level, "/", max_level, 
				", 每级效果: ", effect_per_level * 100, "%", 
				", 当前效果乘数: ", effect_multiplier)
			
			# 根据能力类型打印特定信息
			match ability_name:
				"efficiency":
					var base_amount = game_config.get_generator_template(type).generation.amount
					var boosted_amount = base_amount * effect_multiplier
					print("  基础产出: ", base_amount, ", 提升后产出: ", boosted_amount)
				"speed":
					if game_config.get_generator_template(type).generation.has("interval"):
						var base_interval = game_config.get_generator_template(type).generation.interval
						var boosted_interval = base_interval / effect_multiplier
						print("  基础间隔: ", base_interval, "秒, 提升后间隔: ", boosted_interval, "秒")
				"cooldown":
					if game_config.get_generator_template(type).generation.has("cooldown"):
						var base_cooldown = game_config.get_generator_template(type).generation.cooldown
						var boosted_cooldown = base_cooldown / effect_multiplier
						print("  基础冷却: ", base_cooldown, "秒, 提升后冷却: ", boosted_cooldown, "秒")
	
	print("===============================================")
	
	# 查看实际生成的对象状态
	print("当前场景中的生成物状态:")
	
	# 检查花朵
	var flowers_container = get_node_or_null("Flowers")
	if flowers_container:
		var flowers = flowers_container.get_children()
		print("场景中花朵数量: ", flowers.size())
		for i in range(min(flowers.size(), 3)):  # 只打印前3个花朵信息
			var flower = flowers[i]
			print("花朵 #", i, ": 悬停奖励=", flower.hover_coin_reward, ", 冷却时间=", flower.hover_cooldown_time)
	
	# 检查树木
	var trees_container = get_node_or_null("Trees")
	if trees_container:
		var trees = trees_container.get_children()
		print("场景中树木数量: ", trees.size())
		for i in range(min(trees.size(), 3)):  # 只打印前3个树木信息
			var tree = trees[i]
			print("树木 #", i, ": 产出量=", tree.coin_generation_amount, ", 间隔=", tree.coin_timer.wait_time if tree.coin_timer else "未知")
