# Copilot Instructions for This Repository

## Project Type and Layout
- This is a minimal Godot 4.6 project.
- The only source-level project config is `project.godot`; there are currently no gameplay scenes/scripts committed.
- `icon.svg` is the application icon source, and `icon.svg.import` defines its Godot import settings.
- `.godot/` contains editor/import/shader cache artifacts and is generated state (not hand-edited source).

## Build, Test, and Lint Commands
- This repository does not define project-local build, test, or lint scripts (no `Makefile`, package manager config, or test framework files are present).
- Run the project from the repo root with Godot:
  - `godot4 --path .`
- Re-import assets / validate project loading in headless mode:
  - `godot4 --headless --path . --quit`
- Single-test command: not applicable, because no automated test suite is configured in this repository.

## High-Level Architecture
- Runtime behavior is driven primarily by `project.godot` settings:
  - Application metadata (`config/name`, icon path).
  - Rendering backend is set to `gl_compatibility` for desktop/mobile.
  - 3D physics engine is configured to `Jolt Physics`.
- Asset pipeline is Godot-native:
  - Source asset (`icon.svg`) is imported to `.godot/imported/*.ctex` based on `*.import` settings.

## Repository-Specific Conventions
- Prefer editing engine settings through the Godot Editor UI; `project.godot` explicitly notes that direct manual edits are error-prone.
- Keep generated `.godot/` artifacts out of source control (`.gitignore` already enforces this).
- Preserve UTF-8 encoding for text files per `.editorconfig`.
- Keep the project compatible with the configured renderer/feature set in `project.godot` (`"4.6"` + `"GL Compatibility"`).
