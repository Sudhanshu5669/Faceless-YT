## The firing control bunker at the range, 11 May 1998 (dramatised: a sandbagged concrete room with a slit window
## onto the blazing desert, a steel table with the firing panel, a wall clock and a tear-off date calendar).
##
## Local frame: the floor's centre at the origin, y up; the slit wall at z = -WALL_Z (the room looks out through it,
## toward -z); cameras stand inside at +z. The table's top is at TABLE_Y, the panel on it centred at PANEL_AT.
##
## params:
##   clock     [[t, "HH:MM"], ...]   the wall clock's reading; between keys the hands sweep (eased) and land on each key
##             with a small mechanical overshoot (the minute hand "clunks" onto its mark); the second hand ticks round
##   calendar  {"from": "10", "to": "11", "month": "MAY", "tear": t, "hand": actor id}   a tear-off date calendar beside
##             the clock: the actor reaches up, grabs the top page and rips it off at `tear` (it flutters to the floor),
##             showing the next date
##   key       {"turn": t, "hand": actor id}   the firing key in its lock on the panel: the actor's right hand rests on it;
##             at `turn` it turns a quarter (a hard click, an overshoot) and the panel's lamps flip from amber to red
##   sitters   [actor ids]   each sits on a folding stool that follows their hips
## anchors: clock, calendar, key, panel, slit
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")
const PH := "incoming/polyhaven_pokhran/models/"
const PB := "incoming/pokhran_blender/"
const WALL_Z := 2.2
const HALF_W := 3.0
const ROOF := 2.6
const SLIT := Vector4(-1.9, 1.1, 1.9, 1.38)     # x0, y0, x1, y1 of the window slot in the front wall
const TABLE_Y := 0.76
const PANEL_AT := Vector3(0.0, TABLE_Y, -1.62)
const CLOCK_AT := Vector3(0.5, 2.18, -WALL_Z + 0.02)
const CLOCK_SCALE := 1.7
const CAL_AT := Vector3(0.5, 1.68, -WALL_Z + 0.02)
const KEY_AT := Vector3(0.3, TABLE_Y + 0.115, -1.55)  # the key lock's face on the sloped panel
# The model's hands at rest point at these clock angles (degrees clockwise from 12).
const A0_MIN := 57.4
const A0_HOUR := 305.5
const A0_SEC := 180.0

const CONCRETE := """
shader_type spatial;
varying vec3 wp;
float h(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h(i), h(i + vec3(1, 0, 0)), f.x), mix(h(i + vec3(0, 1, 0)), h(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h(i + vec3(0, 0, 1)), h(i + vec3(1, 0, 1)), f.x), mix(h(i + vec3(0, 1, 1)), h(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = n3(wp * 3.0) * 0.5 + n3(wp * 9.0) * 0.3 + n3(wp * 0.7) * 0.2;
	vec3 c = vec3(0.42, 0.40, 0.36) * (0.78 + 0.35 * n);
	c *= 0.9 + 0.1 * smoothstep(0.0, 0.05, abs(fract(wp.y / 0.9) - 0.5) * 2.0 - 0.9 + 0.9);
	ALBEDO = c;
	ROUGHNESS = 0.92;
}
"""

# The desert outside the slot: blown out, white-hot sand under a pale sky, a heat shimmer.
const OUTSIDE := """
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform float t = 0.0;
void fragment() {
	float y = UV.y;
	vec3 sky = mix(vec3(1.0, 0.98, 0.93), vec3(0.78, 0.86, 0.98), smoothstep(0.55, 0.0, y));
	vec3 sand = vec3(1.0, 0.86, 0.62);
	float hz = 0.56 + 0.006 * sin(UV.x * 40.0 + t * 3.0);
	vec3 c = mix(sky, sand, smoothstep(hz - 0.01, hz + 0.02, y));
	ALBEDO = c * 1.5;
}
"""

