# Merge coordinator handoff: PeteMoe56/8bit-buhurt

Snapshot taken 2026-10-02 00:31 CDT. The cloud-session loop has stopped and its pending check-in was cancelled. Pick up from here.

## The job (unchanged)
You are the merge coordinator for PeteMoe56/8bit-buhurt (Godot 4.6.2). Never write game code. Every 20 minutes, until no lane PRs have been open for 2 hours:
1. List the open PRs. Merge a `lane/*` PR with a merge commit when its "Suite / gate" check is green and it has no conflicts. Then comment `merged — <one line of what it does>`.
2. Gate red: comment the first failing test from the failed job log on the PR. Don't merge it.
3. Two PRs conflict: merge the older one first. Ask the newer one's lane to rebase on main.
4. Keep `docs/MERGE-LOG.md` on main: one line per merge (US Central time, PR number, title). Commit it straight to main; that's the only direct push allowed.

Never force-push. Never merge a PR whose gate is red or pending.

## What I learned
- **`gh pr list` fails here.** GraphQL is blocked from Claude Code sessions. `gh api` (REST) works, for example `gh api repos/PeteMoe56/8bit-buhurt/pulls/N` and `.../commits/<sha>/check-runs?check_name=gate`.
- **The gate is the `gate` job in `.github/workflows/suite.yml`.** It needs `files` (6 shards) and `screens` (shapes and langs). It only appears after those jobs finish, so no gate check run means pending.
- **Each head SHA usually gets two Suite runs** (push and pull_request). I count a PR as green only when every `gate` run on its head is `success` and no job on that SHA is still running.
- **Every lane appends to `docs/REGISTER.md`.** Each merge therefore puts the other open PRs into conflict. Expect to merge one PR, ask the rest to rebase, and repeat. Two possible fixes, which are the user's call: per-PR register fragments, or adding the register line after merging.
- **After a merge, GitHub reports `mergeable: null` for a few seconds.** Re-poll before deciding the next PR.
- **"screens (langs)" failures** on #1 and #2 came from the CI problem that #3 fixed.

## Done so far
| When (CDT) | Action |
|---|---|
| 00:15 | Merged #3, "CI: pin runners to ubuntu-24.04; own user data dir per language-sweep engine". Posted the merged comment. |
| 00:15 | Created `docs/MERGE-LOG.md` on main with the #3 line (commit 89c906e). |
| 00:15 | Asked #4 and #6 to rebase on main (`docs/REGISTER.md` conflict). Their gates had been green. |

No red-gate comments have been posted yet.

## Open PRs at 00:31 CDT
| PR | Branch | Merge state | Gate | Next action |
|---|---|---|---|---|
| #1 | lane/novice-fixes | unstable | queued | wait |
| #2 | lane/review | **dirty** | success ×2 | **ask to rebase on main (not yet asked)** |
| #4 | lane/novice-fixes-3 | unstable | rerunning after rebase | wait, merge when green |
| #5 | lane/novice-fixes-4 | unstable | rerunning | wait |
| #6 | lane/novice-fixes-5 | unstable | rerunning after rebase | wait, merge when green |
| #7 | lane/novice-fixes-6 | unstable | queued | wait |
| #8 | lane/novice-fixes-7 | unstable | queued | wait |
| #9 | lane/novice-runs-kit-refusal | unstable | pending | wait |
| #10 | lane/novice-fixes-8 | unstable | pending | wait |
| #11 | lane/novice-fixes-9 | unstable | pending | wait |
| #12 | lane/novice-fixes-10 | unstable | pending | wait |
| #13 | lane/novice-runs-ground-refusal | unstable | pending | wait |
| #14 | lane/novice-runs-sub-refusal | unstable | pending | wait |
| #15 | lane/novice-runs-fighter-flash | unstable | pending | wait (new since last pass) |

"unstable" here means jobs are still running, not that anything failed. The 2-hour no-lane-PR stop clock has not started.
