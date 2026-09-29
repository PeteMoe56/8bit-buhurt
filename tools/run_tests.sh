#!/usr/bin/env bash
## The suite.
##
##   bash tools/run_tests.sh              fast gate (default) — every file, fast tier
##   bash tools/run_tests.sh --balance    the statistical tier (slow; nightly / before tuning ships)
##   bash tools/run_tests.sh --all        both
##   bash tools/run_tests.sh tests/test_save.gd [more files]   just those, fast tier
##
## A FILE PASSES ONLY IF ALL FOUR HOLD:
##   1. it exits 0 inside its timeout;
##   2. it printed its banner — "... HOLD(S) (N checks)" — with N > 0;
##   3. no `SCRIPT ERROR` / `Parse Error` anywhere in its output — a runtime error
##      kills the function it is in and the rest of the file carries on to a
##      green exit, which is how test_save asserted nothing for a fortnight;
##   4. no engine `ERROR:` line that is not on tests/allowed_errors.txt.
## Full output of every file is kept in logs/tests/<file>.log; the console gets
## the banner, the FAILs, and the reason a file was failed.
##
## TIERS. `RB_TIER=fast|balance` is exported to every test. A test with a slow
## statistical measure reads `OS.get_environment("RB_TIER")` and runs that measure
## only in the balance tier — so tuning work cannot turn the everyday gate red,
## and the everyday gate stays a couple of minutes. The balance tier is not
## optional: run it before any balance change is committed.
##
## Check `uptime` before trusting any timing: a busy machine doubles everything.
set -u
G="${GODOT:-}"
if [ -z "$G" ]; then
  for c in /tmp/godot462/Godot_v4.6.2-stable_linux.x86_64 \
           /tmp/godot/Godot_v4.6-stable_linux.x86_64; do
    [ -x "$c" ] && G="$c" && break
  done
fi
[ -x "${G:-}" ] || { echo "No Godot binary. Set GODOT=/path/to/godot." >&2; exit 2; }
cd "$(dirname "$0")/.."

TIER=fast
FILES=()
for a in "$@"; do
  case "$a" in
    --balance) TIER=balance ;;
    --all) TIER=all ;;
    --fast) TIER=fast ;;
    *) FILES+=("$a") ;;
  esac
done

echo "engine: $("$G" --version 2>&1 | head -1)   ($G)   tier: $TIER   load: $(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null || uptime)"
"$G" --headless --path . --import >/dev/null 2>&1

LOGS=logs/tests
mkdir -p "$LOGS"
ALLOW=tests/allowed_errors.txt
fails=0
ran=0
failed_names=()

## Judge one file's log. Echoes a reason and returns 1 if it failed.
judge() {
  local log="$1" rc="$2"
  if [ "$rc" -eq 124 ]; then echo "timed out"; return 1; fi
  if grep -q -E "SCRIPT ERROR|Parse Error" "$log"; then
    echo "script error: $(grep -m1 -E 'SCRIPT ERROR|Parse Error' "$log" | cut -c1-140)"; return 1
  fi
  local errs
  ## "N resources still in use at exit" is reported separately as a WARN (see
  ## run_one): headless, the audio server still holds a stream's playback when
  ## quit() tears the tree down, so it is shutdown ordering, not a leak in play.
  errs="$(grep -E '^ERROR:' "$log" | grep -v 'resources still in use at exit' \
    | grep -v -F -f <(grep -v '^#' "$ALLOW" | sed '/^$/d') 2>/dev/null)"
  if [ -n "$errs" ]; then
    echo "engine error: $(echo "$errs" | head -1 | cut -c1-140) ($(echo "$errs" | wc -l) lines)"; return 1
  fi
  if [ "$rc" -ne 0 ]; then echo "exit $rc"; return 1; fi
  local n
  n="$(grep -oE 'HOLDS? \(([0-9]+) checks\)' "$log" | tail -1 | grep -oE '[0-9]+')"
  if [ -z "$n" ] || [ "$n" -eq 0 ]; then echo "no banner / zero checks"; return 1; fi
  return 0
}

