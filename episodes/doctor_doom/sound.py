"""The doctor_doom sound design: music cues (Scott Buckley, CC BY 4.0) and effects (Sonniss GDC 2026), every effect
anchored to its word. The WAVs live in audio/lib/ (git-ignored; built by make_audio.py from incoming/).
"""
from places.common import W

FX = "audio/lib/sfx/"
MU = "audio/lib/music/"


def fx(name, at, gain=-6.0, **kw):
    return {"file": f"{FX}{name}.wav", "at": at, "gain": gain, **kw}


def mu(name, at, until=None, offset=0.0, gain=-15.0, fade_in=1.0, fade_out=1.5, duck=0.55):
    m = {"file": f"{MU}{name}.wav", "at": at, "offset": offset, "gain": gain, "fade_in": fade_in, "fade_out": fade_out,
         "duck": duck}
    if until is not None:
        m["until"] = until
    return m


MUSIC = [
    mu("eyes_in_the_void", W("h1", 0, -0.3), W("c1a", 0, 0.3), fade_in=0.3),
    mu("anabasis", W("c1a", 0, -0.2), W("v0a", 0, 0.3), offset=20.0),
    mu("convergence", W("v0a", 0, -0.2), W("v0k", 0, 0.3)),
    mu("penumbra", W("v0k", 0, -0.2), W("v1", 0, 0.3), offset=10.0),
    mu("eyes_in_the_void", W("v1", 0, -0.2), W("v8", 0, 0.3), offset=95.0),
    mu("anabasis", W("v8", 0, -0.2), W("d1", 0, 0.3), offset=240.0),
    mu("aphelion", W("d1", 0, -0.2), W("r1", 0, 0.3), offset=150.0, gain=-14.0),
    mu("starfire", W("r1", 0, -0.2), W("e1", 0, 0.3), offset=30.0),
    mu("eyes_in_the_void", W("e1", 0, -0.2), None, offset=200.0, gain=-13.0, fade_out=3.0),
]

