"""Build the 9:16 cover from the caption-free Godot shot renders.

Run after tf render bombay_gold. Requires FFmpeg and Pillow.
"""

from io import BytesIO
from pathlib import Path
import subprocess

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


HERE = Path(__file__).resolve().parent
SHOTS = HERE.parent / "renders" / "shots"
TITLE_FONT = HERE.parents[2] / "godot" / "fonts" / "lilita_one" / "LilitaOne-Regular.ttf"


def frame(shot, seconds):
    png = subprocess.check_output(
        [
            "ffmpeg", "-v", "error", "-ss", str(seconds), "-i", str(SHOTS / f"{shot}.mp4"),
            "-frames:v", "1", "-c:v", "png", "-f", "image2pipe", "-",
        ]
    )
    return Image.open(BytesIO(png)).convert("RGB")


def falling_bar():
    # Trace the outline of the nearest ingot in the opening shot.
    crop = frame("00_hook_rain", 0.741).crop((580, 350, 715, 460))
    crop = ImageEnhance.Contrast(crop).enhance(1.18).convert("RGBA")
    mask = Image.new("L", (crop.width * 4, crop.height * 4))
    ImageDraw.Draw(mask).polygon(
        [(59, 92), (444, 74), (454, 246), (427, 374), (57, 392), (48, 255)],
        fill=255,
    )
    crop = crop.resize(mask.size, Image.Resampling.BICUBIC)
    crop.putalpha(mask)
    return crop.resize((302, 246), Image.Resampling.LANCZOS)


def main():
    cover = frame("35_gold_rain", 0.275)
    cover = ImageEnhance.Brightness(cover).enhance(1.1)
    bar = falling_bar().rotate(-13, Image.Resampling.BICUBIC, expand=True)
    cover.paste(bar, (385, 410), bar)

    lines = [
        ("IT RAINED", 206, 97, "#fff6e1"),
        ("GOLD", 329, 147, "#ffd66d"),
    ]
    shadow = Image.new("RGBA", cover.size)
    text_layer = Image.new("RGBA", cover.size)
    shadow_draw = ImageDraw.Draw(shadow)
    text_draw = ImageDraw.Draw(text_layer)
    for label, y, size, color in lines:
        font = ImageFont.truetype(TITLE_FONT, size)
        shadow_draw.text(
            (540, y + 9), label, font=font, anchor="mm", fill="#100b10", stroke_width=7
        )
        text_draw.text(
            (540, y), label, font=font, anchor="mm", fill=color,
            stroke_width=3, stroke_fill="#2f2021",
        )
    cover = Image.alpha_composite(cover.convert("RGBA"), shadow.filter(ImageFilter.GaussianBlur(12)))
    cover = Image.alpha_composite(cover, text_layer).convert("RGB")
    cover.save(HERE / "bombay_gold_shorts_cover.png", optimize=True)


if __name__ == "__main__":
    main()
