#!/usr/bin/env bash
## One move for the driver (tools/novice/drive.gd): writes the command, waits for
## the next picture, prints the state JSON. Usage: act.sh <dir> <command...>
d="$1"; shift
prev=$(cat "$d/ready.txt" 2>/dev/null || echo 0)
echo "$*" > "$d/cmd.txt.tmp" && mv "$d/cmd.txt.tmp" "$d/cmd.txt"
[ "$1" = "quit" ] && { sleep 1; echo "quit sent"; exit 0; }
for i in $(seq 1 900); do
  now=$(cat "$d/ready.txt" 2>/dev/null)
  if [ -n "$now" ] && [ "$now" != "$prev" ] && [ -f "$d/state_$now.json" ]; then
    sleep 0.05
    echo "PICTURE: $d/state_$now.png"
    cat "$d/state_$now.json"
    exit 0
  fi
  sleep 0.1
done
echo "no answer from the driver"; exit 1
