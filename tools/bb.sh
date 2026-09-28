#!/usr/bin/env bash
## THE TOOLBOX. One door to every tool in this folder, so a session reaches for a
## command instead of writing a new one-off script.
##
##   bash tools/bb.sh test [--fast|--balance|--all] [tests/test_x.gd ...]
##   bash tools/bb.sh score [seeds] [years] [base]    one career score line
##   bash tools/bb.sh bases [seeds] [years]           score on the five check bases + mean
##   bash tools/bb.sh titles [seeds] [years] [base]   trophies a career wins, by kind
##   bash tools/bb.sh probe <name> [args...]          tools/probe_<name>.gd
##   bash tools/bb.sh shot <name> [WxH] [args...]     tools/shot_<name>.gd under xvfb
##   bash tools/bb.sh soak [args...]                  tools/soak.gd
##   bash tools/bb.sh monkey [steps] [seeds...]       random taps through the real screens
##   bash tools/bb.sh fixture                         write tests/fixtures/save_v<N>.dat
##   bash tools/bb.sh strings                         refresh locale/strings.csv
##   bash tools/bb.sh sweep < plan.tsv | tune | noise the balance sweepers
##   bash tools/bb.sh list                            every probe and shot, one line each
##
## The engine is $GODOT, else the first Godot 4.6.2 found in the usual places.
## Every command prints the engine it used; a number from the wrong engine is a
## number about a different game.
set -u
cd "$(dirname "$0")/.."
G="${GODOT:-}"
if [ -z "$G" ]; then
  for c in /tmp/godot462/Godot_v4.6.2-stable_linux.x86_64 \
           "$(command -v godot 2>/dev/null)" "$(command -v godot4 2>/dev/null)"; do
    [ -n "$c" ] && [ -x "$c" ] && G="$c" && break
  done
fi
export GODOT="$G"
need_godot() { [ -x "${G:-}" ] || { echo "No Godot binary. Set GODOT=/path/to/godot." >&2; exit 2; }; }
run() { need_godot; "$G" --headless --path . --script "res://$1" -- "${@:2}" 2>&1 | grep -v '^Godot Engine\|^$'; }

## The five seed bases every pacing number since 16 Sep has been checked on.
BASES="9001 5150 2718 6060 8123"

cmd="${1:-help}"; shift || true
case "$cmd" in
  test)    exec bash tools/run_tests.sh "$@" ;;
  score)   run tools/career_score.gd "${1:-5}" "${2:-20}" "${3:-9001}" ;;
  bases)
    need_godot
    echo "engine: $("$G" --version | head -1)"
    sum=0; n=0
    for b in $BASES; do
      line="$(run tools/career_score.gd "${1:-5}" "${2:-20}" "$b" | grep '^SCORE')"
      echo "$b  ${line#SCORE }"
      t="$(echo "$line" | grep -oE 'title=[0-9.]+' | cut -d= -f2)"
      [ -n "$t" ] && sum="$(awk -v a="$sum" -v b="$t" 'BEGIN{print a+b}')" && n=$((n+1))
    done
    [ "$n" -gt 0 ] && awk -v s="$sum" -v n="$n" 'BEGIN{printf "mean title %.2f over %d bases\n", s/n, n}'
    ;;
  titles)  run tools/probe_worlds.gd "${1:-5}" "${2:-20}" "${3:-9001}" ;;
  probe)
    f="tools/probe_${1:?probe name}.gd"; [ -f "$f" ] || { echo "no $f" >&2; exit 1; }
    run "$f" "${@:2}" ;;
  shot)
    need_godot
    f="tools/shot_${1:?shot name}.gd"; [ -f "$f" ] || { echo "no $f" >&2; exit 1; }
    ## The shot tools save under res://shots and none of them creates it.
    mkdir -p shots
    res="${2:-960x540}"
    xvfb-run -a "$G" --audio-driver Dummy --path . --resolution "$res" --script "res://$f" -- "${@:3}" 2>&1 \
      | grep -v '^Godot Engine\|^$\|ALSA' ;;
  soak)    run tools/soak.gd "$@" ;;
  monkey)
    need_godot
    steps="${1:-4000}"; shift || true
    seeds="${*:-7}"; bad=0
    for sd in $seeds; do
      out="$("$G" --headless --fixed-fps 60 --path . --script res://tools/monkey.gd -- "$steps" "$sd" 2>&1)"
      echo "$out" | grep -E 'SCRIPT ERROR|PROBLEM|^monkey|MONKEY|screens visited' 
      echo "$out" | grep -q 'SCRIPT ERROR\|PROBLEM' && bad=1
    done
    exit $bad ;;
  fixture) run tools/make_save_fixture.gd ;;
  strings) python3 tools/extract_strings.py ;;
  sweep)   exec bash tools/sweep.sh "$@" ;;
  tune)    exec python3 tools/tune.py "$@" ;;
  noise)   exec bash tools/noise.sh "$@" ;;
  list)
    for f in tools/probe_*.gd tools/shot_*.gd tools/diag_*.gd tools/mock_*.gd; do
      [ -f "$f" ] || continue
      doc="$(grep -m1 '^## ' "$f" | sed 's/^## //')"
      printf '%-32s %s\n' "$(basename "$f" .gd)" "${doc:0:90}"
    done ;;
  *) sed -n '2,20p' "$0" | sed 's/^## \{0,1\}//' ;;
esac
