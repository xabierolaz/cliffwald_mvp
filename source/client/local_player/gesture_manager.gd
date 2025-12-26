class_name GestureManager
extends Node

# --- CONFIGURACIÓN ---
signal spell_cast(gesture_id: StringName, direction: Vector3)

# 0.65 es muy tolerante. Permite líneas chuecas y círculos ovalados.
# Si sientes que confunde gestos, bájalo a 0.5.
const MATCH_THRESHOLD := 0.65
const RESAMPLE_POINTS := 64
const SIZE_BOX := 250.0

# --- VARIABLES INTERNAS ---
var recording: bool = false
var points: PackedVector2Array = []
var min_distance_sqr: float = 20.0 # Filtro de sensibilidad mínimo
var line: Line2D
var line_layer: CanvasLayer
var templates: Dictionary[StringName, PackedVector2Array] = {}

func _ready() -> void:
	_setup_visuals()
	_build_templates()

func _setup_visuals() -> void:
	line_layer = CanvasLayer.new()
	line_layer.name = "GestureLayer"
	add_child(line_layer)

	line = Line2D.new()
	line.width = 5.0
	line.default_color = Color(0.2, 0.8, 1.0, 0.8)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	line_layer.add_child(line)
	line.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cast_spell"):
		recording = true
		points.clear()
		var mouse_pos = get_viewport().get_mouse_position()
		points.append(mouse_pos)
		_update_line()
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

	elif event.is_action_released("cast_spell"):
		recording = false
		_update_line(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		# Filtro: Ignorar clics sin movimiento real
		if points.size() > 5 and _path_length(points) > 50.0:
			_process_gesture()

	elif recording and event is InputEventMouseMotion:
		var pos = event.position
		if points.is_empty() or pos.distance_squared_to(points[-1]) > min_distance_sqr:
			points.append(pos)
			_update_line()

func _update_line(clear_and_hide: bool = false) -> void:
	if not line: return
	if clear_and_hide:
		line.visible = false
		line.clear_points()
	else:
		line.visible = true
		line.points = points

func _process_gesture() -> void:
	# 1. Normalizar dibujo del jugador
	var candidate = _normalize_pipeline(points)

	# 2. Reconocer con tolerancia bidireccional
	var result = _recognize(candidate)

	# 3. Limpiar ID (quitar sufijos de permutación como #0, #1)
	var final_id = result.id.split("#")[0]
	var score = result.score

	print("Input: %s (Raw: %s) | Error: %.3f" % [final_id, result.id, score])

	if final_id != "" and score < MATCH_THRESHOLD:
		var cam = get_viewport().get_camera_3d()
		var aim_dir = -cam.global_transform.basis.z if cam else Vector3.FORWARD
		spell_cast.emit(final_id, aim_dir)
		print("✅ HECHIZO: ", final_id)
	else:
		print("❌ Gesto no claro")

# ---------- LÓGICA DE RECONOCIMIENTO (CORE) ----------

func _recognize(candidate: PackedVector2Array) -> Dictionary:
	var best_dist = INF
	var best_id = &""

	# Crear versión invertida para que no importe si dibuja horario/antihorario
	var candidate_reversed = candidate.duplicate()
	candidate_reversed.reverse()

	for id in templates:
		var template_pts = templates[id]

		var d1 = _path_distance(candidate, template_pts)
		var d2 = _path_distance(candidate_reversed, template_pts)
		var dist = min(d1, d2)

		if dist < best_dist:
			best_dist = dist
			best_id = id

	var avg_dist = best_dist / SIZE_BOX
	return {"id": best_id, "score": avg_dist}

func _build_templates() -> void:
	templates.clear()

	# 1. KINETIC PULSE (Universal) - Horizontal Line
	# GDD: "Simple Horizontal Line (—)"
	var line_pts = PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(20, 0), Vector2(30, 0), Vector2(40, 0), Vector2(50, 0)])
	templates[&"kinetic_pulse"] = _normalize_pipeline(line_pts)

	# 2. AEGIS (Vesper/Universal) - Circle
	# Geometric Shape 1
	templates[&"aegis"] = _normalize_pipeline(_regular_polygon_points(32, 100.0, -PI/2))

	# 3. PYROCLASM (Ignis) - Triangle
	# Geometric Shape 2
	var raw_tri = _regular_polygon_points(3, 100.0, -PI/2)
	_add_permutations_for_shape(&"pyroclasm", raw_tri, 3)

	# 4. STASIS (Axiom) - Square
	# Geometric Shape 3
	var raw_sq = _regular_polygon_points(4, 100.0, -PI/4)
	_add_permutations_for_shape(&"stasis", raw_sq, 4)
