#!/usr/bin/env bash
## Run the persona bots one after another. Usage: run_bots.sh <out_dir> <steps> <seed> [personas...]
cd "$(dirname "$0")/../.."
d="${1:?out}"; steps="${2:-100000}"; sd="${3:-1}"; shift 3
ps="${*:-wanderer gold simmer spender hoarder}"
mkdir -p "$d"
for p in $ps; do
  /tmp/godot462/Godot_v4.6.2-stable_linux.x86_64 --headless --fixed-fps 60 --path . \
    --script res://tools/novice/novice_bot.gd -- "$p" "$sd" "$steps" "$d/${p}_${sd}.jsonl" 2>&1 \
    | grep -E "^novice|SCRIPT ERROR" >> "$d/run.log"
done
echo DONE >> "$d/run.log"
