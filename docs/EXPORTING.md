# Exporting

Written 15 Sep 2026, when the project got its first `export_presets.cfg`. Before
that there was none at all, and `project.godot` had pointed at a `res://icon.svg`
that did not exist since the day it was created — so no build had ever been made,
and nothing in the suite could have told you.

Three presets: **Android**, **Windows Desktop**, **Linux**.

## The engine is 4.6.2

`4.6.2.stable.official.71f334935`, on both machines, as of 15 Sep 2026.

It was 4.6.stable in the test container and 4.6.2 on the machine that will
actually ship the game — a green suite on an engine nobody builds from. **Export
templates are matched to the patch number**, so the two disagreeing is not
academic, and the whole suite was re-run on 4.6.2 before this line was written.

`tools/run_tests.sh` now finds whichever engine is present and **prints its
version on every run**, rather than carrying a path with a version baked into it.
`tools/godot_find.ps1` does the same job on Windows and derives the export
template folder from the answer. Nothing in `tools/` has a version number typed
into it any more, which is the only form of this fix that stays fixed.

## What is proven and what is not

**Linux is proven.** Exported headless, launched, played, quit clean — on 4.6
first, and again on 4.6.2 after the bump:

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

`android_check.ps1` changes nothing. It finds the engine by asking each
candidate `--version` — a `*_console.exe` is only a stub that relaunches the
`.exe` beside it by exact filename, so one whose sibling has been renamed or
never extracted reports *"Main executable ... not found"*, which reads exactly
like a broken engine and is a missing file. It asks each prerequisite separately —
engine version, export templates, SDK, `adb`, `apksigner`, a JVM, the debug
keystore, Godot's own SDK-path *editor* setting, and whether an AVD exists — and
prints what it found. Godot's own refusal is four errors that all say "SDK" and
none of which say which piece is missing, and it refuses *after* doing the work.

`android_run.ps1` starts the emulator, exports the debug APK while it boots,
waits for `sys.boot_completed`, installs and launches. `-Avd <name>` picks a
specific one; `-NoBoot` skips the emulator if a device is already attached.

The rest of this file is what those scripts are doing and why.

## Getting to an app bundle (and an APK for the desk)

1. **Export templates.** 1.2GB, matched to the engine version exactly — and
   **exactly includes the patch number.** A 4.6.2 editor wants
   `4.6.2.stable` templates and will not use `4.6.stable` ones; the folder name
   is the version string the binary itself prints from `--version`. The editor
   will offer to download the right set (*Editor → Manage Export Templates →
   Download and Install*), or fetch the matching
   `Godot_v<version>_export_templates.tpz` from that release's page and point
   the Export Template Manager at it.

   They go in `%APPDATA%\Godot\export_templates\<version>.stable\` on Windows
   or `~/.local/share/godot/export_templates/<version>.stable/` on Linux.
   **They are not in the repo and must not be.**

   `tools/godot_find.ps1` derives that folder from the binary rather than
   carrying a version number of its own, because the first cut of the check
   script hard-coded `4.6` and confidently sent a 4.6.2 machine looking in a
   folder that would never exist.

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

5. **The Android build template (once).** Since 29 Sep 2026 the preset is a
   **gradle build that outputs an app bundle (AAB) targeting API 36** — Play
   takes new apps only as an AAB, and from 31 Aug 2026 only at API 36, and
   Godot can only do either through gradle. In the editor: *Project → Install
   Android Build Template…*. That writes `android/` into the project. It is
   **not committed** (`.gitignore` has `/android/`): it is Godot's stock
   template, regenerated on any machine by the same menu item. If it is ever
   edited — a billing plugin's `.aar` in `android/plugins/`, a manifest
   change — narrow the ignore to the gradle output and commit the rest. It
   needs the export templates from step 1.

6. **Build it.**
   ```
   godot --headless --path . --export-release "Android" build/combat-club.aab   :: for Play (release keystore)
   godot --headless --path . --export-debug "Android" build/combat-club.aab     :: debug-signed bundle
   ```
   An AAB does not install with `adb install`. For a phone on the desk, either
   flip *Export Format* to APK for that one export in the editor, or turn the
   bundle into an installable set with bundletool:
   ```
   java -jar bundletool.jar build-apks --bundle=build/combat-club.aab --output=build/cc.apks --local-testing
   java -jar bundletool.jar install-apks --apks=build/cc.apks
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
| Gradle | **On** (29 Sep 2026): `use_gradle_build=true`, `export_format=1` (AAB), `target_sdk=36`, `min_sdk=24`. Play requires AAB and API 36; the prebuilt APK path could do neither. Needs the build template, step 5 |
| Excludes | `audio/_candidates` (4.5MB), `audio/music/_archive` (12.5MB), the full album MP3 in the root (7MB, licensed as a loop only), `Assets/`, `Claude outputs/`, font specimens, `shots/`, `docs/`, `tools/`, `tests/`. The exported pack went 32.6MB → 15.0MB |
| Includes | The licence texts (`fonts/OFL.txt`, `fonts/fallback/LanaPixel-OFL.txt`, `art/ui/KENNEY-LICENSE.txt`) — the game shows them on Settings → Licences with Godot's own |
| Permissions | `com_android_vending_billing` only. **No `internet`, no `access_network_state`** — nothing in the game opens a socket, and Play Billing talks to the network through the Play Store app |
| Backup | **On.** A career is ~70KB; off, a new phone loses it |
| Splash | The crest on the game's ground colour, filtering off (project.godot `application/boot_splash/*`) |
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

The launcher icons are real: `art/brand/crest_192.png` for the square icon and
the adaptive pair (`adaptive_fg_432.png` with the crest inside the middle 66%,
`adaptive_bg_432.png` in the ground colour), set in the Android preset. The
project icon is `crest_512.png`. (This section said the icon fields were empty
until 29 Sep 2026; they had not been for two weeks.)
