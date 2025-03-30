# 树上的鸟 - Tree Bird Game

一个基于Godot 4.3开发的生成型游戏，玩家可以在游戏世界中生成树木、花朵和鸟类，并管理资源系统。

## 功能

- 使用简单的多边形图形表示树、花朵和鸟
- 动态资源管理系统，使用金币作为游戏内货币
- 点击树的任何位置可以生成一只鸟（消耗10金币）
- 点击空白区域可根据选择生成树木（消耗3金币）或花朵（消耗1金币）
- 每棵树每5秒自动产生1金币
- 实时显示当前选择的生成物类型和金币余额
- 通过弹出式生成器面板选择生成对象类型
- 可折叠的UI界面，支持手动关闭和重新打开
- 美观的按钮样式和状态反馈
- 中央配置系统，方便调整游戏平衡性

## 如何使用

1. 克隆此仓库
2. 使用Godot 4.3引擎打开项目
3. 运行`scene/main.tscn`场景
4. 使用右侧的生成器面板选择要生成的对象类型
5. 点击空白区域生成树木或花朵（取决于当前选择）
6. 点击树木生成鸟类（需要足够金币）
7. 可以通过面板上的"关闭"按钮隐藏UI
8. 隐藏后，可以通过屏幕底部的"打开生成界面"按钮重新显示

## 项目结构

```
tree/
├── treegame/                  # 游戏主要内容目录
│   ├── scene/                 # 场景文件目录
│   │   ├── main.tscn          # 主场景
│   │   ├── direct_tree.tscn   # 树木场景
│   │   ├── flower.tscn        # 花朵场景
│   │   ├── bird.tscn          # 鸟类场景
│   │   ├── ui.tscn            # 主UI场景
│   │   └── generator_popup_ui.tscn # 生成器弹出式UI场景
│   ├── scripts/               # 脚本文件目录
│   │   ├── background_manager.gd # 背景及对象管理器
│   │   ├── generator_popup_ui.gd # 生成器弹出式UI控制器
│   │   ├── ui.gd              # 界面控制脚本
│   │   ├── direct_tree.gd     # 树木行为脚本
│   │   ├── bird.gd            # 鸟的逻辑脚本
│   │   ├── global.gd          # 全局单例（金币系统）
│   │   └── game_config.gd     # 游戏配置单例
│   ├── .godot/                # Godot引擎配置文件
│   ├── project.godot          # 项目配置文件
│   └── icon.svg               # 项目图标
├── .git/                      # Git版本控制目录
├── .gitignore                 # Git忽略文件配置
└── README.md                  # 项目说明文档
```

## 路径规则与引用规范

- 所有资源引用必须使用`res://`作为根目录，例如：`preload("res://scene/flower.tscn")`
- 避免使用相对路径或绝对路径引用资源
- 场景文件必须放在`scene/`目录中
- 脚本文件必须放在`scripts/`目录中
- 脚本文件名应与其关联的场景文件名保持一致（例如：direct_tree.tscn 对应 direct_tree.gd）

## UI系统说明

### 生成器UI系统
- 使用基于PopupPanel的弹出式界面
- 支持手动关闭UI（通过右上角的"关闭"按钮）
- 关闭后在屏幕底部显示"打开生成界面"按钮
- 防止点击穿透和背景自动关闭问题
- 提供清晰的视觉状态反馈（已选择/选择状态）

### 金币与资源系统
- 树木生成成本：3金币
- 花朵生成成本：1金币
- 鸟类生成成本：10金币
- 金币来源：每棵树每5秒自动产生1金币
- 金币余额不足时会有提示信息

## 代码结构规则

### 命名规范
- **变量名**：使用小写字母和下划线，如`flower_scene`、`current_generator`
- **函数名**：使用小写字母和下划线，如`spawn_flower`、`update_coins_display`
- **信号名**：使用小写字母和下划线，描述事件，如`generator_selected`
- **常量和枚举**：使用驼峰命名法，如`GeneratorType`

### 脚本结构
每个脚本文件应遵循以下结构顺序：
1. 类/节点定义（extends语句）
2. 信号定义（signal关键字）
3. 常量和枚举定义（const和enum关键字）
4. 导出变量（export关键字）
5. 类变量定义
6. 内置函数（_ready、_process等）
7. 自定义函数
8. 信号回调函数（通常以_on开头）

