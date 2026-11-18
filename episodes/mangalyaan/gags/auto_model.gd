extends RefCounted
## The Ahmedabad auto-rickshaw, shared by the lane and space gags (compiled at runtime, see mom_script()).
## build() returns the auto (nose toward -z, origin on the ground under its middle). Named parts:
## meter (digits: Label3D, flag), wheel_f, wheel_r0, wheel_r1. set_fare(auto, value or -1) shows the fare.

const Kit = preload("res://scripts/world/gag_kit.gd")


static func set_fare(auto: Node3D, fare: float) -> void:
	var d := auto.get_node("meter/digits") as Label3D
	d.text = "%.2f" % fare if fare >= 0.0 else "- - -"
	(auto.get_node("meter/flag") as Node3D).rotation = Vector3(0, 0, -1.4 if fare >= 0.0 else 0.0)


static func roll(auto: Node3D, dist: float) -> void:
	for n in ["wheel_f", "wheel_r0", "wheel_r1"]:
		(auto.get_node(n) as Node3D).rotation = Vector3(dist / 0.2, 0, 0)


## The auto-rickshaw: a single front wheel under a rounded nose, a windshield, a black body with a
## yellow canvas canopy on a frame, a bench seat at the back, two rear wheels, the meter on the left.
func build() -> Node3D:
	var a := Node3D.new()
	var black := Kit.mat("#141414", 0.32, 0.0, 0.75)
	var yellow := Kit.mat("#e3b41c", 0.55)
	var chrome := Kit.mat("#c9ccd0", 0.15, 0.0, 0.95)
	var tyre := Kit.mat("#121212", 0.85)
	# Body: floor pan and side tub (y 0.3..0.85), nose at -z.
	Kit.slab(a, Vector3(1.3, 0.12, 1.9), 0.15, Vector3(0, 0.32, 0.35), black)
	Kit.slab(a, Vector3(1.32, 0.42, 0.95), 0.25, Vector3(0, 0.58, 0.85), black)
	for s in [-1.0, 1.0]:
		Kit.box(a, Vector3(0.04, 0.38, 0.9), Vector3(s * 0.64, 0.62, 0.0), black)
	# Nose (rounded front fascia), headlight, indicators, the front mudguard and wheel.
	Kit.slab(a, Vector3(0.8, 0.7, 0.45), 0.2, Vector3(0, 0.7, -0.75), black)
	Kit.ball(a, 0.42, Vector3(0, 0.95, -0.8), black, 20, Vector3(1.0, 0.85, 0.6))
	var hl := Kit.cyl(a, 0.1, 0.1, 0.06, Vector3(0, 0.82, -1.0), Kit.lit("#fff3d6", 2.5), 18, Vector3(PI / 2, 0, 0))
	Kit.cyl(a, 0.115, 0.115, 0.05, Vector3(0, 0.82, -0.99), chrome, 18, Vector3(PI / 2, 0, 0))
	Kit.spot(a, Vector3(0, 0.82, -1.05), Vector3(0, 0.0, -7.0), "#fff1d0", 2.5, 12.0, 30.0, true, 0.8)
	for s in [-1.0, 1.0]:
		Kit.ball(a, 0.035, Vector3(s * 0.3, 0.98, -0.98), Kit.lit("#ffa21a", 1.2), 8)
	Kit.ball(a, 0.23, Vector3(0, 0.3, -0.98), black, 16, Vector3(0.5, 0.6, 1.0))
	var fw := Node3D.new()
	fw.position = Vector3(0, 0.2, -0.98)
	a.add_child(fw)
	Kit.cyl(fw, 0.2, 0.2, 0.1, Vector3.ZERO, tyre, 20, Vector3(0, 0, PI / 2))
	Kit.cyl(fw, 0.1, 0.1, 0.11, Vector3.ZERO, chrome, 12, Vector3(0, 0, PI / 2))
	fw.name = "wheel_f"
	for s in [-1.0, 1.0]:
		var rw := Node3D.new()
		rw.position = Vector3(s * 0.58, 0.2, 0.95)
		a.add_child(rw)
		Kit.cyl(rw, 0.2, 0.2, 0.12, Vector3.ZERO, tyre, 20, Vector3(0, 0, PI / 2))
		Kit.cyl(rw, 0.1, 0.1, 0.13, Vector3.ZERO, chrome, 12, Vector3(0, 0, PI / 2))
		rw.name = "wheel_r%d" % (0 if s < 0.0 else 1)
	# Windshield with a black frame, a wiper; handlebar; the driver's seat.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.7, 0.8, 0.85, 0.18)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic_specular = 1.0
	Kit.box(a, Vector3(1.0, 0.6, 0.02), Vector3(0, 1.42, -0.62), glass, Vector3(0.18, 0, 0))
	Kit.box(a, Vector3(1.06, 0.05, 0.05), Vector3(0, 1.72, -0.57), black)
	Kit.box(a, Vector3(1.06, 0.05, 0.05), Vector3(0, 1.12, -0.68), black)
	Kit.rod(a, Vector3(-0.2, 1.15, -0.66), Vector3(0.1, 1.55, -0.6), 0.008, black, 4)
	Kit.rod(a, Vector3(-0.32, 1.12, -0.42), Vector3(0.32, 1.12, -0.42), 0.018, chrome, 8)
	Kit.rod(a, Vector3(0, 1.0, -0.58), Vector3(0, 1.12, -0.42), 0.025, black, 8)
	Kit.slab(a, Vector3(0.5, 0.1, 0.42), 0.08, Vector3(0, 0.82, -0.05), Kit.mat("#2a1c14", 0.6))
	# Passenger bench (red rexine) and backrest.
	Kit.slab(a, Vector3(1.15, 0.14, 0.45), 0.08, Vector3(0, 0.9, 0.78), Kit.mat("#7a1e1c", 0.45))
	Kit.slab(a, Vector3(1.15, 0.5, 0.1), 0.06, Vector3(0, 1.2, 1.02), Kit.mat("#7a1e1c", 0.45))
	# Canopy: steel frame, yellow canvas roof with a black band, open sides.
	var frame := Kit.mat("#1a1a1a", 0.4, 0.0, 0.6)
	for s in [-1.0, 1.0]:
		Kit.rod(a, Vector3(s * 0.62, 0.85, -0.5), Vector3(s * 0.6, 1.95, -0.45), 0.02, frame, 6)
		Kit.rod(a, Vector3(s * 0.62, 0.85, 1.1), Vector3(s * 0.62, 1.95, 1.05), 0.02, frame, 6)
	Kit.slab(a, Vector3(1.36, 0.1, 1.85), 0.3, Vector3(0, 2.0, 0.3), yellow)
	Kit.box(a, Vector3(1.38, 0.08, 1.87), Vector3(0, 1.92, 0.3), black)
	Kit.box(a, Vector3(1.3, 1.05, 0.02), Vector3(0, 1.45, 1.22), yellow)
	Kit.box(a, Vector3(0.6, 0.18, 0.025), Vector3(0, 1.65, 1.235), Kit.mat("#1a1a1a", 0.6))
	# Number plate (Gujarat), a small tassel of lemons and chillies hanging under the nose.
	var plate := Node3D.new()
	plate.position = Vector3(0, 0.5, -0.99)
	plate.rotation = Vector3(0, PI, 0)
	a.add_child(plate)
	Kit.box(plate, Vector3(0.36, 0.12, 0.01), Vector3.ZERO, Kit.mat("#f1eee4", 0.5))
	Kit.text(plate, "GJ 01 TX 4721", 0.05, Color("161616"), Vector3(0, 0, -0.008), Vector3(0, PI, 0))
	Kit.rod(a, Vector3(0, 0.42, -1.0), Vector3(0, 0.25, -1.02), 0.004, Kit.mat("#2a2a2a", 0.6), 4)
	Kit.ball(a, 0.025, Vector3(0, 0.25, -1.02), Kit.mat("#e2d443", 0.5), 8, Vector3(1, 1.3, 1))
	for k in 3:
		Kit.cyl(a, 0.006, 0.0, 0.07, Vector3(-0.015 + 0.015 * k, 0.19, -1.02), Kit.mat("#2e7d2e", 0.5), 6)
	# The fare meter: a black box on a bracket left of the handlebar, red LED digits, a flag lever.
	var meter := Node3D.new()
	meter.name = "meter"
	meter.position = Vector3(-0.38, 1.24, -0.5)
	meter.rotation = Vector3(-0.35, 0.25, 0)
	a.add_child(meter)
	Kit.rod(a, Vector3(-0.38, 1.0, -0.56), Vector3(-0.38, 1.17, -0.52), 0.015, black, 6)
	Kit.slab(meter, Vector3(0.24, 0.13, 0.1), 0.02, Vector3.ZERO, Kit.mat("#17181b", 0.35, 0.0, 0.7))
	Kit.box(meter, Vector3(0.19, 0.06, 0.01), Vector3(0, 0.02, 0.05), Kit.mat("#2a0606", 0.1, 0.0, 0.9))
	var mt := Kit.text(meter, "0.00", 0.045, Color(1.0, 0.16, 0.1), Vector3(0, 0.02, 0.057), Vector3.ZERO, true, 4.0)
	mt.name = "digits"
	Kit.text(meter, "FARE  ₹", 0.014, Color("b9b9b9"), Vector3(0, -0.035, 0.056), Vector3.ZERO, false)
	var flag := Node3D.new()
	flag.name = "flag"
	flag.position = Vector3(0.13, 0.05, 0)
	meter.add_child(flag)
	Kit.box(flag, Vector3(0.012, 0.1, 0.012), Vector3(0, 0.05, 0), chrome)
	Kit.box(flag, Vector3(0.05, 0.03, 0.01), Vector3(0.02, 0.1, 0), Kit.mat("#c4282b", 0.5))
	Kit.omni(meter, Vector3(0, 0.03, 0.15), "#ff3a22", 0.06, 0.6, false, 0.1)
	Kit.omni(a, Vector3(0, 1.75, 0.2), "#ffd9a0", 0.35, 2.2, false, 0.2)
	return a


