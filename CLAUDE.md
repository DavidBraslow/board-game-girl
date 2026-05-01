# Board Game Girl — Claude Code context

## Project
A cozy puzzle game built in Godot 4. Working title: Board Game Girl.
The player plays classic board/card games with a child who has invented her own secret rules.
The puzzle is figuring out the child's rules through play and reaction.

## Engine & language
- Godot 4 (latest stable)
- GDScript only — no C#
- Target platforms: Windows, macOS, Linux (Steam)

## Folder structure
- scenes/ui/          — menus, HUD, pause screen
- scenes/games/       — one scene per game level
- scenes/shared/      — reusable components (child character, hint overlay)
- scripts/game_logic/ — puzzle rule definitions, move validation
- scripts/hint/       — hint state machine (tiers 1–4)
- scripts/ui/         — UI controllers
- scripts/autoloads/  — GameState, AudioManager, SaveSystem
- assets/art/         — all hand-drawn art (not AI-generated)
- assets/audio/       — music, SFX
- assets/fonts/       — handwritten-style fonts
- data/levels/        — JSON level configs (rules, win conditions)
- data/dialogue/      — JSON dialogue files — hand-written by David — DO NOT generate or suggest dialogue lines
- addons/             — GodotSteam and other plugins

## Naming conventions
- Scenes:    PascalCase.tscn    (e.g. TicTacToeGame.tscn)
- Scripts:   snake_case.gd      (e.g. hint_manager.gd)
- Nodes:     PascalCase
- Variables/functions: snake_case
- Constants: UPPER_SNAKE_CASE
- Signals:   past_tense         (e.g. move_made, hint_requested)

## Architecture
- Each game level is a self-contained scene inheriting from BaseGame
- HintManager is a standalone autoload state machine
- Dialogue is loaded from JSON at runtime — never hardcoded
- SaveSystem uses Godot FileAccess + JSON

## Hard rules for Claude Code
- NEVER write or suggest in-game dialogue — Steam AI content policy
- Prefer composition over inheritance except for BaseGame
- Always use signals for cross-node communication
- Keep rule logic in scripts/game_logic/, not embedded in scenes