var _p := {}
var _min_hand: Node3D
var _hour_hand: Node3D
var _sec_hand: Node3D
var _clock: Node3D
var _page: Node3D
var _key: Node3D
var _lamps: Array = []
var _amber: Material
var _red: Material
var _dark: Material
var _stools := {}
var _outside_mat: ShaderMaterial
var _red_glow: OmniLight3D


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "control"))
	var conc := Kit.shader(CONCRETE)
	var steel := Kit.mat("#4a4d4c", 0.5, 0.6)
	var olive := Kit.mat("#465036", 0.55, 0.25)
	# The room: floor, ceiling, side and back walls; the front wall built round the slot.
	Kit.box(root, Vector3(HALF_W * 2.0, 0.1, WALL_Z * 2.0 + 0.4), Vector3(0, -0.05, 0), conc)
	Kit.box(root, Vector3(HALF_W * 2.0, 0.25, WALL_Z * 2.0 + 0.4), Vector3(0, ROOF + 0.125, 0), conc)
	for s: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.3, ROOF, WALL_Z * 2.0 + 0.4), Vector3(s * (HALF_W + 0.15), ROOF * 0.5, 0), conc)
	Kit.box(root, Vector3(HALF_W * 2.0, ROOF, 0.3), Vector3(0, ROOF * 0.5, WALL_Z + 0.35), conc)
	var fz := -WALL_Z - 0.2
	Kit.box(root, Vector3(HALF_W * 2.0, SLIT.y, 0.4), Vector3(0, SLIT.y * 0.5, fz), conc)
	Kit.box(root, Vector3(HALF_W * 2.0, ROOF - SLIT.w, 0.4), Vector3(0, (ROOF + SLIT.w) * 0.5, fz), conc)
	for s: float in [-1.0, 1.0]:
		var w := HALF_W - absf(SLIT.x)
		Kit.box(root, Vector3(w, SLIT.w - SLIT.y, 0.4), Vector3(s * (absf(SLIT.x) + w * 0.5), (SLIT.y + SLIT.w) * 0.5, fz), conc)
	# A steel lintel over the slot.
	Kit.box(root, Vector3(SLIT.z - SLIT.x + 0.3, 0.08, 0.42), Vector3(0, SLIT.w + 0.04, fz), steel)
	# Outside: the blazing desert seen through the slot, far enough for parallax.
	_outside_mat = Kit.shader(OUTSIDE)
	Kit.quad(root, Vector2(40.0, 14.0), Vector3(0, 1.4, -WALL_Z - 9.0), _outside_mat)
	# The sun pours in through the slot: a hard warm beam raking across the table and the floor (dusty air shows it).
	var sun := Kit.spot(root, Vector3(-1.6, 4.6, -WALL_Z - 5.0), Vector3(0.3, 0.6, 0.2), Color(1.0, 0.86, 0.64), 14.0, 14.0, 22.0, true, 1.2)
	sun.spot_attenuation = 0.4
	# Bounce off the sunlit sand: a soft warm glow just inside the slot.
	Kit.omni(root, Vector3(0, 1.5, -WALL_Z + 0.2), Color(1.0, 0.8, 0.55), 0.8, 4.0, false, 0.4)
	# A bare bulb on its flex over the clock: the only light inside besides the slot.
	var bulb := Vector3(CLOCK_AT.x + 0.1, 2.52, -WALL_Z + 0.32)
	Kit.rod(root, bulb, Vector3(bulb.x, ROOF, bulb.z), 0.006, Kit.mat("#111111", 0.6), 4)
	Kit.ball(root, 0.035, bulb, Kit.lit("#ffd9a0", 6.0), 10)
	Kit.omni(root, bulb + Vector3(0, -0.06, 0), Color(1.0, 0.78, 0.5), 1.1, 3.0, true, 0.5)
	# The panel's lamps throw red on the operator once the key turns.
	_red_glow = Kit.omni(root, PANEL_AT + Vector3(-0.2, 0.25, 0.35), Color(1.0, 0.12, 0.06), 0.0, 1.6, false, 0.3)
	# The tube light on the ceiling (off: daylight only) and a caged bulkhead lamp glowing dimly by the door.
	Kit.box(root, Vector3(1.22, 0.05, 0.08), Vector3(0.6, ROOF - 0.04, 0.4), Kit.mat("#d8d8d2", 0.6))
	Kit.ball(root, 0.07, Vector3(-HALF_W + 0.1, 2.1, 1.4), Kit.lit("#ffcf8a", 2.0), 10)
	Kit.omni(root, Vector3(-HALF_W + 0.3, 2.1, 1.4), Color(1.0, 0.75, 0.45), 0.6, 3.5)
	# The steel table and the firing panel.
	Kit.box(root, Vector3(1.9, 0.04, 0.8), Vector3(0, TABLE_Y - 0.02, -1.6), steel)
	for sx: float in [-0.9, 0.9]:
		for sz: float in [-1.95, -1.25]:
			Kit.box(root, Vector3(0.04, TABLE_Y - 0.04, 0.04), Vector3(sx, (TABLE_Y - 0.04) * 0.5, sz), steel)
	_panel(root, olive, steel)
	# The field telephone, a thermos and a log book on the table.
	var radio := Kit.model(PH + "vintage_radio_transceiver/vintage_radio_transceiver_2k.gltf")
	radio.position = Vector3(-0.68, TABLE_Y + 0.07, -1.7)
	radio.rotation.y = 0.35
	radio.scale = Vector3.ONE * 1.4
	root.add_child(radio)
	var thermos := Kit.model(PH + "plastic_thermos/plastic_thermos_2k.gltf")
	thermos.position = Vector3(0.82, TABLE_Y, -1.45)
	root.add_child(thermos)
	Kit.box(root, Vector3(0.3, 0.03, 0.22), Vector3(-0.3, TABLE_Y + 0.015, -1.38), Kit.mat("#2d3a5a", 0.7), Vector3(0, 0.2, 0))
	Kit.box(root, Vector3(0.28, 0.005, 0.2), Vector3(-0.3, TABLE_Y + 0.032, -1.38), Kit.mat("#e8e2d0", 0.9), Vector3(0, 0.2, 0))
	# The wall clock and the tear-off calendar.
	_clock = Kit.model(PH + "wall_clock/wall_clock_2k.gltf")
	_clock.position = CLOCK_AT
	_clock.scale = Vector3.ONE * CLOCK_SCALE
	root.add_child(_clock)
	_min_hand = _clock.find_child("wall_clock_minute_hand", true, false) as Node3D
	_hour_hand = _clock.find_child("wall_clock_hours_hand", true, false) as Node3D
	_sec_hand = _clock.find_child("wall_clock_second_hand", true, false) as Node3D
	_calendar(root)
	# Folding stools for the sitters (they follow the hips).
	for aid in _p.get("sitters", []):
		var st := Kit.model(PH + "folding_wooden_stool/folding_wooden_stool_2k.gltf")
		root.add_child(st)
		_stools[String(aid)] = st
	return root


