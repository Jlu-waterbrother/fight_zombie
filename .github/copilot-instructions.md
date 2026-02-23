# Project Guidelines

## Code Style
- Primary language is GDScript; prefer typed signatures and `class_name` patterns as used in `core/components/health_component.gd`, `game/enemies/scripts/enemy_base.gd`, and `game/waves/scripts/wave_table.gd`.
- Use `snake_case` for functions/variables and `UPPER_SNAKE_CASE` for constants.
- Keep orchestrator scripts (`scenes/run_game.gd`) split into focused helpers for spawn/combat/progression/settlement.
- Put gameplay-tunable values in `@export` fields or `.tres` resources, not hardcoded in UI/runtime glue.

## Architecture
- `autoload/` owns global state/services (`game_state.gd`, `save_service.gd`, `event_bus.gd`, `config_service.gd`, `audio_service.gd`), wired via `project.godot` autoloads.
- `core/` contains reusable components/systems; keep it domain-agnostic.
- `game/` is feature-domain code (combat/enemies/waves/weapons/player/ui/progression) split into `data/`, `scripts/`, and `scenes/`.
- Scene flow is `bootstrap -> main_menu -> run_game` (`scenes/bootstrap.gd`, `game/ui/scripts/menu_flow.gd`, `scenes/run_game.gd`).
- Wave spawn is data-driven: `WaveTable -> WaveDefinition -> WaveSpawnBatch` (`game/waves/scripts/*.gd`) consumed by `scenes/run_game.gd`.
- Weapon runtime is also data-driven from `game/weapons/data/*.tres` + `game/weapons/scripts/weapon_entry.gd`.

## Build and Test
- Run from repo root: `godot4 --path .`
- Headless validation/import check: `godot4 --headless --path . --quit`
- No project-local lint/build script is defined.
- No automated tests yet (`tests/unit/.gitkeep`, `tests/integration/.gitkeep` are placeholders).
- Validate behavior through the playable loop in `main_menu.tscn` and `run_game.tscn`.

## Project Conventions
- Prefer changing engine settings via Godot Editor UI; edit `project.godot` manually only when necessary.
- Keep generated runtime/import artifacts ignored (`.godot/`, `.import/`, `.export/`, `*.import`, `*.imported.*`, `.mono/`) per `.gitignore`.
- Track `.uid` files in Git for stable cross-machine resource IDs.
- Treat `.translation` as generated assets from `localization/*.csv` import pipeline.
- Preserve data-driven patterns:
	- Weapons come from `WeaponEntry` resources (`game/weapons/data/*.tres`, `game/weapons/scripts/weapon_entry.gd`).
	- Wave composition/density comes from `WaveTable` resources (`game/waves/data/*.tres`).
	- Runtime branches by `weapon_kind` (projectile/laser/summon) in `scenes/run_game.gd`.

## Integration Points
- Engine/runtime constraints are defined in `project.godot` (Godot 4.6, renderer/physics/driver settings).
- Autoload registrations in `project.godot` are runtime wiring; keep singleton names and script paths synchronized.
- Scene transitions rely on `SceneTree.change_scene_to_file` / `reload_current_scene` (`scenes/bootstrap.gd`, `game/ui/scripts/menu_flow.gd`, `scenes/run_game.gd`).
- Global pause is unified via `GameState.is_paused`; keep enemy/projectile/summon runtime behavior consistent with this flag.
- End-of-run settlement and reward persistence flow through `scenes/run_game.gd` + `autoload/game_state.gd` + `autoload/save_service.gd`; verify all three when changing run lifecycle.

## Security
- Persistence under `user://` is client-local and mutable (`autoload/save_service.gd`), so keep defensive load/default merge and type-safe fallbacks.
- Save schema uses sections (`meta`, `profile`, `progression`, `settings`); add fields in a backward-compatible way.
- `autoload/event_bus.gd` signals are global coupling points; avoid renaming existing signals casually.
- Changes in `game_state.gd`/`save_service.gd` affect run lifecycle, rewards, and difficulty; verify menu stats (`scenes/main_menu.gd`) and settlement flow (`scenes/run_game.gd`).
