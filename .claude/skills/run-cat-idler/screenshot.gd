extends Node

# Screenshot driver — needs a REAL display (WSLg :0 on WSL2, or xvfb elsewhere).
# Loads the real Main scene, lets it settle for a few frames, captures the
# rendered viewport to a PNG, then quits. Run via run.sh (see SKILL.md).

const OUT_PATH: String = "user://run_screenshot.png"
var _frames: int = 0

func _ready() -> void:
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	add_child(main)

func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 30:
		await RenderingServer.frame_post_draw
		var img: Image = get_viewport().get_texture().get_image()
		var err: int = img.save_png(OUT_PATH)
		print("SCREENSHOT err=", err, " -> ", ProjectSettings.globalize_path(OUT_PATH))
		get_tree().quit(0 if err == OK else 1)
