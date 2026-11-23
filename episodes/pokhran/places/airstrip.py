"""In the air, dawn, 1998: the An-32 carrying the devices from Mumbai to Jaisalmer (gags/flight.gd, gag id "flight").

Frame: the aircraft's nose +X, up +Y; the fuselage axis at y 2.25, its right-hand side (portholes) at z +1.44. The hold
floor is at y 1.15; the device's cradle base at DEVICE (0.8, 1.15, 0). The desert is 380 m below.

an32_land ends tight on the strapped device; convoy (places/range.py) must open on exactly the same device-relative
framing (DEVICE_END_CAM / DEVICE_END_LOOK below) inside the truck, then pull back out to the convoy.
"""
from .common import W, frame, cam
from . import range as range_place

AIR_Z = 24000.0
P = frame("airstrip", AIR_Z)

DEVICE = (0.8, 1.15, 0.0)
# The closing frame on the device, relative to its cradle base (x along the device, +z the side we came in from).
DEVICE_END_CAM = (1.95, 1.05, 1.0)
DEVICE_END_LOOK = (-0.15, 0.55, 0.0)
DEVICE_END_LENS = 24


def DV(rel):
    """A point relative to the device's cradle base, in this place."""
    return P(DEVICE[0] + rel[0], DEVICE[1] + rel[1], DEVICE[2] + rel[2])


# Dawn at altitude: the sun just up behind the aircraft (backlight, a hot rim on the fuselage), a pale gold sky,
# the desert below in blue-gold haze.
LOOK_FLIGHT = dict(range_place.LOOK_DAWN,
                   sun={"elevation": 7, "azimuth": 212, "color": "#ffc27e", "energy": 2.8, "softness": 0.6,
                        "visible": True, "size": 1.4, "glow": 2.6, "glow_color": "#ffb060", "shadows": True},
                   sky={"top": "#6a8cc0", "horizon": "#f6cf9e", "clouds": 0.0},
                   ambient={"color": "#8e96aa", "energy": 0.3, "sky": 0.7},
                   fog={"begin": 300, "end": 9000, "curve": 1.3, "volumetric": 0.0},
                   glow={"enabled": True, "intensity": 0.75, "bloom": 0.06, "threshold": 1.0},
                   grade={"contrast": 1.16, "saturation": 1.02, "vignette": 0.45, "grain": 0.035})

GAGS = [{"id": "flight", "script": "gags/flight.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"speed": 75.0, "altitude": 380.0}}]

# The camera's way in: from a wide front-quarter view it pushes straight through a porthole on the right-hand side
# (at x 3.7, y 2.45) and comes to rest close on the device. The start, the porthole and the end are in line.
_PORT = (3.7, 2.45, 1.46)        # a forward porthole: the way in starts ahead of the nose, front three-quarter
_END = (DEVICE[0] + DEVICE_END_CAM[0], DEVICE[1] + DEVICE_END_CAM[1], DEVICE[2] + DEVICE_END_CAM[2])
_K = 16.0
_START = tuple(_PORT[i] + (_PORT[i] - _END[i]) * _K for i in range(3))

SHOTS = {
    # Dawn, high over the Thar: the An-32 wide and backlit, propellers turning; from "flown" the camera pushes in
    # through a porthole into the hold and settles tight on the device strapped to its cradle, under its work light.
    "an32_land": {"look": LOOK_FLIGHT, "camera": {
        "from": cam(P(*_START), P(1.0, 2.4, 0.0), 30, {"strength": 0.05}),
        "to": cam(P(*_END), DV(DEVICE_END_LOOK), DEVICE_END_LENS, {"strength": 0.12}),
        "ease": "in", "start": W("l10a", offset=-0.2), "end": W("l10a", "plane,", 0.15)}},
}

PLACE = {"gags": GAGS, "actors": [], "shots": SHOTS}
