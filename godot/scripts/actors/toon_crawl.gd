## Procedural crawling for toon actors (there is no crawl clip in the animation library).
## Gag scripts call it after the actor's own pose_at():
##     const Crawl = preload("res://scripts/actors/toon_crawl.gd")
##     var info := Crawl.pose(actor, chest_point, forward, up, distance, {...})
##
## A pure function of the distance crawled: hands and knees are planted on the ground and the body is
## pulled past them (they never slide), the shoulders roll toward the reaching hand, the spine snakes,
## the head stays up looking ahead and nods with each pull. `Crawl.surge()` turns steady speed into the
## pull-and-rest rhythm of a real crawl.
##
## Options (all optional):
##   stride     metres per full cycle (both hands)                 default 0.5 * body length scale
##   tilt       how far the chest is raised, radians (0 = flat on the belly, 0.45 = hands and knees)
##   floor_y    world height of the ground under the hands / knees
##   pipe_r     > 0: the ground is the inside of a pipe of this radius (floor_y = its lowest line)
##   spread     sideways distance of the hands from the centre line
##   reach      how far ahead of the shoulders a hand is planted
##   look       Vector2(yaw, pitch) radians: where the head looks relative to straight ahead
##   weight     0..1 blend of the limb IK (for easing in and out of the crawl)
##   arms       false: leave the arms alone (the caller poses them: tools, a rope)
##   roll, sway multipliers of the body's rocking (1 = default)
##   arm_scale  > 1 lengthens both arms (a toon's arms are too short to work in front of its own head)
## Returns {"head": world centre of the head, "face": unit vector the face points along, "left": unit vector to
## the actor's left, "hand_l", "hand_r": world hand targets, "basis": the body basis}.
extends RefCounted

const Cast = preload("res://scripts/actors/cast.gd")

const CHEST := 0.5       # the chest point as a fraction of the height, from the feet


## Distance crawled at time t for an average speed: two surges per stride (one per hand pull), never backwards.
static func surge(t: float, speed: float, stride: float, depth: float = 0.55) -> float:
	var d := speed * t
	return d + stride / (4.0 * PI) * depth * sin(4.0 * PI * d / maxf(stride, 0.01))


## Where a planted limb is relative to its root joint, along the direction of travel, at cycle fraction f:
## planted (world-fixed) for the first `stance` of the cycle, then swung forward. -> Vector2(along, lift 0..1).
static func _step(f: float, stride: float, ahead: float, stance: float) -> Vector2:
	if f < stance:
		return Vector2(ahead - f * stride, 0.0)
	var s := (f - stance) / (1.0 - stance)
	var e := s * s * (3.0 - 2.0 * s)
	var from := ahead - stance * stride
	# During the swing the body keeps moving, so the hand travels the whole stride in world space.
	return Vector2(lerpf(from, ahead, e), sin(s * PI))


static func _sk(a) -> Skeleton3D:
	return a.retarget.dst if a.retarget != null else a.skeleton


## Two-bone IK on one arm ("l" / "r") to a world target, the elbow toward a world direction.
static func arm(a, side: String, target: Vector3, pole: Vector3, weight: float = 1.0) -> void:
	if weight <= 0.0:
		return
	var sk := _sk(a)
	var inv: Transform3D = a._world_of(sk).affine_inverse()
	a._ik_limb(sk, "upperarm_" + side, "lowerarm_" + side, "hand_" + side, inv * target, inv.basis * pole, weight)


static func leg(a, side: String, target: Vector3, pole: Vector3, weight: float = 1.0) -> void:
	if weight <= 0.0:
		return
	var sk := _sk(a)
	var inv: Transform3D = a._world_of(sk).affine_inverse()
	a._ik_limb(sk, "thigh_" + side, "calf_" + side, "foot_" + side, inv * target, inv.basis * pole, weight)


## Scale both arms from the shoulder (sticks and hands grow with them). Call every frame: poses are rebuilt each frame.
static func long_arms(a, k: float) -> void:
	var sk := _sk(a)
	for s in ["l", "r"]:
		var i := sk.find_bone("upperarm_" + s)
		if i >= 0:
			sk.set_bone_pose_scale(i, Vector3.ONE * k)


## The body basis of a toon lying face down along `fwd`, chest raised by `tilt`, rolled and yawed a little.
static func basis_for(fwd: Vector3, up: Vector3, tilt: float, roll: float = 0.0, yaw: float = 0.0) -> Basis:
	var f := fwd.normalized()
	var u := (up - f * up.dot(f)).normalized()
	f = f.rotated(u, yaw)
	var y := f * cos(tilt) + u * sin(tilt)          # feet -> head
	var z := -u * cos(tilt) + f * sin(tilt)         # the chest's front: down at the ground
	var x := y.cross(z).normalized()
	return Basis(x, y, z).rotated(y, roll)


