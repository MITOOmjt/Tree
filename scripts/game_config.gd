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
		"placement_offset": -250,          # 放置时的Y轴偏移量
		"container_node": "Trees",       # 容器节点名称
		"abilities": {                  # 能力系统
			"efficiency": {             # 效率能力 - 增加金币产出
				"level": 1,             # 当前等级
				"base_cost": 10,        # 升级基础成本
				"growth_factor": 5,   # 升级成本增长系数
				"effect_per_level": 0.5, # 每级增加50%产出
				"max_level": 10         # 最大等级
			},
			"speed": {                  # 速度能力 - 减少产出间隔
				"level": 1,
				"base_cost": 15,
				"growth_factor": 5,
				"effect_per_level": 0.1, # 每级减少10%间隔时间
				"max_level": 10
			}
		}
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
		"placement_offset": 0,          # 放置时的Y轴偏移量
		"container_node": "Flowers",     # 容器节点名称
		"abilities": {                  # 能力系统
			"efficiency": {             # 效率能力 - 增加金币产出
				"level": 1,             # 当前等级
				"base_cost": 8,         # 升级基础成本
				"growth_factor": 5,   # 升级成本增长系数
				"effect_per_level": 0.25, # 每级增加25%产出
				"max_level": 10         # 最大等级
			},
			"cooldown": {               # 冷却能力 - 减少冷却时间
				"level": 1,
				"base_cost": 12,
				"growth_factor": 5,
				"effect_per_level": 0.12, # 每级减少12%冷却时间
				"max_level": 10
			}
		}
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
		"placement_offset": 0,          # 放置时的Y轴偏移量
		"container_node": "",            # 容器节点名称(为空表示直接添加到父节点)
		"abilities": {                  # 能力系统
			"efficiency": {             # 效率能力 - 增加金币产出
				"level": 1,             # 当前等级
				"base_cost": 15,        # 升级基础成本
				"growth_factor": 5,   # 升级成本增长系数
				"effect_per_level": 0.3, # 每级增加30%产出
				"max_level": 10         # 最大等级
			}
		}
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

# 能力系统方法

# 获取生成物的能力列表
func get_generator_abilities(type):
	var template = get_generator_template(type)
	if template and template.has("abilities"):
		return template.abilities
	return {}

# 获取特定能力的当前等级
func get_ability_level(type, ability_name):
	var abilities = get_generator_abilities(type)
	if abilities.has(ability_name):
		return abilities[ability_name].level
	return 1

# 计算能力升级成本
func calculate_ability_upgrade_cost(type, ability_name):
	var abilities = get_generator_abilities(type)
	if abilities.has(ability_name):
		var ability = abilities[ability_name]
		var level = ability.level
		var base_cost = ability.base_cost
		var growth_factor = ability.growth_factor
		
		# 如果已达到最大等级，返回-1表示无法升级
		if level >= ability.max_level:
			return -1
			
		# 计算升级成本: base_cost * (growth_factor ^ (level - 1))
		var cost = base_cost * pow(growth_factor, level - 1)
		return int(ceil(cost))
	return 0

# 升级特定能力
func upgrade_ability(type, ability_name):
	var abilities = get_generator_abilities(type)
	if abilities.has(ability_name):
		var ability = abilities[ability_name]
		
		# 检查是否已达最大等级
		if ability.level >= ability.max_level:
			print("能力", ability_name, "已达到最大等级")
			return false
			
		# 增加等级
		ability.level += 1
		print("成功升级", get_generator_name(type), "的", ability_name, "能力到", ability.level, "级")
		return true
	return false

# 获取能力效果倍数（用于计算实际产出效率）
func get_ability_effect_multiplier(type, ability_name):
	var abilities = get_generator_abilities(type)
	if abilities.has(ability_name):
		var ability = abilities[ability_name]
		var level = ability.level
		var effect_per_level = ability.effect_per_level
		
		# 计算效果倍数: 1 + (level - 1) * effect_per_level
		return 1 + (level - 1) * effect_per_level
	return 1.0  # 默认无效果

# 获取能力描述
func get_ability_description(type, ability_name):
	var abilities = get_generator_abilities(type)
	if abilities.has(ability_name):
		var ability = abilities[ability_name]
		var effect_percent = ability.effect_per_level * 100
		
		match ability_name:
			"efficiency":
				return "提高金币产出效率，每级增加" + str(effect_percent) + "%"
			"speed":
				return "减少产出间隔时间，每级减少" + str(effect_percent) + "%"
			"cooldown":
				return "减少冷却时间，每级减少" + str(effect_percent) + "%"
			_:
				return "提高" + ability_name + "，每级" + str(effect_percent) + "%"
	
	return "未知能力" 

# 获取生成物放置偏移
func get_placement_offset(type):
	var template = get_generator_template(type)
	if template and template.has("placement_offset"):
		return template.placement_offset
	return 0

# 设置生成物放置偏移
func set_placement_offset(type, offset):
	var template = get_generator_template(type)
	if template:
		template.placement_offset = offset
		return true
	return false

# 计算生成器当前奖励值（适用于任何生成器类型）
func calculate_generator_reward(generator_type):
	var reward = 0
	var template = get_generator_template(generator_type)
	
	if template and template.generation.has("amount"):
		var base_amount = template.generation.amount
		var efficiency_multiplier = get_ability_effect_multiplier(generator_type, "efficiency")
		reward = base_amount * efficiency_multiplier
	
	return reward 