run_one() {
  ## $1 test path, $2 tier, $3 label, rest: extra godot args (before --script)
  local t="$1" tier="$2" label="$3"; shift 3
  local name log start rc why
  name="$(basename "$t" .gd)"
  log="$LOGS/${name}${label:+@$label}.$tier.log"
  start=$SECONDS
  RB_TIER="$tier" timeout 900 "$@" --path . --script "res://$t" >"$log" 2>&1
  rc=$?
  ran=$((ran+1))
  local secs=$((SECONDS-start))
  if why="$(judge "$log" "$rc")"; then
    printf "  ok   %-34s %4ss  %s\n" "$name${label:+ @$label}" "$secs" "$(grep -oE 'HOLDS? \([0-9]+ checks\)' "$log" | tail -1)"
    grep -m1 'resources still in use at exit' "$log" | sed 's/^ERROR: /         WARN at exit: /' 
  else
    printf "  FAIL %-34s %4ss  %s\n" "$name${label:+ @$label}" "$secs" "$why"
    grep -E '^FAIL' "$log" | head -8 | sed 's/^/         /'
    fails=$((fails+1)); failed_names+=("$name${label:+@$label}")
  fi
}

## EVERY SCRIPT PARSES, TOOLS INCLUDED — in one engine (29 Sep 2026).
## This used to launch the engine once per file with --check-only: 235 launches,
## about twelve minutes of a fifteen-minute gate. `tools/parse_all.gd` loads
## every script inside the project, where every class_name resolves as it does
## in the game, and the engine prints Parse / Compile Error per file. The file
## must also print its PARSED line, so a crash part-way is a failure.
if [ ${#FILES[@]} -eq 0 ]; then
  echo "=== every script parses"
  plog="$LOGS/parse_all.log"
  timeout 300 "$G" --headless --path . --script res://tools/parse_all.gd >"$plog" 2>&1
  prc=$?
  ran=$((ran+1))
  if [ $prc -ne 0 ] || grep -q -E "Parse Error|Compile Error|SCRIPT ERROR" "$plog" || ! grep -q "^PARSED" "$plog"; then
    grep -E "DOES NOT PARSE|Parse Error|Compile Error|SCRIPT ERROR" "$plog" | head -20
    echo "FAILED: parse sweep (rc $prc)   log: $plog"; fails=$((fails+1)); failed_names+=("parse")
  else
    echo "  ok   all scripts parse ($(grep -oE 'PARSED [0-9]+' "$plog" | grep -oE '[0-9]+') in one engine)"
  fi
fi

tiers=()
case "$TIER" in fast) tiers=(fast) ;; balance) tiers=(balance) ;; all) tiers=(fast balance) ;; esac

