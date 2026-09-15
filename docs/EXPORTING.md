# Exporting

Written 15 Sep 2026, when the project got its first `export_presets.cfg`. Before
that there was none at all, and `project.godot` had pointed at a `res://icon.svg`
that did not exist since the day it was created — so no build had ever been made,
and nothing in the suite could have told you.

Three presets: **Android**, **Windows Desktop**, **Linux**.

## What is proven and what is not

**Linux is proven.** Exported headless, 90MB, launched, played, quit clean:

```
godot --headless --path . --export-debug "Linux" build/combat-club.x86_64
```

**Android parses and is correct, and has never been built** — because building it
needs the Android SDK, which is a per-machine setup and not a repo change. The
exact refusal, so you can match it:

```
ERROR: Cannot export project with preset "Android" due to configuration errors:
Invalid Android SDK path in Editor Settings. Missing 'platform-tools' directory!
Unable to find Android SDK platform-tools' adb command.
Invalid Android SDK path in Editor Settings. Missing 'build-tools' directory!
Unable to find Android SDK build-tools' apksigner command.
```

**Windows has never been built either** — same file, different template, and
nothing about it is specific to this project.

## The short version, on Windows

Two scripts, in `tools/`. Run them in that order from the repo root.

```
powershell -ExecutionPolicy Bypass -File tools\android_check.ps1
powershell -ExecutionPolicy Bypass -File tools\android_run.ps1
```

`android_check.ps1` changes nothing. It asks each prerequisite separately —
engine version, export templates, SDK, `adb`, `apksigner`, a JVM, the debug
keystore, Godot's own SDK-path *editor* setting, and whether an AVD exists — and
prints what it found. Godot's own refusal is four errors that all say "SDK" and
none of which say which piece is missing, and it refuses *after* doing the work.

`android_run.ps1` starts the emulator, exports the debug APK while it boots,
waits for `sys.boot_completed`, installs and launches. `-Avd <name>` picks a
specific one; `-NoBoot` skips the emulator if a device is already attached.

The rest of this file is what those scripts are doing and why.

## Getting to an APK

1. **Export templates.** 1.2GB, matched to the engine version exactly. The
   editor will offer to download them; or fetch
   `Godot_v4.6-stable_export_templates.tpz` from the release page and point the
   Export Template Manager at it. They go in
   `~/.local/share/godot/export_templates/4.6.stable/` (Linux) or the equivalent
   `%APPDATA%` path on Windows. **They are not in the repo and must not be.**

2. **The Android SDK.** Android Studio, or the command-line tools. Godot needs
   `platform-tools/adb` and `build-tools/<version>/apksigner`, and it finds them
   through *Editor Settings → Export → Android → Android SDK Path*. That is an
   editor setting, not a project setting — it does not live in this repo and
   never will.

3. **A debug keystore.** The SDK makes one at `~/.android/debug.keystore` the
   first time it needs one. Godot will use it without being told, which is why
   `--export-debug` is the shortest path to a phone. If it is absent and Godot
   cannot make one, `keytool` does:

   ```
   keytool -genkeypair -v -keystore %USERPROFILE%\.android\debug.keystore ^
     -storepass android -keypass android -alias androiddebugkey ^
     -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
   ```

   Those are Android's own published debug values, not secrets — that is the
   whole point of a debug keystore, and it is why none of this touches the
   release rule below.

4. **A JVM.** `apksigner` is a `.bat` wrapping `java`. Android Studio ships one
   at `...\Android Studio\jbr`; point `JAVA_HOME` at it if `java` is not
   already on `PATH`. A missing JVM fails as an SDK error, which is how it
   costs an hour.

5. **Build it.**
   ```
   godot --headless --path . --export-debug "Android" build/combat-club.apk
   adb install -r build/combat-club.apk
   ```

## Release signing — and the one rule

A release build needs your own keystore. Fill `keystore/release` and
`keystore/release_password` in the **editor**, not in this file.

> **`export_presets.cfg` is tracked in git.** That is the opposite of the usual
> advice, and it is safe only because the file holds no secret: it carries the
> exclude filters, the architectures, the billing permission and the package
> name, which are decisions worth having history for.
>
> `tests/test_export.gd` fails the suite if any of eleven credential fields has a
> value in it. If you fill one in locally, **do not commit that line.**

Godot also reads `keystore/release` from the environment
(`GODOT_ANDROID_KEYSTORE_RELEASE_PATH` and friends), which is the clean way to do
it on a build machine and keeps the file empty.

## What the presets decide

| | |
|---|---|
| Package | `com.bonkworks.combatclub` — *not* Godot's `com.example` default, which Play refuses at upload, after the build |
| Architectures | `arm64-v8a` and `x86_64`. No armeabi-v7a: 32-bit ARM phones are long gone, and it doubles the APK. **`x86_64` is also what the desktop emulator runs** — an AVD on an Intel or AMD PC must use an x86_64 system image, or the install fails with `INSTALL_FAILED_NO_MATCHING_ABIS` |
| Gradle | **Off.** `use_gradle_build=false`, so the export uses the prebuilt `android_debug.apk` template and signs it with `apksigner`. That is the short path: no gradle, no Android build template, no `android/` folder. It is also why Play Billing is not in the build — a plugin needs the gradle path, and that is a decision, not an oversight |
| Excludes | `audio/_candidates` is 20 of the project's 25MB of audio and not one file in it is referenced. `shots/`, `docs/`, `tools/`, `tests/` go too |
| Billing | `com_android_vending_billing` plus `internet` and `access_network_state`, for the credit unlock |
| Orientation | **Not set here.** Godot writes `android:screenOrientation` into the manifest from `display/window/handheld/orientation` in `project.godot`, which is 4 — `SENSOR_LANDSCAPE`. It was PORTRAIT under a landscape game until the mobile pass, so `test_export.gd` holds it |

## Real billing needs one more thing

The billing *permission* is in the manifest, and that is all a preset can do.
The library itself is an Android plugin, which needs `use_gradle_build=true`, an
Android build template installed from the editor, and the plugin's `.aar` in
`android/plugins/`.

Until that exists, `Store` runs on its stub backend and **says so on the screen**
rather than pretending a purchase succeeded. See `scripts/game/store.gd`.

## On the emulator

The AVD needs an **x86_64** system image on an Intel or AMD PC. Any API level
from 24 up will run it; the preset sets no `min_sdk`, so Godot 4.6's own floor
applies. A "Google Play" image is worth picking over "Google APIs" only when
there is a real billing plugin to test against — until then either does.

Two things about this game specifically:

- **It is `SENSOR_LANDSCAPE`.** An AVD that boots portrait with auto-rotate off
  shows the game sideways. `adb shell settings put system accelerometer_rotation 1`
  fixes it, and `android_run.ps1` does that for you.
- **It renders with `gl_compatibility`**, so the emulator needs working GLES3.
  Leave the AVD's graphics on *Hardware — GLES 2.0* / automatic; software
  rendering will run it at a frame rate that tells you nothing.

Useful once it is up:

```
adb logcat -s godot                    :: the game's own output
adb exec-out screencap -p > shot.png   :: a real frame off a real device
adb uninstall com.bonkworks.combatclub
```

## The icon

`icon.svg` is a placeholder: a heater shield with a cross, drawn on a 16×16 grid
in the game's own palette. It exists so exports resolve. The real one belongs to
the art pass, along with the launcher icons — the three `launcher_icons/*` fields
in the Android preset are empty, so Godot falls back to `icon.svg` for all of
them, which is fine for a debug build and not fine for a listing.
