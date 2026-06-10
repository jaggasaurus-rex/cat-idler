#!/usr/bin/env bash
# Driver for Cat Idler (Godot 4.6). Downloads the matching Godot binary on first
# use, then runs one of: check | smoke | shot | shot-bubble | play.
#
#   .claude/skills/run-cat-idler/run.sh check        # import + compile all GDScript
#   .claude/skills/run-cat-idler/run.sh smoke        # headless gameplay assertions
#   .claude/skills/run-cat-idler/run.sh shot         # windowed screenshot (needs a display)
#   .claude/skills/run-cat-idler/run.sh shot-bubble  # windowed screenshot of the bubble feature
#   .claude/skills/run-cat-idler/run.sh play         # launch the real game windowed (human path)
#
# Paths are resolved relative to this script, so it works from any CWD.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SKILL_DIR/../../.." && pwd)"   # <unit> = repo root
GODOT_VER="4.6-stable"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cat-idler-run"
GODOT_BIN="$CACHE_DIR/Godot_v${GODOT_VER}_linux.x86_64"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VER}/Godot_v${GODOT_VER}_linux.x86_64.zip"

ensure_godot() {
	if [[ -x "$GODOT_BIN" ]]; then return; fi
	echo "Godot $GODOT_VER not cached; downloading to $CACHE_DIR ..."
	mkdir -p "$CACHE_DIR"
	curl -sL --max-time 300 -o "$CACHE_DIR/godot.zip" "$GODOT_URL"
	unzip -o "$CACHE_DIR/godot.zip" -d "$CACHE_DIR" >/dev/null
	chmod +x "$GODOT_BIN"
	"$GODOT_BIN" --version
}

# Import once so newly added scripts/scenes are known to the engine. Fails loudly
# on GDScript parse errors.
import_project() {
	local out
	out="$("$GODOT_BIN" --headless --path "$PROJECT_DIR" --editor --quit 2>&1)" || true
	if grep -qiE "SCRIPT ERROR|Parse Error|Failed to load script" <<<"$out"; then
		echo "$out" | grep -iE "SCRIPT ERROR|Parse Error|Failed to load script"
		echo "FAIL: GDScript errors during import"; exit 1
	fi
}

run_scene() { # $1 = res:// scene path ; extra args passed through
	local scene="$1"; shift
	"$GODOT_BIN" --headless --path "$PROJECT_DIR" "$@" "$scene"
}

cmd="${1:-smoke}"
ensure_godot

case "$cmd" in
	check)
		import_project
		echo "OK: project imports, all GDScript compiles"
		;;
	smoke)
		import_project
		run_scene "res://.claude/skills/run-cat-idler/gameplay_harness.tscn" --fixed-fps 60
		;;
	shot)
		import_project
		[[ -n "${DISPLAY:-}" ]] || { echo "FAIL: no DISPLAY (needs WSLg :0 or xvfb)"; exit 1; }
		# Windowed (no --headless): real GL context required for a non-blank capture.
		"$GODOT_BIN" --path "$PROJECT_DIR" "res://.claude/skills/run-cat-idler/screenshot.tscn"
		echo "Screenshot: $HOME/.local/share/godot/app_userdata/Cat Idler/run_screenshot.png"
		;;
	shot-bubble)
		import_project
		[[ -n "${DISPLAY:-}" ]] || { echo "FAIL: no DISPLAY (needs WSLg :0 or xvfb)"; exit 1; }
		"$GODOT_BIN" --path "$PROJECT_DIR" "res://.claude/skills/run-cat-idler/screenshot_bubble.tscn"
		echo "Screenshot: $HOME/.local/share/godot/app_userdata/Cat Idler/run_bubble_screenshot.png"
		echo "Zoom:       $HOME/.local/share/godot/app_userdata/Cat Idler/run_bubble_zoom.png"
		;;
	play)
		[[ -n "${DISPLAY:-}" ]] || { echo "FAIL: no DISPLAY (needs WSLg :0 or xvfb)"; exit 1; }
		"$GODOT_BIN" --path "$PROJECT_DIR"
		;;
	*)
		echo "usage: run.sh {check|smoke|shot|shot-bubble|play}"; exit 2
		;;
esac
