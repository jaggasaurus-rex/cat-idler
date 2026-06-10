---
name: run-cat-idler
description: Build, run, drive, smoke-test, and screenshot the Cat Idler game (Godot 4.6 / GDScript). Use when asked to run, launch, start, play, screenshot, or verify Cat Idler, or to check that a gameplay change works.
---

# Run Cat Idler

Cat Idler is a **Godot 4.6 (GL Compatibility)** desktop idle game; gameplay lives
entirely in GDScript (`autoloads/GameState.gd` logic + `scenes/Main.gd` UI/spawn
glue, tuned by `Config.gd`). There is no Godot binary on the machine — the driver
downloads the matching one (4.6-stable, ~140 MB) into `~/.cache/cat-idler-run/`
on first use and reuses it after.

**Everything goes through one driver: `.claude/skills/run-cat-idler/run.sh`.**
All paths below are relative to the repo root (`<unit>/`). The script resolves its
own location, so you can call it from any CWD.

## Prerequisites

- `curl` and `unzip` (used to fetch Godot). Already present on this box.
- **No `apt-get` needed** to *run logic*: headless mode uses Godot's dummy
  renderer. Audio libs are absent (`libasound.so.2`) — Godot prints one warning
  and continues; ignore it.
- **Screenshots only** need a real display + GL. On this WSL2 box that's already
  provided by **WSLg** (`DISPLAY=:0`, Mesa `llvmpipe` software GL — no GPU, no
  xvfb required). On a plain headless box, prefix the `shot` commands with
  `xvfb-run -a` instead.

## Run — agent path (use this)

```bash
# 1. Compile check: imports the project, fails loudly on any GDScript parse error.
.claude/skills/run-cat-idler/run.sh check

# 2. Drive the game logic headless and assert behaviour (core loop + bubble feature).
.claude/skills/run-cat-idler/run.sh smoke

# 3. Real rendered screenshot of the running game (needs a display; WSLg works).
.claude/skills/run-cat-idler/run.sh shot

# 4. Real screenshot driven into the bubble feature (spawns 💰 + 💡 over cats).
.claude/skills/run-cat-idler/run.sh shot-bubble
```

`smoke` prints `PASS:` lines and ends with `ALL GAMEPLAY CHECKS PASSED` (exit 0),
or `FAIL: <reason>` (exit 1). It instantiates the **real** `Main.tscn`, drives
`GameState`, and calls the real handlers (`_try_spawn_bubble`, `_spawn_bubble`,
`_show_viral_popup`, `_on_bubble_pressed`).

Screenshots are written to (note the **space** in the dir):

```
~/.local/share/godot/app_userdata/Cat Idler/run_screenshot.png
~/.local/share/godot/app_userdata/Cat Idler/run_bubble_screenshot.png
~/.local/share/godot/app_userdata/Cat Idler/run_bubble_zoom.png   # 5× nearest crop around the bubbles
```

Copy out and view, e.g.:
`cp "$HOME/.local/share/godot/app_userdata/Cat Idler/run_screenshot.png" /tmp/ && # then Read it`

### Driving a different/new feature

Add a step to the `match _step:` block in
`.claude/skills/run-cat-idler/gameplay_harness.gd`. Each integer step runs on its
own frame, so anything needing a frame to elapse (pause/unpause, a timer crossing a
threshold) just lives in a later-numbered step. The harness pre-sets the popup
"shown" latches in `_ready()` so Main's progression popups don't pause the tree
under you — keep that if you add steps. Run with `smoke` (it passes `--fixed-fps 60`
so per-frame delta is a deterministic 1/60 s, which the unlock-timer step relies on).

## Run — human path

`.claude/skills/run-cat-idler/run.sh play` launches the real game in a window
(needs a display). Useful for hands-on play; useless on a truly headless box.

## Gotchas (battle scars from this container)

- **Emoji glyphs render as "tofu" boxes.** The bubble buttons set text `💰`/`💡`,
  but the default Godot font has no emoji coverage, so on this Linux/llvmpipe setup
  they draw as missing-glyph boxes showing the hex codepoint (`01F4B0`, `01F4A1`) —
  see `run_bubble_zoom.png`. The mechanic is correct (the `smoke` run asserts the
  button `.text` is exactly `💰`/`💡` and that clicks pay out); this is purely a
  font gap in the run environment. The user develops on Windows, where the system
  font may supply emoji. If you need them visible on Linux, bundle an emoji font
  and set it as the theme default — not required for logic verification.
- **`--headless` cannot screenshot.** The dummy renderer produces a blank/empty
  frame. Screenshots MUST run windowed (no `--headless`) against a real display —
  that's why `shot`/`shot-bubble` drop `--headless` and check `$DISPLAY`.
- **You must import before running a newly added scene/script.** A fresh `.gd`/
  `.tscn` the engine hasn't indexed won't load. `run.sh` runs an
  `--editor --quit` import pass before every command for exactly this reason.
- **`.tscn` files reference scripts by `res://` path, not UID.** Intentional — the
  driver scenes load without committing `.godot/` cache or `.uid` files (both
  regenerate; `.godot/` is gitignored).
- **`get_active_research_id()` / bubble gating require progression.** Bubbles only
  spawn when `viral_bubbles_unlocked` (a bot owned + 20 s elapsed) AND
  `only_paws_active` AND a cat exists AND under `BUBBLE_MAX_ON_SCREEN`. Idling the
  game won't show them quickly — `smoke`/`shot-bubble` set this state directly.

## Troubleshooting

- `FAIL: no DISPLAY` from `shot` → no display server. On WSL2 ensure WSLg is up
  (`echo $DISPLAY` → `:0`); otherwise run `xvfb-run -a .claude/skills/run-cat-idler/run.sh shot`.
- `Could not set V-Sync mode` warning on windowed launch → harmless (llvmpipe).
- `libasound.so.2: cannot open shared object file` → harmless; audio is absent.
- Download fails / slow → the binary is cached at
  `~/.cache/cat-idler-run/Godot_v4.6-stable_linux.x86_64`; drop one there manually
  to skip the download.
