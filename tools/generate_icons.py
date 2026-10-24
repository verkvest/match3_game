#!/usr/bin/env python3
"""Draw the Cindermote app icon and emit every iOS and Android size.

The mark is a night-sky candle with three match gems. It is drawn on a 64x64
grid and scaled with nearest-neighbor so the pixels stay crisp.
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "assets" / "icons" / "ios"
ANDROID = ROOT / "assets" / "icons" / "android"

NIGHT = (27, 36, 51, 255)
NIGHT_DEEP = (18, 24, 36, 255)
GLOW = (46, 58, 82, 255)
WAX = (246, 231, 193, 255)
WAX_DARK = (196, 165, 116, 255)
WICK = (58, 42, 34, 255)
FLAME_HOT = (255, 243, 196, 255)
FLAME = (255, 176, 46, 255)
FLAME_DEEP = (232, 98, 32, 255)
MOON = (244, 226, 176, 255)
PUMPKIN = (224, 122, 61, 255)
GHOST = (215, 226, 234, 255)
BAT = (122, 86, 176, 255)
WHITE = (255, 255, 255, 255)

IOS_SIZES = {
    "notification_40x40": 40,
    "notification_60x60": 60,
    "notification_76x76": 76,
    "notification_114x114": 114,
    "settings_58x58": 58,
    "settings_87x87": 87,
    "spotlight_80x80": 80,
    "spotlight_120x120": 120,
    "iphone_120x120": 120,
    "iphone_180x180": 180,
    "ipad_152x152": 152,
    "ipad_167x167": 167,
    "ios_128x128": 128,
    "ios_136x136": 136,
    "ios_192x192": 192,
    "app_store_1024x1024": 1024,
    "icon_1024x1024": 1024,
}

ANDROID_LAUNCHER = {
    "mdpi_48": 48,
    "hdpi_72": 72,
    "xhdpi_96": 96,
    "xxhdpi_144": 144,
    "xxxhdpi_192": 192,
    "play_store_512": 512,
}


def _blank(transparent: bool) -> Image.Image:
    color = (0, 0, 0, 0) if transparent else NIGHT
    return Image.new("RGBA", (64, 64), color)


def _draw_scene(transparent_bg: bool, monochrome: bool) -> Image.Image:
    img = _blank(transparent_bg)
    d = ImageDraw.Draw(img)
    wax = WHITE if monochrome else WAX
    wax_dark = WHITE if monochrome else WAX_DARK
    flame = WHITE if monochrome else FLAME
    flame_hot = WHITE if monochrome else FLAME_HOT
    flame_deep = WHITE if monochrome else FLAME_DEEP
    wick = WHITE if monochrome else WICK
    gems = (WHITE, WHITE, WHITE) if monochrome else (PUMPKIN, GHOST, BAT)

    if not transparent_bg and not monochrome:
        d.rectangle((0, 0, 63, 63), fill=NIGHT)
        d.rectangle((0, 0, 63, 63), outline=NIGHT_DEEP)
        d.ellipse((8, 6, 56, 58), fill=GLOW)
        # Crescent, kept inside the adaptive-icon safe circle.
        d.ellipse((40, 10, 54, 24), fill=MOON)
        d.ellipse((44, 10, 58, 24), fill=GLOW)
        for sx, sy in ((14, 16), (18, 12), (22, 20), (12, 28)):
            d.point((sx, sy), fill=MOON)

    # Candle, centered in the 64px safe zone (about 11..53).
    d.rectangle((29, 24, 34, 44), fill=wax)
    d.rectangle((29, 24, 34, 44), outline=wax_dark)
    d.point((30, 36), fill=wax_dark)
    d.point((33, 30), fill=wax_dark)
    d.line((31, 22, 31, 24), fill=wick)
    d.polygon([(28, 22), (35, 22), (31, 12)], fill=flame_deep)
    d.polygon([(29, 21), (34, 21), (31, 14)], fill=flame)
    d.polygon([(30, 20), (33, 20), (31, 16)], fill=flame_hot)

    for cx, color in zip((18, 32, 46), gems):
        d.ellipse((cx - 4, 46, cx + 4, 54), fill=color)
        if not monochrome:
            d.point((cx - 1, 48), fill=(255, 255, 255, 180))
    return img


def _scale(img: Image.Image, size: int, opaque: bool) -> Image.Image:
    out = img.resize((size, size), Image.Resampling.NEAREST)
    if opaque and out.mode == "RGBA":
        flat = Image.new("RGB", out.size, NIGHT[:3])
        flat.paste(out, mask=out.split()[-1])
        return flat
    return out


def main() -> None:
    IOS.mkdir(parents=True, exist_ok=True)
    ANDROID.mkdir(parents=True, exist_ok=True)

    full = _draw_scene(False, False)
    foreground = _draw_scene(True, False)
    background = _blank(False)
    ImageDraw.Draw(background).rectangle((0, 0, 63, 63), fill=NIGHT)
    ImageDraw.Draw(background).ellipse((8, 6, 56, 58), fill=GLOW)
    mono = _draw_scene(True, True)

    for name, size in IOS_SIZES.items():
        _scale(full, size, opaque=True).save(IOS / f"{name}.png")

    for name, size in ANDROID_LAUNCHER.items():
        _scale(full, size, opaque=True).save(ANDROID / f"{name}.png")

    _scale(foreground, 432, opaque=False).save(ANDROID / "adaptive_foreground_432.png")
    _scale(background, 432, opaque=True).save(ANDROID / "adaptive_background_432.png")
    _scale(mono, 432, opaque=False).save(ANDROID / "adaptive_monochrome_432.png")
    # Project icon used by the Godot editor and as a fallback.
    _scale(full, 1024, opaque=True).save(ROOT / "assets" / "icons" / "icon_1024.png")
    _scale(full, 128, opaque=True).save(ROOT / "assets" / "drawables" / "icon.png")
    print("wrote icons")


if __name__ == "__main__":
    main()
