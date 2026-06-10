extends Node

# Headless gameplay harness — drives the REAL Main scene + GameState autoload and
# asserts behaviour. No display needed (runs under --headless with the dummy renderer).
#
# This is the primary programmatic driver for this project: gameplay lives in GDScript
# (GameState.gd logic + Main.gd UI/spawn glue), so the way to "drive the app" is to
# instantiate Main.tscn, poke GameState, call the real handlers, and check state.
#
# Pattern to extend: add a new step in the `match _step` block. Each integer step runs
# on its own frame, so steps that need a frame to pass (pause/unpause, timer accrual)
# just live in a later-numbered step. Call _fail(msg) to abort with exit code 1.
#
# Run with: --fixed-fps 60 so per-frame delta is deterministic (1/60 s).

var _main: Control
var _step: int = 0
var _bubble: Dictionary
var _cat_node: Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep ticking even while the tree is paused
	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)
	# Suppress Main's progression popups so they don't pause the tree under us.
	_main._only_paws_popup_shown = true
	_main._happiness_cramped_popup_shown = true
	_main._happiness_riot_popup_shown = true
	_main._cat_crusher_popup_shown = true
	_main._starvation_popup_shown = true
	_main._starvation_2_popup_shown = true
	GameState.first_cat_popup_shown = true
	GameState.bot_unlock_popup_shown = true
	GameState.upgrades_tab_popup_shown = true
	GameState.bot_manager_unlock_popup_shown = true

func _fail(msg: String) -> void:
	print("FAIL: ", msg)
	get_tree().quit(1)

