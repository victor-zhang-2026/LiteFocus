#!/usr/bin/env python3
"""Generate the product icon from the same yellow-circle/white-sprout design."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import subprocess

root = Path(__file__).resolve().parents[1]
iconset = root / "build" / "LiteFocus.iconset"
iconset.mkdir(parents=True, exist_ok=True)
size = 1024
scale = size / 48
im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
sd.ellipse((4*scale, 5*scale, 44*scale, 45*scale), fill=(0, 0, 0, 58))
shadow = shadow.filter(ImageFilter.GaussianBlur(2.5*scale))
im.alpha_composite(shadow)
d = ImageDraw.Draw(im)
d.ellipse((3*scale, 3*scale, 45*scale, 45*scale), fill=(255, 255, 255, 255))
d.ellipse((6*scale, 6*scale, 42*scale, 42*scale), fill=(232, 181, 26, 255))
def points(coords): return [(round(x*scale), round(y*scale)) for x, y in coords]
d.line(points([(24, 32), (24, 20)]), fill="white", width=round(2.7*scale), joint="curve")
d.ellipse((22.65*scale, 18.65*scale, 25.35*scale, 21.35*scale), fill="white")
d.polygon(points([(23.5, 23), (21, 22), (18, 20), (16, 17), (15, 15), (18, 15), (21, 17), (23, 20)]), fill="white")
d.polygon(points([(24.5, 21), (26, 17), (29, 15), (33, 13), (33, 17), (30, 20), (27, 21)]), fill="white")
sizes = {"16x16":16,"16x16@2x":32,"32x32":32,"32x32@2x":64,
         "128x128":128,"128x128@2x":256,"256x256":256,"256x256@2x":512,
         "512x512":512,"512x512@2x":1024}
for name, pixels in sizes.items():
    im.resize((pixels, pixels), Image.Resampling.LANCZOS).save(iconset / f"icon_{name}.png")
subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(root / "Support" / "LiteFocus.icns")], check=True)
print(root / "Support" / "LiteFocus.icns")