SFX = [
    # Cold open: Hall H.
    fx("crowd_cheer_b", W("h1", 0, -0.2), -20.0),
    fx("woosh_debris", W("h2", "walk", 0.0), -12.0),
    fx("boom_a", W("h3", "mask.", -0.05), -4.0),
    fx("crowd_cheer", W("h3", "mask.", 0.3), -7.0),
    fx("crowd_cheer_b", W("h4", 0, 0.5), -9.0),
    fx("braam_a", W("h4", "Robert", -0.3), -5.0),
    fx("braam_creepy", W("o3", "villain", -0.4), -6.0),
    fx("paper_turn", W("o6", "Comics.", 0.0), -3.0),
    fx("boom_b", W("o7", "apart.", 0.0), -9.0),
    # Chapter 1.
    fx("woosh_ui", W("c1a", 0, -0.1), -6.0),
    fx("crowd_cheer_b", W("c1b", 0, 0.0), -14.0),
    fx("impact_chord", W("c1c", "billion", 0.0), -6.0),
    fx("crowd_cheer", W("c1d", "biggest", -0.2), -8.0),
    fx("braam_b", W("c1f", "Kang", -0.2), -9.0),
    fx("wood_hit", W("c1e", "villain.", 0.0), -8.0),
    fx("wood_hit", W("c1g", "Loki", 0.0), -8.0),
    fx("wood_hit", W("c1h", "Quantumania", 0.0), -8.0),
    fx("crowd_cheer", W("c1j", 0, 0.0), -10.0),
    fx("snap", W("c1k", "crack.", 0.0), -8.0),
    fx("snap", W("k3", "drops", 0.0), -5.0),
    fx("boom_c", W("k4", "comes", 0.9), -4.0),
    fx("woosh_debris", W("k4", "comes", 0.3), -8.0),
    # Chapter 2: the comics, Latveria, the lab, Tibet, the castle.
    fx("woosh_ui", W("v0a", 0, -0.1), -6.0),
    fx("paper_rummage", W("v0b", "answer", 0.0), -8.0),
    fx("braam_a", W("v0d", "Doom.", -0.2), -6.0),
    fx("arc_powerup", W("v0f", 0, -0.2), -10.0),
    fx("impact_sweep", W("v0f", "machine,", 0.1), -5.0),
    fx("storm_night", W("v0g", 0, -0.3), -10.0),
    fx("paper_turn", W("v0j", "Avengers,", 0.0), -7.0),
    fx("paper_turn", W("v0j", "Spider-Man,", 0.0), -7.0),
    fx("paper_turn", W("v0j", "Iron", 0.0), -7.0),
    fx("paper_turn", W("v0j", "Daredevil.", 0.0), -7.0),
    fx("fire_crackle", W("v0k", 0, -0.2), -16.0),
    fx("wind_storm", W("v0o", 0, -0.3), -8.0),
    fx("latch_thunk", W("v0q", "secret:", 0.0), -5.0),
    fx("spell_drone", W("v0q", "secret:", 0.0), -12.0),
    fx("arc_buzz", W("v1", "builds", 0.0), -14.0),
    fx("arc_zap", W("v2", "flaw", 0.0), -12.0),
    fx("arc_powerup", W("v4", 0, -0.4), -8.0),
    fx("boom_a", W("v4", "explodes", 0.0), -2.0),
    fx("metal_hit", W("v9", "forges", 0.0), -6.0),
    fx("metal_hit", W("v9", "his", 0.0), -6.0),
    fx("metal_hit", W("v9", "armor.", 0.0), -4.0),
    fx("impact_chord", W("v10", "red-hot.", 0.1), -5.0),
    fx("metal_drag", W("v11", 0, -0.2), -8.0),
    fx("boom_b", W("v12", "Doom.", 0.0), -5.0),
    # Chapter 3.
    fx("woosh_ui", W("d1", 0, -0.1), -6.0),
    fx("metal_drag", W("d2", "immunity.", 0.7), -6.0),
    fx("boom_c", W("d2", "immunity.", 1.0), -8.0),
    fx("crowd_cheer_b", W("d2b", "cares", 0.0), -11.0),
    fx("arc_zap", W("d3", "sorcerer.", 0.0), -8.0),
    fx("snap", W("d5", "real", 0.0), -6.0),
    fx("arc_zap", W("d5", "real", 0.05), -8.0),
    fx("spell_drone", W("d6", 0, -0.2), -10.0),
    fx("boom_c", W("d6", "Devil", 0.0), -8.0),
    fx("wind_storm", W("d7", 0, -0.2), -14.0),
    fx("arc_buzz", W("d7", 0, 0.0), -12.0),
    fx("braam_a", W("d8", "god.", -0.3), -5.0),
    fx("boom_a", W("d11", "stitches", 0.0), -6.0),
    fx("braam_b", W("d12", "Emperor", -0.3), -6.0),
    fx("impact_chord", W("d15", "Overnight,", 0.0), -7.0),
    fx("metal_hit", W("d18", "armor,", 0.0), -8.0),
    # Chapter 4.
    fx("woosh_ui", W("r1", 0, -0.1), -6.0),
    fx("paper_rummage", W("r11", "deal", 0.0), -8.0),
    fx("shield_spin", W("r13", "bought", 0.1), -10.0),
    fx("crowd_cheer", W("r16", "Rogers,", 0.0), -10.0),
    fx("storm_night", W("r19", 0, -0.2), -12.0),
    fx("boom_b", W("r20", "world.", 0.0), -6.0),
    # Bookend.
    fx("braam_a", W("e2", "task.", 0.1), -3.0),
    fx("crowd_cheer", W("e2", "task.", 0.4), -6.0),
]


# 2D overlays (HyperFrames, rendered by make_overlays.py into overlays/out/), placed at their words.
OVERLAY_AT = {
    "ch1": W("c1a", 0, -0.2), "ch2": W("v0a", 0, -0.2), "ch3": W("d1", 0, -0.2), "ch4": W("r1", 0, -0.2),
    "news_arrest": W("c1m", 0, 0.3), "news_verdict": W("k2", 0, 0.6),
}
