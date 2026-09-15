#!/usr/bin/env bash
## The whole suite, in one go.
##
##   bash tools/run_tests.sh
##
## The timeout is 900s per test and NOT 300s, because test_melee.gd takes
## 8m20s on its own — 40 bouts a measure, thirteen measures. A 300s cap
## killed it mid-run and the suite printed fourteen greens' worth of
## nothing without saying a word. A harness that can silently drop a test
## is worse than no harness.
set -u
G="${GODOT:-/tmp/godot/Godot_v4.6-stable_linux.x86_64}"
cd "$(dirname "$0")/.."
"$G" --headless --path . --import >/dev/null 2>&1

fails=0
ran=0

## EVERY SCRIPT PARSES, TOOLS INCLUDED.
##
## A tool that no longer compiles fails loudly the moment anybody runs it, which
## sounds self-correcting and is the opposite: nobody runs it, so nobody sees it,
## and it rots. `shot_menus.gd` sat broken against a facility enum that had moved
## underneath it for long enough that nothing in the repo remembered. `--check-only`
## parses without running, so this costs a second and covers what no test does:
## the tools themselves.
echo "=== every script parses"
parse_bad=0
for f in $(find scripts tools tests -name '*.gd' | sort); do
  if timeout 40 "$G" --headless --check-only --script "res://$f" 2>&1 | grep -q "Parse Error"; then
    echo "PARSE ERROR: $f"
    parse_bad=$((parse_bad+1))
  fi
done
ran=$((ran+1))
if [ "$parse_bad" -ne 0 ]; then
  echo "FAILED: $parse_bad script(s) do not parse"
  fails=$((fails+1))
else
  echo "all scripts parse"
fi
for t in tests/test_*.gd; do
  ## `test_shapes.gd` needs a real display and a stated resolution — headless
  ## hands it 960x960, which is not a shape any device has. It runs below.
  [ "$t" = "tests/test_shapes.gd" ] && continue
  echo "=== $t"
  timeout 900 "$G" --headless --path . --script "res://$t" 2>&1 \
    | grep -Ev '^(Godot Engine|--- Debug|Vulkan|OpenGL|TextServer|WARNING|ERROR: Condition "\(uint32_t\)|  |$)'
  rc=${PIPESTATUS[0]}
  ran=$((ran+1))
  if [ "$rc" -eq 124 ]; then echo "TIMED OUT: $t"; fails=$((fails+1))
  elif [ "$rc" -ne 0 ]; then echo "FAILED: $t"; fails=$((fails+1)); fi
done

## AND THE INK SWEEP AGAIN, IN THE SHAPES A HANDSET ACTUALLY HANDS THE GAME.
##
## `stretch/aspect = "expand"` does not letterbox: a 19.5:9 phone gives the game
## 1170x540, a 21:9 phone 1260x540, a 4:3 tablet 960x720. Every check in this
## suite had only ever rendered 960x540 — which is the one shape no phone has —
## so a layout that stopped three-quarters of the way across the screen was
## invisible to all of it. Needs a real display, hence xvfb; skipped with a
## printed reason rather than silently if there is none, because **a check that
## can be skipped quietly is a check nobody is running.**
if command -v xvfb-run >/dev/null 2>&1; then
  for res in 960x540 1170x540 1260x540 960x720; do
    for t in tests/test_ink.gd tests/test_shapes.gd; do
      echo "=== $t @ $res"
      timeout 900 xvfb-run -a "$G" --path . --resolution "$res" --script "res://$t" 2>&1 \
        | grep -Ev '^(Godot Engine|--- Debug|Vulkan|OpenGL|TextServer|WARNING|ERROR|ALSA|  |$)'
      rc=${PIPESTATUS[0]}
      ran=$((ran+1))
      if [ "$rc" -ne 0 ]; then echo "FAILED: $t @ $res"; fails=$((fails+1)); fi
    done
  done
else
  echo "SKIPPED the shape sweep: no xvfb-run on this machine"
  fails=$((fails+1))
fi

echo ""
if [ "$fails" -eq 0 ]; then echo "SUITE GREEN — $ran files"; exit 0; fi
echo "SUITE RED — $fails of $ran files"; exit 1
