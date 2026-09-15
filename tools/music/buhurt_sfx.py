#!/usr/bin/env python3
"""
Retro Buhurt — the one-shots.

Eight sounds, built from the same four voices as the music (see
buhurt_music.py), because a UI blip made with a different synthesiser than the
score is a UI blip that sounds like it came from a different game. Same pulse,
same stepped triangle, same held-random noise.

TWO RULES, both learned the expensive way on the music:

  * NO ARPEGGIOS. Cycling pitches frequency-modulates the oscillator and throws
    sidebands either side of every harmonic — 37-55 % inharmonic against a held
    note's 0.4 %. Where a sound wants two notes it plays two notes.
  * EVERYTHING ENDS IN A RELEASE. A one-shot that stops dead is a click, and a
    click on a button tap is the single most noticeable defect a UI can have
    because the player hears it a thousand times an hour.

And one rule of their own: **a UI sound must be short.** Anything over about
120 ms starts to feel like the interface is answering back.
"""

import sys, os, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from buhurt_music import SR, hz, pulse, triangle, noise, env, write_wav


def blip(note, ms, duty=0.5, gain=0.5, bend=0.0, release=0.4):
    """One pulse note. `bend` slides the pitch over its length — up reads as
    confirmation, down as refusal, and that is most of a UI vocabulary."""
    n = int(ms / 1000.0 * SR)
    f0 = hz(note)
    f = np.linspace(f0, f0 * (2.0 ** (bend / 12.0)), n)
    ph = np.cumsum(f) / SR
    w = np.where((ph % 1.0) < duty, 1.0, -1.0).astype(np.float32)
    return w * env(n, 0.001, 0.0, 1.0, ms / 1000.0 * release) * gain


def thud(ms, hi, lo, gain=0.7, period=6, noise_gain=0.5):
    """Triangle body with the pitch falling off a cliff, plus noise on top. The
    NES kick, and the shape of every impact in the game."""
    n = int(ms / 1000.0 * SR)
    f = np.linspace(hi, lo, n)
    ph = np.cumsum(f) / SR
    body = (2.0 * np.abs(2.0 * ((ph % 1.0) - 0.5)) - 1.0).astype(np.float32)
    e = env(n, 0.001, ms / 1000.0 * 0.5, 0.2, ms / 1000.0 * 0.45)
    out = body * e * gain
    if noise_gain > 0:
        out = out + noise(n, period, seed=int(hi)) * e * noise_gain
    return out


def hiss(ms, period=1, gain=0.5, swell=False):
    n = int(ms / 1000.0 * SR)
    x = noise(n, period, seed=period * 7 + ms)
    e = env(n, 0.0008, ms / 1000.0 * 0.6, 0.15, ms / 1000.0 * 0.35)
    if swell:
        e = np.minimum(np.linspace(0.0, 1.6, n), 1.0).astype(np.float32) * \
            np.linspace(1.0, 0.0, n).astype(np.float32) ** 0.6
    return x * e * gain


def cat(*parts):
    """Lay sounds end to end or overlapped, by offset in ms."""
    total = max(int(off / 1000.0 * SR) + len(buf) for off, buf in parts)
    out = np.zeros(total + 64, dtype=np.float32)
    for off, buf in parts:
        i = int(off / 1000.0 * SR)
        out[i:i + len(buf)] += buf
    p = float(np.max(np.abs(out))) or 1.0
    return (out / p * 0.9).astype(np.float32)


