# 音效接入说明

本项目已接入运行时音效系统，当前支持以下 4 类声音：
- 战斗场景 BGM
- 子弹/武器射出音效（可按武器区分）
- 敌人受击音效（可按敌人类型区分）
- 升级（等级提升）音效

## 代码位置
- 音频服务：`autoload/audio_service.gd`
- 战斗接入：`scenes/run_game.gd`

## 你需要准备的资源
建议把音频文件放在：
- `assets/bgm/`：例如 `run_bgm.ogg`
- `assets/sfx/`：例如 `shoot.wav`、`hit.wav`、`level_up.wav`

推荐格式：
- BGM：`.ogg`（体积更小）
- SFX：`.wav` 或 `.ogg`

## 在 Godot 中绑定音效（重要）
1. 打开场景 `scenes/run_game.tscn`
2. 选中根节点（挂载 `run_game.gd`）
3. 在 Inspector 的 `Audio` 分组中设置：
   - `run_bgm_stream` -> 你的 BGM
   - `shoot_sfx_stream` -> 发射通用音效（兜底）
   - `shoot_sfx_pulse_stream` / `shoot_sfx_laser_stream` / `shoot_sfx_summon_stream` / `shoot_sfx_scatter_stream` / `shoot_sfx_arc_stream` -> 各武器专用发射音效
   - `hit_sfx_stream` -> 受击通用音效（兜底）
   - `hit_sfx_basic_stream` / `hit_sfx_runner_stream` / `hit_sfx_weaver_stream` / `hit_sfx_tank_stream` / `hit_sfx_berserker_stream` / `hit_sfx_boss_brute_stream` / `hit_sfx_boss_overlord_stream` -> 各敌人专用受击音效
   - `level_up_sfx_stream` -> 升级音效
4. 可按需调整同分组下的音量和冷却参数：
   - `run_bgm_volume_db`
   - `shoot_sfx_volume_db`
   - `shoot_sfx_cooldown`
   - `hit_sfx_volume_db`
   - `hit_sfx_cooldown`
   - `level_up_sfx_volume_db`

## 触发时机
- BGM：进入 `run_game` 时播放，离开场景时停止
- 射击音效：每次武器触发开火时播放（带冷却，避免过密）
- 命中音效：敌人受到有效伤害时播放（带冷却，按敌人类型分别限流）
- 升级音效：每次等级提升时播放

## 说明
- 当前未绑定具体资源时，系统会安全跳过播放，不会报错。
- `AudioService` 使用 SFX 播放池，可支持高频并发播放，适合弹幕场景。
- 如果某个“专用音效”未设置，会自动回退到对应的通用音效（`shoot_sfx_stream` 或 `hit_sfx_stream`）。
