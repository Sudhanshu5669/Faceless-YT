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