func _panel(root: Node3D, olive: Material, steel: Material) -> void:
	# A sloped console: its face tilts up toward the operator.
	var pn := Node3D.new()
	pn.position = PANEL_AT
	root.add_child(pn)
	Kit.box(pn, Vector3(1.0, 0.1, 0.42), Vector3(0, 0.05, 0), olive)
	var face := Node3D.new()
	face.position = Vector3(0, 0.1, 0.0)
	face.rotation.x = 0.42
	pn.add_child(face)
	Kit.box(face, Vector3(1.0, 0.03, 0.44), Vector3(0, 0.015, 0), olive)
	Kit.box(face, Vector3(0.96, 0.004, 0.4), Vector3(0, 0.032, 0), Kit.mat("#2a2e26", 0.4, 0.3))
	# Two rows of toggle switches with chrome levers flipped up, white stencils under each row.
	var chrome := Kit.mat("#d8d8d8", 0.2, 1.0)
	for row in 2:
		for k in 6:
			var p := Vector3(-0.42 + 0.1 * k, 0.034, -0.13 + 0.1 * row)
			Kit.cyl(face, 0.014, 0.014, 0.012, p + Vector3(0, 0.006, 0), chrome, 10)
			Kit.rod(face, p + Vector3(0, 0.01, 0), p + Vector3(0, 0.05, -0.018), 0.004, chrome, 6)
	Kit.text(face, "CIRCUIT  1   2   3   4   5   6", 0.018, "#e8e4d8", Vector3(-0.17, 0.036, 0.02), Vector3(-PI / 2, 0, 0), false)
	# The lamps: ARM (amber) row; they flip to red FIRE when the key turns.
	_amber = Kit.lit("#ffaa22", 4.0)
	_red = Kit.lit("#ff2a12", 6.0)
	_dark = Kit.mat("#3a1a10", 0.3)
	for k in 4:
		var lp := Vector3(-0.42 + 0.12 * k, 0.04, 0.12)
		Kit.cyl(face, 0.024, 0.026, 0.01, lp, chrome, 12)
		_lamps.append(Kit.ball(face, 0.02, lp + Vector3(0, 0.008, 0), _amber, 12, Vector3(1, 0.55, 1)))
	Kit.text(face, "ARM", 0.022, "#e8e4d8", Vector3(-0.24, 0.036, 0.17), Vector3(-PI / 2, 0, 0), false)
	# The key lock: a chrome bezel, the key in it (a flat bow and a stem), FIRE stencilled above.
	var kf := KEY_AT - PANEL_AT - Vector3(0, 0.1, 0)
	Kit.cyl(face, 0.04, 0.045, 0.014, kf + Vector3(0, 0.035, 0), chrome, 20)
	Kit.cyl(face, 0.026, 0.026, 0.006, kf + Vector3(0, 0.045, 0), Kit.mat("#202020", 0.4, 0.5), 16)
	_key = Node3D.new()
	_key.position = kf + Vector3(0, 0.048, 0)
	face.add_child(_key)
	var brass := Kit.mat("#c9a24a", 0.3, 1.0)
	Kit.box(_key, Vector3(0.008, 0.03, 0.012), Vector3(0, 0.015, 0), brass)
	Kit.cyl(_key, 0.028, 0.028, 0.008, Vector3(0, 0.055, 0), brass, 20, Vector3(PI / 2, 0, 0))
	Kit.cyl(_key, 0.009, 0.009, 0.01, Vector3(0, 0.062, 0), Kit.mat("#202020", 0.5), 10, Vector3(PI / 2, 0, 0))
	# A red tag on a ring through the bow.
	Kit.box(_key, Vector3(0.03, 0.045, 0.003), Vector3(0.012, 0.1, 0.006), Kit.mat("#c01810", 0.6), Vector3(0, 0, 0.25))
	Kit.text(face, "FIRE", 0.026, "#ff5a40", kf + Vector3(0, 0.037, 0.08), Vector3(-PI / 2, 0, 0), false)