SOUNDS = {
    # ---- interface ------------------------------------------------------
    "tap": lambda: cat((0, blip("A5", 34, duty=0.25, gain=0.55))),
    ## Two notes rising. The interval is a fifth rather than an octave because a
    ## fifth is the consonance this whole score is built on.
    "confirm": lambda: cat((0, blip("D5", 44, duty=0.5, gain=0.5)),
                           (40, blip("A5", 72, duty=0.5, gain=0.5))),
    ## Down, and thin. A refusal should be felt as a shape, not read as a word.
    "refuse": lambda: cat((0, blip("F4", 90, duty=0.125, gain=0.5, bend=-5.0))),
    ## The pickup. Short-long, up a fourth — the shape every coin in every
    ## platform game has had since 1985, and it is that shape because it works.
    "coin": lambda: cat((0, blip("B5", 40, duty=0.5, gain=0.45)),
                        (36, blip("E6", 130, duty=0.5, gain=0.45))),

    # ---- the fight ------------------------------------------------------
    ## A MAN GOING DOWN is the biggest sound in the game and the only one that
    ## is allowed to be long. Low, heavy, with the noise rolled well off so it
    ## lands as weight rather than as a crash.
    "down": lambda: cat((0, thud(220, 190.0, 42.0, gain=0.75, period=11,
                                 noise_gain=0.30))),
    ## Steel on steel: short, bright, metallic. Period 1 noise is the hiss end
    ## of the channel, and a tiny pulse under it gives it a pitch so it reads as
    ## a struck object rather than as static.
    "clash": lambda: cat((0, hiss(55, period=1, gain=0.45)),
                         (0, blip("D6", 38, duty=0.125, gain=0.16))),
    ## The marshal. Two blasts, high and hard, the way one is actually blown.
    "whistle": lambda: cat((0, blip("A6", 110, duty=0.5, gain=0.34, bend=0.4)),
                           (150, blip("A6", 150, duty=0.5, gain=0.34, bend=0.4))),
    ## A crowd is long-period noise with a SWELL rather than an attack — it is
    ## the one sound in the set that arrives instead of hitting.
    "crowd": lambda: cat((0, hiss(900, period=14, gain=0.42, swell=True))),

    # ---- the juice layer ------------------------------------------------
    ## BACK IS TAP, A FIFTH DOWN. Same length, same duty, same everything else —
    ## which is the point. A back sound that is its own invention makes the
    ## player learn two sounds; a back sound that is the tap transposed is
    ## understood the first time it is heard, because the interval does the
    ## telling. Down a fifth for the same reason `confirm` goes UP one.
    "back": lambda: cat((0, blip("D5", 34, duty=0.25, gain=0.5))),
    ## THE BIG MOMENT — a cup won, a promotion. Three notes up the same fifth
    ## the whole score is built on, and the ONLY one-shot besides `down` and
    ## `crowd` that is allowed past 200 ms, because it is the only one the
    ## player is meant to stop and listen to.
    "fanfare": lambda: cat((0, blip("D5", 90, duty=0.5, gain=0.45)),
                           (85, blip("A5", 90, duty=0.5, gain=0.45)),
                           (170, blip("D6", 190, duty=0.5, gain=0.5))),
    ## THE WIPE. Noise, short, no pitch — a screen change is a movement of air
    ## and not a note. Period 2 keeps it dry; anything hissier reads as steel
    ## and this game already has a steel sound.
    "wipe": lambda: cat((0, hiss(95, period=2, gain=0.30))),
    ## THE TYPER, and it is barely there on purpose. This fires every second
    ## frame for the length of a paragraph — anything with a shape to it becomes
    ## a machine gun by the third word. High, thin, and quiet enough that what
    ## the player notices is the TEXT arriving, not the sound of it.
    "type": lambda: cat((0, blip("E6", 12, duty=0.125, gain=0.20))),
}


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "/tmp/sfx"
    os.makedirs(out, exist_ok=True)
    bad = []
    for name, fn in SOUNDS.items():
        x = fn()
        ms = 1000.0 * len(x) / SR
        ## THE CLICK CHECK. The first and last samples must be at rest, or the
        ## sound begins and ends with a step — which is a click, and on a button
        ## tap the player hears it a thousand times an hour.
        edge = max(abs(float(x[0])), abs(float(x[-1])))
        ## `fanfare` is exempt for the reason written beside it; so are the
        ## two fight sounds that were always allowed to breathe.
        ui = name in ("tap", "confirm", "refuse", "coin", "back", "wipe", "type")
        too_long = ui and ms > 200.0
        if edge > 0.02 or too_long:
            bad.append("%s (edge %.3f, %.0f ms)" % (name, edge, ms))
        write_wav(os.path.join(out, name + "_raw.wav"), x)
        print("  %-9s %5.0f ms   edge %.4f   %s"
              % (name, ms, edge, "ok" if edge <= 0.02 and not too_long else "CLICKS"))
    if bad:
        print("\nNOT FIT TO SHIP: " + ", ".join(bad))
        sys.exit(1)
