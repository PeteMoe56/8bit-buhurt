#!/usr/bin/env bash
## THE LEARNER, save after save. Usage: run_learner.sh <out_dir> <saves> [max_seasons] [steps_per_save]
cd "$(dirname "$0")/../.."
d="${1:?out}"; n="${2:-30}"; ms="${3:-15}"; st="${4:-150000}"
mkdir -p "$d"
for i in $(seq 0 $((n-1))); do
  /tmp/godot462/Godot_v4.6.2-stable_linux.x86_64 --headless --fixed-fps 60 --path . \
    --script res://tools/novice/novice_bot.gd -- learner $((1000+i)) "$st" "$d/save_$i.jsonl" "$d/values.json" "$i" "$ms" 2>&1 \
    | grep -E "^novice|SCRIPT ERROR" >> "$d/run.log"
  if grep -q '"worlds_won"' "$d/save_$i.jsonl"; then echo "WORLDS on save $i" >> "$d/run.log"; fi
done
echo DONE >> "$d/run.log"