## 游戏配置系统

游戏使用GameConfig单例来集中管理配置参数。这使得修改游戏平衡性和各种数值变得简单。

### 主要配置内容

- **生成物模板系统**：在game_config.gd中使用generator_templates字典定义所有生成物
  ```gdscript
  # 生成物模板系统示例
  var generator_templates = {
    GeneratorType.TREE: {
      "id": GeneratorType.TREE,
      "name": "树木",
      "scene_path": "res://scene/direct_tree.tscn",
      "base_cost": 5,                 # 基础生成成本
      "growth_factor": 1.5,           # 成本增长系数
      "color": Color(0.145, 0.639, 0.121), # 显示颜色
      "generation": {
        "type": "interval",         # 产出类型: interval表示定时产出
        "amount": 1,                # 产出金币数量
        "interval": 5.0,            # 产出间隔(秒)
      },
      "placement": "ground",          # 放置类型: ground表示放置在地面/背景
      "placement_offset": 0,          # 放置时的Y轴偏移量
      "container_node": "Trees",       # 容器节点名称
      "abilities": {                   # 能力系统
        "efficiency": {                # 效率能力 - 增加金币产出
          "level": 1,                  # 当前等级
          "base_cost": 10,             # 升级基础成本
          "growth_factor": 1.5,        # 升级成本增长系数
          "effect_per_level": 0.2,     # 每级增加20%产出
          "max_level": 10              # 最大等级
        },
        // 其它能力...
      }
    },
    // 其它生成物配置...
  }
  ```

- **金币产出配置**：根据生成物类型和产出方式定义在各个generator_template中
  - 间隔产出(interval)：适用于定时产生金币的生成物，如树木
  - 悬停产出(hover)：适用于鼠标悬停时产生金币的生成物，如花朵
  - 点击产出(click)：适用于点击时产生金币的生成物，如鸟类

- **费用增长系数**：每种生成物都有独立的成本增长系数，玩家每建造一个该类型的生成物，下一个相同类型的成本会增加

- **放置位置配置**：使用placement_offset参数来控制生成物放置时的Y轴偏移量
  - 每种生成物都有独立的偏移值，可以根据需要调整
  - 例如，不同高度的花朵可以设置不同的Y轴偏移量
  - 通过`game_config.set_placement_offset(GeneratorType.FLOWER, -20)`来调整

### 配置加载机制
所有实体（树、花、鸟）都会在其_ready函数中调用_load_config()来从GameConfig单例加载配置。这确保了游戏数值的一致性和可配置性。

### 能力系统机制

游戏中的每种生成物都有可升级的能力，通过能力系统来增强其产出效率和性能：

#### 能力类型
- **效率(efficiency)**：增加金币产出量
- **速度(speed)**：减少产出间隔时间（仅适用于间隔产出类型）
- **冷却(cooldown)**：减少冷却时间（仅适用于悬停产出类型）

#### 能力配置
每个能力都有以下属性：
```gdscript
"efficiency": {
  "level": 1,                # 当前等级
  "base_cost": 10,           # 升级基础成本
  "growth_factor": 1.5,      # 升级成本增长系数
  "effect_per_level": 0.2,   # 每级效果（20%）
  "max_level": 10            # 最大等级
}
```

#### 效果计算机制
1. **效果乘数计算公式**：`1 + (level - 1) * effect_per_level`
   - 例如：效率能力2级（effect_per_level为0.2）的效果乘数为 1 + (2 - 1) * 0.2 = 1.2

2. **动态更新机制**
   - 所有生成物在每次触发产出奖励前会实时重新计算最新的效果值
   - GameConfig提供了通用方法`calculate_generator_reward(generator_type)`用于计算任何生成器的当前奖励值
   - 这确保了能力升级后，效果能立即应用，不需要等待刷新或重建对象

3. **实现方式**
   ```gdscript
   # 从GameConfig获取当前奖励值（示例）
   func _give_reward():
     var game_config = get_node_or_null("/root/GameConfig")
     if game_config:
       reward_amount = game_config.calculate_generator_reward(game_config.GeneratorType.FLOWER)
     
     # 使用计算出的奖励值
     Global.add_coins(reward_amount)
   ```

