extends Node

# 游戏配置单例

# 生成物类型枚举
enum GeneratorType {TREE = 0, FLOWER = 1, BIRD = 2}

# 生成费用配置
var generator_costs = {
	GeneratorType.TREE: 5,   # 树木生成费用：5金币
	GeneratorType.FLOWER: 1, # 花朵生成费用：1金币
	GeneratorType.BIRD: 10   # 鸟类生成费用：10金币
}

# 生成费用增长系数配置 - 每生成一个对应的生成物，其费用将乘以此系数
var cost_growth_factors = {
	GeneratorType.TREE: 1.5,    # 树木费用增长系数
	GeneratorType.FLOWER: 1.2,  # 花朵费用增长系数
	GeneratorType.BIRD: 1.8     # 鸟费用增长系数
}

# 金币产出配置
var coin_generation = {
	"tree_coin_generation": 1,  # 树每次产生金币数量
	"tree_coin_interval": 5.0,  # 树产生金币的间隔时间(秒)
	"bird_click_reward": 1,     # 点击鸟获得的金币奖励
	"flower_hover_reward": 2,   # 鼠标悬停在花上获得的金币奖励
	"flower_hover_cooldown": 1.5 # 花悬停奖励的冷却时间(秒)
}

# 初始配置
var initial_config = {
	"starting_coins": 5,       # 初始金币数量
	"default_generator": GeneratorType.FLOWER  # 默认选择的生成物类型
}

# 获取生成物费用
func get_generator_cost(type):
	return generator_costs.get(type, 0)

# 设置生成物费用
func set_generator_cost(type, cost):
	generator_costs[type] = cost

# 获取生成物费用增长系数
func get_cost_growth_factor(type):
	return cost_growth_factors.get(type, 1.0)

# 设置生成物费用增长系数  
func set_cost_growth_factor(type, factor):
	cost_growth_factors[type] = factor

# 获取金币产出配置
func get_coin_generation(key):
	return coin_generation.get(key, 0)

# 设置金币产出配置
func set_coin_generation(key, value):
	if coin_generation.has(key):
		coin_generation[key] = value 
