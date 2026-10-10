# Difficulty #1: what each dial is worth when fights are skipped (Claude)

Main + the step-1 changes (4 points a level, cup XP, same-pool teams apart until the final, the strong
Worlds team after the first title). Custom difficulty with one dial moved from Sanctioned's values.
Three engaged manager styles x 3 careers x 5 tune bases = 45 careers a row, 20 seasons, every bout
skipped. First Worlds title counts careers that never win one as 20.

## Opponent strength

| Strength | First Worlds title | Careers winning one | Worlds titles per career | Late Worlds win rate | Relegations | Bank, season 12+ |
|---|---|---|---|---|---|---|
| 0.90 | 8.51 | 45/45 | 9.2 | 0.77 | 0.04 | 237 |
| 0.94 | 9.62 | 45/45 | 7.4 | 0.64 | 0.11 | 222 |
| 0.96 (Friendly) | 10.22 | 45/45 | 6.3 | 0.62 | 0.18 | 211 |
| 0.98 | 10.38 | 45/45 | 5.4 | 0.51 | 0.20 | 206 |
| 1.00 (Sanctioned) | 10.89 | 45/45 | 4.7 | 0.46 | 0.07 | 198 |
| 1.02 | 11.67 | 45/45 | 3.3 | 0.33 | 0.18 | 191 |
| 1.04 (Full Steel) | 12.18 | 44/45 | 2.4 | 0.22 | 0.29 | 175 |
| 1.06 | 13.33 | 44/45 | 2.0 | 0.21 | 0.42 | 169 |
| 1.08 | 14.09 | 40/45 | 1.8 | 0.21 | 0.62 | 156 |
| 1.10 | 16.51 | 26/45 | 0.9 | 0.12 | 0.76 | 128 |

## Bills (dues and federation renewals)

| Bills | First Worlds title | Careers winning one | Worlds titles per career | Late Worlds win rate | Relegations | Bank, season 12+ |
|---|---|---|---|---|---|---|
| 0.5 | 10.09 | 45/45 | 4.9 | 0.44 | 0.16 | 211 |
| 0.8 (Friendly) | 10.02 | 45/45 | 4.9 | 0.43 | 0.07 | 208 |
| 1.0 (Sanctioned) | 10.89 | 45/45 | 4.7 | 0.46 | 0.07 | 198 |
| 1.2 (Full Steel) | 11.29 | 44/45 | 4.5 | 0.43 | 0.16 | 194 |
| 1.5 | 12.69 | 42/45 | 3.4 | 0.39 | 0.24 | 181 |

## Training injuries and the Hard List rule

| Setting | First Worlds title | Careers winning one | Worlds titles per career | Late Worlds win rate | Relegations | Bank, season 12+ |
|---|---|---|---|---|---|---|
| Injuries 0.2 | 10.89 | 45/45 | 4.7 | 0.46 | 0.07 | 198 |
| Injuries 1.0 | 10.89 | 45/45 | 4.7 | 0.46 | 0.07 | 198 |
| Hard List rule on, strength 1.00 | 12.07 | 45/45 | 3.2 | 0.37 | 0.44 | 180 |

Training injuries change nothing when every bout is skipped (identical careers): injuries only
land in fought bouts, so that dial is measured in Codex's real-fight runs.

## Federation Sanctions (Claude's creative idea, prototype)

Each sanction: opponents 2% stronger, prize and tournament money +25%. Taken every season by a rule
standing in for the player's choice.

| Sanctions | First Worlds title | Careers winning one | Worlds titles per career | Late Worlds win rate | Relegations | Bank, season 12+ |
|---|---|---|---|---|---|---|
| None | 10.89 | 45/45 | 4.7 | 0.46 | 0.07 | 198 |
| 1 after first Worlds title | 10.89 | 45/45 | 3.7 | 0.34 | 0.07 | 218 |
| 2 after first Worlds title | 10.89 | 45/45 | 3.1 | 0.27 | 0.07 | 232 |
| 3 after first Worlds title | 10.89 | 45/45 | 2.8 | 0.29 | 0.07 | 258 |
| 1 from season one | 11.09 | 44/45 | 3.8 | 0.36 | 0.16 | 232 |

Late-career income per season: 536 CC with none; 570 / 599 / 633 with 1 / 2 / 3; 581 with one from
season one. Each sanction costs about one Worlds title a career and pays about 34 CC a season, which
a late-career club cannot turn into wins. The reward should be glory (a mark on the trophy, sanctioned
titles counted in the Hall of Fame) with money as a small extra.

## Skip penalty: opponents 7% stronger in skipped bouts only

Patch: `../skip-penalty.patch`. Every bout skipped, 45 careers per cell; fighting figures are Codex's interim.

| Difficulty | Fighting (tune / check) | Skipping, tune | Skipping, check |
|---|---|---|---|
| Friendly | 8.40 / 8.92 | 10.96 (44/45 win) | 11.44 (45/45 win) |
| Normal | 10.24 / 10.68 | 14.00 (41/45 win) | 14.40 (41/45 win) |
| Full Steel | not in yet | 17.11 (24/45 win) | 17.78 (19/45 win) |

## Presets and Custom extremes, skipped, before the skip penalty

| Version | First Worlds title | Careers winning one |
|---|---|---|
| Custom, all easiest | 7.33 | 45/45 |
| Friendly | 9.07 | 45/45 |
| Normal | 10.89 | 45/45 |
| Full Steel | 13.80 | 43/45 |
| Hard List | 14.38 | 40/45 |
| Custom, all hardest | 19.22 | 7/45 |
