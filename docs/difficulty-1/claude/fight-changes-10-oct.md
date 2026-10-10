# Fight changes, 10 Oct 2026 (Claude): what changed and what it did

What changed (all on this branch, none on main yet):
- Roles: Rail 245-280 lb strongest and hardest to move; Flanker 210-235 lb hardest hitter; Center 175-200 lb quickest, fittest, most skilled. Generated clubs and the hand-made clubs both.
- Off-balance bullrush: the bonus raises the 42% cap by its own size and grows the further under half balance he is.
- Blindside: arriving on a man tied up with someone else, the wheel offers Bullrush | Hit | Break (Takedown stays on the clinch wheel). Anyone gets +10% on a tied-up man, a Center +20% more from the angle, and both raise the cap. The Third Man trait now boosts this bullrush.
- Wheel words: name biggest, percentages nearest the hub, no explainers; "Free Teammate" under Break.
- Guide: ten picture pages drawn live in every language; accented letters added to the body font.
- Signing: a free agent replaces a worse man of his own role first; the market only offers men who make the club stronger.

Normal, 50 careers a side, scripted player fighting every bout, stop at first Worlds title:

| | Tune seeds | Check seeds | All 50 |
|---|---|---|---|
| Main today | 10.24 | 10.68 | 10.46 |
| This branch | 10.52 | 10.12 | 10.32 |

All 100 careers won a Worlds title. Main today reproduces Codex's figures exactly.

Roles, computer against computer, 300 bouts (`bash tools/bb.sh probe roles 300`):

| Role | lb | Bullrushes per man per bout | Floored | Men put down per bout |
|---|---|---|---|---|
| Rail | 262 | 1.87 | 15.4% | 1.31 |
| Flanker | 222 | 1.94 | 12.7% | 1.47 |
| Center | 187 | 1.00 | 16.7% | 1.53 |

Full test suite: green, 97 runs.
