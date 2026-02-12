# Project Guidelines

## Code Style
- Primary language is GDScript; prefer typed signatures and `class_name` patterns shown in `core/components/health_component.gd`, `game/enemies/scripts/enemy_base.gd`, and `game/waves/scripts/wave_table.gd`.
- Use `snake_case` for functions/variables and `UPPER_SNAKE_CASE` for constants.
- Keep functions focused; in orchestrator scripts (like `scenes/run_game.gd`) split flow into small helpers for spawn/combat/progression/settlement.
- Runtime-tunable gameplay values belong in `@export` fields or `.tres` resources (not hardcoded in UI scripts).

## Architecture
- `autoload/` owns global state/services (`game_state.gd`, `save_service.gd`, `event_bus.gd`, `config_service.gd`, `audio_service.gd`).
- `core/` contains reusable components/systems; avoid domain-specific assumptions there.
- `game/` is feature-domain code (combat/enemies/waves/weapons/player/ui/progression) split into `data/`, `scripts/`, `scenes/`.
- Scene flow is `bootstrap` -> `main_menu` -> `run_game` (`scenes/bootstrap.gd`, `scenes/main_menu.gd`, `scenes/run_game.gd`).
- Wave spawning is data-driven: `game/waves/data/wave_table_default.tres` + `game/waves/scripts/wave_definition.gd` + `wave_spawn_batch.gd` consumed by `run_game.gd`.

## Build and Test
- Run from repo root: `godot4 --path .`
- Headless validation/import check: `godot4 --headless --path . --quit`
- No project-local lint/build script is defined.
- No automated tests yet (`tests/unit/.gitkeep`, `tests/integration/.gitkeep` are placeholders), so validate gameplay via scene loop in `main_menu.tscn`/`run_game.tscn`.

## Project Conventions
- Prefer changing engine settings via Godot Editor UI; edit `project.godot` manually only when necessary.
- Keep generated runtime/import artifacts ignored (`.godot/`, `.import/`, `.export/`, `*.import`, `*.imported.*`, `.mono/`) per `.gitignore`.
- Track `.uid` files in Git for stable cross-machine resource IDs.
- Treat `.translation` as generated assets from `localization/*.csv` import pipeline.
- Preserve data-driven patterns:
	- Weapons come from `WeaponEntry` resources (`game/weapons/data/*.tres`, `game/weapons/scripts/weapon_entry.gd`).
	- Wave composition/density comes from `WaveTable` resources (`game/waves/data/*.tres`).
	- Runtime should branch by `weapon_kind` (projectile/laser/summon) in `scenes/run_game.gd`.

## Integration Points
- Engine/runtime constraints are defined in `project.godot` (Godot 4.6, renderer/physics/driver settings).
- Autoload registrations in `project.godot` are runtime wiring; keep singleton names and script paths synchronized.
- Scene transitions rely on `SceneTree.change_scene_to_file` / `reload_current_scene` (`scenes/bootstrap.gd`, `game/ui/scripts/menu_flow.gd`, `scenes/run_game.gd`).
- Global pause is unified via `GameState.is_paused`; keep enemy/projectile/summon runtime behavior consistent with this flag.

## Security
- Persistence under `user://` is client-local and mutable (`autoload/save_service.gd`), so keep defensive load/default merge and type-safe fallbacks.
- Save schema uses sections (`meta`, `profile`, `progression`, `settings`); add fields in a backward-compatible way.
- `autoload/event_bus.gd` signals are global coupling points; avoid renaming existing signals casually.
- Changes in `game_state.gd`/`save_service.gd` affect run lifecycle, rewards, and difficulty; verify menu stats (`scenes/main_menu.gd`) and settlement flow (`scenes/run_game.gd`).
