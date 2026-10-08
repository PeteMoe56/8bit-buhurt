#!/usr/bin/env bash
## Exactly how every file in this folder was made (8 Oct 2026, US Central).
## Godot 4.6.2.stable.official.71f334935, headless, Linux container, from a
## clone of C:\Dev\RetroBuhurt at d5ce8a9 plus the bake-off #2 commit (which only
## adds policy switches to tools/manager.gd and columns to probe_level_flow.gd;
## with no RB_LV / RB_LV_BOUT / RB_HARNESS set, both behave exactly as before).
G=/tmp/godot462/Godot_v4.6.2-stable_linux.x86_64
CFGS=("auto 0 0" "auto 1 0" "low 0 0" "low 1 0" "spec 0 0" "spec 1 0" "auto 0 1" "spec 1 1")

## flow_policies.tsv — 2 careers x 5 bases x 12 seasons per policy
for cfg in "${CFGS[@]}"; do set -- $cfg
  RB_LV=$1 RB_LV_BOUT=$2 RB_HARNESS=$3 $G --headless --path . \
    --script res://tools/probe_level_flow.gd -- 2 12 | grep '^FLOW' | sed 's/^FLOW\t//'
done   # header kept once

## scores_policies.tsv — career_score.gd, 5 careers x 14 seasons, per base, per policy
for cfg in "${CFGS[@]}"; do set -- $cfg
  for b in 9001 5150 2718 6060 8123; do
    RB_LV=$1 RB_LV_BOUT=$2 RB_HARNESS=$3 bash tools/bb.sh score 5 14 $b | grep '^SCORE'
  done
done

## balance_tier.txt — the statistical gate (C-numbers), policies unset
bash tools/bb.sh test --balance

## summary_by_policy.tsv — means of the two files above, nothing else
python3 tools/bakeoff2_summary.py
