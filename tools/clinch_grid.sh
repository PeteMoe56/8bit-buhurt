#!/usr/bin/env bash
## CLINCH GRID (29 Sep 2026): for each line of a config file ("name ENV=v ENV=v"),
## the spam edge (probe fightskill gap, n) and the tactics spread (probe tactics, m).
##   bash tools/clinch_grid.sh configs.txt [n=120] [m=40] > out.log
## RB_AI_THROW defaults to 0 here (the old game) unless a line sets it.
cd "$(dirname "$0")/.."
n="${2:-120}"; m="${3:-40}"
while read -r name rest; do
  [ -z "$name" ] && continue
  case "$name" in \#*) continue;; esac
  envs="RB_AI_THROW=0 $rest"
  g="$(env $envs bash tools/bb.sh probe fightskill "$n" gap 2>&1 | grep '^GAP')"
  t="-"
  [ "$m" != "0" ] && t="$(env $envs bash tools/bb.sh probe tactics "$m" 2>&1 | grep 'mean |win' | grep -oE '[0-9.]+$')"
  h=""
  [ -n "$GRID_HELP" ] && h=" | $(env $envs bash tools/bb.sh probe fightskill "$n" help2 2>&1 | grep '^HELP')"
  echo "$name | $rest | $g | tactics $t$h"
done < "$1"
