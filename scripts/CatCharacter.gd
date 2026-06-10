extends Node2D

# Wander states. IDLE: waiting for next move decision. WALKING: moving toward _target_pos.
# _bubble_paused = true freezes both movement and timer; only viral bubbles trigger this.
# Animation names "idle" and "walk" are called by name — frames are added in the editor.
enum State { IDLE, WALKING }

var _state: State = State.IDLE
var _wander_timer: float = 0.0
var _target_pos: Vector2 = Vector2.ZERO
var _bubble_paused: bool = false


func _ready() -> void:
	_wander_timer = randf_range(Config.CAT_WANDER_MIN, Config.CAT_WANDER_MAX)


func _process(delta: float) -> void:
	if _bubble_paused:
		return

	_wander_timer -= delta
	if _wander_timer <= 0.0:
		# Pick a new destination inside the safe zone (matches _place_cat in Main.gd).
		var vp: Vector2 = get_viewport_rect().size
		var padding: float = 40.0
		_target_pos.x = randf_range(padding, vp.x - padding)
		_target_pos.y = randf_range(vp.y * 0.10 + padding, vp.y - padding)
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


# Plays the named animation only when the AnimatedSprite2D exists and its SpriteFrames
# defines that animation; otherwise leaves the current animation unchanged. Never
# touches SpriteFrames data — "idle"/"walk" frames are authored in the editor.
func _play_anim(anim_name: String) -> void:
	var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
