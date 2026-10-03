#!/usr/bin/env bash
## A PLAY BUNDLE (AAB) FROM A SCRATCH COPY (2 Oct 2026). Installs Godot's
## Android build template into the copy (it is not committed), then exports the
## "Android" preset as it stands: gradle, AAB, API 36, the billing plugin.
##
##   bash tools/aab_release.sh [out.aab]            # release, needs the key below
##   AAB_DEBUG=1 bash tools/aab_release.sh out.aab  # debug-signed, for a smoke test
##
## THE UPLOAD KEY COMES FROM THE ENVIRONMENT, never from the repo:
##   GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD
## (Codemagic sets these from its encrypted keystore; on a desk, export them in
## the shell). tests/test_export.gd fails if a key field lands in the preset.
set -euo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-$(command -v godot || echo /tmp/godot462/Godot_v4.6.2-stable_linux.x86_64)}"
out="$(python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "${1:-build/combat-club.aab}")"
work="$(mktemp -d "${TMPDIR:-/tmp}/rbaab.XXXX")"
cp -a . "$work/p"
rm -rf "$work/p/.git" "$work/p/logs" "$work/p/build" "$work/p/android"
mkdir -p "$work/p/build" "$(dirname "$out")"
## VERSION_CODE / VERSION_NAME, when set, go into the COPY's preset (Codemagic
## passes Play's latest + 1). The tracked preset keeps its own numbers.
## perl, not sed -i: the same line runs on Linux and on Codemagic's Mac.
if [ -n "${VERSION_CODE:-}" ]; then perl -pi -e "s/^version\/code=.*/version\/code=${VERSION_CODE}/" "$work/p/export_presets.cfg"; fi
if [ -n "${VERSION_NAME:-}" ]; then perl -pi -e "s/^version\/name=.*/version\/name=\"${VERSION_NAME}\"/" "$work/p/export_presets.cfg"; fi
"$G" --headless --path "$work/p" --import >/dev/null 2>&1 || true
if [ "${AAB_DEBUG:-0}" = 1 ]; then mode=--export-debug; else
  : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?set the upload keystore path}"
  : "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?set the key alias}"
  : "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?set the keystore password}"
  mode=--export-release; fi
## --install-android-build-template only works alongside an export (alone it
## runs the game and never returns).
"$G" --headless --path "$work/p" --install-android-build-template $mode "Android" "$work/p/build/out.aab" 2>&1 | grep -E "ERROR|DONE|BUILD|FAIL" || true
test -f "$work/p/build/out.aab" || { echo "no bundle was made"; exit 1; }
cp "$work/p/build/out.aab" "$out"
rm -rf "$work"
ls -la "$out"
