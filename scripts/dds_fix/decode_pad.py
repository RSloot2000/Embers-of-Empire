#!/usr/bin/env python3
"""Decode a DXT5 DDS to raw RGBA and pad to the next multiple of 4.

Reads the source DDS (any compressed format PIL can decode), pads the
image to the next multiple-of-4 dimensions (preserving the artwork exactly,
adding a transparent border), and writes raw RGBA bytes (R,G,B,A per pixel,
row-major, top-to-bottom) for the C encoder to consume.
"""
import sys
from PIL import Image

src = sys.argv[1]
out_raw = sys.argv[2]

im = Image.open(src).convert("RGBA")
w, h = im.size
print(f"source: {w}x{h}")

# Pad to next multiple of 4 (no resampling -> artwork preserved exactly).
nw = (w + 3) // 4 * 4
nh = (h + 3) // 4 * 4
print(f"padded: {nw}x{nh}")

canvas = Image.new("RGBA", (nw, nh), (0, 0, 0, 0))
canvas.paste(im, (0, 0))

raw = canvas.tobytes()  # RGBA, row-major, top-to-bottom
with open(out_raw, "wb") as f:
    f.write(raw)
print(f"wrote {len(raw)} bytes -> {out_raw}")
print(f"DIMENSIONS {nw} {nh}")
