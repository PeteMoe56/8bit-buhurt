# Full harness-budget run

- Game snapshot: `27367d2911ebd3b6089578425de9fdbdd2aec536`, local main.
- Probe and manager unchanged from that snapshot; no game-code edits.
- Arguments: `-- 5 20 --out=res://docs/bakeoff-2/harness/full`.
- Engine: `C:\Users\PeterM\Desktop\Godot_v4.6.2-stable_win64.exe`.
- Version printed by engine: `4.6.2.stable.official.71f334935`.
- Headless runner uses workspace-local APPDATA and explicit log.
- Godot exit 0: `diagnostic_only=false careers=75 validation_passed=true`.
- The Windows root certificate-store error remains. This run emitted no
  shutdown resource warnings. It is not a full Windows release/test gate.
- Engine transcript: `../full-stdout.txt`; engine log: `../full-engine.log`.
- Independent validator: `../analyse_full.py`, bundled Python runtime.
- Independent validation completed exit 0: 75 ledgers, 1,500 season rows,
  75 paired contrasts, three attainment rows, source hashes, per-action cash
  intervals, complete cash/XP conservation, action counts and positive cash-in.
- `validation.json` records coverage; `analysis.json` contains arithmetic and
  definitions; `base_contrasts.tsv` exposes the five-base ordering variation.
- First-title times are read before rollover; ending power/bank after rollover.
  Censored first-title cells stay empty. Derived restricted time uses `min(T,20)`.
- CC categories are normalized over 500 closed seasons per arm. They are not
  restricted to the years before a career's first title. Recruitment/facility
  policies are held fixed; realized purchases and opponents may diverge.
- The full run's in-engine parity column is `not_run`: parity is a dry-run
  check, not silently repeated over these careers. No claim of 75 parity tests.
- No commit or push performed. Existing unrelated working-tree changes retained.
