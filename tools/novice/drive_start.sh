#!/usr/bin/env bash
## Start the driver in the background. Usage: drive_start.sh <dir> [seed]
cd "$(dirname "$0")/../.."
d="${1:?dir}"; sd="${2:-11}"; mkdir -p "$d"; rm -f "$d"/*
nohup xvfb-run -a /tmp/godot462/Godot_v4.6.2-stable_linux.x86_64 --audio-driver Dummy --path . \
  --resolution 960x540 --script res://tools/novice/drive.gd -- "$d" "$sd" > "$d/godot.log" 2>&1 &
for i in $(seq 1 300); do [ -f "$d/ready.txt" ] && { echo "PICTURE: $d/state_1.png"; cat "$d/state_1.json"; exit 0; }; sleep 0.2; done
echo "driver did not start"; tail -20 "$d/godot.log"; exit 1
