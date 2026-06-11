extends Node

# Screenshot driver for the BUBBLE feature — needs a real display.
# Drives GameState into the unlocked state, spawns viral + inspiration bubbles
# over cats, captures the frame, then quits. Verifies the bubbles render visibly.

const OUT_PATH: String = "user://run_bubble_screenshot.png"
var _main: Control
var _frames: int = 0

func _ready() -> void:
	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)
	# Suppress Main's progression popups so nothing pauses/obscures the frame.
	_main._only_paws_popup_shown = true
	GameState.first_cat_popup_shown = true
	GameState.bot_unlock_popup_shown = true
	GameState.upgrades_tab_popup_shown = true
	GameState.bot_manager_unlock_popup_shown = true
	# Drive into the bubble-spawning state.
	GameState.money = 100000.0
	GameState.cats = 5
	GameState.manager_bots = 1
	GameState.only_paws_active = true
	GameState.viral_bubbles_unlocked = true
	GameState.viral_popup_shown = true  # skip the one-time whale popup
	GameState.update_paws_rate()
	# Spawn a few cat sprites to anchor bubbles to.
	for i: int in 5:
		_main._on_cat_purchased()
	# Fund research so the inspiration type is also reachable.
	GameState.research_cat_fraction = 1.0
	GameState.fund_research("cat_power_unite")

func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 10:
		# Force one of each bubble type onto the screen, anchored to two different cats.
		var cats: Array[Node] = _main.cat_container.get_children()
		GameState.research_cat_fraction = 0.0  # forces "viral"
		_main._spawn_bubble(cats[0] as Node2D)
		GameState.research_cat_fraction = 1.0  # forces "inspiration"
		_main._spawn_bubble(cats[1] as Node2D)
	elif _frames == 25:
		await RenderingServer.frame_post_draw
		var img: Image = get_viewport().get_texture().get_image()
		var err: int = img.save_png(OUT_PATH)
		# Crop+magnify around the bubbles so the glyphs are inspectable.
		var b0: Button = _main._active_bubbles[0].node
		var b1: Button = _main._active_bubbles[1].node
		var minp: Vector2 = b0.position.min(b1.position) - Vector2(20, 20)
		var maxp: Vector2 = (b0.position + b0.size).max(b1.position + b1.size) + Vector2(20, 20)
		var region := Rect2i(Vector2i(minp), Vector2i(maxp - minp))
		region = region.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		var crop: Image = img.get_region(region)
		crop.resize(crop.get_width() * 5, crop.get_height() * 5, Image.INTERPOLATE_NEAREST)
		crop.save_png("user://run_bubble_zoom.png")
		print("BUBBLE_SCREENSHOT err=", err, " bubbles=", _main._active_bubbles.size(),
			" b0_text='", b0.text, "' b1_text='", b1.text, "'",
			" -> ", ProjectSettings.globalize_path(OUT_PATH))
		get_tree().quit(0 if err == OK else 1)
