# 武器与敌人配表说明

这版已经把战斗参数整理为“配表优先读取”。

## 1) 武器参数在哪里改

### 武器总表（入口）
- `game/weapons/data/weapon_table_default.tres`
- 这里管理本局可用的武器条目列表（`entries`）。

### 武器条目（具体数值）
- `game/weapons/data/*.tres`（例如 `pulse_weapon.tres`、`laser_weapon.tres`）
- 每个文件对应一个 `WeaponEntry`。

### 武器可调核心参数
- `fire_interval`：攻击间隔（越小越快）
- `fire_interval_min`：攻速下限
- `damage`：伤害
- `projectile_count`：弹数
- `spread_degrees`：散射角
- `hit_radius`：命中判定半径
- 激光类：`laser_width`、`laser_duration`
- 召唤类：`summon_duration`、`summon_tick_interval`、`summon_radius`

## 2) 敌人参数在哪里改

### 敌人总表（入口）
- `game/enemies/data/enemy_table_default.tres`
- 这里维护所有敌人类型条目（`entries`），并绑定敌人场景。

### 敌人条目结构
- 脚本定义：`game/enemies/scripts/enemy_entry.gd`
- 表定义：`game/enemies/scripts/enemy_table.gd`

### 敌人可调核心参数
- `base_max_health`：基础血量
- `base_move_speed`：基础移速
- `base_attack_damage`：基础攻击伤害
- `attack_interval`：攻击间隔
- 通用反馈参数：`hit_flash_duration`、`death_fade_duration`
- 音效键：`audio_key`（用于受击音效分流）

## 3) run_game 如何读取

- 场景脚本：`scenes/run_game.gd`
- 优先级：
  1. `weapon_table` / `enemy_table`
  2. 兼容旧字段（如 `weapon_entries` 和旧敌人导出参数）

## 4) 推荐修改流程（Godot 编辑器）

1. 打开 `scenes/run_game.tscn`，确认根节点的 `weapon_table` / `enemy_table` 指向默认表。
2. 打开武器或敌人的 `.tres`，直接改数值并保存。
3. 运行一局，观察节奏（TTK、敌人压迫感、升级后强度）。
4. 小步迭代：每次只改 1-2 组参数，避免一次改太多难以回溯。

## 5) 常见平衡建议

- 想提高武器强度：优先加 `damage`，其次降 `fire_interval`。
- 想让怪更有压迫：优先加 `base_move_speed` 或降 `attack_interval`。
- 想拉高后期难度：可在 `run_game.gd` 的 `enemy_health_growth_per_wave` 调整波次成长。