func _calendar(root: Node3D) -> void:
	var cal := Node3D.new()
	cal.position = CAL_AT
	root.add_child(cal)
	var cd: Dictionary = _p.get("calendar", {})
	var month := String(cd.get("month", "MAY"))
	Kit.box(cal, Vector3(0.3, 0.38, 0.012), Vector3(0, 0, 0.006), Kit.mat("#7a5a3a", 0.7))
	Kit.box(cal, Vector3(0.26, 0.08, 0.004), Vector3(0, 0.13, 0.014), Kit.mat("#b0201a", 0.6))
	Kit.text(cal, month + " 1998", 0.045, "#ffffff", Vector3(0, 0.13, 0.017), Vector3.ZERO, true)
	# The pad under: the new date.
	Kit.box(cal, Vector3(0.26, 0.24, 0.006), Vector3(0, -0.04, 0.015), Kit.mat("#f2eee2", 0.9))
	Kit.text(cal, String(cd.get("to", "11")), 0.17, "#1a1a1a", Vector3(0, -0.035, 0.019), Vector3.ZERO, true)
	# The top page: the old date (torn off at `tear`).
	_page = Node3D.new()
	_page.position = Vector3(0, -0.04, 0.022)
	cal.add_child(_page)
	Kit.box(_page, Vector3(0.26, 0.24, 0.002), Vector3.ZERO, Kit.mat("#f4f0e4", 0.9))
	Kit.text(_page, String(cd.get("from", "10")), 0.17, "#1a1a1a", Vector3(0, 0.005, 0.002), Vector3.ZERO, true)


