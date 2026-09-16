#!/usr/bin/env bash
## SWEEP ONE TUNABLE AND SCORE THE CAREER AT EACH VALUE.
##
##   bash tools/sweep.sh < plan.tsv > results.tsv
##
## Pete, 15 Sep 2026: *"We should be gathering all the possible variables of this
## including every price and I want to find some balancing... Each variable
## deserves its own test so we can see some graphed out areas where a good
## throughput of an experience can be had by players."*
##
## GDScript constants cannot be changed at run time, so a sweep either converts
## every tunable to a `static var` — which is a large edit to shipping code made
## for the benefit of a measurement — or it rewrites the source between runs.
## This rewrites, and it does it on a COPY of the project under /tmp, so the real
## tree is never modified and a crash mid-sweep cannot leave a constant in a
## state nobody intended. `tools/career_score.gd` scores a whole career in about
## two seconds, which is what makes the brute-force version affordable at all.
##
## The plan file is one line per point: NAME <tab> FILE <tab> VALUE.
set -u
G="${GODOT:-/tmp/godot462/Godot_v4.6.2-stable_linux.x86_64}"
SRC="$(cd "$(dirname "$0")/.." && pwd)"
LANE="${LANE:-/tmp/sweeplane}"
SEEDS="${SEEDS:-3}"
YEARS="${YEARS:-14}"

## ONE COPY, MADE ONCE. `.git` and the art are excluded: the art is 140MB of
## PNGs no headless career sim ever opens, and `.godot` IS copied because it
## carries the import cache and the global class table — without it every single
## run pays a re-import.
if [ ! -d "$LANE" ]; then
  mkdir -p "$LANE"
  tar -C "$SRC" --exclude=.git --exclude='art/*' -cf - . | tar -C "$LANE" -xf -
fi

printf 'var\tvalue\ttitle\tt1\tt2\tt3\ttier\tpower\tcc\tworlds\tyouth_title\tyouth_t3\n'
while IFS=$'\t' read -r NAME FILE VALUE; do
  [ -z "${NAME:-}" ] && continue
  case "$NAME" in \#*) continue ;; esac
  F="$LANE/$FILE"
  ## The original line is kept verbatim and put back after the run, so a sweep of
  ## twenty values leaves the file exactly as it started rather than twenty
  ## edits deep.
  BEFORE="$(grep -nE "^const ${NAME}\b" "$F" | head -1)"
  if [ -z "$BEFORE" ]; then
    echo "MISSING	$NAME	$FILE" >&2
    continue
  fi
  LN="${BEFORE%%:*}"
  ORIG="$(sed -n "${LN}p" "$F")"
  ## Replace only what is after the `=`, so the declared type and any trailing
  ## comment on the line are preserved — a sweep that rewrites the whole line
  ## silently drops `: float` and turns 0.5 into an int.
  NEW="$(printf '%s' "$ORIG" | sed -E "s/= *[^#]*/= ${VALUE} /")"
  printf '%s\n' "$NEW" > /tmp/sweepline
  sed -i "${LN}r /tmp/sweepline" "$F"
  sed -i "${LN}d" "$F"
  OUT="$("$G" --headless --path "$LANE" --script res://tools/career_score.gd -- "$SEEDS" "$YEARS" 2>/dev/null | grep '^SCORE')"
  printf '%s\n' "$ORIG" > /tmp/sweepline
  sed -i "${LN}r /tmp/sweepline" "$F"
  sed -i "${LN}d" "$F"
  if [ -z "$OUT" ]; then
    echo "FAILED	$NAME	$VALUE" >&2
    continue
  fi
  VALS="$(printf '%s' "$OUT" | sed -E 's/^SCORE //; s/[a-z_0-9]+=//g; s/ +/\t/g')"
  printf '%s\t%s\t%s\n' "$NAME" "$VALUE" "$VALS"
done