static func pose(a, chest: Vector3, fwd: Vector3, up: Vector3, d: float, o: Dictionary = {}) -> Dictionary:
	var h: float = a._height_scale * Cast.BASE_HEIGHT
	var stride := float(o.get("stride", 0.5 * h))
	var tilt := float(o.get("tilt", 0.12))
	var w := clampf(float(o.get("weight", 1.0)), 0.0, 1.0)
	var u := d / maxf(stride, 0.01)                 # cycles
	var ph := u * TAU
	var k_roll := float(o.get("roll", 1.0))
	var k_sway := float(o.get("sway", 1.0))
	# The body: rolls onto the planted (pulling) side, snakes, lifts a touch at each pull.
	var roll := 0.14 * k_roll * sin(ph)
	var yaw := 0.07 * k_sway * sin(ph + PI * 0.5)
	var f := fwd.normalized()
	var upn := (up - f * up.dot(f)).normalized()
	var side := upn.cross(f).normalized()          # the actor's left
	var b := basis_for(f, upn, tilt + 0.02 * absf(sin(ph)), roll * w, yaw * w)
	var bob := upn * 0.012 * h * absf(sin(ph)) + side * 0.02 * h * k_sway * sin(ph) * w
	a.global_transform = Transform3D(b, chest + bob - b.y * CHEST * h)
	long_arms(a, float(o.get("arm_scale", 1.0)))
	# The head: up and ahead whatever the body does, a small nod into every pull, lagging the shoulders.
	var look: Vector2 = o.get("look", Vector2.ZERO)
	var nod := 0.06 * sin(2.0 * ph - 0.6)
	var pitch := -(PI * 0.5 - tilt) * float(o.get("head_up", 0.9)) + nod * w - look.y
	a._pose_head(Vector3(pitch, look.x - yaw * w * 0.8, -roll * w * 0.7))
	var hb := b * Basis.from_euler(Vector3(pitch, look.x - yaw * w * 0.8, -roll * w * 0.7))
	var head: Vector3 = a.bone_world("Head") + hb.y * a._head_lift
	var res := {"head": head, "face": hb.z, "head_up": hb.y, "left": side, "basis": b, "fwd": f, "up": upn}
	var floor_y := float(o.get("floor_y", chest.y - 0.14 * h))
	var pipe_r := float(o.get("pipe_r", 0.0))
	var spread := float(o.get("spread", 0.1 * h))
	var reach := float(o.get("reach", 0.2 * h))
	var stance := 0.62
	for s in ["l", "r"]:
		var sg := 1.0 if s == "l" else -1.0
		# Diagonal gait: the right hand and the left knee go together.
		var fa := fposmod(u + (0.0 if s == "l" else 0.5), 1.0)
		var st := _step(fa, stride, reach, stance)
		var sh: Vector3 = a.bone_world("upperarm_" + s)
		var lat := spread * sg
		var along := (sh - chest).dot(f) + st.x
		var gy := floor_y
		if pipe_r > 0.0:
			gy += pipe_r - sqrt(maxf(pipe_r * pipe_r - lat * lat, 0.0))
		var hand := chest + f * along + side * lat
		hand += upn * (gy - hand.dot(upn) + 0.035 * h + st.y * 0.07 * h)
		res["hand_" + s] = hand
		if bool(o.get("arms", true)):
			arm(a, s, hand, side * sg * 1.0 + upn * 0.9 - f * 0.3, w)
		# Knees: planted under the hips, the shins trailing; the foot drags and flicks up as the knee comes forward.
		var fl := fposmod(u + (0.5 if s == "l" else 0.0), 1.0)
		var sl := _step(fl, stride, 0.02 * h, stance)
		var hip: Vector3 = a.bone_world("thigh_" + s)
		var leg_lat := float(o.get("leg_spread", 0.07 * h)) * sg
		var back := float(o.get("leg_back", 0.2 * h))
		var foot := hip + f * (sl.x - back) + side * (leg_lat - (hip - chest).dot(side))
		var fy := floor_y
		if pipe_r > 0.0:
			fy += pipe_r - sqrt(maxf(pipe_r * pipe_r - leg_lat * leg_lat, 0.0))
		foot += upn * (fy - foot.dot(upn) + 0.03 * h + sl.y * 0.05 * h)
		res["foot_" + s] = foot
		if bool(o.get("legs", true)):
			leg(a, s, foot, side * sg * 0.9 - upn * 0.6 + f * 0.5, w)
	return res
