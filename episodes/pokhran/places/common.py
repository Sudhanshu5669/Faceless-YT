"""Helpers shared by the place modules."""


def W(line, word=None, offset=0.0, edge=None):
    """A time reference: a word of a line (or the line's start/end)."""
    r = {"line": line}
    if word is not None:
        r["word"] = word
    if edge:
        r["edge"] = edge
    if offset:
        r["offset"] = round(offset, 3)
    return r


def frame(anchor, z_off):
    """Point builder for a gag placed at {"anchor": anchor, "offset": [0, 0, z_off]}: gag-local x, y, z
    (the gag faces the bay's forward, +Z; right = -x)."""
    def P(x, y, z):
        return {"anchor": anchor, "offset": [round(-x, 3), round(y, 3), round(z + z_off, 3)]}
    return P


def cam(at, look, lens, dof=None, **kw):
    c = {"at": at, "look_at": look, "lens_mm": lens}
    if dof:
        c["dof"] = dof
    c.update(kw)
    return c


def move(a, b, ease="in_out"):
    return {"from": a, "to": b, "ease": ease}


# The an32_land -> convoy match cut: the closing frame on the device, relative to its cradle base (x along the device and
# the vehicle's forward, +z the vehicle's right side), shared by places/airstrip.py and places/range.py.
DEVICE_END_CAM = (1.95, 1.05, 1.0)
DEVICE_END_LOOK = (-0.15, 0.55, 0.0)
DEVICE_END_LENS = 24
