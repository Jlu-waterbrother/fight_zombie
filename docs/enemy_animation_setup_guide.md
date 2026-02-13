# 敌人精灵图动画接入说明（AnimatedSprite2D）

本文档说明如何使用**精灵图（Sprite Sheet）帧动画**接入当前敌人系统。  
当前项目已从 `AnimationPlayer` 方案切换为 `AnimatedSprite2D + SpriteFrames` 方案。

---

## 1. 当前接口概览

通用入口：

- `game/enemies/scripts/enemy_base.gd`
- `game/enemies/scenes/enemy_base.tscn`

统一状态名（必须同名）：

- `idle`
- `move`
- `attack`
- `hit`
- `death`

状态触发时机已在代码里接好，无需额外脚本调用。

---

## 2. 场景结构要求

`enemy_base.tscn` 关键节点：

- `EnemyBase (CharacterBody2D)`
  - `Visual (Polygon2D)`（无素材时的回退可视）
  - `AnimatedSprite2D`（帧动画播放器）
  - `HealthComponent / HealthBar / DamageLayer`

脚本参数：

- `animated_sprite_path`（默认 `AnimatedSprite2D`）
- `fallback_visual_path`（默认 `Visual`）
- `hit_flash_duration`
- `death_fade_duration`

当检测到 `AnimatedSprite2D` 有有效动画帧时，`Visual` 会自动隐藏。

---

## 3. 精灵图素材准备建议

建议每个状态单独一张序列图，或一张大图按行分状态。  
推荐统一：

- 单帧尺寸一致（如 64x64）
- 朝向一致（默认朝下）
- 中心点一致（避免播放时抖动）

状态最少帧数建议：

- `idle`: 2~6 帧
- `move`: 4~8 帧
- `attack`: 4~8 帧
- `hit`: 2~4 帧
- `death`: 4~10 帧

---

## 4. Godot 编辑器接入步骤（SpriteFrames）

1. 打开敌人场景（例如 `zombie_basic.tscn` / `enemy_base.tscn`）。
2. 选中 `AnimatedSprite2D` 节点。
3. 在 Inspector 的 `Sprite Frames` 新建一个 `SpriteFrames` 资源。
4. 打开 SpriteFrames 编辑器，为 `idle/move/attack/hit/death` 新建同名动画。
5. 对每个动画导入对应精灵图：
   - 可用“Add frames from Sprite Sheet”
   - 设定 H/V 帧切分
   - 校正每帧裁剪范围
6. 设置循环：
   - `idle`、`move`：开启 loop
   - `attack`、`hit`、`death`：关闭 loop（推荐）
7. 设置 FPS（每个动画可不同）：
   - `idle`：6~10
   - `move`：8~14
   - `attack`：10~16
   - `hit`：10~16
   - `death`：8~14
8. 保存场景运行即可。

---

## 5. 代码触发逻辑（已实现）

### move
- 非暂停、非死亡、非攻击状态时自动播放。

### attack
- 到达攻击线时播放；
- 每次攻击 tick（造成玩家伤害）会强制重播。

### hit
- 受到有效伤害时触发；
- 若 `hit` 动画不存在，自动回退为闪白反馈。

### death
- 死亡时触发；
- 若 `death` 动画存在，按估算时长后移除节点；
- 若不存在，回退为淡出+缩放动画。

---

## 6. 派生敌人脚本接入要求

若派生敌人重写 `_physics_process`（如 `EnemyWeaver`），请保留：

- `_set_enemy_animation_state(ANIM_MOVE)`
- `_set_enemy_animation_state(ANIM_ATTACK)`
- `_set_enemy_animation_state(ANIM_IDLE)`
- 进入攻击线时 `_set_enemy_animation_state(ANIM_ATTACK, true)`

否则会出现“有移动但不切动画”的问题。

---

## 7. 死亡动画期战斗逻辑说明

敌人死亡后，即使还在播放 `death` 动画，也会被标记为 `is_defeated()`。  
战斗系统已经跳过这类敌人，避免：

- 被继续索敌
- 被重复命中
- 阻塞波次结算

---

## 8. 快速自测清单

1. 出生后是否从 `idle` 进入 `move`。  
2. 到攻击线是否切 `attack`。  
3. 命中时是否播放 `hit`（无素材时是否闪白）。  
4. 死亡时是否播放 `death`（无素材时是否淡出）。  
5. 死亡动画中是否不会被继续锁定/命中。  
6. 波次剩余数是否正常递减并结算。

---

## 9. 常见问题排查

### Q1：动画不播放，只显示静态
- 检查 `AnimatedSprite2D` 的 `SpriteFrames` 是否赋值。
- 检查是否存在同名动画（`idle/move/attack/hit/death`）。
- 检查该动画是否有帧（frame_count > 0）。

### Q2：一直显示绿色方块（Visual）
- 说明 SpriteFrames 可能为空或没有有效帧；脚本判定为回退模式。

### Q3：死亡后不消失
- 检查 `death` 动画 FPS 是否为 0；
- 检查 `AnimatedSprite2D.speed_scale` 是否被设为 0。

---

## 10. 命令行验证

```bash
/var/lib/flatpak/exports/bin/org.godotengine.Godot --headless --path . --quit
```
