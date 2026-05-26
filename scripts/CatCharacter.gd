extends Node2D

# ── Colours ──────────────────────────────────────────────────────────────────
const CAT_COLOR       := Color(0.90, 0.60, 0.20)   # ginger orange
const INNER_EAR_COLOR := Color(0.95, 0.70, 0.70)   # pale pink
const EYE_WHITE       := Color(1.00, 1.00, 1.00)
const PUPIL_COLOR     := Color(0.08, 0.08, 0.08)
const NOSE_COLOR      := Color(0.95, 0.55, 0.65)   # rose pink
const TAIL_COLOR      := CAT_COLOR

# ── Bob animation ─────────────────────────────────────────────────────────────
var base_y: float = 0.0


func _ready() -> void:
	base_y = position.y


func _process(_delta: float) -> void:
	position.y = base_y + sin(Time.get_ticks_msec() * 0.002) * 6.0


func _draw() -> void:
	_draw_tail()
	_draw_body()
	_draw_head()
	_draw_ears()
	_draw_eyes()
	_draw_nose()


# ── Individual draw helpers ───────────────────────────────────────────────────

func _draw_body() -> void:
	draw_circle(Vector2(0.0, 0.0), 52.0, CAT_COLOR)


func _draw_head() -> void:
	draw_circle(Vector2(0.0, -78.0), 38.0, CAT_COLOR)


func _draw_ears() -> void:
	# Left ear — outer + inner
	var l_outer := PackedVector2Array([
		Vector2(-38.0, -105.0),
		Vector2(-16.0, -105.0),
		Vector2(-30.0, -138.0),
	])
	var l_inner := PackedVector2Array([
		Vector2(-34.0, -108.0),
		Vector2(-20.0, -108.0),
		Vector2(-28.0, -128.0),
	])
	draw_polygon(l_outer, PackedColorArray([CAT_COLOR, CAT_COLOR, CAT_COLOR]))
	draw_polygon(l_inner, PackedColorArray([INNER_EAR_COLOR, INNER_EAR_COLOR, INNER_EAR_COLOR]))

	# Right ear — outer + inner
	var r_outer := PackedVector2Array([
		Vector2(16.0, -105.0),
		Vector2(38.0, -105.0),
		Vector2(30.0, -138.0),
	])
	var r_inner := PackedVector2Array([
		Vector2(20.0, -108.0),
		Vector2(34.0, -108.0),
		Vector2(28.0, -128.0),
	])
	draw_polygon(r_outer, PackedColorArray([CAT_COLOR, CAT_COLOR, CAT_COLOR]))
	draw_polygon(r_inner, PackedColorArray([INNER_EAR_COLOR, INNER_EAR_COLOR, INNER_EAR_COLOR]))


func _draw_eyes() -> void:
	# Whites
	draw_circle(Vector2(-14.0, -80.0), 8.0, EYE_WHITE)
	draw_circle(Vector2( 14.0, -80.0), 8.0, EYE_WHITE)
	# Pupils
	draw_circle(Vector2(-13.0, -80.0), 4.5, PUPIL_COLOR)
	draw_circle(Vector2( 13.0, -80.0), 4.5, PUPIL_COLOR)
	# Gleam
	draw_circle(Vector2(-11.0, -82.0), 1.5, EYE_WHITE)
	draw_circle(Vector2( 15.0, -82.0), 1.5, EYE_WHITE)


func _draw_nose() -> void:
	var pts := PackedVector2Array([
		Vector2( 0.0, -64.0),
		Vector2(-5.0, -70.0),
		Vector2( 5.0, -70.0),
	])
	draw_polygon(pts, PackedColorArray([NOSE_COLOR, NOSE_COLOR, NOSE_COLOR]))


func _draw_tail() -> void:
	# Smooth arc: points sampled along a sine curve emanating from the
	# right flank of the body and curling upward — drawn back-to-front
	# so it sits behind the body.
	var pts := PackedVector2Array()
	var steps := 16
	for i in steps:
		var t := float(i) / float(steps - 1)
		pts.append(Vector2(
			50.0 + t * 62.0,
			12.0 - sin(t * PI) * 42.0
		))
	draw_polyline(pts, TAIL_COLOR, 9.0, true)
