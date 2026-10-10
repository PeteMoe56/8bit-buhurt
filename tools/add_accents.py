#!/usr/bin/env python3
"""THE ACCENTED LETTERS BuhurtRail never had (10 Oct 2026). The body face carried
plain ASCII only, so every é, ü, ł, ß and ñ fell back to LanaPixel, a smaller
face, and "Zurück" printed with a half-size ü in the middle of the word (Pete
saw it on the German Guide). Each letter here is its own base glyph's pixels
plus a mark, on the face's own grid: 128 units a pixel, lowercase rows y=3..-1,
capitals y=5..-1. A lowercase mark sits on y=5 (one clear row above the
letter), a capital's on y=6. Idempotent: a glyph already mapped is redrawn.

    python3 tools/add_accents.py
"""
from fontTools.ttLib import TTFont
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.ttGlyphPen import TTGlyphPen

PX = 128
PATH = "fonts/BuhurtRail-Regular.ttf"

## Marks for a five-wide letter, top row first.
MARK = {
    "acute": ["...X."],
    "grave": [".X..."],
    "circ": ["..X..", ".X.X."],
    "dier": [".X.X."],
    "tilde": [".XX.X", "X..X."],
    "dot": ["..X.."],
}
## The same marks for a three-wide letter (capital I, and the lowercase i family).
MARK3 = {
    "acute": ["..X"],
    "grave": ["X.."],
    "circ": [".X.", "X.X"],
    "dier": ["X.X"],
}
## Marks that hang below the baseline (row y=-2): cedilla and ogonek.
BELOW = {"ced": "..X..", "ogo": "...X."}

LETTERS = {
    "á": ("a", "acute"), "à": ("a", "grave"), "â": ("a", "circ"), "ã": ("a", "tilde"), "ä": ("a", "dier"),
    "é": ("e", "acute"), "è": ("e", "grave"), "ê": ("e", "circ"), "ë": ("e", "dier"),
    "ó": ("o", "acute"), "ò": ("o", "grave"), "ô": ("o", "circ"), "õ": ("o", "tilde"), "ö": ("o", "dier"),
    "ú": ("u", "acute"), "ù": ("u", "grave"), "û": ("u", "circ"), "ü": ("u", "dier"),
    "ñ": ("n", "tilde"), "ń": ("n", "acute"), "ć": ("c", "acute"), "ś": ("s", "acute"),
    "ź": ("z", "acute"), "ż": ("z", "dot"), "ç": ("c", "ced"), "ą": ("a", "ogo"), "ę": ("e", "ogo"),
    "Á": ("A", "acute"), "À": ("A", "grave"), "Â": ("A", "circ"), "Ã": ("A", "tilde"), "Ä": ("A", "dier"),
    "É": ("E", "acute"), "È": ("E", "grave"), "Ê": ("E", "circ"), "Ë": ("E", "dier"),
    "Ó": ("O", "acute"), "Ò": ("O", "grave"), "Ô": ("O", "circ"), "Õ": ("O", "tilde"), "Ö": ("O", "dier"),
    "Ú": ("U", "acute"), "Ù": ("U", "grave"), "Û": ("U", "circ"), "Ü": ("U", "dier"),
    "Ñ": ("N", "tilde"), "Ń": ("N", "acute"), "Ć": ("C", "acute"), "Ś": ("S", "acute"),
    "Ź": ("Z", "acute"), "Ż": ("Z", "dot"), "Ç": ("C", "ced"), "Ą": ("A", "ogo"), "Ę": ("E", "ogo"),
    "Í": ("I", "acute"), "Ì": ("I", "grave"), "Î": ("I", "circ"), "Ï": ("I", "dier"),
}
## Drawn whole, top row first, from y=5 down to y=-1: the i family on a centred
## stem (the dot gives way to the mark), the barred l's and the sharp s.
WHOLE = {
    "í": ["..X", "...", ".X.", ".X.", ".X.", ".X.", ".X."],
    "ì": ["X..", "...", ".X.", ".X.", ".X.", ".X.", ".X."],
    "î": ["X.X", "...", ".X.", ".X.", ".X.", ".X.", ".X."],
    "ï": ["X.X", "...", ".X.", ".X.", ".X.", ".X.", ".X."],
    "ł": ["XX...", ".X...", ".X...", ".XX..", "XX...", ".X...", ".XX.."],
    "Ł": ["X....", "X....", "X.X..", "XX...", "X....", "X....", "XXXXX"],
    "ß": [".XX..", "X..X.", "X.X..", "X..X.", "X...X", "X...X", "X.XX."],
}
## "î" over two rows like the other circumflexes.
WHOLE_TOP = {"î": ".X."}


def cells_of(gs, cm, ch):
    g = gs[cm[ord(ch)]]
    p = RecordingPen()
    g.draw(p)
    cells, cur = set(), []
    for op, args in p.value:
        if op in ("moveTo", "lineTo"):
            cur.append(args[0])
        elif op in ("closePath", "endPath"):
            xs = [x for x, y in cur]
            ys = [y for x, y in cur]
            for x in range(min(xs), max(xs), PX):
                for y in range(min(ys), max(ys), PX):
                    cells.add((x // PX, y // PX))
            cur = []
    return cells, g.width


def rows_at(rows, top_y):
    out = set()
    for i, line in enumerate(rows):
        for c, v in enumerate(line):
            if v == "X":
                out.add((c, top_y - i))
    return out


def glyph(cells):
    pen = TTGlyphPen(None)
    for x, y in sorted(cells):
        x0, y0 = x * PX, y * PX
        pen.moveTo((x0, y0)); pen.lineTo((x0, y0 + PX)); pen.lineTo((x0 + PX, y0 + PX)); pen.lineTo((x0 + PX, y0)); pen.closePath()
    return pen.glyph()


f = TTFont(PATH)
gs = f.getGlyphSet()
cm = f.getBestCmap()
made = {}
for ch, (base, mark) in LETTERS.items():
    cells, adv = cells_of(gs, cm, base)
    cap = base.isupper()
    narrow = adv <= 4 * PX
    if mark in BELOW:
        cells |= rows_at([BELOW[mark]], -2)
    else:
        rows = (MARK3 if narrow else MARK)[mark]
        cells |= rows_at(rows, (6 if cap else 5) + len(rows) - 1)
    made[ch] = (cells, adv)
for ch, rows in WHOLE.items():
    cells = rows_at(rows, 5)
    if ch in WHOLE_TOP:
        cells |= rows_at([WHOLE_TOP[ch]], 6)
    made[ch] = (cells, (max(x for x, y in cells) + 2) * PX)

order = f.getGlyphOrder()
for ch, (cells, adv) in made.items():
    name = cm.get(ord(ch), "uni%04X" % ord(ch))
    if name not in order:
        order.append(name)
        f.setGlyphOrder(order)
    f["glyf"][name] = glyph(cells)
    f["hmtx"][name] = (adv, 0)
    for t in f["cmap"].tables:
        if t.isUnicode():
            t.cmap[ord(ch)] = name
f["maxp"].numGlyphs = len(f.getGlyphOrder())
f.save(PATH)
print("accented glyphs in", PATH, ":", "".join(made))
