#!/usr/bin/env python3
"""
8-Bit Buhurt — the Team USA menu songs (Pete, 11 Oct 2026: "let's find some
8-Bit USA national songs ... a ratio of the current songs with national song
mixed in. We'll make it sound cool").

Every tune here is in the public domain, and every recording is ours, made with
the same four NES voices as the rest of the score (`buhurt_music.py`):

    anthem     The Star-Spangled Banner (John Stafford Smith, c. 1773)
               transcribed by hand
    country    My Country, 'Tis of Thee (the 1744 tune), transcribed by hand
    stripes    The Stars and Stripes Forever (Sousa, 1896), from the Mutopia
               Project's public-domain MIDI (piece 626, John Church 1897 ed.)
    liberty    The Liberty Bell (Sousa, 1893), from the Mutopia Project's
               public-domain MIDI (piece 625)

No third-party recording is used, so nothing needs a credit line.

    python3 tools/music/usa_music.py <out_dir> [midi_dir]
        -> <out_dir>/usa_<name>.wav  (convert to .ogg with ffmpeg)
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from buhurt_music import Song, SR, write_wav  # noqa: E402

NAMES = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]


def note_name(midi):
    return "%s%d" % (NAMES[midi % 12], midi // 12 - 1)


def num(note):
    """'Bb3' -> MIDI number."""
    step = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}[note[0]]
    i = 1
    while note[i] in "#b":
        step += 1 if note[i] == "#" else -1
        i += 1
    return step + (int(note[i:]) + 1) * 12


# ------------------------------------------------------------ hand-written
# (note, beats) in order; None is a rest. Chords are one per bar, as roots.

ANTHEM_KEY = 0   # written in Bb major, 3/4
ANTHEM_A = [  # O say can you see ... twilight's last gleaming
    ("F4", .75), ("D4", .25),
    ("Bb3", 1), ("D4", 1), ("F4", 1),
    ("Bb4", 2), ("D5", .75), ("C5", .25),
    ("Bb4", 1), ("D4", 1), ("E4", 1),
    ("F4", 2), ("F4", .75), ("F4", .25),
    ("D5", 1.5), ("C5", .5), ("Bb4", 1),
    ("A4", 2), ("G4", .75), ("A4", .25),
    ("Bb4", 1), ("Bb4", 1), ("F4", 1),
    ("D4", 1), ("Bb3", 1),
]
ANTHEM_B = [  # and the rockets' red glare ... home of the brave
    ("D5", .75), ("D5", .25),
    ("D5", 1), ("Eb5", 1), ("F5", 1),
    ("F5", 2), ("Eb5", .75), ("D5", .25),
    ("C5", 1), ("D5", 1), ("Eb5", 1),
    ("Eb5", 2), ("Eb5", 1),
    ("D5", 1.5), ("C5", .5), ("Bb4", 1),
    ("A4", 2), ("G4", .75), ("A4", .25),
    ("Bb4", 1), ("D4", 1), ("E4", 1),
    ("F4", 2), ("F4", 1),
    ("Bb4", 1), ("Bb4", 1), ("Bb4", .5), ("A4", .5),
    ("G4", 1), ("G4", 1), ("G4", 1),
    ("C5", 1), ("Eb5", .5), ("D5", .5), ("C5", .5), ("Bb4", .5),
    ("Bb4", 1), ("A4", 1), ("F4", .75), ("F4", .25),
    ("Bb4", 1.5), ("C5", .5), ("D5", .5), ("Eb5", .5),
    ("F5", 2), ("Bb4", .5), ("C5", .5),
    ("D5", 1.5), ("Eb5", .5), ("C5", 1),
    ("Bb4", 3),
]

YANKEE = [  # 4/4 at a quick march, G major
    ("G4", 1), ("G4", 1), ("A4", 1), ("B4", 1),
    ("G4", 1), ("B4", 1), ("A4", 1), ("D4", 1),
    ("G4", 1), ("G4", 1), ("A4", 1), ("B4", 1),
    ("G4", 2), ("F#4", 2),
    ("G4", 1), ("G4", 1), ("A4", 1), ("B4", 1),
    ("C5", 1), ("B4", 1), ("A4", 1), ("G4", 1),
    ("F#4", 1), ("D4", 1), ("E4", 1), ("F#4", 1),
    ("G4", 2), ("G4", 2),
    # chorus
    ("E4", 1.5), ("F#4", .5), ("E4", 1), ("D4", 1),
    ("E4", 1), ("F#4", 1), ("G4", 2),
    ("D4", 1.5), ("E4", .5), ("D4", 1), ("C4", 1),
    ("B3", 2), ("D4", 2),
    ("E4", 1.5), ("F#4", .5), ("E4", 1), ("D4", 1),
    ("E4", 1), ("F#4", 1), ("G4", 1), ("E4", 1),
    ("D4", 1), ("G4", 1), ("F#4", 1), ("A4", 1),
    ("G4", 2), ("G4", 2),
]
YANKEE_ROOTS = ["G", "G", "G", "D", "G", "C", "D", "G",
                "C", "G", "G", "D", "C", "C", "D", "G"]

COUNTRY = [  # 3/4, G major
    ("G4", 1), ("G4", 1), ("A4", 1),
    ("F#4", 1.5), ("G4", .5), ("A4", 1),
    ("B4", 1), ("B4", 1), ("C5", 1),
    ("B4", 1.5), ("A4", .5), ("G4", 1),
    ("A4", 1), ("G4", 1), ("F#4", 1),
    ("G4", 3),
    ("D5", 1), ("D5", 1), ("D5", 1),
    ("D5", 1.5), ("C5", .5), ("B4", 1),
    ("C5", 1), ("C5", 1), ("C5", 1),
    ("C5", 1.5), ("B4", .5), ("A4", 1),
    ("B4", 1), ("C5", .5), ("B4", .5), ("A4", .5), ("G4", .5),
    ("B4", 1.5), ("C5", .5), ("D5", 1),
    ("E5", .5), ("C5", .5), ("B4", 1), ("A4", 1),
    ("G4", 3),
]
COUNTRY_ROOTS = ["G", "D", "G", "G", "D", "G", "G", "G", "C", "D", "G", "G", "C", "G"]

ANTHEM_ROOTS_A = ["Bb", "Bb", "Bb", "C", "F", "F", "F", "Bb", "Bb"]
ANTHEM_ROOTS_B = ["Bb", "Bb", "F", "C", "Eb", "Bb", "F", "C", "F",
                  "Bb", "G", "C", "F", "Bb", "Bb", "F", "Bb"]

TRIAD = {  # major triads by root (enough for these tunes)
    "C": ["C", "E", "G"], "D": ["D", "F#", "A"], "Eb": ["Eb", "G", "Bb"],
    "E": ["E", "G#", "B"], "F": ["F", "A", "C"], "G": ["G", "B", "D"],
    "A": ["A", "C#", "E"], "Bb": ["Bb", "D", "F"],
}


def lay_line(song, start, line, duty=0.25, gain=0.21, oct_=0):
    b = start
    for note, beats in line:
        if note is not None:
            n = note_name(num(note) + 12 * oct_)
            song.lead(b, n, beats * 0.92, duty=duty, gain=gain, vib=beats >= 2)
        b += beats
    return b


def lay_roots(song, start, roots, bar, gain=0.30, chord_gain=0.07, march=True):
    """Bass on the root, march-style (root on 1, fifth on the off beat), and a
    soft held chord on the second pulse so the tune never stands alone."""
    for i, r in enumerate(roots):
        at = start + i * bar
        root = r + "2"
        fifth = TRIAD[r][2] + ("2" if TRIAD[r][2] in ("C", "D", "Eb", "E") and r not in ("C", "D") else "2")
        song.bass(at, root, bar * 0.5 if march else bar * 0.95, gain)
        if march:
            song.bass(at + bar * 0.5, fifth, bar * 0.45, gain * 0.85)
        song.chord(at, [t + "4" for t in TRIAD[r]], bar * 0.9, duty=0.5, gain=chord_gain, chan="p2")


def drums(song, start, bars, bar, roll_every=4):
    """A parade drum: kick on the downbeat, snare on the backbeat, a roll into
    every fourth bar."""
    for i in range(bars):
        at = start + i * bar
        song.kick(at, gain=0.42)
        if bar >= 4:
            song.snare(at + 1, gain=0.20)
            song.kick(at + 2, gain=0.30)
            song.snare(at + 3, gain=0.22)
        else:
            for k in range(1, int(bar)):
                song.snare(at + k, gain=0.18)
        for h in np.arange(0.0, bar, 0.5):
            song.hat(at + float(h), gain=0.05)
        if (i + 1) % roll_every == 0:
            for k in range(6):
                song.snare(at + bar - 0.75 + k * 0.125, gain=0.12 + 0.02 * k)


def beats_of(line):
    return sum(b for _, b in line)


def anthem():
    bar = 3.0
    a, b = beats_of(ANTHEM_A), beats_of(ANTHEM_B)
    total = 1.0 + a * 2 + b + 1.0
    song = Song(84, int(np.ceil(total / 4.0)) + 1)
    t = 1.0
    for _ in range(2):
        t0 = t
        t = lay_line(song, t, ANTHEM_A, duty=0.5, gain=0.21)
        lay_roots(song, t0, ANTHEM_ROOTS_A, bar, march=False)
    t0 = t
    t = lay_line(song, t, ANTHEM_B, duty=0.25, gain=0.22)
    lay_roots(song, t0, ANTHEM_ROOTS_B, bar, march=False)
    drums(song, t0, len(ANTHEM_ROOTS_B), bar, roll_every=8)
    return song, t + 1.0


def yankee():
    bar = 4.0
    once = beats_of(YANKEE)
    song = Song(132, int(np.ceil(once * 3 / 4.0)) + 1)
    t = 0.0
    for k in range(3):
        t0 = t
        t = lay_line(song, t, YANKEE, duty=0.25 if k != 1 else 0.125, gain=0.21, oct_=1 if k == 2 else 0)
        if k == 1:
            lay_line(song, t0, YANKEE, duty=0.5, gain=0.09, oct_=-1)
        lay_roots(song, t0, YANKEE_ROOTS, bar)
        drums(song, t0, len(YANKEE_ROOTS), bar)
    return song, t


def country():
    bar = 3.0
    once = beats_of(COUNTRY)
    song = Song(96, int(np.ceil(once * 2 / 4.0)) + 1)
    t = 0.0
    for k in range(2):
        t0 = t
        t = lay_line(song, t, COUNTRY, duty=0.5 if k == 0 else 0.25, gain=0.21)
        lay_roots(song, t0, COUNTRY_ROOTS, bar, march=False)
        if k == 1:
            drums(song, t0, len(COUNTRY_ROOTS), bar, roll_every=7)
    return song, t


# ------------------------------------------------------------- from MIDI
def from_midi(path, seconds_cap=150.0, bpm_scale=1.0):
    """A piano score as NES voices: the top note of the right hand is the lead,
    the bottom of the left hand the triangle bass, the rest of the right hand a
    soft second pulse. Drums follow the bar."""
    import mido
    m = mido.MidiFile(path)
    tpb = m.ticks_per_beat
    tempo = 500000
    num_, den_ = 4, 4
    events = []
    for tr in m.tracks:
        t = 0
        on = {}
        for msg in tr:
            t += msg.time
            if msg.type == "set_tempo" and tempo == 500000:
                tempo = msg.tempo
            if msg.type == "time_signature":
                num_, den_ = msg.numerator, msg.denominator
            if msg.type == "note_on" and msg.velocity > 0:
                on[msg.note] = t
            elif msg.type in ("note_off", "note_on") and msg.note in on:
                s = on.pop(msg.note)
                events.append((s / tpb, (t - s) / tpb, msg.note, tr.name.strip(": ").lower()))
    bpm = 60_000_000 / tempo * bpm_scale
    total_beats = max(s + d for s, d, _, _ in events)
    total_beats = min(total_beats, seconds_cap * bpm / 60.0)
    song = Song(bpm, int(np.ceil(total_beats / 4.0)) + 1)
    by_start = {}
    for s, d, n, trk in events:
        if s >= total_beats:
            continue
        by_start.setdefault((round(s, 3), trk), []).append((n, d))
    for (s, trk), notes in sorted(by_start.items()):
        notes.sort()
        if trk.startswith("upper"):
            top_n, top_d = notes[-1]
            song.lead(s, note_name(top_n), max(0.12, min(top_d, 4.0)) * 0.92, duty=0.25, gain=0.20)
            if len(notes) > 1:
                n2, d2 = notes[-2]
                song.lead(s, note_name(n2), max(0.12, min(d2, 4.0)) * 0.85, duty=0.5, gain=0.07, chan="p2")
        else:
            lo_n, lo_d = notes[0]
            while lo_n > 52:
                lo_n -= 12
            song.bass(s, note_name(lo_n), max(0.12, min(lo_d, 2.0)) * 0.9, gain=0.28)
    beat_unit = 4.0 / den_
    bar = num_ * beat_unit
    bars = int(total_beats // bar)
    for i in range(bars):
        at = i * bar
        song.kick(at, gain=0.36)
        song.snare(at + bar / 2.0, gain=0.17)
        for h in np.arange(0.0, bar, bar / 4.0):
            song.hat(at + float(h), gain=0.04)
    return song, total_beats


def finish(song, end_beat):
    """Mix, trim to the last note plus a breath, fade the very end."""
    mono = song.mix(loop=False)
    end = min(len(mono), int((end_beat * song.spb + 0.6) * SR))
    mono = mono[:end].copy()
    f = int(0.5 * SR)
    mono[-f:] *= np.linspace(1.0, 0.0, f).astype(np.float32)
    return mono


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "/tmp/usa"
    mid = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "midi")
    os.makedirs(out, exist_ok=True)
    jobs = {
        "anthem": anthem,
        "country": country,
        "stripes": lambda: from_midi(os.path.join(mid, "stars_stripes.mid")),
        "liberty": lambda: from_midi(os.path.join(mid, "TheLibertyBell.mid")),
    }
    only = sys.argv[3] if len(sys.argv) > 3 else None
    for name, fn in jobs.items():
        if only and name != only:
            continue
        song, end = fn()
        mono = finish(song, end)
        write_wav(os.path.join(out, "usa_%s.wav" % name), mono)
        print("usa_%-8s %5.1f s" % (name, len(mono) / SR))
