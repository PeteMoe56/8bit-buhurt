#!/usr/bin/env bash
## A DEBUG APK FOR A PHONE, FROM LINUX (2 Oct 2026). The repo's Android preset
## is the Play build (gradle, AAB); this copies the project to a scratch folder,
## flips the copy's preset to a plain APK, turns on ETC2/ASTC there, and exports
## it signed with a throwaway debug keystore. The repo itself is not touched.
##
##   bash tools/apk_debug.sh [out.apk]
##
## Needs: the 4.6.2 Android templates in ~/.local/share/godot/export_templates,
## an Android SDK (build-tools + platform-tools) and a debug keystore, with
## editor_settings pointing at both (export/android/*). No credential is read
## from or written to the repo.
set -euo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-$(command -v godot || echo /tmp/godot462/Godot_v4.6.2-stable_linux.x86_64)}"
out="${1:-/tmp/combat-club-debug.apk}"
work="$(mktemp -d /tmp/rbapk.XXXX)"
cp -a . "$work/p"
rm -rf "$work/p/.git" "$work/p/logs" "$work/p/build"
python3 - "$work/p" <<'PY'
import sys
root = sys.argv[1]
p = root + "/export_presets.cfg"; s = open(p).read()
for a, b in [("gradle_build/use_gradle_build=true", "gradle_build/use_gradle_build=false"),
             ("gradle_build/export_format=1", "gradle_build/export_format=0"),
             ('gradle_build/min_sdk="24"', 'gradle_build/min_sdk=""'),
             ('gradle_build/target_sdk="36"', 'gradle_build/target_sdk=""')]:
    assert a in s, a
    s = s.replace(a, b, 1)
open(p, "w").write(s)
p = root + "/project.godot"; s = open(p).read()
## The billing plugin is a gradle-only (v2) plugin; a plain APK cannot carry it,
## so the desk copy leaves it off and Store says "no billing" on screen.
import re
s = re.sub(r"\n\[editor_plugins\]\n\nenabled=PackedStringArray\([^)]*\)\n", "\n", s)
if "import_etc2_astc" not in s:
    s = s.replace("[rendering]\n", "[rendering]\n\ntextures/vram_compression/import_etc2_astc=true\n", 1)
open(p, "w").write(s)
PY
mkdir -p "$work/p/build"
"$G" --headless --path "$work/p" --export-debug "Android" "$work/p/build/debug.apk" 2>&1 | grep -E "ERROR|DONE" || true
cp "$work/p/build/debug.apk" "$out"
rm -rf "$work"
ls -la "$out"
