#!/usr/bin/env python3
"""Redraw '%' in the pixel faces (30 Sep 2026): the original read as 'K'
("100K chance", "15K") in two blind reviews. Pixel matrices, top row first."""
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

SHAPES = {
    "fonts/BuhurtRail-Regular.ttf": (128, -128, [
        "XX..X",
        "XX..X",
        "...X.",
        "..X..",
        ".X...",
        "X..XX",
        "X..XX"]),
    "fonts/BuhurtPlate-Regular.ttf": (125, 125, [
        "XX....X",
        "XX...X.",
        "....X..",
        "...X...",
        "..X....",
        ".X...XX",
        "X....XX"]),
}

for path, (px, base, rows) in SHAPES.items():
    f = TTFont(path)
    gname = f.getBestCmap()[ord("%")]
    pen = TTGlyphPen(None)
    h = len(rows)
    for r, line in enumerate(rows):
        y0 = base + (h - 1 - r) * px
        for c, ch in enumerate(line):
            if ch != "X":
                continue
            x0 = c * px
            pen.moveTo((x0, y0)); pen.lineTo((x0, y0 + px)); pen.lineTo((x0 + px, y0 + px)); pen.lineTo((x0 + px, y0)); pen.closePath()
    f["glyf"][gname] = pen.glyph()
    f.save(path)
    print("redrew % in", path)
