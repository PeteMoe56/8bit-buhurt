# Reproduction and provenance

Base: 7c79a7f3522529a06a503b6b07e69236b08ad937. No commits or pushes.
Each of wear, economy, grade, gentle, value, prices, wages, bonus was a separate
detached worktree under C:/Users/PeterM/Documents/Codex/work/harness-2/.
All eight .patch files apply independently to this base; no stacking needed.

Engine: C:/Users/PeterM/Desktop/Godot_v4.6.2-stable_win64.exe.
Actual --version: 4.6.2.stable.official.71f334935.
For each worktree, imported with --headless --editor --import --quit.
APPDATA was set to that worktree's .runtime directory and explicit logs were used.
The retained run.ps1 documents the ProcessStartInfo runner and output capture.

Every original three-arm sweep used exactly:

    --headless --path <worktree> --log-file <explicit-log>
    --script res://tools/probe_harness_budget.gd
    -- 5 20 --out=res://docs/bakeoff-2/harness/codex-<variant>

No explicit base arguments: defaults 9001 5150 2718 6060 8123; seed=base+i*7919.
Primary probe and tools/manager.gd have no edits in any worktree.

The value-sensible worktree applies the SAME value game patch, then adds the
retained probe_harness_budget_sensible.gd to tools/. Its separate run was:

    --headless --path <value-sensible-worktree> --log-file <explicit-log>
    --script res://tools/probe_harness_budget_sensible.gd
    -- 5 20 --out=res://docs/bakeoff-2/harness/codex-value-sensible

This tool extends the arm list to four and adds the policy in SENSIBLE-PLAN.md.
The primary probe is retained unchanged. Its added tool is included in metadata
source hashes. policy-parity.json checks all 75 original-arm journals byte-for-byte.
The sensible-policy.patch is a readable unified diff between the two tools;
the full new tool is also saved so reproduction does not require applying that diff.

Independent validation (bundled Python) for a three-arm folder:

    python analyse.py <frozen-worktree-root> <raw-result-folder>

For the four-arm folder add --four-arm. The validator checks source SHA-256,
raw cash/XP replay, closed season books, summaries, paired/censor flags and
inspection transitions. Source hashes normalize CRLF to LF as the engine does.
Each original folder has 75 careers, 1500 seasons, 75 pair records; the extended
folder has 100 careers, 2000 seasons and 150 pairs. No raw result was edited.
JSON manifests beside the report verify the copied result files.

Focused game checks, for each mechanics variant:

    --headless --path <worktree> --script res://tests/test_quartermaster.gd
    --headless --path <worktree> --script res://tools/probe_harness_ladder_check.gd

The grade worktree also ran the retained probe_harness_quality_check.gd, which
extends tests/test_c6.gd: baseline Rust C6 checks, then Rust/Titanium cases at
deficits 0,12,16, 48 bouts per cell on bases 30000/61000, and 96-bout same-grade
mirrors on 700000. The Rust tactical hole is selected once before the grade
changes; the upgraded player does not choose a new favorable tactical pairing.
No full Windows gate claimed. All engine and validation logs are retained.

Fixture correction: the first added unevenness assertion checked only the first
three wear differences and omitted Titanium's final step. On the baseline ladder
that asserted incorrectly. Corrected it to check all four differences, reran,
and preserved prices-ladder-fixture-error.log. No game mechanics changed for this.

Scratch worktrees remain available for review/reproduction. Main game sources
were not modified; pre-existing untracked files and probe_scouting.gd.uid deletion
were preserved. Claude's output locations were never read.
