# Board Game Girl — Claude Code context

## Project
A cozy puzzle game built in Godot 4 (working title: Board Game Girl). The player plays classic board and card games with a child who has invented her own secret rules. The puzzle is figuring out her rules through trial and observation — no rules are ever stated explicitly.

## Engine & language
- Godot 4 (latest stable)
- GDScript only — no C#
- Target platforms: Windows, macOS, Linux (Steam)

## Folder structure
- scenes/ui/          — menus, HUD, pause screen
- scenes/games/       — one scene per game level (scenes/games/<gamename>/)
- scenes/shared/      — reusable components (child character, hint overlay)
- scripts/game_logic/ — puzzle rule definitions, move validation
- scripts/hint/       — hint state machine (tiers 1–4)
- scripts/ui/         — UI controllers
- scripts/autoloads/  — GameState, AudioManager, SaveSystem
- assets/art/         — all hand-drawn art (not AI-generated)
- assets/audio/       — music, SFX
- assets/fonts/       — handwritten-style fonts
- data/levels/        — JSON level configs (rules, win conditions)
- data/dialogue/      — JSON dialogue files, authored by David
- addons/             — GodotSteam and other plugins

## Naming conventions
- Scenes:    PascalCase.tscn    (e.g. TicTacToeGame.tscn)
- Scripts:   snake_case.gd      (e.g. hint_manager.gd)
- Nodes:     PascalCase
- Variables/functions: snake_case
- Constants: UPPER_SNAKE_CASE
- Signals:   past_tense         (e.g. move_made, hint_requested)

## Architecture
- Each game level is a self-contained scene inheriting from BaseGame, in scenes/games/<gamename>/
- HintManager is a standalone autoload state machine; the hint system is always separate from game logic — connected via signals only
- Win condition logic is always left as an empty stub for David to implement — never fill it in
- Dialogue is loaded from JSON at runtime — never hardcoded
- SaveSystem uses Godot FileAccess + JSON

## Steam AI compliance
This game must pass Steam's AI content disclosure with NO on all questions. All player-facing content is human-authored by David.
- NEVER generate dialogue, character reactions, or any in-game text
- NEVER generate art, UI copy, or store page content
- GDScript and scene structure is fine — code is developer tooling, not game content

## What Claude Code should and shouldn't do

**Do:** boilerplate scenes, state machines, signal wiring, save systems, Steam SDK integration  
**Don't:** write dialogue, implement win conditions, name the game, generate art

- Prefer composition over inheritance except for BaseGame
- Always use signals for cross-node communication
- Keep rule logic in scripts/game_logic/, not embedded in scenes
