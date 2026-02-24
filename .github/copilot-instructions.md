# Project Guidelines

## Build, Test, and Lint
- Run game from repo root: `godot4 --path .`
- Headless validation/import check: `godot4 --headless --path . --quit`
- Flatpak fallback (when `godot4` is not in PATH): `/var/lib/flatpak/exports/bin/org.godotengine.Godot --headless --path . --quit`
- No project-local lint/build scripts are defined.
- No automated test suite exists yet (`tests/unit/.gitkeep`, `tests/integration/.gitkeep` are placeholders), so there is currently no single-test CLI command.
- Focused manual verification should run `scenes/run_game.tscn` and check one targeted flow end-to-end (e.g., wave spawn pacing, upgrade pick, settlement).

## High-Level Architecture
- Main scene flow is fixed: `bootstrap.tscn` -> `main_menu.tscn` -> `run_game.tscn` (`scenes/bootstrap.gd`, `game/ui/scripts/menu_flow.gd`).
- Global services are autoload singletons in `project.godot`: `GameState`, `SaveService`, `EventBus`, `ConfigService`, `AudioService`.
- `scenes/run_game.gd` is the gameplay orchestrator: wave progression, enemy spawn, weapon fire loop, upgrade selection, HUD updates, run victory/failure, and settlement recording.
- Runtime gameplay is table-driven:
  - Weapons: `WeaponTable -> WeaponEntry` (`game/weapons/data/weapon_table_default.tres`, `game/weapons/scripts/weapon_entry.gd`)
  - Enemies: `EnemyTable -> EnemyEntry` (`game/enemies/data/enemy_table_default.tres`, `game/enemies/scripts/enemy_entry.gd`)
  - Waves: `WaveTable -> WaveDefinition -> WaveSpawnBatch` (`game/waves/data/wave_table_default.tres`, `game/waves/scripts/*.gd`)
- Wave count is fixed to 20 in `run_game.gd`; difficulty modifies density/timing, not total waves.
- Waves 1-5 come from `wave_table_default.tres`; later waves can be generated in code paths in `run_game.gd` and boss batches are appended on specific waves.

## Key Conventions
- Prefer typed GDScript and `class_name`; use `snake_case` and `UPPER_SNAKE_CASE` conventions consistently.
- Keep gameplay knobs in `@export` fields or `.tres` data files; avoid embedding balancing numbers directly in UI glue.
- When adding a new weapon, update both data and runtime wiring:
  - Add/update a `WeaponEntry` resource and include it in `weapon_table_default.tres`.
  - Ensure `run_game.gd` handles its runtime behavior, icon mapping, and optional projectile display profile/audio branch.
- When adding a new enemy, update both scene and enemy table:
  - Add scene under `game/enemies/scenes/`.
  - Add an `EnemyEntry` in `enemy_table_default.tres` with `enemy_scene` and `audio_key` so stat/audio lookup works.
- Spawn pacing convention: each batch should feel near-simultaneous without same-frame pops; keep per-batch spawn intervals short and avoid large burst sizes.
- `GameState.is_paused` is the global pause gate; enemy/projectile/summon runtime loops should honor it.
- Save data schema lives in `SaveService` sections (`meta`, `profile`, `progression`, `settings`); keep changes backward-compatible.
