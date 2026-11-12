## Motion: the house animation toolkit (docs/MOTION_SPEC.md). Pure functions of time only, so
## renders that seek frames in any order stay deterministic. Gag scripts preload it:
##     const Motion = preload("res://scripts/timeline/motion.gd")
##
## Distilled from three skills (disney-animation-rule-skill, game-feel, animation-principles):
## block every action as phases (anticipation -> action -> contact -> overshoot -> settle), ease
## everything that moves, squash/stretch only around force and contact (volume preserved),
## follow-through = sample the primary motion later in time, shake = trauma squared with summed sines.
extends RefCounted


# ---------------------------------------------------------------- easing (x in 0..1)

## Progress of t through [t0, t1], clamped to 0..1.
static func seg(t: float, t0: float, t1: float) -> float:
	return clampf((t - t0) / maxf(t1 - t0, 0.0001), 0.0, 1.0)


static func out_cubic(x: float) -> float:   # enter / settle (default "arrives with energy")
	return 1.0 - pow(1.0 - x, 3.0)


static func out_quint(x: float) -> float:   # snappy, decisive arrival
	return 1.0 - pow(1.0 - x, 5.0)


static func in_cubic(x: float) -> float:    # exit / accelerate away / wind-up
	return x * x * x


static func in_out(x: float) -> float:      # move on screen (cubic)
	return 4.0 * x * x * x if x < 0.5 else 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0


static func smooth(x: float) -> float:      # gentle in-out (camera-like)
	return x * x * (3.0 - 2.0 * x)


## Overshoots past 1 then settles (pops, "weight"). c = 1.7 is ~10 % overshoot; 2.5 is cartoony.
static func out_back(x: float, c: float = 1.7) -> float:
	var m := x - 1.0
	return 1.0 + (c + 1.0) * m * m * m + c * m * m


## Dips below 0 before going (anticipation baked into one curve).
static func in_back(x: float, c: float = 1.7) -> float:
	return (c + 1.0) * x * x * x - c * x * x


static func out_bounce(x: float) -> float:
	var n1 := 7.5625
	var d1 := 2.75
	if x < 1.0 / d1:
		return n1 * x * x
	elif x < 2.0 / d1:
		x -= 1.5 / d1
		return n1 * x * x + 0.75
	elif x < 2.5 / d1:
		x -= 2.25 / d1
		return n1 * x * x + 0.9375
	x -= 2.625 / d1
	return n1 * x * x + 0.984375


# ---------------------------------------------------------------- phases

## Block an action as named phases starting at t0: table = [["wind", 0.15], ["throw", 0.12], ...].
## -> {"name", "k" (0..1 inside the phase), "i" (index), "t" (seconds into the phase)}.
## Before t0: the first phase with k = 0; after the end: the last phase with k = 1.
static func phase(t: float, t0: float, table: Array) -> Dictionary:
	var start := t0
	for i in table.size():
		var d := float(table[i][1])
		if t < start + d or i == table.size() - 1:
			var k := clampf((t - start) / maxf(d, 0.0001), 0.0, 1.0)
			return {"name": String(table[i][0]), "k": k, "i": i, "t": maxf(t - start, 0.0)}
		start += d
	return {"name": "", "k": 1.0, "i": -1, "t": 0.0}


## Start time of a named phase (for events: launch, contact).
static func phase_start(t0: float, table: Array, name: String) -> float:
	var s := t0
	for row in table:
		if String(row[0]) == name:
			return s
		s += float(row[1])
	return s


# ---------------------------------------------------------------- weight

## Damped oscillation after an event, 1 -> 0 (springy settle, recoil, wobble). dt = t - event.
## freq in Hz, decay per second. 0 before the event.
static func wobble(dt: float, freq: float = 3.0, decay: float = 7.0) -> float:
	if dt < 0.0:
		return 0.0
	return exp(-decay * dt) * cos(TAU * freq * dt)


## Volume-preserving squash/stretch along local Y: a > 0 stretches, a < 0 squashes.
static func squash(a: float) -> Vector3:
	var y := maxf(1.0 + a, 0.2)
	var xz := 1.0 / sqrt(y)
	return Vector3(xz, y, xz)


## The squash after a contact at dt seconds: -strength at the hit, springs back with overshoot.
## Feed it to squash(). Scale strength by incoming speed (heavier hit = deeper squash, 0.15-0.45).
static func impact(dt: float, strength: float = 0.3, freq: float = 4.0, decay: float = 9.0) -> float:
	if dt < 0.0:
		return 0.0
	return -strength * wobble(dt, freq, decay)


## Stretch while moving fast (along the travel direction), clamped. speed in m/s, size in m.
static func speed_stretch(speed: float, size: float, most: float = 0.35) -> float:
	return clampf(speed / maxf(size, 0.05) * 0.03, 0.0, most)


## Anticipation: a counter-move that winds up over `wind` seconds before t_action and releases
## by t_action (returns 0 -> -1 -> 0). Multiply by an amount and apply opposite the action.
static func wind_up(t: float, t_action: float, wind: float = 0.18) -> float:
	var k := seg(t, t_action - wind, t_action)
	if k <= 0.0 or t >= t_action:
		return 0.0
	return -sin(k * PI * 0.5) if k < 0.85 else -sin(0.85 * PI * 0.5) * (1.0 - (k - 0.85) / 0.15)


# ---------------------------------------------------------------- paths

## A parabolic arc from a to b peaking `height` above the straight line (throws, hops).
static func arc(a: Vector3, b: Vector3, height: float, k: float) -> Vector3:
	return a.lerp(b, k) + Vector3.UP * height * 4.0 * k * (1.0 - k)


## Velocity of any pure function of time f(t) -> Vector3 (central difference). For stretch along
## travel, smear, follow-through and impact strength.
static func velocity(f: Callable, t: float, dt: float = 1.0 / 120.0) -> Vector3:
	return (f.call(t + dt) - f.call(t - dt)) / (2.0 * dt)


# ---------------------------------------------------------------- camera

## Trauma-based shake, pure in t. events = [{"t": s, "amount": 0..1}] (heavy hit 0.7-1.0,
## medium 0.3-0.5, light 0.1-0.2). Trauma decays linearly; shake = trauma^2 so light hits barely
## move and heavy ones punch. -> Vector3(x, y, roll) in -1..1 units (scale them by the rig).
static func shake(t: float, events: Array, decay: float = 1.6, seed: float = 0.0) -> Vector3:
	var trauma := 0.0
	for e in events:
		var dt := t - float(e["t"])
		if dt >= 0.0:
			trauma += maxf(float(e.get("amount", 0.5)) - decay * dt, 0.0)
	trauma = minf(trauma, 1.0)
	if trauma <= 0.0:
		return Vector3.ZERO
	var s := trauma * trauma
	var u := t * 30.0
	return Vector3(
		s * (0.6 * sin(u * 1.7 + seed) + 0.4 * sin(u * 3.1 + seed * 2.0)),
		s * (0.6 * sin(u * 2.3 + seed * 3.0) + 0.4 * sin(u * 4.3 + seed)),
		s * sin(u * 1.1 + seed * 5.0))
