#!/usr/bin/env python3
"""Add the ASCII punctuation BuhurtRail never had (30 Sep 2026). Without them
the engine fell back to LanaPixel, a smaller face, so "&", "<", ">" and "="
printed at half size mid-sentence (blind review round 10: "the & glyph drops to
a smaller font everywhere"). Same grid as the face: 128 units a pixel, cap
height rows 5..-1, advance 768. Idempotent: a glyph already mapped is redrawn."""
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

PX = 128
PATH = "fonts/BuhurtRail-Regular.ttf"
TOP = 5
G = {
    "&": [".XX..", "X..X.", "X.X..", ".X...", "X.X.X", "X..X.", ".XX.X"],
    "<": [".....", "...X.", "..X..", ".X...", "..X..", "...X.", "....."],
    ">": [".....", ".X...", "..X..", "...X.", "..X..", ".X...", "....."],
    "=": [".....", ".....", "XXXX.", ".....", "XXXX.", ".....", "....."],
    '"': ["X.X..", "X.X..", ".....", ".....", ".....", ".....", "....."],
    "*": [".....", "X.X.X", ".XXX.", "XXXXX", ".XXX.", "X.X.X", "....."],
    "[": ["XX", "X.", "X.", "X.", "X.", "X.", "XX"],
    "]": ["XX", ".X", ".X", ".X", ".X", ".X", "XX"],
    "_": [".....", ".....", ".....", ".....", ".....", ".....", "XXXXX"],
    "|": ["..X..", "..X..", "..X..", "..X..", "..X..", "..X..", "..X.."],
    "~": [".....", ".....", ".X..X", "X.XX.", ".....", ".....", "....."],
    "^": ["..X..", ".X.X.", "X...X", ".....", ".....", ".....", "....."],
}

f = TTFont(PATH)
order = f.getGlyphOrder()
for ch, rows in G.items():
    pen = TTGlyphPen(None)
    for i, line in enumerate(rows):
        y0 = (TOP - i) * PX
        for c, v in enumerate(line):
            if v == "X":
                x0 = c * PX
                pen.moveTo((x0, y0)); pen.lineTo((x0, y0 + PX)); pen.lineTo((x0 + PX, y0 + PX)); pen.lineTo((x0 + PX, y0)); pen.closePath()
    cm = f.getBestCmap()
    name = cm.get(ord(ch), "uni%04X" % ord(ch))
    if name not in order:
        order.append(name)
        f.setGlyphOrder(order)
    f["glyf"][name] = pen.glyph()
    width = max(len(r.rstrip(".")) for r in rows)
    f["hmtx"][name] = ((width + 1) * PX, 0)
    for t in f["cmap"].tables:
        if t.isUnicode():
            t.cmap[ord(ch)] = name
f.save(PATH)
print("glyphs in", PATH, ":", "".join(G))
