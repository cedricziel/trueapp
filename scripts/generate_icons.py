#!/usr/bin/env python3
"""Generate the app icon, macOS icon and menu bar glyphs from one design.

Requires `rsvg-convert` (brew install librsvg) and Pillow.
Run from the repo root: python3 scripts/generate_icons.py
"""
import io
import json
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
DESIGN = ROOT / "design"

DEFS = """
<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0" stop-color="#27B4EE"/>
  <stop offset="0.5" stop-color="#0B63C4"/>
  <stop offset="1" stop-color="#07225E"/>
</linearGradient>
<radialGradient id="glow" cx="0.3" cy="0.12" r="0.75">
  <stop offset="0" stop-color="#ffffff" stop-opacity="0.32"/>
  <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
</radialGradient>
<linearGradient id="slab" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#ffffff"/>
  <stop offset="1" stop-color="#D3E6F8"/>
</linearGradient>
<linearGradient id="grip" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#1573D0"/>
  <stop offset="1" stop-color="#0B4FA0"/>
</linearGradient>
<radialGradient id="led" cx="0.5" cy="0.4" r="0.6">
  <stop offset="0" stop-color="#8CFFC4"/>
  <stop offset="1" stop-color="#22C77A"/>
</radialGradient>
<filter id="shadow" x="-20%" y="-20%" width="140%" height="150%">
  <feDropShadow dx="0" dy="14" stdDeviation="16" flood-color="#021438" flood-opacity="0.45"/>
</filter>
<filter id="tile" x="-10%" y="-10%" width="120%" height="125%">
  <feDropShadow dx="0" dy="10" stdDeviation="12" flood-color="#000000" flood-opacity="0.35"/>
</filter>
"""


def glyph() -> str:
    """Three stacked drive bays with status LEDs, centred on a 1024 canvas."""
    w, h, gap, r = 630, 152, 44, 48
    x = (1024 - w) / 2
    top = (1024 - (3 * h + 2 * gap)) / 2
    out = ['<g filter="url(#shadow)">']
    for i in range(3):
        y = top + i * (h + gap)
        out.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="url(#slab)"/>'
            f'<rect x="{x + 56}" y="{y + h / 2 - 13}" width="216" height="26" rx="13" fill="url(#grip)"/>'
            f'<circle cx="{x + w - 74}" cy="{y + h / 2}" r="24" fill="url(#led)"/>'
        )
    out.append("</g>")
    return "".join(out)


def svg(body: str) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" '
        f'viewBox="0 0 1024 1024"><defs>{DEFS}</defs>{body}</svg>'
    )


def ios_svg() -> str:
    return svg(
        '<rect width="1024" height="1024" fill="url(#bg)"/>'
        '<rect width="1024" height="1024" fill="url(#glow)"/>' + glyph()
    )


def macos_svg() -> str:
    tile = (
        '<rect x="100" y="100" width="824" height="824" rx="185" fill="url(#bg)" filter="url(#tile)"/>'
        '<rect x="100" y="100" width="824" height="824" rx="185" fill="url(#glow)"/>'
    )
    scaled = f'<g transform="translate(512 512) scale(0.8) translate(-512 -512)">{glyph()}</g>'
    return svg(tile + scaled)


def tray_svg() -> str:
    bars = "".join(
        f'<rect x="1" y="{1 + i * 5}" width="14" height="4" rx="1.4" fill="#fff"/>'
        for i in range(3)
    )
    holes = "".join(
        f'<circle cx="12.4" cy="{3 + i * 5}" r="0.9" fill="#000"/>' for i in range(3)
    )
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">'
        f'<mask id="m"><rect width="16" height="16" fill="#000"/>{bars}{holes}</mask>'
        '<rect width="16" height="16" fill="#000" mask="url(#m)"/></svg>'
    )


def render(svg_text: str, px: int) -> Image.Image:
    png = subprocess.run(
        ["rsvg-convert", "-w", str(px), "-h", str(px)],
        input=svg_text.encode(),
        capture_output=True,
        check=True,
    ).stdout
    return Image.open(io.BytesIO(png)).convert("RGBA")


def write_catalog(directory: Path, svg_text: str, entries: list, opaque: bool):
    directory.mkdir(parents=True, exist_ok=True)
    for old in directory.glob("*.png"):
        old.unlink()
    sizes = sorted({e["px"] for e in entries})
    for px in sizes:
        img = render(svg_text, px)
        if opaque:
            img = img.convert("RGB")
        img.save(directory / f"{px}.png", optimize=True)
    images = [
        {
            "filename": f"{e['px']}.png",
            "idiom": e["idiom"],
            "scale": e["scale"],
            "size": e["size"],
        }
        for e in entries
    ]
    (directory / "Contents.json").write_text(
        json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2)
        + "\n"
    )


def entry(idiom, size, scale):
    pt = float(size.split("x")[0])
    return {"idiom": idiom, "size": size, "scale": f"{scale}x", "px": round(pt * scale)}


IOS = (
    [entry("iphone", s, sc) for s, scs in {"20x20": (2, 3), "29x29": (2, 3), "40x40": (2, 3), "60x60": (2, 3)}.items() for sc in scs]
    + [entry("ipad", s, sc) for s, scs in {"20x20": (1, 2), "29x29": (1, 2), "40x40": (1, 2), "76x76": (1, 2)}.items() for sc in scs]
    + [entry("ipad", "83.5x83.5", 2), entry("ios-marketing", "1024x1024", 1)]
)
MACOS = [entry("mac", f"{s}x{s}", sc) for s in (16, 32, 128, 256, 512) for sc in (1, 2)]


def main():
    DESIGN.mkdir(exist_ok=True)
    ios, mac, tray = ios_svg(), macos_svg(), tray_svg()
    (DESIGN / "app_icon_ios.svg").write_text(ios)
    (DESIGN / "app_icon_macos.svg").write_text(mac)
    (DESIGN / "tray_glyph.svg").write_text(tray)

    write_catalog(ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset", ios, IOS, opaque=True)
    write_catalog(ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset", mac, MACOS, opaque=False)

    render(mac, 1024).save(ROOT / "assets/icons/image.png", optimize=True)

    # 32px @ 144 dpi = 16pt on retina; light-mode glyph is black, dark-mode white.
    glyph_img = render(tray, 32)
    glyph_img.save(ROOT / "assets/icons/nasTemplate_light.png", dpi=(144, 144))
    r, g, b, a = glyph_img.split()
    inv = Image.merge("RGBA", (r.point(lambda v: 255 - v), g.point(lambda v: 255 - v), b.point(lambda v: 255 - v), a))
    inv.save(ROOT / "assets/icons/nasTemplate_dark.png", dpi=(144, 144))


if __name__ == "__main__":
    main()
