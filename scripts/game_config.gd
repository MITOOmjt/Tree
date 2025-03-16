extends Node

# 游戏配置单例

# 生成物类型枚举
enum GeneratorType {TREE = 0, FLOWER = 1, BIRD = 2}

# 生成物模板系统
# 统一管理所有生成物的配置，便于扩展新生成物
var generator_templates = {
	GeneratorType.TREE: {
		"id": GeneratorType.TREE,
		"name": "树木",
		"scene_path": "res://scene/direct_tree.tscn",
		"base_cost": 5,                 # 基础生成成本
		"growth_factor": 2,           # 成本增长系数
		"color": Color(0.145, 0.639, 0.121), # 显示颜色
		"generation": {
			"type": "interval",         # 产出类型: interval表示定时产出
			"amount": 1,                # 产出金币数量
			"interval": 5.0,            # 产出间隔(秒)
		},
		"placement": "ground",          # 放置类型: ground表示放置在地面/背景
		"container_node": "Trees"       # 容器节点名称
	},
	
	GeneratorType.FLOWER: {
		"id": GeneratorType.FLOWER,
		"name": "花朵",
		"scene_path": "res://scene/flower.tscn",
		"base_cost": 3,                 # 基础生成成本
		"growth_factor": 3,           # 成本增长系数
		"color": Color(0.933, 0.262, 0.603), # 显示颜色
		"generation": {
			"type": "hover",            # 产出类型: hover表示悬停产出
			"amount": 2,                # 产出金币数量
			"cooldown": 1.5,            # 产出冷却时间(秒)
		},
		"placement": "ground",          # 放置类型: ground表示放置在地面/背景
		"container_node": "Flowers"     # 容器节点名称
	},
	
	GeneratorType.BIRD: {
		"id": GeneratorType.BIRD,
		"name": "鸟",
		"scene_path": "res://scene/bird.tscn",
		"base_cost": 10,                # 基础生成成本
		"growth_factor": 2,           # 成本增长系数
		"color": Color(0.874, 0.443, 0.149), # 显示颜色
		"generation": {
			"type": "click",            # 产出类型: click表示点击产出
			"amount": 1,                # 产出金币数量
		},
		"placement": "on_tree",         # 放置类型: on_tree表示放置在树上
		"container_node": ""            # 容器节点名称(为空表示直接添加到父节点)
	}
}

# 初始配置
var initial_config = {
	"starting_coins": 5,              # 初始金币数量
	"default_generator": GeneratorType.FLOWER  # 默认选择的生成物类型
}

# 获取所有生成物类型
func get_all_generator_types():
	return generator_templates.keys()

# 获取生成物模板
func get_generator_template(type):
	return generator_templates.get(type, null)

# 获取生成物基础成本
func get_generator_base_cost(type):
	var template = get_generator_template(type)
	if template:
		return template.base_cost
	return 0

# 获取当前生成物费用(考虑到增长系数)
func get_generator_cost(type):
	var template = get_generator_template(type)
	if template:
		return template.base_cost
	return 0

# 设置生成物基础成本
func set_generator_base_cost(type, cost):
	var template = get_generator_template(type)
	if template:
		template.base_cost = cost

# 获取生成物费用增长系数
func get_cost_growth_factor(type):
	var template = get_generator_template(type)
	if template:
		return template.growth_factor
	return 1.0

# 设置生成物费用增长系数  
func set_cost_growth_factor(type, factor):
	var template = get_generator_template(type)
	if template:
		template.growth_factor = factor

# 获取生成物的场景路径
func get_generator_scene_path(type):
	var template = get_generator_template(type)
	if template:
		return template.scene_path
	return ""

# 获取生成物名称
func get_generator_name(type):
	var template = get_generator_template(type)
	if template:
		return template.name
	return "未知"

# 获取生成物颜色
func get_generator_color(type):
	var template = get_generator_template(type)
	if template:
		return template.color
	return Color.WHITE

# 获取生成物产出信息
func get_generator_output_info(type):
	var template = get_generator_template(type)
	if template:
		return template.generation
	return {}

# 获取金币产出配置(向后兼容)
func get_coin_generation(key):
	# 映射旧的键名到新结构
	match key:
		"tree_coin_generation":
			return generator_templates[GeneratorType.TREE].generation.amount
		"tree_coin_interval":
			return generator_templates[GeneratorType.TREE].generation.interval
		"bird_click_reward":
			return generator_templates[GeneratorType.BIRD].generation.amount
		"flower_hover_reward":
			return generator_templates[GeneratorType.FLOWER].generation.amount
		"flower_hover_cooldown":
			return generator_templates[GeneratorType.FLOWER].generation.cooldown
	return 0

# 设置金币产出配置(向后兼容)
func set_coin_generation(key, value):
	# 映射旧的键名到新结构
	match key:
		"tree_coin_generation":
			generator_templates[GeneratorType.TREE].generation.amount = value
		"tree_coin_interval":
			generator_templates[GeneratorType.TREE].generation.interval = value
		"bird_click_reward":
			generator_templates[GeneratorType.BIRD].generation.amount = value
		"flower_hover_reward":
			generator_templates[GeneratorType.FLOWER].generation.amount = value
		"flower_hover_cooldown":
			generator_templates[GeneratorType.FLOWER].generation.cooldown = value

# 注册新的生成物类型
func register_generator(id, config):
	if not generator_templates.has(id):
		generator_templates[id] = config
		print("已注册新生成物: ", config.name)
		return true
	else:
		print("注册失败: 生成物ID已存在")
		return false 