func _process(_delta: float) -> void:
	_step += 1
	match _step:
		2:
			# Core loop: manual click earns $1.
			var before: float = GameState.money
			GameState.click()
			if GameState.money != before + 1.0:
				_fail("click() did not add $1")
			print("PASS: click() earns money")
			# Bubble unlock timer: needs a bot, then 20s of accumulation.
			GameState.manager_bots = 1
			GameState._viral_delay_timer = 19.8
		40:
			if not GameState.viral_bubbles_unlocked:
				_fail("viral_bubbles_unlocked did not flip after 20s (timer=%f)" % GameState._viral_delay_timer)
			print("PASS: 20s timer flips viral_bubbles_unlocked")
			GameState.money = 100000.0
			GameState.cats = 5
			GameState.only_paws_active = true
			GameState._update_paws_rate()
			_main._on_cat_purchased()  # spawn a real CatCharacter to anchor bubbles
			_cat_node = _main.cat_container.get_children().back()
		42:
			if _main.cat_container.get_child_count() == 0:
				_fail("no cat node in CatContainer")
			# Guard: no spawn while OnlyPaws is off.
			GameState.only_paws_active = false
			_main._try_spawn_bubble_for_cat(_cat_node)
			if _main._active_bubbles.size() != 0 or GameState.viral_popup_shown:
				_fail("spawn not blocked while only_paws_active == false")
			print("PASS: spawn blocked while only_paws_active is false")
			GameState.only_paws_active = true
		44:
			# First viral spawn fires the whale popup (not a bubble) and pauses the tree.
			_main._try_spawn_bubble_for_cat(_cat_node)
			if not GameState.viral_popup_shown:
				_fail("viral_popup_shown not set on first viral spawn")
			if _main._active_bubbles.size() != 0:
				_fail("bubble spawned instead of popup on first viral event")
			if not get_tree().paused:
				_fail("tree not paused by whale popup")
			var overlay: Node = null
			for c: Node in _main.get_children():
				if c is ColorRect and (c as ColorRect).z_index == 20:
					overlay = c
			if overlay == null:
				_fail("whale popup overlay (ColorRect z_index 20) not found")
			print("PASS: first viral spawn shows whale popup and pauses tree")
			get_tree().paused = false
			overlay.queue_free()
		46:
			# After dismiss, a viral bubble Button spawns.
			_main._try_spawn_bubble_for_cat(_cat_node)
			if _main._active_bubbles.size() != 1:
				_fail("no bubble after popup dismissed (size=%d)" % _main._active_bubbles.size())
			_bubble = _main._active_bubbles[0]
			if _bubble.type != "viral":
				_fail("expected viral, got " + str(_bubble.type))
			if (_bubble.node as Button).text != "💰":
				_fail("viral text wrong: '" + (_bubble.node as Button).text + "'")
			print("PASS: viral bubble spawns with 💰 text")
		48:
			# Clicking the viral bubble grants money and removes it.
			var before: float = GameState.money
			_main._on_bubble_pressed(_bubble)
			if GameState.money <= before:
				_fail("viral click granted no money")
			if _main._active_bubbles.size() != 0:
				_fail("bubble not removed after click")
			print("PASS: viral click grants money (+$%.2f)" % (GameState.money - before))
		50:
			# Inspiration path with active research.
			GameState.money = 100000.0
			GameState.research_cat_fraction = 1.0
			GameState.fund_research("cat_power_unite")
			if GameState.get_active_research_id() != "cat_power_unite":
				_fail("research not active after funding")
			_main._try_spawn_bubble_for_cat(_cat_node)  # fraction 1.0 => always inspiration
			if _main._active_bubbles.size() != 1:
				_fail("no inspiration bubble spawned")
			var ib: Dictionary = _main._active_bubbles[0]
			if ib.type != "inspiration":
				_fail("expected inspiration, got " + str(ib.type))
			if (ib.node as Button).text != "💡":
				_fail("inspiration text wrong: '" + (ib.node as Button).text + "'")
			var pts_before: float = GameState.research_points.get("cat_power_unite", 0.0)
			_main._on_bubble_pressed(ib)
			if GameState.research_points.get("cat_power_unite", 0.0) <= pts_before:
				_fail("inspiration click added no research points")
			print("PASS: inspiration bubble spawns 💡 and grants research points")
		51:
			# Click-through: one left-click collects the clicked bubble AND any stacked under the cursor.
			GameState.research_cat_fraction = 0.0  # force viral
			GameState.money = 100000.0
			_main._try_spawn_bubble_for_cat(_cat_node)
			_main._try_spawn_bubble_for_cat(_cat_node)
			if _main._active_bubbles.size() != 2:
				_fail("expected 2 stacked bubbles, got %d" % _main._active_bubbles.size())
			# Overlap both bubble rects on the cursor point so one click hits both.
			var click_pos: Vector2 = get_viewport().get_mouse_position()
			for b: Dictionary in _main._active_bubbles:
				var btn: Button = b.node
				btn.size = Vector2(80, 80)
				btn.position = click_pos - Vector2(40, 40)
			var first: Dictionary = _main._active_bubbles[0]
			var money_before: float = GameState.money
			var ev: InputEventMouseButton = InputEventMouseButton.new()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.pressed = true
			_main._on_bubble_gui_input(ev, first)
			if _main._active_bubbles.size() != 0:
				_fail("stacked bubbles not all collected (left=%d)" % _main._active_bubbles.size())
			if GameState.money <= money_before:
				_fail("stacked collect granted no money")
			print("PASS: one click collects stacked bubbles (2 at once)")
		52:
			# Burst gate (closed): an expiring per-cat timer must reset but NOT spawn.
			GameState.research_cat_fraction = 0.0
			GameState.money = 100000.0
			_main._burst_window_active = false
			_main._global_cd_timer = 100.0  # hold the window closed across the test
			_main._cat_bubble_timers[_cat_node.get_instance_id()] = 0.001  # about to expire
		54:
			if _main._active_bubbles.size() != 0:
				_fail("bubble spawned while burst window closed")
			if _main._cat_bubble_timers[_cat_node.get_instance_id()] <= 0.0:
				_fail("per-cat timer did not reset on expiry while window closed")
			print("PASS: closed window discards expired timer (resets, no spawn)")
			# Burst gate (open): force the window open and expire the timer again.
			_main._burst_window_active = true
			_main._burst_window_timer = 100.0  # hold the window open across the test
			_main._cat_bubble_timers[_cat_node.get_instance_id()] = 0.001
		56:
			if _main._active_bubbles.size() != 1:
				_fail("no bubble spawned during open burst window (size=%d)" % _main._active_bubbles.size())
			print("PASS: open window allows per-cat spawn")
		57:
			# Cat wander + bubble pause/resume on an isolated instance (State.WALKING == 1).
			# set_process(false) so only our manual _process() calls drive it (deterministic).
			var c: Node2D = load("res://scenes/CatCharacter.tscn").instantiate()
			_main.add_child(c)
			c.set_process(false)
			c.global_position = Vector2(500, 400)
			c._wander_timer = 0.001
			c._process(0.1)  # timer expires → picks target, enters WALKING
			if c._state != 1:
				_fail("cat did not enter WALKING after timer expiry")
			# Deterministic movement toward a known target.
			c._target_pos = Vector2(900, 400)
			c.global_position = Vector2(500, 400)
			c._process(0.1)
			if c.global_position.x <= 500.0:
				_fail("walking cat did not move toward target")
			# pause_for_bubble freezes movement.
			c.pause_for_bubble()
			var frozen_pos: Vector2 = c.global_position
			c._wander_timer = 0.001
			c._process(1.0)
			if c.global_position != frozen_pos:
				_fail("paused cat moved")
			# resume_from_bubble clears the pause.
			c.resume_from_bubble()
			if c._bubble_paused:
				_fail("resume_from_bubble did not clear _bubble_paused")
			c.queue_free()
			print("PASS: cat wanders, freezes on pause, and resumes")
		58:
			print("ALL GAMEPLAY CHECKS PASSED")
			get_tree().quit(0)
