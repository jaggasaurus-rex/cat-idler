extends Node2D

# Wander states. IDLE: waiting for next move decision. WALKING: moving toward _target_pos.
# HISSING: frozen during dog attack warning phase; composes with _bubble_paused independently.
# _bubble_paused = true freezes both movement and timer; only viral bubbles trigger this.
# Animation names "idle" and "walk" are called by name — frames are authored in .tres resources.
enum State { IDLE, WALKING, HISSING }

# Each .tres defines both "idle" (19 frames) and "walk" (25 frames) at 6 fps, loop=true.
# randi() % COLOR_VARIANTS.size() yields an index in [0, 4] for five variants.
# All instances share these preloaded resources — never call mutating SpriteFrames methods
# (add_animation, remove_animation, set_animation_speed, etc.) through sprite.sprite_frames.
const COLOR_VARIANTS: Array[SpriteFrames] = [
	preload("res://assets/cats/cat_frames_1.tres"),
	preload("res://assets/cats/cat_frames_2.tres"),
	preload("res://assets/cats/cat_frames_3.tres"),
	preload("res://assets/cats/cat_frames_4.tres"),
	preload("res://assets/cats/cat_frames_5.tres"),
]

var _state: State = State.IDLE
var _wander_timer: float = 0.0
var _target_pos: Vector2 = Vector2.ZERO
var _bubble_paused: bool = false
var _bounds: Rect2


func _ready() -> void:
	var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null:
		sprite.sprite_frames = COLOR_VARIANTS[randi() % COLOR_VARIANTS.size()]
		_play_anim("idle")
	_wander_timer = randf_range(Config.CAT_WANDER_MIN, Config.CAT_WANDER_MAX)
	_bounds = get_viewport_rect()


## Sets the play-area rect used for wander targeting. Called by Main after add_child
## so cats stay inside CenterPanel rather than the full viewport.
## Ignores zero-size rects (layout not yet resolved) and keeps the current bounds.
func set_bounds(rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	_bounds = rect


func _process(delta: float) -> void:
	if _bubble_paused:
		return
	if _state == State.HISSING:
		return

	_wander_timer -= delta
	if _wander_timer <= 0.0:
		# Pick a new destination inside the injected bounds (matches _place_cat in Main.gd).
		var padding: float = 40.0
		_target_pos.x = randf_range(_bounds.position.x + padding, _bounds.end.x - padding)
		_target_pos.y = randf_range(_bounds.position.y + _bounds.size.y * 0.10 + padding, _bounds.end.y - padding)
		_state = State.WALKING
		_wander_timer = randf_range(Config.CAT_WANDER_MIN, Config.CAT_WANDER_MAX)
		var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if sprite != null:
			sprite.flip_h = _target_pos.x < global_position.x
			_play_anim("walk")

	if _state == State.WALKING:
		var dir: Vector2 = _target_pos - global_position
		if dir.length() <= Config.CAT_MOVE_SPEED * delta:
			global_position = _target_pos
			_state = State.IDLE
			_play_anim("idle")
		else:
			global_position += dir.normalized() * Config.CAT_MOVE_SPEED * delta


## Stops all movement and timer while a money bubble is active above this cat.
func pause_for_bubble() -> void:
	_bubble_paused = true
	_state = State.IDLE
	_play_anim("idle")


## Resumes wandering after the money bubble is collected or expires.
func resume_from_bubble() -> void:
	_bubble_paused = false
	_wander_timer = randf_range(Config.CAT_WANDER_MIN, Config.CAT_WANDER_MAX)


## Interrupts wander behavior and plays the hissing animation for the warning phase.
## Movement and wander timer are frozen until stop_hissing() is called.
## Composes with _bubble_paused: a cat can be both bubble-paused and hissing.
func start_hissing() -> void:
	_state = State.HISSING
	# TODO: swap "idle" for "hiss" once cat_frames_N.tres includes that animation
	_play_anim("idle")


## Resumes normal wander behavior after battle warning ends.
func stop_hissing() -> void:
	_state = State.IDLE
	_play_anim("idle")
	_wander_timer = randf_range(Config.CAT_WANDER_MIN, Config.CAT_WANDER_MAX)


# Plays the named animation only when the AnimatedSprite2D exists and its SpriteFrames
# defines that animation; otherwise leaves the current animation unchanged. Never
# touches SpriteFrames data — "idle"/"walk" frames are authored in the editor.
func _play_anim(anim_name: String) -> void:
	var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
