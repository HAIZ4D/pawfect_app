"""Build square launcher-icon sources from the wide Pawfect logo.

The source art is 1920x1080 with a transparent background and large empty
margins, which is wrong for an app icon in three ways: it is not square,
it is mostly empty, and iOS forbids an alpha channel (it composites
transparency to black). This trims to the real artwork, centres it on a
square cream field, and writes:

  icon_source.png       flat cream background, used for iOS/web/legacy
  icon_foreground.png   transparent art with adaptive-icon safe padding
"""
import os
from PIL import Image

SRC = "assets/images/pawfect-logo.png"
OUT_DIR = "assets/icon"
CREAM = (255, 244, 219, 255)  # PawfectColors.pawfectCream #FFF4DB
SIZE = 1024

os.makedirs(OUT_DIR, exist_ok=True)

img = Image.open(SRC).convert("RGBA")
print("source        :", img.size, img.mode)

# 1. Trim the transparent margin down to the real artwork.
bbox = img.getbbox()
art = img.crop(bbox)
print("trimmed to    :", art.size, "from bbox", bbox)


def square_canvas(art_img, scale, background):
    """Centre art on a square canvas, occupying `scale` of the width."""
    target = int(SIZE * scale)
    w, h = art_img.size
    ratio = min(target / w, target / h)
    resized = art_img.resize(
        (max(1, int(w * ratio)), max(1, int(h * ratio))), Image.LANCZOS
    )
    canvas = Image.new("RGBA", (SIZE, SIZE), background)
    canvas.paste(
        resized,
        ((SIZE - resized.width) // 2, (SIZE - resized.height) // 2),
        resized,
    )
    return canvas


# 2. Flat icon. 82% keeps a little breathing room inside the rounded mask
#    every launcher applies.
flat = square_canvas(art, 0.82, CREAM)
flat_path = os.path.join(OUT_DIR, "icon_source.png")
# Drop alpha: iOS app icons must be fully opaque or they render black.
flat.convert("RGB").save(flat_path, "PNG")
print("wrote         :", flat_path, flat.size, "RGB (no alpha)")

# 3. Adaptive foreground. Android crops the outer ~28% of this layer for
#    circular and squircle masks, so the art sits smaller and transparent.
#    0.74 lands the art at ~78% of the 66dp safe-zone circle once the
#    ic_launcher.xml 16% inset and the launcher crop are applied.
fg = square_canvas(art, 0.74, (0, 0, 0, 0))
fg_path = os.path.join(OUT_DIR, "icon_foreground.png")
fg.save(fg_path, "PNG")
print("wrote         :", fg_path, fg.size, "RGBA")
