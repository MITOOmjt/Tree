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
- **生成物费用**：在game_config.gd中的generator_costs字典中定义
  ```gdscript
  var generator_costs = {
      GeneratorType.TREE: 5,   # 树木生成费用
      GeneratorType.FLOWER: 1, # 花朵生成费用
      GeneratorType.BIRD: 10   # 鸟类生成费用
  }
  ```

- **金币产出配置**：在game_config.gd中的coin_generation字典中定义
  ```gdscript
  var coin_generation = {
      "tree_coin_generation": 1,  # 树每次产生金币数量
      "tree_coin_interval": 5.0,  # 树产生金币的间隔时间(秒)
      "bird_click_reward": 1,     # 点击鸟获得的金币奖励
      "flower_hover_reward": 2,   # 鼠标悬停在花上获得的金币奖励
      "flower_hover_cooldown": 1.5 # 花悬停奖励的冷却时间(秒)
  }
  ```

- **初始配置**：在game_config.gd中的initial_config字典中定义
  ```gdscript
  var initial_config = {
      "starting_coins": 5,       # 初始金币数量
      "default_generator": GeneratorType.FLOWER  # 默认选择的生成物类型
  }
  ```

### 配置加载机制
所有实体（树、花、鸟）都会在其_ready函数中调用_load_config()来从GameConfig单例加载配置。这确保了游戏数值的一致性和可配置性。

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
