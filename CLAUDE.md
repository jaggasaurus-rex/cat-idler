# CLAUDE.md
## Project
This is a Godot 4 project using GDScript.
## Maintenance
**After every discrete working change, review and update CONTEXT.md.** 
- Before starting any task, read `CONTEXT.md` to understand current project state.
- After every change, update `CONTEXT.md` in the project root to reflect what was added, modified, or removed. Include the affected files and a brief description of the change.
## Commit discipline
**After every discrete working change, commit before continuing.**  
Do not batch multiple feature changes into one commit.  
Do not end a session without committing completed work.  
Commit message format: brief imperative sentence describing what changed.
## Language and Syntax
- Godot 4 GDScript only. Never use Godot 3 syntax.
- All variables, parameters, and return types must be explicitly typed. No inferred types except for loop variables where the type is obvious from context.
- Use `signal` keyword for signal declarations. Connect signals with `.connect()`.
- Use `@export` for all exported variables. Group related exports with `@export_group`.
- Reference nodes with `$NodeName` for direct children, `%NodeName` for unique-named nodes.
## Architecture
- Prefer composition over inheritance. Build behavior by combining nodes, not subclassing.
- Do not subclass unless there is a clear, reusable abstraction that cannot be achieved with composition.
- Scenes are self-contained. A scene should not directly manipulate the internals of another scene -- communicate via signals or injected references.
- All user-visible strings must be defined as named constants in `res://Strings.gd` and referenced from there. Never hardcode display text inline in scripts or scene files.
## Naming Conventions
- Variables and functions: `snake_case`
- Constants: `ALL_CAPS_SNAKE_CASE`
- Classes and node names: `PascalCase`
- Scene files: `snake_case.tscn`
- Script files: `snake_case.gd`
- Private functions and variables: prefix with `_underscore`
## Error Handling
- Use `assert()` for invariants that should never be false in correct code.
- Use `push_error()` for runtime errors that should be surfaced but not crash the game.
- Always check for null with `is_instance_valid()` before accessing a node reference that may have been freed.
## Comments
- All public functions (no leading underscore) must have a docstring comment directly above them describing what the function does, its parameters, and its return value.
- Do not comment obvious code. Comment non-obvious logic, workarounds, or intentional decisions that might look like mistakes.
## Autoloads
<!-- List autoloads here when used. Example:
- `GameManager` — global game state (scene transitions, session data)
- `AudioBus` — centralized audio playback and bus management
-->
## Agent Pipeline
Seven sub-agents live in `.claude/agents/`. Six run automatically at defined points in every task. The seventh, `architect`, runs on-demand at the start of a task when you opt in (see below). Do not skip any of the automatic stages.

**At the start of any new feature or fix task — design gate:**
0. Ask the user whether to run the `architect` agent first. Skip this question (and the agent) for pure Config.gd balance changes or single-line fixes; ask for anything involving new mechanics, scenes, or signals.
   - If the user says yes: run `architect` with the task description, then write its returned ADR verbatim to `docs/adr/NNNN-title.md` (next zero-padded number) before proceeding. Do not ask for confirmation to write the ADR.
   - If the user says no: proceed directly to step 1.

**Before starting any task:**
1. Run `context-validator` — if it reports STALE, update CONTEXT.md before proceeding.
2. Run `pre-task-scaffolder` with the task description — review SHOULD CHANGE / SHOULD NOT CHANGE before touching any file.

**After implementation, before committing:**
3. Run `gdscript-reviewer` — fix all reported violations.
4. Run `strings-guardian` — add any flagged strings to Strings.gd and replace inline occurrences.
5. Run `adversarial-reviewer` — it attacks the change for logic, edge-case, and design weaknesses. Resolve every BREAKS and RISKY finding before committing; address or consciously accept each WEAK finding.

**After committing:**
6. Run `commit-auditor` — resolve any UNCOMMITTED CHANGES or BAD MESSAGE reports.

Do not consider a task complete until all six automatic agents report clean. (`architect` is a design step, not a clean/violation report, so it is exempt from this check.)
