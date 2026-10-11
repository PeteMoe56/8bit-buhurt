#!/usr/bin/env python3
"""THE WORLDS' FLAGS (Pete, 11 Oct 2026: "you would still need to create all the
32 and 16px country flags and colors"). Drawn here pixel by pixel, not scaled:
48x32 and 24x16 (3:2, so 32 and 16 tall), flat colours, every pixel fully on.

    python3 tools/make_flags.py [out_dir]     -> art/flags/<code>_16.png, <code>_32.png

A flag with a crest is simplified at 16: the crest becomes its colour block or is
dropped (Spain red-yellow-red, Portugal's sphere a yellow dot), the way sports
apps draw them small. The 32 keeps more of it.
"""
import math
import os
import sys
from PIL import Image

C = {
    "white": (255, 255, 255), "red": (200, 16, 46), "blue": (0, 40, 104), "navy": (1, 33, 105),
    "yellow": (255, 205, 0), "gold": (255, 206, 0), "black": (16, 16, 16), "green": (0, 122, 61),
    "orange": (255, 136, 62), "ukblue": (0, 87, 183), "ukyellow": (255, 215, 0),
    "frblue": (0, 35, 149), "frred": (237, 41, 57), "itgreen": (0, 146, 70), "itred": (206, 43, 55),
    "esred": (170, 21, 27), "esyellow": (241, 191, 0), "gbblue": (1, 33, 105), "gbred": (200, 16, 46),
    "ieorange": (255, 121, 0), "iegreen": (22, 155, 98), "beyellow": (253, 218, 36), "bered": (239, 51, 64),
    "nlred": (174, 28, 40), "nlblue": (33, 70, 139), "dkred": (198, 12, 48), "seblue": (0, 106, 167),
    "seyellow": (254, 204, 2), "nored": (186, 12, 47), "noblue": (0, 32, 91), "fiblue": (0, 47, 108),
    "czblue": (17, 69, 126), "czred": (215, 20, 26), "skblue": (11, 78, 162), "skred": (238, 28, 37),
    "hured": (206, 41, 57), "hugreen": (71, 112, 80), "atred": (200, 16, 46), "chred": (218, 41, 28),
    "ptgreen": (0, 102, 0), "ptred": (255, 0, 0), "ilblue": (0, 56, 184), "cared": (216, 6, 33),
    "mxgreen": (0, 104, 71), "mxred": (206, 17, 38), "mxbrown": (124, 86, 38), "arblue": (116, 172, 223),
    "arsun": (246, 180, 14), "brgreen": (0, 151, 57), "bryellow": (254, 221, 0), "brblue": (1, 33, 105),
    "clblue": (0, 57, 166), "clred": (213, 43, 30), "aublue": (1, 33, 105), "jpred": (188, 0, 45),
    "lvmaroon": (158, 48, 57), "ltyellow": (253, 185, 19), "ltgreen": (0, 106, 68), "ltred": (193, 39, 45),
    "eeblue": (0, 114, 206), "roblue": (0, 43, 127), "royellow": (252, 209, 22), "rored": (206, 17, 38),
    "hrred": (255, 0, 0), "hrblue": (23, 23, 150), "rsred": (198, 54, 60), "rsblue": (12, 64, 118),
    "grblue": (13, 94, 175), "usred": (178, 34, 52), "usblue": (60, 59, 110), "srgold": (237, 185, 65),
}


