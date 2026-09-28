#!/usr/bin/env bash
## THE NOISE FLOOR — the same game, scored against different worlds.
##
##   bash tools/noise.sh > noise.tsv
##
## Every number `tools/sweep.sh` prints is one sample of a stochastic career, and
## a sweep that does not know its own noise floor will confidently recommend
## whichever value got lucky. This changes NOTHING and scores the game eight
## times on eight different seed bases; the spread is what a result has to beat
## before it means anything.
set -u
G="${GODOT:-/tmp/godot462/Godot_v4.6.2-stable_linux.x86_64}"
## THIS project by default, wherever it is checked out.
LANE="${LANE:-$(cd "$(dirname "$0")/.." && pwd)}"
SEEDS="${SEEDS:-5}"
YEARS="${YEARS:-14}"
fails=0
printf 'base\ttitle\tt1\tt2\tt3\ttier\tpower\tcc\tworlds\tyouth_title\tyouth_t3\n'
for B in 4242 90210 31337 777 24601 1848 606060 13131; do
  OUT="$("$G" --headless --path "$LANE" --script res://tools/career_score.gd -- "$SEEDS" "$YEARS" "$B" 2>/dev/null | grep '^SCORE')"
  ## A FAILED RUN IS REPORTED, NOT DROPPED. It used to `continue` quietly, so a
  ## wrong path printed a header and nothing and exited 0.
  if [ -z "$OUT" ]; then printf '%s\tFAILED\n' "$B"; fails=$((fails+1)); continue; fi
  printf '%s\t%s\n' "$B" "$(printf '%s' "$OUT" | sed -E 's/^SCORE //; s/[a-z_0-9]+=//g; s/ +/\t/g')"
done
[ "$fails" -eq 0 ] || { echo "noise: $fails base(s) failed" >&2; exit 1; }
