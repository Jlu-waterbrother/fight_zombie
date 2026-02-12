# Project Guidelines

## Code Style
- Primary language is GDScript; follow typed signatures seen in `core/components/health_component.gd` and `autoload/save_service.gd`.
- Use `snake_case` for funcs/vars, `UPPER_SNAKE_CASE` for constants, and keep functions short and single-purpose.
- Use `class_name` for reusable domain types/components (example: `core/components/health_component.gd`, `game/ui/scripts/menu_flow.gd`).
- Keep module boundaries clean: do not mix UI flow, combat math, and persistence inside one script.

## Architecture
- `autoload/`: global services/state (`game_state.gd`, `event_bus.gd`, `save_service.gd`, `config_service.gd`, `audio_service.gd`).
- `core/`: reusable components/systems/data/utils shared across game domains.
- `game/`: feature domains (`combat`, `enemies`, `player`, `waves`, `loot`, `ui`, `progression`) split by `data/`, `scripts/`, `scenes/`.
- `scenes/`: app entry and flow orchestration (`bootstrap.tscn` -> `main_menu.tscn` -> `run_game.tscn`).
- `localization/`: CSV source + generated translation resource pipeline.

## Build and Test
- Run game from repo root: `godot4 --path .`
- Headless validation/import check: `godot4 --headless --path . --quit`
- No project-local lint/build script is defined.
- No automated tests are configured yet (`tests/unit/.gitkeep`, `tests/integration/.gitkeep` are placeholders).

## Project Conventions
- Prefer changing engine/project settings through Godot Editor UI; avoid manual edits in `project.godot` unless necessary.
- Keep generated runtime/import artifacts ignored (`.godot/`, `.import/`, `.export/`, `*.import`, `*.imported.*`, `.mono/`) per `.gitignore`.
- Track `.uid` files in Git (for stable resource/script IDs across machines), e.g. `game/enemies/scripts/enemy_base.gd.uid`.
- Treat `.translation` files as generated binary assets from CSV import pipeline (`localization/zh_CN.csv.import`).

## Integration Points
- Engine/runtime constraints are defined in `project.godot` (`4.6`, `GL Compatibility`, `Jolt Physics`, Windows driver `d3d12`).
- Autoload registrations in `project.godot` are part of runtime wiring; keep names and paths synchronized with scripts.
- Scene switches rely on `SceneTree.change_scene_to_file` patterns (see `scenes/bootstrap.gd`, `game/ui/scripts/menu_flow.gd`).

## Security
- Persistence under `user://` is client-local and mutable (`autoload/save_service.gd`), so add defensive load/default handling.
- `autoload/event_bus.gd` signals are global coupling points; keep signal names stable and scope emissions carefully.
- Changes to global state/config services can affect whole-run behavior; verify interactions in `autoload/game_state.gd` and `autoload/config_service.gd`.