if [ ${#FILES[@]} -gt 0 ]; then list=("${FILES[@]}"); else list=(tests/test_*.gd); fi

for tier in "${tiers[@]}"; do
  echo "=== $tier tier"
  for t in "${list[@]}"; do
    ## test_shapes needs a real display; it runs in the shape sweep below.
    [ "$(basename "$t")" = "test_shapes.gd" ] && continue
    ## The balance tier only re-runs files that have a balance tier. A file marked
    ## "RB_TIER: balance-only" is listed, not run, in the fast tier.
    if [ "$tier" = balance ] && ! grep -q 'RB_TIER' "$t"; then continue; fi
    if [ "$tier" = fast ] && grep -q 'RB_TIER: balance-only' "$t"; then
      printf "  --   %-34s        balance tier only\n" "$(basename "$t" .gd)"; continue
    fi
    run_one "$t" "$tier" "" "$G" --headless
  done
done

## THE SHAPE SWEEP — the screens at the shapes a handset hands the game.
## `stretch/aspect = "expand"` does not letterbox, so 960x540 is the one shape no
## phone has. Needs a display, hence xvfb. Missing xvfb is a failure, not a skip.
if [ ${#FILES[@]} -eq 0 ] && [ "$TIER" != balance ]; then
  echo "=== shape sweep"
  if command -v xvfb-run >/dev/null 2>&1; then
    for res in 960x540 1170x540 1260x540 960x720; do
      for t in tests/test_ink.gd tests/test_shapes.gd; do
        run_one "$t" fast "$res" xvfb-run -a "$G" --audio-driver Dummy --resolution "$res"
      done
    done
  else
    echo "  FAIL shape sweep: no xvfb-run on this machine"; fails=$((fails+1)); failed_names+=("shape-sweep")
  fi
fi

## THE LANGUAGE SWEEP (29 Sep 2026) — the drawn text and the controls in every
## draft language, at 960 wide, the narrowest shape a phone hands us. English
## fit every box because English is what the boxes were measured on; the French
## and German drafts ran 60 strings off panels, out of columns and under
## buttons. Run in parallel (each is a separate engine) and judged exactly as
## run_one judges. RB_LOCALE pins the file; see test_ink / test_layout.
if [ ${#FILES[@]} -eq 0 ] && [ "$TIER" != balance ]; then
  echo "=== language sweep @960x540"
  if command -v xvfb-run >/dev/null 2>&1; then
    locs=(es fr de it pt_BR pl ru ja)
    pids=()
    n=0
    for loc in "${locs[@]}"; do
      for t in test_ink test_layout; do
        n=$((n+1))
        ## test_layout measures nodes and runs headless, as it does in the main
        ## pass. test_ink needs a display — its own number each, because two
        ## `xvfb-run -a` started together can pick the same one and one dies.
        if [ "$t" = test_layout ]; then
          runner=("$G" --headless)
        else
          runner=(xvfb-run -n $((140 + n)) -s "-screen 0 960x540x24" "$G" --audio-driver Dummy --resolution 960x540)
        fi
        ( RB_LOCALE="$loc" RB_TIER=fast timeout 900 "${runner[@]}" --path . --script "res://tests/$t.gd" \
            >"$LOGS/$t@$loc.fast.log" 2>&1; echo $? >"$LOGS/$t@$loc.rc" ) &
        pids+=($!)
      done
    done
    start=$SECONDS
    wait "${pids[@]}"
    for loc in "${locs[@]}"; do
      for t in test_ink test_layout; do
        log="$LOGS/$t@$loc.fast.log"; rc="$(cat "$LOGS/$t@$loc.rc")"; rm -f "$LOGS/$t@$loc.rc"
        ran=$((ran+1))
        if why="$(judge "$log" "$rc")"; then
          printf "  ok   %-34s %4ss  %s\n" "$t @$loc" "$((SECONDS-start))" "$(grep -oE 'HOLDS? \([0-9]+ checks\)' "$log" | tail -1)"
        else
          printf "  FAIL %-34s %4ss  %s\n" "$t @$loc" "$((SECONDS-start))" "$why"
          grep -E '^FAIL' "$log" | head -8 | sed 's/^/         /'
          fails=$((fails+1)); failed_names+=("$t@$loc")
        fi
      done
    done
  else
    echo "  FAIL language sweep: no xvfb-run on this machine"; fails=$((fails+1)); failed_names+=("language-sweep")
  fi
fi

echo ""
## A RUN THAT RAN NOTHING IS NOT GREEN (29 Sep 2026). Naming only
## test_shapes.gd (display-only, skipped in the headless pass) printed
## "SUITE GREEN — 0 runs".
if [ "$ran" -eq 0 ]; then echo "SUITE RED — 0 runs: nothing was run (test_shapes needs the full sweep)"; exit 1; fi
if [ "$fails" -eq 0 ]; then echo "SUITE GREEN — $ran runs ($TIER)   logs: $LOGS/"; exit 0; fi
echo "SUITE RED — $fails of $ran runs: ${failed_names[*]}   logs: $LOGS/"; exit 1