class F:
    def __init__(self, w, h, bg=(255, 255, 255)):
        self.w, self.h = w, h
        self.px = [[bg for _ in range(w)] for _ in range(h)]

    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(max(0, int(y0)), min(self.h, int(y1))):
            for x in range(max(0, int(x0)), min(self.w, int(x1))):
                self.px[y][x] = c

    def hstripes(self, cols, weights=None):
        weights = weights or [1] * len(cols)
        tot = sum(weights)
        for y in range(self.h):
            t = (y + 0.5) / self.h * tot
            acc = 0
            for c, wgt in zip(cols, weights):
                acc += wgt
                if t < acc:
                    self.rect(0, y, self.w, y + 1, c)
                    break

    def vstripes(self, cols, weights=None):
        weights = weights or [1] * len(cols)
        tot = sum(weights)
        for x in range(self.w):
            t = (x + 0.5) / self.w * tot
            acc = 0
            for c, wgt in zip(cols, weights):
                acc += wgt
                if t < acc:
                    self.rect(x, 0, x + 1, self.h, c)
                    break

    def fill(self, inside, c):
        for y in range(self.h):
            for x in range(self.w):
                if inside(x + 0.5, y + 0.5):
                    self.px[y][x] = c

    def disc(self, cx, cy, r, c):
        self.fill(lambda x, y: (x - cx) ** 2 + (y - cy) ** 2 <= r * r, c)

    def poly(self, pts, c):
        def inside(x, y):
            n, ok = len(pts), False
            j = n - 1
            for i in range(n):
                xi, yi = pts[i]
                xj, yj = pts[j]
                if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi + 1e-9) + xi:
                    ok = not ok
                j = i
            return ok
        self.fill(inside, c)

    def star(self, cx, cy, r, c, points=5, inner=0.4, rot=-90):
        pts = []
        for k in range(points * 2):
            rr = r if k % 2 == 0 else r * inner
            a = math.radians(rot + k * 180 / points)
            pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
        self.poly(pts, c)

    def nordic(self, bg, cross, inner=None):
        self.rect(0, 0, self.w, self.h, bg)
        big = self.h >= 32
        t = 6 if big else 4               ## bar thickness
        cx = int(self.w * 0.375)          ## the vertical bar's centre, toward the hoist
        cy = self.h // 2
        self.rect(cx - t // 2, 0, cx + t // 2, self.h, cross)
        self.rect(0, cy - t // 2, self.w, cy + t // 2, cross)
        if inner:
            ti = t // 2
            self.rect(cx - ti // 2, 0, cx + ti // 2, self.h, inner)
            self.rect(0, cy - ti // 2, self.w, cy + ti // 2, inner)

    def image(self):
        im = Image.new("RGB", (self.w, self.h))
        im.putdata([p for row in self.px for p in row])
        return im


def union_jack(f, x0, y0, w, h):
    """The Union Jack in a w x h box (the whole flag, or a canton)."""
    big = h >= 16
    tw = max(1, round(h * 0.2))       ## white cross half-width-ish
    tr = max(1, round(h * 0.12))
    dw = h * 0.20                      ## diagonal white thickness
    dr = h * 0.08 if big else 0.0
    for y in range(h):
        for x in range(w):
            u, v = (x + 0.5) / w, (y + 0.5) / h
            c = C["gbblue"]
            d1 = abs((u - v) * h)      ## distance-ish to the top-left/bottom-right diagonal (in px)
            d2 = abs((u + v - 1) * h)
            if min(d1, d2) < dw:
                c = C["white"]
                if dr and min(d1, d2) < dr:
                    c = C["gbred"]
            if abs(x + 0.5 - w / 2) < tw or abs(y + 0.5 - h / 2) < tw * h / h * 0.9:
                c = C["white"]
            if abs(x + 0.5 - w / 2) < tr or abs(y + 0.5 - h / 2) < tr * 0.9:
                c = C["gbred"]
            f.set(x0 + x, y0 + y, c)


def draw(code, w, h):
    big = h >= 32
    f = F(w, h)
    s = h / 32.0                        ## 1 at 32 tall, 0.5 at 16
    if code == "USA":
        n = 13 if big else 7
        f.hstripes([C["usred"] if i % 2 == 0 else C["white"] for i in range(n)])
        cw, ch = round(w * 0.42), round(h * (7 / 13 if big else 4 / 7))
        f.rect(0, 0, cw, ch, C["usblue"])
        step = 3 if big else 2
        for yy in range(1, ch - 1, step):
            off = 1 + ((yy - 1) // step) % 2 * (step // 2 if big else 0)
            for xx in range(off, cw - 1, step):
                f.set(xx, yy, C["white"])
    elif code == "UKR":
        f.hstripes([C["ukblue"], C["ukyellow"]])
    elif code == "POL":
        f.hstripes([C["white"], C["red"]])
    elif code == "FRA":
        f.vstripes([C["frblue"], C["white"], C["frred"]])
    elif code == "GER":
        f.hstripes([C["black"], (221, 0, 0), C["gold"]])
    elif code == "ITA":
        f.vstripes([C["itgreen"], C["white"], C["itred"]])
    elif code == "ESP":
        f.hstripes([C["esred"], C["esyellow"], C["esred"]], [1, 2, 1])
        if big:                          ## the crest, as its colour block toward the hoist
            f.rect(round(w * 0.22), round(h * 0.34), round(w * 0.36), round(h * 0.68), C["esred"])
            f.rect(round(w * 0.24), round(h * 0.38), round(w * 0.34), round(h * 0.5), C["esyellow"])
    elif code == "GBR":
        union_jack(f, 0, 0, w, h)
    elif code == "IRL":
        f.vstripes([C["iegreen"], C["white"], C["ieorange"]])
    elif code == "BEL":
        f.vstripes([C["black"], C["beyellow"], C["bered"]])
    elif code == "NED":
        f.hstripes([C["nlred"], C["white"], C["nlblue"]])
    elif code == "DEN":
        f.nordic(C["dkred"], C["white"])
    elif code == "SWE":
        f.nordic(C["seblue"], C["seyellow"])
    elif code == "NOR":
        f.nordic(C["nored"], C["white"], C["noblue"])
    elif code == "FIN":
        f.nordic(C["white"], C["fiblue"])
    elif code == "CZE":
        f.hstripes([C["white"], C["czred"]])
        f.poly([(0, 0), (w / 2, h / 2), (0, h)], C["czblue"])
    elif code == "SVK":
        f.hstripes([C["white"], C["skblue"], C["skred"]])
        x0, y0 = round(w * 0.2), round(h * 0.22)
        sw, sh = round(w * 0.2), round(h * 0.56)
        f.rect(x0 - 1, y0 - 1, x0 + sw + 1, y0 + sh, C["white"])
        f.rect(x0, y0, x0 + sw, y0 + sh - 1, C["skred"])
        cx = x0 + sw // 2
        f.rect(cx - (1 if big else 0), y0 + 1, cx + 1, y0 + sh - 3, C["white"])          ## the double cross
        f.rect(x0 + 2, y0 + round(sh * 0.3), x0 + sw - 2, y0 + round(sh * 0.3) + max(1, round(s * 2)), C["white"])
        if big:
            f.rect(x0 + 1, y0 + round(sh * 0.5), x0 + sw - 1, y0 + round(sh * 0.5) + 2, C["white"])
            f.rect(x0, y0 + sh - 5, x0 + sw, y0 + sh - 1, C["skblue"])                  ## the hills
    elif code == "HUN":
        f.hstripes([C["hured"], C["white"], C["hugreen"]])
    elif code == "AUT":
        f.hstripes([C["atred"], C["white"], C["atred"]])
    elif code == "SUI":
        f.rect(0, 0, w, h, C["chred"])
        a = round(h * 0.62)              ## the square cross, centred in the 3:2 tile
        t = max(2, round(a * 0.3))
        cx, cy = w // 2, h // 2
        f.rect(cx - t // 2, cy - a // 2, cx + (t + 1) // 2, cy + (a + 1) // 2, C["white"])
        f.rect(cx - a // 2, cy - t // 2, cx + (a + 1) // 2, cy + (t + 1) // 2, C["white"])
    elif code == "POR":
        f.vstripes([C["ptgreen"], C["ptred"]], [2, 3])
        cx, cy = w * 0.4, h / 2
        f.disc(cx, cy, h * (0.26 if big else 0.22), C["yellow"])
        if big:
            f.rect(cx - 3, cy - 4, cx + 3, cy + 4, C["white"])
            f.rect(cx - 2, cy - 3, cx + 2, cy + 3, C["ptred"])
            f.rect(cx - 1, cy - 2, cx + 1, cy + 2, C["white"])
    elif code == "ISR":
        f.rect(0, 0, w, h, C["white"])
        b = max(2, round(h * 0.15))
        o = round(h * 0.1)
        f.rect(0, o, w, o + b, C["ilblue"])
        f.rect(0, h - o - b, w, h - o, C["ilblue"])
        cx, cy, r = w / 2, h / 2, h * (0.2 if big else 0.22)
        if big:
            tri = lambda rot: [(cx + r * math.cos(math.radians(rot + 120 * k)), cy + r * math.sin(math.radians(rot + 120 * k))) for k in range(3)]
            g = F(w, h, None)
            g.poly(tri(-90), 1); up = [[g.px[y][x] for x in range(w)] for y in range(h)]
            g = F(w, h, None); g.poly(tri(90), 1); dn = [[g.px[y][x] for x in range(w)] for y in range(h)]
            gi = F(w, h, None)
            ri = r - 2.2
            tri_i = lambda rot: [(cx + ri * math.cos(math.radians(rot + 120 * k)), cy + ri * math.sin(math.radians(rot + 120 * k))) for k in range(3)]
            gi.poly(tri_i(-90), 1); upi = [[gi.px[y][x] for x in range(w)] for y in range(h)]
            gi = F(w, h, None); gi.poly(tri_i(90), 1); dni = [[gi.px[y][x] for x in range(w)] for y in range(h)]
            for y in range(h):
                for x in range(w):
                    if (up[y][x] == 1 and upi[y][x] != 1) or (dn[y][x] == 1 and dni[y][x] != 1):
                        f.set(x, y, C["ilblue"])
        else:
            f.star(cx, cy, r + 0.6, C["ilblue"], points=6, inner=0.62)
            f.set(int(cx), int(cy), C["white"]); f.set(int(cx) - 1, int(cy), C["white"])
            f.set(int(cx), int(cy) - 1, C["white"]); f.set(int(cx) - 1, int(cy) - 1, C["white"])
    elif code == "CAN":
        f.vstripes([C["cared"], C["white"], C["cared"]], [1, 2, 1])
        cx, cy = w / 2, h / 2
        if big:
            leaf = [(0, -10), (2, -6), (4, -7), (3, -2), (7, -5), (6, -2), (9, -1), (6, 2), (7, 4), (1, 3), (1, 9),
                    (-1, 9), (-1, 3), (-7, 4), (-6, 2), (-9, -1), (-6, -2), (-7, -5), (-3, -2), (-4, -7), (-2, -6)]
            f.poly([(cx + x, cy + y) for x, y in leaf], C["cared"])
        else:
            leaf = [(0, -5), (1.5, -3), (2.5, -3.5), (2, -1), (4.5, -2), (3.5, 1), (0.6, 1.5), (0.6, 4.5),
                    (-0.6, 4.5), (-0.6, 1.5), (-3.5, 1), (-4.5, -2), (-2, -1), (-2.5, -3.5), (-1.5, -3)]
            f.poly([(cx + x, cy + y) for x, y in leaf], C["cared"])
    elif code == "MEX":
        f.vstripes([C["mxgreen"], C["white"], C["mxred"]])
        cx, cy = w / 2, h / 2
        f.disc(cx, cy, h * (0.18 if big else 0.2), C["mxbrown"])
        if big:
            f.rect(cx - 4, cy + 3, cx + 4, cy + 5, C["mxgreen"])
    elif code == "ARG":
        f.hstripes([C["arblue"], C["white"], C["arblue"]])
        f.disc(w / 2, h / 2, h * (0.13 if big else 0.13), C["arsun"])
    elif code == "BRA":
        f.rect(0, 0, w, h, C["brgreen"])
        m = round(h * 0.12) if big else 2
        f.poly([(w / 2, m), (w - m - 1, h / 2), (w / 2, h - m), (m + 1, h / 2)], C["bryellow"])
        f.disc(w / 2, h / 2, h * 0.24, C["brblue"])
        if big:
            f.fill(lambda x, y: abs(math.hypot(x - w / 2, y - h / 2 + 14) - 15.5) < 1.0 and math.hypot(x - w / 2, y - h / 2) < h * 0.24, C["white"])
    elif code == "CHI":
        f.hstripes([C["white"], C["clred"]])
        sq = h // 2
        f.rect(0, 0, sq, sq, C["clblue"])
        f.star(sq / 2, sq / 2, sq * (0.36 if big else 0.42), C["white"], inner=0.42 if big else 0.5)
    elif code in ("AUS", "NZL"):
        f.rect(0, 0, w, h, C["aublue"])
        union_jack(f, 0, 0, w // 2, h // 2)
        if code == "AUS":
            if big:
                f.star(w * 0.25, h * 0.75, 5, C["white"], points=7, inner=0.5)
                for (x, y, r) in [(0.75, 0.22, 2.2), (0.63, 0.47, 2.2), (0.87, 0.42, 2.2), (0.75, 0.82, 2.4), (0.81, 0.58, 1.3)]:
                    f.star(w * x, h * y, r, C["white"], inner=0.45)
            else:
                f.star(w * 0.25, h * 0.75, 2.6, C["white"], points=7, inner=0.55)
                for (x, y) in [(0.75, 0.2), (0.62, 0.48), (0.88, 0.42), (0.75, 0.82)]:
                    f.set(int(w * x), int(h * y), C["white"])
        else:
            pts = [(0.75, 0.22), (0.62, 0.47), (0.87, 0.42), (0.75, 0.82)]
            for (x, y) in pts:
                if big:
                    f.star(w * x, h * y, 2.8, C["white"], inner=0.45)
                    f.star(w * x, h * y, 1.8, C["red"], inner=0.45)
                else:
                    f.set(int(w * x), int(h * y), C["red"])
    elif code == "JPN":
        f.rect(0, 0, w, h, C["white"])
        f.disc(w / 2, h / 2, h * 0.3, C["jpred"])
    elif code == "LAT":
        f.hstripes([C["lvmaroon"], C["white"], C["lvmaroon"]], [2, 1, 2])
    elif code == "LTU":
        f.hstripes([C["ltyellow"], C["ltgreen"], C["ltred"]])
    elif code == "EST":
        f.hstripes([C["eeblue"], C["black"], C["white"]])
    elif code == "ROU":
        f.vstripes([C["roblue"], C["royellow"], C["rored"]])
    elif code == "CRO":
        f.hstripes([C["hrred"], C["white"], C["hrblue"]])
        cell = 2 if big else 1
        n = 5 if big else 4
        x0 = round(w / 2 - n * cell / 2)
        y0 = round(h * 0.3)
        f.rect(x0 - 1, y0 - 1, x0 + n * cell + 1, y0 + n * cell + 1, C["white"])
        for j in range(n):
            for i in range(n):
                f.rect(x0 + i * cell, y0 + j * cell, x0 + (i + 1) * cell, y0 + (j + 1) * cell,
                       C["hrred"] if (i + j) % 2 == 0 else C["white"])
        f.rect(x0 - 1, y0 - 2, x0 + n * cell + 1, y0 - 1, C["hrblue"])
    elif code == "SRB":
        f.hstripes([C["rsred"], C["rsblue"], C["white"]])
        x0 = round(w * 0.25)
        sw, sh = (8, 12) if big else (4, 7)
        y0 = round(h / 2 - sh / 2)
        f.rect(x0 - (2 if big else 1), y0 - (2 if big else 1), x0 + sw + (2 if big else 1), y0 + sh // 2, C["srgold"])  ## the eagle's wings
        f.rect(x0, y0, x0 + sw, y0 + sh, C["rsred"])
        f.rect(x0 + sw // 2 - (1 if big else 0), y0 + 1, x0 + sw // 2 + 1, y0 + sh - 1, C["white"])
        f.rect(x0 + 1, y0 + sh // 2 - (1 if big else 0), x0 + sw - 1, y0 + sh // 2 + 1, C["white"])
    elif code == "GRE":
        f.hstripes([C["grblue"] if i % 2 == 0 else C["white"] for i in range(9)])
        cs = round(h * 5 / 9)
        f.rect(0, 0, cs, cs, C["grblue"])
        t = 2 if big else 1
        f.rect(cs // 2 - t // 2 - (0 if big else 0), 0, cs // 2 + (t + 1) // 2, cs, C["white"])
        f.rect(0, cs // 2 - t // 2, cs, cs // 2 + (t + 1) // 2, C["white"])
    else:
        raise ValueError(code)
    return f.image()


## Every Worlds team: [code, name, kit, mark]. Kit is the darker flag colour the
## team wears, mark the lighter one on it; both checked against the clubs' own
## contrast rule (IconBank.contrast_ok) by tools/check_flag_colours.gd.
TEAMS = [
    ["USA", "Team USA", "#3c3b6e", "#ffffff"], ["UKR", "Team Ukraine", "#0057b7", "#ffd700"],
    ["POL", "Team Poland", "#c8102e", "#ffffff"], ["FRA", "Team France", "#002395", "#ffffff"],
    ["GER", "Team Germany", "#1c1c1c", "#ffce00"], ["ITA", "Team Italy", "#00703c", "#ffffff"],
    ["ESP", "Team Spain", "#aa151b", "#f1bf00"], ["GBR", "Team Great Britain", "#012169", "#ffffff"],
    ["IRL", "Team Ireland", "#169b62", "#ffffff"], ["BEL", "Team Belgium", "#1c1c1c", "#fdda24"],
    ["NED", "Team Netherlands", "#e05206", "#ffffff"], ["DEN", "Team Denmark", "#c60c30", "#ffffff"],
    ["SWE", "Team Sweden", "#006aa7", "#fecc02"], ["NOR", "Team Norway", "#ba0c2f", "#ffffff"],
    ["FIN", "Team Finland", "#002f6c", "#ffffff"], ["CZE", "Team Czechia", "#11457e", "#ffffff"],
    ["SVK", "Team Slovakia", "#0b4ea2", "#ffffff"], ["HUN", "Team Hungary", "#477050", "#ffffff"],
    ["AUT", "Team Austria", "#c8102e", "#ffffff"], ["SUI", "Team Switzerland", "#da291c", "#ffffff"],
    ["POR", "Team Portugal", "#006600", "#ffcd00"], ["ISR", "Team Israel", "#0038b8", "#ffffff"],
    ["CAN", "Team Canada", "#d80621", "#ffffff"], ["MEX", "Team Mexico", "#006847", "#ffffff"],
    ["ARG", "Team Argentina", "#1b4f8a", "#74acdf"], ["BRA", "Team Brazil", "#009739", "#fedd00"],
    ["CHI", "Team Chile", "#0039a6", "#ffffff"], ["AUS", "Team Australia", "#012169", "#ffcd00"],
    ["NZL", "Team New Zealand", "#1c1c1c", "#ffffff"], ["JPN", "Team Japan", "#bc002d", "#ffffff"],
    ["LAT", "Team Latvia", "#9e3039", "#ffffff"], ["LTU", "Team Lithuania", "#006a44", "#fdb913"],
    ["EST", "Team Estonia", "#0072ce", "#ffffff"], ["ROU", "Team Romania", "#002b7f", "#fcd116"],
    ["CRO", "Team Croatia", "#171796", "#ffffff"], ["SRB", "Team Serbia", "#0c4076", "#ffffff"],
    ["GRE", "Team Greece", "#0d5eaf", "#ffffff"],
]


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "art/flags"
    os.makedirs(out, exist_ok=True)
    for code, *_ in TEAMS:
        draw(code, 48, 32).save(os.path.join(out, "%s_32.png" % code.lower()))
        draw(code, 24, 16).save(os.path.join(out, "%s_16.png" % code.lower()))
    print("flags:", len(TEAMS), "->", out)


if __name__ == "__main__":
    main()
