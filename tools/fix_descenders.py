#!/usr/bin/env python3
"""Give the body face real descenders (30 Sep 2026). In BuhurtRail every
lowercase letter sat on the same bottom row, so 'g' was a '9' on the baseline
and the blind review read "Settings" as "Settinas" (round 9). g, y, p, q, j now
drop one row below the baseline, like BuhurtPlate's g. Pixel matrices, top row
first; the first row is at `top`, one pixel = 128 units, baseline row is -1."""
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

PX = 128
PATH = "fonts/BuhurtRail-Regular.ttf"
SHAPES = {  # char: (top row, rows)
    "g": (3, [".XXXX", "X...X", "X...X", ".XXXX", "....X", ".XXX."]),
    "y": (3, ["X...X", "X...X", "X...X", ".XXXX", "....X", ".XXX."]),
    "p": (3, ["XXXX.", "X...X", "X...X", "XXXX.", "X....", "X...."]),
    "q": (3, [".XXXX", "X...X", "X...X", ".XXXX", "....X", "....X"]),
    "j": (5, ["...X", "....", "...X", "...X", "...X", "...X", "X..X", ".XX."]),
}

f = TTFont(PATH)
cm = f.getBestCmap()
for ch, (top, rows) in SHAPES.items():
    pen = TTGlyphPen(None)
    for i, line in enumerate(rows):
        y0 = (top - i) * PX
        for c, v in enumerate(line):
            if v != "X":
                continue
            x0 = c * PX
            pen.moveTo((x0, y0)); pen.lineTo((x0, y0 + PX)); pen.lineTo((x0 + PX, y0 + PX)); pen.lineTo((x0 + PX, y0)); pen.closePath()
    f["glyf"][cm[ord(ch)]] = pen.glyph()
f.save(PATH)
print("descenders on g y p q j in", PATH)
