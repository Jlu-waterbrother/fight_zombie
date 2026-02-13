# 子弹视觉配置说明（形状 / 颜色 / 朝向 / 拖尾）

本文档说明如何基于当前公用子弹基类 `ProjectileRuntime`，给不同武器子弹配置形状、颜色、朝向和拖尾，并补充命中/消失特效。

---

## 1. 相关代码入口

- 公用基类：`game/weapons/scripts/projectile_runtime.gd`
- 发射接入：`scenes/run_game.gd`
  - `_spawn_projectile(...)`
  - `_projectile_display_profile_for_weapon(...)`

当前流程是：  
`run_game.gd` 组装 profile -> `ProjectileRuntime.configure_display_profile(profile)` 应用视觉参数。

---

## 2. profile 可配置字段

在 `_projectile_display_profile_for_weapon` 中返回 `Dictionary`，可用字段如下：

- `shape_points: PackedVector2Array`  
  子弹几何形状（作用于 `Polygon2D` 的 `Visual`）。
- `color: Color`  
  子弹主体颜色。
- `rotation_follows_direction: bool`  
  是否跟随飞行方向旋转。
- `rotation_offset_degrees: float`  
  朝向偏移角（美术朝向与数学朝向不一致时使用）。
- `scale: float`  
  子弹整体缩放。
- `trail_enabled: bool`  
  是否开启拖尾粒子（`TrailParticles`）。
- `trail_color: Color` / `trail_amount: int` / `trail_lifetime: float` / `trail_scale: float`  
  拖尾颜色、数量、生命周期和缩放。
- `impact_color: Color` / `despawn_color: Color`  
  命中/消失反馈颜色。
- `impact_effect_shape: PackedVector2Array` / `despawn_effect_shape: PackedVector2Array`  
  命中/消失反馈几何形状（无自定义特效场景时生效）。
- `impact_effect_scale: float` / `despawn_effect_scale: float`  
  命中/消失反馈缩放。

---

## 3. 操作流程（推荐）

1. 打开 `scenes/run_game.gd`，定位函数 `_projectile_display_profile_for_weapon`。  
2. 在默认 profile 里先设通用基线参数（朝向、默认色、默认反馈）。  
3. 在 `match weapon_id` 分支内按武器单独覆写：
   - `shape_points`（定义子弹形状）
   - `color`（定义主体色）
   - `rotation_follows_direction` / `rotation_offset_degrees`（定义朝向行为）
   - `trail_enabled + trail_*`（定义拖尾）
4. 如需增强命中手感，再覆写 `impact_*` 与 `despawn_*` 字段。  
5. 运行验证：

```bash
/var/lib/flatpak/exports/bin/org.godotengine.Godot --headless --path . --quit
```

---

## 4. 已落地的示例特效（本轮）

- `pulse`（脉冲枪）
  - 开启短促暖色拖尾。
  - 命中反馈使用星芒形 `impact_effect_shape`。
- `scatter`（散射枪）
  - 保持不跟随方向旋转（喷射感）。
  - 命中/消失反馈改为扁平火花与碎片形状。
- `arc`（弧光枪）
  - 强化青色拖尾（数量和生命周期更高）。
  - 命中/消失反馈改为电弧风格多边形。

---

## 5. 常见排查

- 拖尾不显示：检查子弹场景是否包含 `TrailParticles` 节点。  
- 形状不变化：`Visual` 必须是 `Polygon2D`，且 `shape_points` 非空。  
- 朝向看起来不对：优先调 `rotation_offset_degrees`。  
- 特效太大/太小：调 `impact_effect_scale` / `despawn_effect_scale`。  