#### 升级能力
通过ability_upgrade_ui界面可以升级各种生成物的能力，升级后的效果会立即应用到所有同类型的生成物上。

升级能力后，系统会调用`background_manager.refresh_generators_config()`函数来刷新所有生成物的配置，但由于动态计算机制的存在，即使不刷新，下一次触发产出时也会使用最新的能力效果值。

## 扩展新的生成物类型

游戏系统设计为可轻松扩展新的生成物类型。下面是添加新生成物的完整步骤：

### 1. 在GameConfig中添加新的生成物类型

首先，在scripts/game_config.gd中的GeneratorType枚举中添加新的类型：

```gdscript
enum GeneratorType {TREE = 0, FLOWER = 1, BIRD = 2, NEW_TYPE = 3}
```

### 2. 创建生成物场景

创建新生成物的场景文件，并保存到scene目录下，例如scene/new_generator.tscn。
确保该场景包含必要的脚本来处理其行为和金币生成逻辑。

### 3. 在GameConfig中定义生成物模板

在scripts/game_config.gd的generator_templates字典中添加新生成物的配置：

```gdscript
GeneratorType.NEW_TYPE: {
  "id": GeneratorType.NEW_TYPE,
  "name": "新生成物",                      # 显示名称
  "scene_path": "res://scene/new_generator.tscn", # 场景路径
  "base_cost": 15,                      # 基础生成成本
  "growth_factor": 1.3,                 # 成本增长系数
  "color": Color(0.2, 0.5, 0.8),        # UI显示颜色
  "generation": {
    "type": "interval",                 # 产出类型: interval/hover/click
    "amount": 2,                        # 产出金币数量
    "interval": 3.0,                    # 产出间隔(如适用)
  },
  "placement": "ground",                # 放置类型: ground/on_tree
  "placement_offset": 0,                # 放置时的Y轴偏移量
  "container_node": "NewGenerators"     # 容器节点名称
}
```

### 4. 生成物脚本实现

确保新生成物的脚本实现了_load_config()方法来从GameConfig加载配置：

```gdscript
# 从GameConfig加载配置
func _load_config():
  var game_config = get_node_or_null("/root/GameConfig")
  if game_config:
    var template = game_config.get_generator_template(game_config.GeneratorType.NEW_TYPE)
    if template and template.generation.has("amount"):
      coin_amount = template.generation.amount
      print("从GameConfig加载金币产出量:", coin_amount)
    if template.generation.has("interval"):
      $CoinTimer.wait_time = template.generation.interval
      print("从GameConfig加载产出间隔:", $CoinTimer.wait_time)
  else:
    print("GameConfig单例不可用，使用默认配置")
```

### 重要提示

1. **放置类型**: 根据生成物放置位置选择合适的放置类型
   - `ground`: 放置在地面/背景的生成物(如树木、花朵)
   - `on_tree`: 放置在树上的生成物(如鸟类)

2. **产出类型**: 根据生成物产生金币的方式选择合适的产出类型
   - `interval`: 定时产出金币(如树木)
   - `hover`: 鼠标悬停产出金币(如花朵)
   - `click`: 点击产出金币(如鸟类)

3. **容器节点**: 指定存放该类型生成物的容器节点名称，系统会自动创建这个节点

4. **位置偏移**: 使用`placement_offset`参数配置生成物的Y轴偏移量
   - 正值：将生成物向下移动
   - 负值：将生成物向上移动
   - 此参数可以在游戏运行时通过`game_config.set_placement_offset(type, value)`动态调整

添加完成后，UI系统会自动创建新生成物的选择按钮和信息显示，无需修改UI代码。背景管理器也会根据放置类型自动处理新生成物的创建和放置逻辑。

## 后续开发计划

- 为鸟添加飞行动画
- 为花朵添加生长动画
- 添加更多互动元素（如昆虫）
- 实现不同对象之间的互动系统
- 添加音效和背景音乐
- 优化UI系统和资源管理
- 添加存档和读档功能

## 许可证

此项目采用MIT许可证
