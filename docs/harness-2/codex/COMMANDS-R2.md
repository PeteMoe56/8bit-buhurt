# Reproduce round 2

Base: 7c79a7f3522529a06a503b6b07e69236b08ad937. Each r2-*.patch is standalone against this base, including the unchanged value platform. Do not stack it over value.patch.

Create a detached scratch worktree outside the main Godot project, apply one patch, import it with Godot, then run the unchanged primary probe twice:

```
Godot_v4.6.2-stable_win64.exe --headless --path <scratch> --editor --import --quit
Godot_v4.6.2-stable_win64.exe --headless --path <scratch> --script res://tools/probe_harness_budget.gd -- 5 20 --out=res://docs/bakeoff-2/harness/codex-r2-<variant>/default
Godot_v4.6.2-stable_win64.exe --headless --path <scratch> --script res://tools/probe_harness_budget.gd -- 5 20 17011 29033 43049 67061 91081 --out=res://docs/bakeoff-2/harness/codex-r2-<variant>/heldout
```

Default bases: 9001 5150 2718 6060 8123. Five seeds per base, seed = base+i*7919. Original three arms only. Keep all game sources, primary probe and manager frozen throughout both runs. The runner redirects APPDATA to scratch/.runtime and stores engine logs in work-r2/logs; every process is headless and waited to exit.

Engine path: C:\Users\PeterM\Desktop\Godot_v4.6.2-stable_win64.exe. Fresh --version output is retained in work-r2/logs/engine-version.txt.

Helper scripts under work-r2 are experiment tooling, not game changes. build.py creates worktrees and patches; fixtures.py installs the focused tools; run.ps1 runs import, sweeps and tests; collect.py copies completed raw output and independently validates it; analyse.py replays source hashes, currency, XP, paired times and censoring; summarize.py produces the tables and byte comparisons. collect.py never accepts a run without its completed metadata.json.

Expected raw output per set: 75 careers, 1,500 closed seasons, 75 paired rows. Every output retains metadata/source hashes, validation flags and every transaction. Derived validation.json, analysis.json and base_contrasts.tsv sit beside the raw files. The same evaluation bases are reused across designs; adaptive combinations are not independent confirmation.
