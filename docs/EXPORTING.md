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
   `--export-debug` is the shortest path to a phone.

4. **Build it.**
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
| Architectures | `arm64-v8a` and `x86_64`. No armeabi-v7a: 32-bit ARM phones are long gone, and it doubles the APK |
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

## The icon

`icon.svg` is a placeholder: a heater shield with a cross, drawn on a 16×16 grid
in the game's own palette. It exists so exports resolve. The real one belongs to
the art pass, along with the launcher icons — the three `launcher_icons/*` fields
in the Android preset are empty, so Godot falls back to `icon.svg` for all of
them, which is fine for a debug build and not fine for a listing.
