#!/usr/bin/env bash
## THE BLIND-REVIEW SET (30 Sep 2026): every menu screen plus the fight's, into one
## directory, named the way the reviews have used them.
##   bash tools/shot_review.sh <out_dir>
cd "$(dirname "$0")/.."
d="${1:?out dir}"; mkdir -p "$d" shots
bash tools/bb.sh shot all 960x540 "$d" >/dev/null 2>&1
for t in prefight corner aar bracket_real; do bash tools/bb.sh shot $t 960x540 >/dev/null 2>&1; done
bash tools/bb.sh shot melee 960x540 30 "$d/24_fight_live.png" >/dev/null 2>&1
bash tools/bb.sh shot wheel 960x540 approach "$d/25_contact_wheel.png" >/dev/null 2>&1
cp shots/bracket_live.png "$d/21_bracket.png"
cp shots/prefight_splash.png "$d/23_walkout.png"
cp shots/prefight_plan.png "$d/23b_prefight_plan.png"
cp shots/corner_round.png "$d/26_corner.png"
cp shots/corner_sub.png "$d/27_corner_sub.png"
cp shots/aar.png "$d/28_report.png"
ls "$d" | wc -l