# Crea copias rotando el punto de inicio para que no importe dónde empieza el jugador
func _add_permutations_for_shape(base_name: StringName, raw_pts: PackedVector2Array, sides: int) -> void:
	var pts = _resample(raw_pts, RESAMPLE_POINTS)
	var step = int(pts.size() / float(sides))

	for i in range(sides):
		var rotated = pts.duplicate()
		# Mover el inicio del array 'step' veces
		for k in range(step * i):
			# rotated.append(rotated.pop_front()) # pop_front not supported on PackedVector2Array
			var first = rotated[0]
			rotated.remove_at(0)
			rotated.append(first)

		templates[StringName(base_name + "#" + str(i))] = _normalize_pipeline(rotated)

# ---------- PIPELINE MATEMÁTICO ----------

func _normalize_pipeline(raw_pts: PackedVector2Array) -> PackedVector2Array:
	var pts = _resample(raw_pts, RESAMPLE_POINTS)
	pts = _rotate_to_zero(pts)
	pts = _scale_to_square(pts, SIZE_BOX) # Este paso arregla los óvalos
	pts = _translate_to_origin(pts)
	return pts

# Algoritmo de resampleo corregido (sin bug de inserción)
func _resample(pts: PackedVector2Array, n: int) -> PackedVector2Array:
	var I = _path_length(pts) / float(n - 1)
	var D = 0.0
	var new_pts = PackedVector2Array()
	new_pts.append(pts[0])
	var i = 1
	while i < pts.size():
		var d = pts[i-1].distance_to(pts[i])
		if (D + d) >= I:
			var t = (I - D) / d
			var q = pts[i-1].lerp(pts[i], t)
			new_pts.append(q)
			pts.insert(i, q) # Insertamos para mantener la continuidad correcta
			D = 0.0
			i += 1
		else:
			D += d
			i += 1
	while new_pts.size() < n:
		new_pts.append(pts[-1])
	return new_pts

func _rotate_to_zero(pts: PackedVector2Array) -> PackedVector2Array:
	var c = _centroid(pts)
	var angle = atan2(c.y - pts[0].y, c.x - pts[0].x)
	return _rotate_by(pts, -angle, c)

func _rotate_by(pts: PackedVector2Array, radians: float, pivot: Vector2) -> PackedVector2Array:
	var new_pts = PackedVector2Array()
	var t = Transform2D().translated(pivot).rotated(radians).translated(-pivot)
	return t * pts

func _scale_to_square(pts: PackedVector2Array, size: float) -> PackedVector2Array:
	var min_v = Vector2(INF, INF)
	var max_v = Vector2(-INF, -INF)
	for p in pts:
		min_v = min_v.min(p)
		max_v = max_v.max(p)
	var w = max_v.x - min_v.x
	var h = max_v.y - min_v.y
	var new_pts = PackedVector2Array()
	for p in pts:
		new_pts.append(Vector2(
			(p.x - min_v.x) * (size / max(w, 0.01)),
			(p.y - min_v.y) * (size / max(h, 0.01))
		))
	return new_pts

func _translate_to_origin(pts: PackedVector2Array) -> PackedVector2Array:
	var c = _centroid(pts)
	var new_pts = PackedVector2Array()
	for p in pts: new_pts.append(p - c)
	return new_pts

func _centroid(pts: PackedVector2Array) -> Vector2:
	var sum = Vector2.ZERO
	for p in pts: sum += p
	return sum / pts.size()

func _path_length(pts: PackedVector2Array) -> float:
	var d = 0.0
	for i in range(1, pts.size()): d += pts[i-1].distance_to(pts[i])
	return d

func _path_distance(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var d = 0.0
	var n = min(a.size(), b.size())
	for i in range(n): d += a[i].distance_to(b[i])
	return d / n

func _regular_polygon_points(sides: int, radius: float, start_angle: float = 0.0) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in range(sides):
		var angle = start_angle + (TAU * i / sides)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	pts.append(pts[0])
	return pts