static func _minutes(s: String) -> float:
	var parts := s.split(":")
	return float(int(parts[0]) * 60 + int(parts[1]))


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	_outside_mat.set_shader_parameter("t", t)
	# The clock: between keys the minutes sweep (eased); each landing overshoots a hair and settles.
	var keys: Array = _p.get("clock", [[0.0, "09:00"]])
	var m := _minutes(String(keys[0][1]))
	for i in range(1, keys.size()):
		var a: Array = keys[i - 1]
		var b: Array = keys[i]
		if t >= float(a[0]):
			var u := Motion.seg(t, float(a[0]), float(b[0]))
			var dm := _minutes(String(b[1])) - _minutes(String(a[1]))
			var short := absf(dm) <= 2.0
			# One minute or two: a mechanical jump at the end (out_back); longer: a time-lapse whirl.
			var e := Motion.out_back(clampf((u - 0.75) / 0.25, 0.0, 1.0), 2.4) if short else Motion.in_out(u)
			m = _minutes(String(a[1])) + dm * e
	var min_a := fmod(m, 60.0) / 60.0 * 360.0
	var hour_a := fmod(m / 60.0, 12.0) / 12.0 * 360.0
	_min_hand.rotation.z = -deg_to_rad(min_a - A0_MIN)
	_hour_hand.rotation.z = -deg_to_rad(hour_a - A0_HOUR)
	_sec_hand.rotation.z = -deg_to_rad(floor(t * 1.0) * 6.0 + 6.0 * Motion.out_back(clampf(fmod(t, 1.0) / 0.15, 0.0, 1.0), 2.0) - A0_SEC)
	# A jolt of the whole clock when the minute hand lands on a key that the shot calls out (the last key).
	var last: Array = keys[keys.size() - 1]
	var jolt := 0.0
	if keys.size() > 1 and t >= float(last[0]):
		var k := t - float(last[0])
		jolt = 0.05 * exp(-k * 9.0) * sin(k * 60.0)
	_clock.rotation.z = jolt
	_clock.scale = Vector3.ONE * CLOCK_SCALE * (1.0 + 0.6 * absf(jolt))
	# The calendar page.
	var cd: Dictionary = _p.get("calendar", {})
	if not cd.is_empty():
		var tear := float(cd.get("tear", 1e9))
		var hand = ctx["actor"].call(String(cd.get("hand", ""))) if ctx.has("actor") and cd.has("hand") else null
		var page_home := gt * (CAL_AT + Vector3(0, -0.04, 0.024))
		if hand != null and hand.visible:
			Crawl.long_arms(hand, 1.75)
			# Reach for the page before the tear, rip it down and away on the tear, the arm falls back.
			var reach := Motion.in_out(Motion.seg(t, tear - 0.7, tear - 0.18))
			var rip := Motion.out_cubic(Motion.seg(t, tear - 0.05, tear + 0.25))
			var drop := Motion.in_out(Motion.seg(t, tear + 0.3, tear + 0.9))
			var grab := page_home + gt.basis * Vector3(0.0, 0.08, 0.04)
			var pulled := grab + gt.basis * Vector3(0.28, -0.42, 0.3)
			var target: Vector3 = grab.lerp(pulled, rip)
			if reach > 0.0 and drop < 1.0:
				hand.aim_hand("r", target, reach * (1.0 - drop))
		if t < tear:
			_page.position = Vector3(0, -0.04, 0.022)
			_page.rotation = Vector3.ZERO
			_page.visible = true
		else:
			# Torn off: it goes with the hand for a moment, then flutters down to the floor, rocking.
			var k := t - tear
			_page.visible = k < 2.2
			var fall := Vector3(0.28 * minf(k / 0.25, 1.0) + 0.12 * maxf(k - 0.25, 0.0),
				-0.42 * minf(k / 0.25, 1.0) - 0.9 * maxf(k - 0.25, 0.0) * minf(1.0, (k - 0.25) * 1.2),
				0.3 * minf(k / 0.25, 1.0) + 0.1 * sin(k * 7.0))
			fall.y = maxf(fall.y, -(CAL_AT.y - 0.05))
			_page.position = Vector3(0, -0.04, 0.022) + fall
			_page.rotation = Vector3(0.6 * sin(k * 6.0) - 0.3, 0.4 * sin(k * 4.0), 0.5 * sin(k * 5.0 + 1.0) - 0.4 * minf(k * 3.0, 1.0))
	# The key: the hand on it; a quarter turn with a hard overshoot at `turn`; the lamps flip red.
	var kd: Dictionary = _p.get("key", {})
	var turn := float(kd.get("turn", 1e9))
	var ku := Motion.out_back(Motion.seg(t, turn - 0.04, turn + 0.14), 2.2)
	_key.rotation.y = -PI / 2.0 * ku
	for l in _lamps:
		(l as MeshInstance3D).material_override = _red if t >= turn else _amber
	_red_glow.light_energy = 0.0 if t < turn else 1.6 * (1.0 + 0.6 * exp(-(t - turn) * 6.0))
	if ctx.has("actor") and kd.has("hand"):
		var op = ctx["actor"].call(String(kd["hand"]))
		if op != null and op.visible:
			Crawl.long_arms(op, 1.3)
			var kw: Vector3 = _key.global_transform * Vector3(0.0, 0.05, 0.03)
			op.aim_hand("r", kw + Vector3(0.0, 0.0, 0.03 * (1.0 - ku)), 1.0)
	# Stools under the sitters.
	if ctx.has("actor"):
		var inv := gt.affine_inverse()
		for aid in _stools:
			var a = ctx["actor"].call(aid)
			var st: Node3D = _stools[aid]
			st.visible = a != null and a.visible
			if not st.visible:
				continue
			var hip: Vector3 = inv * ((a.bone_world("thigh_l") + a.bone_world("thigh_r")) * 0.5)
			var ay := float(a.rotation.y) - gt.basis.get_euler().y
			var fwd := Vector3(sin(ay), 0, cos(ay))
			var seat := hip - fwd * 0.06
			st.position = Vector3(seat.x, 0, seat.z)
			st.scale = Vector3(1, maxf(seat.y - 0.06, 0.2) / 0.442, 1)
			st.rotation.y = ay
	return {"clock": gt * (CLOCK_AT + Vector3(0, 0, 0.05)), "calendar": gt * (CAL_AT + Vector3(0, 0, 0.03)),
		"key": _key.global_transform * Vector3(0, 0.04, 0), "panel": gt * (PANEL_AT + Vector3(0, 0.1, 0)), "slit": gt * Vector3(0, 1.47, -WALL_Z)}
