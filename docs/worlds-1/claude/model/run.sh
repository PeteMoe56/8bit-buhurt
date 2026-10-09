#!/usr/bin/env bash
# run.sh WT NAME BASES...  (5 careers/base, 20 seasons)
wt=$1; name=$2; shift 2
cd /home/claude/$wt && bash tools/bb.sh probe harness_budget ${NC:-5} ${NY:-20} "$@" --out=res://docs/bakeoff-2/harness/wl-$name > /home/claude/wl/$name.log 2>&1
grep '^WORLDS_' /home/claude/wl/$name.log > /home/claude/wl/$name.worlds
find docs/bakeoff-2/harness/wl-$name -name "*.jsonl" -delete
grep HARNESS /home/claude/wl/$name.log
