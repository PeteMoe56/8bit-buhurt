# Screen Score #1: Codex
Game score: 4.9 / 5   (S1: 0, S2: 11, S3: 5)

Per viewport:
- v16x9: 4.9 / 5 (S1: 0, S2: 9; 55 renders)
- v19x9n: 5.0 / 5 (S1: 0, S2: 1; 22 renders)
- v19x9: 4.8 / 5 (S1: 0, S2: 9; 33 renders)
- v16x10: 5.0 / 5 (S1: 0, S2: 2; 22 renders)

Reviewed all 132 supplied renders individually at their native canvas dimensions, against the locked rubric. The images are the supplied `d5ce8a9` snapshot; the local checkout began at `d8cf2d5`. No Claude score, sealed output or earlier screen review was read. No game code changed.

Aggregation: 55 logical screen/state groups; unrounded criterion means feed viewport and logical means. Only displayed values are rounded. Finding counts are distinct defects, not multiplied by the number of affected images. A 5 means the criterion is met in the supplied still, not that animation, behavior or every unseen state is proven.

The broad menu work is strong: club identity, prices, upkeep, lineups and primary actions are usually clear. The main weaknesses are overlay layering, angled wheel text and a few state-specific layout errors. I found no still-proven S1 blocked essential action or unreadable essential result. The S2 findings remain worth fixing despite the high mean.

## Priority fixes

1. **S38-1 S2** — Put the pre-bout full playbook on an opaque modal panel. Effort: S.
2. **S40-1 S2** — Apply the wide colour-popup offset once; cover the entire viewport with its scrim. Effort: S.
3. **S37b-1 S2** — Keep the champion name fully inside Your Path. Effort: S.
4. **S29-1 S2** — Remove stale walk-out controls from the live-fight coach mark; check the shot fixture. Effort: S.
5. **S05-1 S2** — Restore the BENCH heading in the taller TEAM layout. Effort: S.
6. **S12-1 S2** — Keep Extend and Release in the same order on every captain card. Effort: S.
7. **S41-1 S2** — Preserve Open/Classic distinctions in dated tournament cells. Effort: S.
8. **S26b-2 S2** — Give Done and Back separate meanings and use the correct opener name. Effort: S.
9. **S25-1 S2** — Keep wheel action/chance/effect text horizontal. Effort: M.
10. **S25-2 S2** — Keep standing counts and fighter status visible while the wheel is open. Effort: M.
11. **S42-1 S2** — Replace the coach appearance placeholder with a working preview. Effort: M.
12. **S33-1 S3** — Separate the total differential from the current grade in the records footer. Effort: S.
13. **S41-2 S3** — Separate the calendar heading from its phase label. Effort: S.
14. **S01-1 S3** — Put the music credit inside the declared safe inset. Effort: S.
15. **S26b-1 S3** — Use the same pixel typography in the full-playbook header. Effort: S.
16. **S16-1 S3** — Let the venue panel show the ground, not just repeat its name and capacity. Effort: M.

Severity comes first; within severity, small concrete repairs precede broader control/art work. Effort is an estimate. Behavioral impact and fixture-versus-production questions need validation.

## Scores

| render | viewport | screen / state | C1 | C2 | C3 | C4 | C5 | C6 | score | S1/S2 | note |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| v16x10/01_start.png | v16x10 | Start / front door, career exists | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Strong branded entry; clear Play action. — |
| v16x10/02_title_slots.png | v16x10 | Title / save slots / three empty slots | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Empty slots communicate the new-career action clearly. — |
| v16x10/03_settings.png | v16x10 | Settings / in a career | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Grouped settings; selected options and automatic saving are explicit. — |
| v16x10/04_season_club.png | v16x10 | Season hub: FIGHT tab / cup quarter-final waiting, Backyard season 3 | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Club identity, upcoming cup tie and main fight action read clearly. — |
| v16x10/05_season_squad.png | v16x10 | Season hub: TEAM tab / levels waiting (+N), no man picked | 5 | 4 | 4 | 5 | 5 | 5 | 4.7 | 0/1 | Bench heading disappears in the taller layout. S05-1 |
| v16x10/06_season_armorer.png | v16x10 | Season hub: MAINTENANCE tab / 1-star armorer, kit 84-94% | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Inspection threshold and kit condition are explicit; repair route is explained. — |
| v16x10/07_season_clubhouse.png | v16x10 | Season hub: UPGRADES tab / cap, camp, infirmary, insurance, arena | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Upgrade price, benefit and recurring upkeep are shown together. — |
| v16x10/08_season_finances.png | v16x10 | Season hub: MANAGEMENT tab / finances, staff, coach card | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Finance, staff and coach columns retain readable separation. — |
| v16x10/09_roster.png | v16x10 | Squad (card view) / eight men, line of five + bench | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Five starters and smaller bench cards distinguish lineup roles. — |
| v16x10/10_fighter.png | v16x10 | Fighter page / Rail Calder, 3 levels to spend | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The level-spending row is prominent; stats have plain-language descriptions. — |
| v16x10/11_market.png | v16x10 | Free agents / six men, one unaffordable | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Fees, wages, rating and unaffordability are explicit. — |
| v16x10/12_staff.png | v16x10 | Staff / two captains hired, 1-star armorer | 5 | 4 | 5 | 5 | 4 | 5 | 4.7 | 0/1 | Extend/Release order reverses between adjacent captain cards. S12-1 |
| v16x10/13_coach.png | v16x10 | Your coach / 2 skill points to spend | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Available points, current effects and upgrade controls are visible together. — |
| v16x10/14_records.png | v16x10 | Records: The club tab / club records | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Records retain named club history and clear tab selection. — |
| v16x10/15_guide.png | v16x10 | Guide / The table page | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The selected guide topic and compact bullet explanations are clear. — |
| v16x10/16_arena.png | v16x10 | Arena (venue) / Back field, level 0 | 5 | 4 | 5 | 5 | 5 | 4 | 4.7 | 0/0 | Venue controls are clear; the large venue panel repeats text instead of showing the ground. S16-1 |
| v16x10/17_chalkboard.png | v16x10 | Playbook editor (chalkboard) / formations tab, a saved shape | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Start line, direction, roles and saved state explain the editor. — |
| v16x10/18_create_fighter.png | v16x10 | Create: fighter / custom fighter, 4 of 4 creations left | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Stat descriptions, rating cap, price and wage exposure are readable. — |
| v16x10/19_create_club.png | v16x10 | Create: club / name, kit and badge | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Badge preview, selected mark and paid choices are distinct. — |
| v16x10/20_create_grade.png | v16x10 | Create: grade / Sanctioned selected | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Selected grade, immediate saving and mechanical effects are explained. — |
| v16x10/21_bracket.png | v16x10 | Cup bracket / Milwaukee Open, quarter-final to fight | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Bracket route, next opponent and Fight action are easy to locate. — |
| v16x10/22_club_menu.png | v16x10 | Pause menu / open over the season hub | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | A focused pause panel keeps Resume primary and the club visible beneath. — |
| v16x9/01_start.png | v16x9 | Start / front door, career exists | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Strong branded entry; clear Play action. — |
| v16x9/02_title_slots.png | v16x9 | Title / save slots / three empty slots | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Empty slots communicate the new-career action clearly. — |
| v16x9/03_settings.png | v16x9 | Settings / in a career | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Grouped settings; selected options and automatic saving are explicit. — |
| v16x9/04_season_club.png | v16x9 | Season hub: FIGHT tab / cup quarter-final waiting, Backyard season 3 | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Club identity, upcoming cup tie and main fight action read clearly. — |
| v16x9/05_season_squad.png | v16x9 | Season hub: TEAM tab / levels waiting (+N), no man picked | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Level badges, contract colours and a visible legend support roster decisions. — |
| v16x9/06_season_armorer.png | v16x9 | Season hub: MAINTENANCE tab / 1-star armorer, kit 84-94% | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Inspection threshold and kit condition are explicit; repair route is explained. — |
| v16x9/07_season_clubhouse.png | v16x9 | Season hub: UPGRADES tab / cap, camp, infirmary, insurance, arena | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Upgrade price, benefit and recurring upkeep are shown together. — |
| v16x9/08_season_finances.png | v16x9 | Season hub: MANAGEMENT tab / finances, staff, coach card | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Finance, staff and coach columns retain readable separation. — |
| v16x9/09_roster.png | v16x9 | Squad (card view) / eight men, line of five + bench | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Five starters and smaller bench cards distinguish lineup roles. — |
| v16x9/10_fighter.png | v16x9 | Fighter page / Rail Calder, 3 levels to spend | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The level-spending row is prominent; stats have plain-language descriptions. — |
| v16x9/11_market.png | v16x9 | Free agents / six men, one unaffordable | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Fees, wages, rating and unaffordability are explicit. — |
| v16x9/12_staff.png | v16x9 | Staff / two captains hired, 1-star armorer | 5 | 4 | 5 | 5 | 4 | 5 | 4.7 | 0/1 | Extend/Release order reverses between adjacent captain cards. S12-1 |
| v16x9/13_coach.png | v16x9 | Your coach / 2 skill points to spend | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Available points, current effects and upgrade controls are visible together. — |
| v16x9/14_records.png | v16x9 | Records: The club tab / club records | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Records retain named club history and clear tab selection. — |
| v16x9/15_guide.png | v16x9 | Guide / The table page | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The selected guide topic and compact bullet explanations are clear. — |
| v16x9/16_arena.png | v16x9 | Arena (venue) / Back field, level 0 | 5 | 4 | 5 | 5 | 5 | 4 | 4.7 | 0/0 | Venue controls are clear; the large venue panel repeats text instead of showing the ground. S16-1 |
| v16x9/17_chalkboard.png | v16x9 | Playbook editor (chalkboard) / formations tab, a saved shape | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Start line, direction, roles and saved state explain the editor. — |
| v16x9/18_create_fighter.png | v16x9 | Create: fighter / custom fighter, 4 of 4 creations left | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Stat descriptions, rating cap, price and wage exposure are readable. — |
| v16x9/19_create_club.png | v16x9 | Create: club / name, kit and badge | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Badge preview, selected mark and paid choices are distinct. — |
| v16x9/20_create_grade.png | v16x9 | Create: grade / Sanctioned selected | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Selected grade, immediate saving and mechanical effects are explained. — |
| v16x9/21_bracket.png | v16x9 | Cup bracket / Milwaukee Open, quarter-final to fight | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Bracket route, next opponent and Fight action are easy to locate. — |
| v16x9/22_club_menu.png | v16x9 | Pause menu / open over the season hub | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | A focused pause panel keeps Resume primary and the club visible beneath. — |
| v16x9/23_walkout.png | v16x9 | Walk-out (pre-bout splash) / league bout, both clubs | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Home identity and roster comparison establish the bout. — |
| v16x9/23b_prefight_plan.png | v16x9 | Pre-fight plan / formation + play chosen | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Lineup, chosen opening and FIGHT action are well grouped. — |
| v16x9/24_fight_live.png | v16x9 | Fight (the list) / live, frame 30, first-bout route tip showing | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Teams, standing counts, timer and route instruction are readable; fixed-ratio framing is purposeful. — |
| v16x9/25_contact_wheel.png | v16x9 | Contact wheel / prompt open: a man routed onto a free enemy | 5 | 4 | 3 | 4 | 5 | 5 | 4.3 | 0/2 | Angled three-line labels are harder to scan; the wheel obscures HUD/cards. S25-1, S25-2 |
| v16x9/25b_contact_wheel_third.png | v16x9 | Contact wheel / prompt open: third man onto a clinch | 5 | 4 | 3 | 4 | 5 | 5 | 4.3 | 0/2 | Angled three-line labels are harder to scan; the wheel obscures HUD/cards. S25-1, S25-2 |
| v16x9/26_corner.png | v16x9 | Corner (between rounds) / after round 1 | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Round result, energy recovery, substitutions and next opening are clearly grouped. — |
| v16x9/26b_corner_playbook.png | v16x9 | Corner: full playbook / favourites starred, two scrolling panes | 4 | 5 | 5 | 5 | 4 | 5 | 4.7 | 0/1 | Two exit labels need clearer distinction; header typography differs. S26b-1, S26b-2 |
| v16x9/26c_corner_favourites.png | v16x9 | Corner: favourites strip / four favourites | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Two favourites visible (manifest says four); selected opening remains clear. — |
| v16x9/27_corner_sub.png | v16x9 | Corner: substitution / sub picker open | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Incoming fighter, energy and same-role recommendation are clear. — |
| v16x9/28_report.png | v16x9 | After-action report / bout fought, levels waiting | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Named contributions, management feedback and level-spending route are visible. — |
| v16x9/29_tip_route.png | v16x9 | Fight: first-time coach mark / route tip showing | 5 | 4 | 5 | 5 | 4 | 5 | 4.7 | 0/1 | Instruction is clear; stale Walk out/Back controls remain over fighter cards. S29-1 |
| v16x9/29b_tip_corner.png | v16x9 | Corner: first-time coach mark / corner tip showing | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The corner instruction explains substitutions, planning and the timer. — |
| v16x9/30_dilemma.png | v16x9 | Dilemma card / card on the table, prices shown | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Narrative choices show cash and morale/kit trade-offs. — |
| v16x9/31_promotion.png | v16x9 | Promotion offer / offer open | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Required ground, total cost, current funds and recurring upkeep are explicit. — |
| v16x9/32_fixture_sim.png | v16x9 | Fixture card / sim-it confirm open | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Confirmation identifies the opponent and explains that simmed consequences still apply. — |
| v16x9/32b_promo_ground_state.png | v16x9 | Promotion ground prompt / State League needs fenced ground, over the hub | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Required upgrade chain, staged building rule and next purchase are explicit. — |
| v16x9/33_records_this_year.png | v16x9 | Records: This year / season so far, 5 fought | 5 | 4 | 4 | 5 | 5 | 5 | 4.7 | 0/0 | Totals crowd the current-grade text in the footer. S33-1 |
| v16x9/34_promo_ground_regional.png | v16x9 | Promotion ground prompt / Regional League needs arena; 9048 CC is test money from the tool | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Required upgrade chain, staged building rule and next purchase are explicit. — |
| v16x9/35_hub_week1.png | v16x9 | Season hub: FIGHT tab / week 1, league fixture waiting | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Opponent, rating advantage, coming fixtures and Fight/Sim actions are clear. — |
| v16x9/36_history.png | v16x9 | Club history / records page | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Sparse history is an honest empty-trophy state, not a viewport defect. — |
| v16x9/37_worlds_groups.png | v16x9 | Worlds / group stage, 16 clubs in 4 pools | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Four pools, the player's row and the qualification rule are readable. — |
| v16x9/37b_bracket_done.png | v16x9 | Cup bracket (Path of Honor) / finished, champion shown | 5 | 3 | 4 | 4 | 5 | 5 | 4.3 | 0/1 | Champion text straddles the bottom edge of Your Path. S37b-1 |
| v16x9/38_playbook_favs.png | v16x9 | Playbook over the walk-out: picking favourites / before | 3 | 2 | 3 | 5 | 4 | 5 | 3.7 | 0/2 | The playbook has no opaque modal backing; walk-out text interleaves with its controls. S38-1, S26b-1, S26b-2 |
| v16x9/38b_playbook_favs.png | v16x9 | Playbook over the walk-out: picking favourites / after, four starred | 3 | 2 | 3 | 5 | 4 | 5 | 3.7 | 0/2 | The playbook has no opaque modal backing; walk-out text interleaves with its controls. S38-1, S26b-1, S26b-2 |
| v16x9/39_free_agent_market_ask.png | v16x9 | Free-agent prompt / market_ask | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The recommendation names the upgrade, its fee and available funds. — |
| v16x9/39_free_agent_market_picked.png | v16x9 | Free-agent prompt / market_picked | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The picked agent's named signing action is prominent. — |
| v16x9/40_popup_mark.png | v16x9 | Club tab popup / mark | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Badge preview and disabled-colour explanation are clear. — |
| v16x9/40_popup_town.png | v16x9 | Club tab popup / town | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | State and city selection, current choice and Done are clear. — |
| v16x9/41_calendar.png | v16x9 | Calendar / week 5 of a Backyard season | 5 | 4 | 3 | 5 | 5 | 5 | 4.5 | 0/1 | Tournament names truncate identically; the season header crowds its status. S41-1, S41-2 |
| v16x9/42_founding_step_1.png | v16x9 | New career (founding) / step_1 | 4 | 5 | 5 | 5 | 4 | 3 | 4.3 | 0/1 | Face/kit/beard choices have an 'art to follow' preview placeholder. S42-1 |
| v16x9/42_founding_step_2.png | v16x9 | New career (founding) / step_2 | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The club preview and named next step support the founding flow. — |
| v16x9/42_founding_step_3.png | v16x9 | New career (founding) / step_3 | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Final step gives a clear selected grade and Start action. — |
| v16x9/42_founding_step_4.png | v16x9 | New career (founding) / step_4 | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Custom controls and values remain readable; this is still step 3 of 3. — |
| v19x9/23_walkout.png | v19x9 | Walk-out (pre-bout splash) / league bout, both clubs | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Home identity and roster comparison establish the bout. — |
| v19x9/23b_prefight_plan.png | v19x9 | Pre-fight plan / formation + play chosen | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Lineup, chosen opening and FIGHT action are well grouped. — |
| v19x9/24_fight_live.png | v19x9 | Fight (the list) / live, frame 30, first-bout route tip showing | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Teams, standing counts, timer and route instruction are readable; fixed-ratio framing is purposeful. — |
| v19x9/25_contact_wheel.png | v19x9 | Contact wheel / prompt open: a man routed onto a free enemy | 5 | 4 | 3 | 4 | 5 | 5 | 4.3 | 0/2 | Angled three-line labels are harder to scan; the wheel obscures HUD/cards. S25-1, S25-2 |
| v19x9/25b_contact_wheel_third.png | v19x9 | Contact wheel / prompt open: third man onto a clinch | 5 | 4 | 3 | 4 | 5 | 5 | 4.3 | 0/2 | Angled three-line labels are harder to scan; the wheel obscures HUD/cards. S25-1, S25-2 |
| v19x9/26_corner.png | v19x9 | Corner (between rounds) / after round 1 | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Round result, energy recovery, substitutions and next opening are clearly grouped. — |
| v19x9/26b_corner_playbook.png | v19x9 | Corner: full playbook / favourites starred, two scrolling panes | 4 | 5 | 5 | 5 | 4 | 5 | 4.7 | 0/1 | Two exit labels need clearer distinction; header typography differs. S26b-1, S26b-2 |
| v19x9/26c_corner_favourites.png | v19x9 | Corner: favourites strip / four favourites | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Two favourites visible (manifest says four); selected opening remains clear. — |
| v19x9/27_corner_sub.png | v19x9 | Corner: substitution / sub picker open | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Incoming fighter, energy and same-role recommendation are clear. — |
| v19x9/28_report.png | v19x9 | After-action report / bout fought, levels waiting | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Named contributions, management feedback and level-spending route are visible. — |
| v19x9/29_tip_route.png | v19x9 | Fight: first-time coach mark / route tip showing | 5 | 4 | 5 | 5 | 4 | 5 | 4.7 | 0/1 | Instruction is clear; stale Walk out/Back controls remain over fighter cards. S29-1 |
| v19x9/29b_tip_corner.png | v19x9 | Corner: first-time coach mark / corner tip showing | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The corner instruction explains substitutions, planning and the timer. — |
| v19x9/30_dilemma.png | v19x9 | Dilemma card / card on the table, prices shown | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Narrative choices show cash and morale/kit trade-offs. — |
| v19x9/31_promotion.png | v19x9 | Promotion offer / offer open | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Required ground, total cost, current funds and recurring upkeep are explicit. — |
| v19x9/32_fixture_sim.png | v19x9 | Fixture card / sim-it confirm open | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Confirmation identifies the opponent and explains that simmed consequences still apply. — |
| v19x9/32b_promo_ground_state.png | v19x9 | Promotion ground prompt / State League needs fenced ground, over the hub | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Required upgrade chain, staged building rule and next purchase are explicit. — |
| v19x9/33_records_this_year.png | v19x9 | Records: This year / season so far, 5 fought | 5 | 4 | 4 | 5 | 5 | 5 | 4.7 | 0/0 | Totals crowd the current-grade text in the footer. S33-1 |
| v19x9/34_promo_ground_regional.png | v19x9 | Promotion ground prompt / Regional League needs arena; 9048 CC is test money from the tool | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Required upgrade chain, staged building rule and next purchase are explicit. — |
| v19x9/35_hub_week1.png | v19x9 | Season hub: FIGHT tab / week 1, league fixture waiting | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Opponent, rating advantage, coming fixtures and Fight/Sim actions are clear. — |
| v19x9/36_history.png | v19x9 | Club history / records page | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Sparse history is an honest empty-trophy state, not a viewport defect. — |
| v19x9/37_worlds_groups.png | v19x9 | Worlds / group stage, 16 clubs in 4 pools | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Four pools, the player's row and the qualification rule are readable. — |
| v19x9/37b_bracket_done.png | v19x9 | Cup bracket (Path of Honor) / finished, champion shown | 5 | 3 | 4 | 4 | 5 | 5 | 4.3 | 0/1 | Champion text straddles the bottom edge of Your Path. S37b-1 |
| v19x9/38_playbook_favs.png | v19x9 | Playbook over the walk-out: picking favourites / before | 3 | 2 | 3 | 5 | 4 | 5 | 3.7 | 0/2 | The playbook has no opaque modal backing; walk-out text interleaves with its controls. S38-1, S26b-1, S26b-2 |
| v19x9/38b_playbook_favs.png | v19x9 | Playbook over the walk-out: picking favourites / after, four starred | 3 | 2 | 3 | 5 | 4 | 5 | 3.7 | 0/2 | The playbook has no opaque modal backing; walk-out text interleaves with its controls. S38-1, S26b-1, S26b-2 |
| v19x9/39_free_agent_market_ask.png | v19x9 | Free-agent prompt / market_ask | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The recommendation names the upgrade, its fee and available funds. — |
| v19x9/39_free_agent_market_picked.png | v19x9 | Free-agent prompt / market_picked | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The picked agent's named signing action is prominent. — |
| v19x9/40_popup_mark.png | v19x9 | Club tab popup / mark | 5 | 4 | 5 | 3 | 5 | 5 | 4.5 | 0/1 | The popup is shifted right and its dimmer leaves a 105px grey strip. S40-1 |
| v19x9/40_popup_town.png | v19x9 | Club tab popup / town | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | State and city selection, current choice and Done are clear. — |
| v19x9/41_calendar.png | v19x9 | Calendar / week 5 of a Backyard season | 5 | 4 | 3 | 5 | 5 | 5 | 4.5 | 0/1 | Tournament names truncate identically; the season header crowds its status. S41-1, S41-2 |
| v19x9/42_founding_step_1.png | v19x9 | New career (founding) / step_1 | 4 | 5 | 5 | 5 | 4 | 3 | 4.3 | 0/1 | Face/kit/beard choices have an 'art to follow' preview placeholder. S42-1 |
| v19x9/42_founding_step_2.png | v19x9 | New career (founding) / step_2 | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The club preview and named next step support the founding flow. — |
| v19x9/42_founding_step_3.png | v19x9 | New career (founding) / step_3 | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Final step gives a clear selected grade and Start action. — |
| v19x9/42_founding_step_4.png | v19x9 | New career (founding) / step_4 | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Custom controls and values remain readable; this is still step 3 of 3. — |
| v19x9n/01_start.png | v19x9n | Start / front door, career exists | 5 | 5 | 5 | 4 | 5 | 5 | 4.8 | 0/0 | Strong branded entry; clear Play action. S01-1 |
| v19x9n/02_title_slots.png | v19x9n | Title / save slots / three empty slots | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Empty slots communicate the new-career action clearly. — |
| v19x9n/03_settings.png | v19x9n | Settings / in a career | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Grouped settings; selected options and automatic saving are explicit. — |
| v19x9n/04_season_club.png | v19x9n | Season hub: FIGHT tab / cup quarter-final waiting, Backyard season 3 | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Club identity, upcoming cup tie and main fight action read clearly. — |
| v19x9n/05_season_squad.png | v19x9n | Season hub: TEAM tab / levels waiting (+N), no man picked | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Level badges, contract colours and a visible legend support roster decisions. — |
| v19x9n/06_season_armorer.png | v19x9n | Season hub: MAINTENANCE tab / 1-star armorer, kit 84-94% | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Inspection threshold and kit condition are explicit; repair route is explained. — |
| v19x9n/07_season_clubhouse.png | v19x9n | Season hub: UPGRADES tab / cap, camp, infirmary, insurance, arena | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Upgrade price, benefit and recurring upkeep are shown together. — |
| v19x9n/08_season_finances.png | v19x9n | Season hub: MANAGEMENT tab / finances, staff, coach card | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Finance, staff and coach columns retain readable separation. — |
| v19x9n/09_roster.png | v19x9n | Squad (card view) / eight men, line of five + bench | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Five starters and smaller bench cards distinguish lineup roles. — |
| v19x9n/10_fighter.png | v19x9n | Fighter page / Rail Calder, 3 levels to spend | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The level-spending row is prominent; stats have plain-language descriptions. — |
| v19x9n/11_market.png | v19x9n | Free agents / six men, one unaffordable | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Fees, wages, rating and unaffordability are explicit. — |
| v19x9n/12_staff.png | v19x9n | Staff / two captains hired, 1-star armorer | 5 | 4 | 5 | 5 | 4 | 5 | 4.7 | 0/1 | Extend/Release order reverses between adjacent captain cards. S12-1 |
| v19x9n/13_coach.png | v19x9n | Your coach / 2 skill points to spend | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Available points, current effects and upgrade controls are visible together. — |
| v19x9n/14_records.png | v19x9n | Records: The club tab / club records | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Records retain named club history and clear tab selection. — |
| v19x9n/15_guide.png | v19x9n | Guide / The table page | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | The selected guide topic and compact bullet explanations are clear. — |
| v19x9n/16_arena.png | v19x9n | Arena (venue) / Back field, level 0 | 5 | 4 | 5 | 5 | 5 | 4 | 4.7 | 0/0 | Venue controls are clear; the large venue panel repeats text instead of showing the ground. S16-1 |
| v19x9n/17_chalkboard.png | v19x9n | Playbook editor (chalkboard) / formations tab, a saved shape | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Start line, direction, roles and saved state explain the editor. — |
| v19x9n/18_create_fighter.png | v19x9n | Create: fighter / custom fighter, 4 of 4 creations left | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Stat descriptions, rating cap, price and wage exposure are readable. — |
| v19x9n/19_create_club.png | v19x9n | Create: club / name, kit and badge | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Badge preview, selected mark and paid choices are distinct. — |
| v19x9n/20_create_grade.png | v19x9n | Create: grade / Sanctioned selected | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Selected grade, immediate saving and mechanical effects are explained. — |
| v19x9n/21_bracket.png | v19x9n | Cup bracket / Milwaukee Open, quarter-final to fight | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | Bracket route, next opponent and Fight action are easy to locate. — |
| v19x9n/22_club_menu.png | v19x9n | Pause menu / open over the season hub | 5 | 5 | 5 | 5 | 5 | 5 | 5.0 | 0/0 | A focused pause panel keeps Resume primary and the club visible beneath. — |

## Logical-screen means

| screen / state | viewports | mean | S1/S2 | worst finding |
|---|---|---:|---|---|
| 01_start: Start / front door, career exists | v16x10, v16x9, v19x9n | 4.9 | 0/0 | S01-1 |
| 02_title_slots: Title / save slots / three empty slots | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 03_settings: Settings / in a career | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 04_season_club: Season hub: FIGHT tab / cup quarter-final waiting, Backyard season 3 | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 05_season_squad: Season hub: TEAM tab / levels waiting (+N), no man picked | v16x10, v16x9, v19x9n | 4.9 | 0/1 | S05-1 |
| 06_season_armorer: Season hub: MAINTENANCE tab / 1-star armorer, kit 84-94% | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 07_season_clubhouse: Season hub: UPGRADES tab / cap, camp, infirmary, insurance, arena | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 08_season_finances: Season hub: MANAGEMENT tab / finances, staff, coach card | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 09_roster: Squad (card view) / eight men, line of five + bench | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 10_fighter: Fighter page / Rail Calder, 3 levels to spend | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 11_market: Free agents / six men, one unaffordable | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 12_staff: Staff / two captains hired, 1-star armorer | v16x10, v16x9, v19x9n | 4.7 | 0/1 | S12-1 |
| 13_coach: Your coach / 2 skill points to spend | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 14_records: Records: The club tab / club records | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 15_guide: Guide / The table page | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 16_arena: Arena (venue) / Back field, level 0 | v16x10, v16x9, v19x9n | 4.7 | 0/0 | S16-1 |
| 17_chalkboard: Playbook editor (chalkboard) / formations tab, a saved shape | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 18_create_fighter: Create: fighter / custom fighter, 4 of 4 creations left | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 19_create_club: Create: club / name, kit and badge | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 20_create_grade: Create: grade / Sanctioned selected | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 21_bracket: Cup bracket / Milwaukee Open, quarter-final to fight | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 22_club_menu: Pause menu / open over the season hub | v16x10, v16x9, v19x9n | 5.0 | 0/0 | — |
| 23_walkout: Walk-out (pre-bout splash) / league bout, both clubs | v16x9, v19x9 | 5.0 | 0/0 | — |
| 23b_prefight_plan: Pre-fight plan / formation + play chosen | v16x9, v19x9 | 5.0 | 0/0 | — |
| 24_fight_live: Fight (the list) / live, frame 30, first-bout route tip showing | v16x9, v19x9 | 5.0 | 0/0 | — |
| 25_contact_wheel: Contact wheel / prompt open: a man routed onto a free enemy | v16x9, v19x9 | 4.3 | 0/2 | S25-1 |
| 25b_contact_wheel_third: Contact wheel / prompt open: third man onto a clinch | v16x9, v19x9 | 4.3 | 0/2 | S25-1 |
| 26_corner: Corner (between rounds) / after round 1 | v16x9, v19x9 | 5.0 | 0/0 | — |
| 26b_corner_playbook: Corner: full playbook / favourites starred, two scrolling panes | v16x9, v19x9 | 4.7 | 0/1 | S26b-2 |
| 26c_corner_favourites: Corner: favourites strip / four favourites | v16x9, v19x9 | 5.0 | 0/0 | — |
| 27_corner_sub: Corner: substitution / sub picker open | v16x9, v19x9 | 5.0 | 0/0 | — |
| 28_report: After-action report / bout fought, levels waiting | v16x9, v19x9 | 5.0 | 0/0 | — |
| 29_tip_route: Fight: first-time coach mark / route tip showing | v16x9, v19x9 | 4.7 | 0/1 | S29-1 |
| 29b_tip_corner: Corner: first-time coach mark / corner tip showing | v16x9, v19x9 | 5.0 | 0/0 | — |
| 30_dilemma: Dilemma card / card on the table, prices shown | v16x9, v19x9 | 5.0 | 0/0 | — |
| 31_promotion: Promotion offer / offer open | v16x9, v19x9 | 5.0 | 0/0 | — |
| 32_fixture_sim: Fixture card / sim-it confirm open | v16x9, v19x9 | 5.0 | 0/0 | — |
| 32b_promo_ground_state: Promotion ground prompt / State League needs fenced ground, over the hub | v16x9, v19x9 | 5.0 | 0/0 | — |
| 33_records_this_year: Records: This year / season so far, 5 fought | v16x9, v19x9 | 4.7 | 0/0 | S33-1 |
| 34_promo_ground_regional: Promotion ground prompt / Regional League needs arena; 9048 CC is test money from the tool | v16x9, v19x9 | 5.0 | 0/0 | — |
| 35_hub_week1: Season hub: FIGHT tab / week 1, league fixture waiting | v16x9, v19x9 | 5.0 | 0/0 | — |
| 36_history: Club history / records page | v16x9, v19x9 | 5.0 | 0/0 | — |
| 37_worlds_groups: Worlds / group stage, 16 clubs in 4 pools | v16x9, v19x9 | 5.0 | 0/0 | — |
| 37b_bracket_done: Cup bracket (Path of Honor) / finished, champion shown | v16x9, v19x9 | 4.3 | 0/1 | S37b-1 |
| 38_playbook_favs: Playbook over the walk-out: picking favourites / before | v16x9, v19x9 | 3.7 | 0/2 | S38-1 |
| 38b_playbook_favs: Playbook over the walk-out: picking favourites / after, four starred | v16x9, v19x9 | 3.7 | 0/2 | S38-1 |
| 39_free_agent_market_ask: Free-agent prompt / market_ask | v16x9, v19x9 | 5.0 | 0/0 | — |
| 39_free_agent_market_picked: Free-agent prompt / market_picked | v16x9, v19x9 | 5.0 | 0/0 | — |
| 40_popup_mark: Club tab popup / mark | v16x9, v19x9 | 4.8 | 0/1 | S40-1 |
| 40_popup_town: Club tab popup / town | v16x9, v19x9 | 5.0 | 0/0 | — |
| 41_calendar: Calendar / week 5 of a Backyard season | v16x9, v19x9 | 4.5 | 0/1 | S41-1 |
| 42_founding_step_1: New career (founding) / step_1 | v16x9, v19x9 | 4.3 | 0/1 | S42-1 |
| 42_founding_step_2: New career (founding) / step_2 | v16x9, v19x9 | 5.0 | 0/0 | — |
| 42_founding_step_3: New career (founding) / step_3 | v16x9, v19x9 | 5.0 | 0/0 | — |
| 42_founding_step_4: New career (founding) / step_4 | v16x9, v19x9 | 5.0 | 0/0 | — |

## Findings

### S38-1 — Put the pre-bout full playbook on an opaque modal panel.

- **[seen][judgement][needs validation] S2**: The pre-bout full playbook is drawn without the opaque panel/backdrop seen in the corner version. Louisville and both clubs' stats remain between and behind its title, cards and ordering instructions, merging two screens' content.
- Evidence: `v16x9/38_playbook_favs.png`, `v19x9/38_playbook_favs.png`, `v16x9/38b_playbook_favs.png`, `v19x9/38b_playbook_favs.png`; entire overlay, especially title y80–110 and ordering instruction y378–400.
- Suggestion: Give the pre-bout editor the same opaque modal panel and dimmer as the corner editor; reproduce in the live transition to distinguish game behavior from shot setup.
- Effort: S. Criteria: C1, C2, C3.

### S40-1 — Apply the wide colour-popup offset once; cover the entire viewport with its scrim.

- **[seen][judgement] S2**: The wide mark-colour popup centres around x689 rather than x585, and the dimmer leaves the leftmost 105px as a uniform grey strip. This is a visible frame/overlay-offset mismatch, not useful side padding.
- Evidence: `v19x9/40_popup_mark.png`; full modal and left x0–104 strip.
- Suggestion: Position the modal and scrim in the same coordinate space: apply the wide-frame offset once, cover the full viewport and centre within the safe content rect.
- Effort: S. Criteria: C2, C4.

### S37b-1 — Keep the champion name fully inside Your Path.

- **[seen][judgement] S2**: The CHAMPION heading fits near the bottom of Your Path, but the winning club's name straddles the panel's bottom border. The most celebratory result gets the least stable placement.
- Evidence: `v16x9/37b_bracket_done.png`, `v19x9/37b_bracket_done.png`; right Your Path panel, CHAMPION and Detroit Free at y425–454.
- Suggestion: Reserve a complete champion footer inside the panel or shorten the round summaries enough to give the winner its own padded row.
- Effort: S. Criteria: C2, C3, C4.

### S29-1 — Remove stale walk-out controls from the live-fight coach mark; check the shot fixture.

- **[seen][judgement][needs validation] S2**: Back and Walk out remain visible beneath the route coach mark, superimposed on live-fight fighter cards. The render mixes pre-bout actions with the fight's HUD; whether this is a fixture artifact or a live transition defect needs reproduction.
- Evidence: `v16x9/29_tip_route.png`, `v19x9/29_tip_route.png`; bottom-left Back and bottom-centre Walk out behind dimmer.
- Suggestion: Reproduce the first-bout transition, then hide the walk-out controls before drawing the live fight/coach mark; correct the shot fixture instead if production already does that.
- Effort: S. Criteria: C2, C5.

### S05-1 — Restore the BENCH heading in the taller TEAM layout.

- **[seen][judgement] S2**: The second roster block loses its BENCH heading in the 16:10 render, although the corresponding heading is visible at 16:9 and 19:9. The lineup/reserve distinction is less explicit.
- Evidence: `v16x10/05_season_squad.png`; left roster between starters and Dain/Pike/Orr, y338–360.
- Suggestion: Anchor BENCH above the second block after the taller-layout calculation, with a reserved label row.
- Effort: S. Criteria: C2, C3.

### S12-1 — Keep Extend and Release in the same order on every captain card.

- **[seen][judgement][needs validation] S2**: Vaughn's actions are Release then Extend; Ardry's are Extend then Release. Adjacent cards reverse the placement of the destructive action. Whether this causes wrong taps needs testing, but the inconsistency is visible.
- Evidence: `v16x9/12_staff.png`, `v19x9n/12_staff.png`, `v16x10/12_staff.png`; captain action buttons below the two cards.
- Suggestion: Use one fixed Extend/Release order for every captain card and keep the destructive action visually separated.
- Effort: S. Criteria: C2, C5.

### S41-1 — Preserve Open/Classic distinctions in dated tournament cells.

- **[seen][judgement] S2**: Tournament cells truncate to BALTIMORE..., while the sidebar contains both Baltimore Open and Baltimore Classic. The distinguishing event name disappears from the dated cells.
- Evidence: `v16x9/41_calendar.png`, `v19x9/41_calendar.png`; calendar dates 16–18 and sidebar event list.
- Suggestion: Wrap the event suffix onto a second line or use distinct short labels such as 'B. Classic'; keep the full name available on selection.
- Effort: S. Criteria: C3.

### S26b-2 — Give Done and Back separate meanings and use the correct opener name.

- **[seen][judgement][needs validation] S2**: Done picking favourites and Back to the corner are equally weighted exit-like actions, without explaining whether Done returns to the corner or changes an editing mode. In the pre-bout renders, 'Back to the corner' also names a different context from the walk-out beneath it.
- Evidence: `v16x9/26b_corner_playbook.png`, `v19x9/26b_corner_playbook.png`, `v16x9/38_playbook_favs.png`, `v19x9/38_playbook_favs.png`, `v16x9/38b_playbook_favs.png`, `v19x9/38b_playbook_favs.png`; two bottom modal buttons.
- Suggestion: If Done commits favourites and returns, make that one primary exit; otherwise name the mode change explicitly and visually distinguish it from Back to the corner. Use 'Back to the plan' or the actual opener's name before a bout.
- Effort: S. Criteria: C1.

### S25-1 — Keep wheel action/chance/effect text horizontal.

- **[seen][judgement] S2**: Action, chance and consequence text rotate with each wedge, including an almost vertical Takedown/Bullrush label. Comparing the three options requires reading several orientations; the small raster letters lose clarity at these angles.
- Evidence: `v16x9/25_contact_wheel.png`, `v19x9/25_contact_wheel.png`, `v16x9/25b_contact_wheel_third.png`, `v19x9/25b_contact_wheel_third.png`; lower-right wheel wedge labels.
- Suggestion: Keep action names and probability/effect lines horizontal on compact plates aligned with their wedges; retain the wedge hit areas and sport-specific effects.
- Effort: M. Criteria: C2, C3.

### S25-2 — Keep standing counts and fighter status visible while the wheel is open.

- **[seen][judgement] S2**: The open wheel covers the fifth fighter's bottom card and part of the opponent's standing panel. At 1170px wide the far-right 105px gutter remains available above it, while the overlapping HUD loses context.
- Evidence: `v16x9/25_contact_wheel.png`, `v19x9/25_contact_wheel.png`, `v16x9/25b_contact_wheel_third.png`, `v19x9/25b_contact_wheel_third.png`; opponent HUD and bottom-right fighter status behind wheel.
- Suggestion: Reserve a prompt region or relocate compact option plates so standing counts and the selected fighter's status stay unobscured; do not stretch the locked list.
- Effort: M. Criteria: C4.

### S42-1 — Replace the coach appearance placeholder with a working preview.

- **[seen][judgement] S2**: Face, Kit and Beard controls sit beside a portrait box that only says 'art to follow'. The player cannot see the appearance these choices produce, and unfinished production wording reaches the new-career flow.
- Evidence: `v16x9/42_founding_step_1.png`, `v19x9/42_founding_step_1.png`; coach portrait preview and appearance controls.
- Suggestion: Render the selected coach appearance; until that exists, remove the appearance controls without a visible preview and the development placeholder from the player flow.
- Effort: M. Criteria: C1, C5, C6.

### S33-1 — Separate the total differential from the current grade in the records footer.

- **[seen][judgement] S3**: The footer's red -33 differential runs directly into 'now at full steel', so the statistic and grade read as one continuous string.
- Evidence: `v16x9/33_records_this_year.png`, `v19x9/33_records_this_year.png`; bottom-right summary inside the record panel, y410.
- Suggestion: Give the differential a fixed-width total cell with at least one text-space of padding, and place the current grade in a separate labelled footer field.
- Effort: S. Criteria: C2, C3.

### S41-2 — Separate the calendar heading from its phase label.

- **[seen][judgement] S3**: THE SEASON and 'now: weekdays' touch in the right-hand panel header with no stable separation.
- Evidence: `v16x9/41_calendar.png`, `v19x9/41_calendar.png`; top of right-hand season panel.
- Suggestion: Put the current phase on a separate line beneath the panel heading.
- Effort: S. Criteria: C2.

### S01-1 — Put the music credit inside the declared safe inset.

- **[seen][judgement] S3**: The right-hand music credit ends around x1145, inside the declared right 63px inset (safe edge x1107). This is nonessential text, but the footer does not share the menu's safe-area discipline.
- Evidence: `v19x9n/01_start.png`; bottom-right music credit, y512.
- Suggestion: Inset footer credits by the same safe-area margin as the menu content.
- Effort: S. Criteria: C4.

### S26b-1 — Use the same pixel typography in the full-playbook header.

- **[seen][judgement] S3**: The full-playbook modal's header uses smooth sans-serif lettering while its cards and surrounding fight UI use the pixel font. This is a conspicuous typographic change inside the same interaction.
- Evidence: `v16x9/26b_corner_playbook.png`, `v19x9/26b_corner_playbook.png`, `v16x9/38_playbook_favs.png`, `v19x9/38_playbook_favs.png`, `v16x9/38b_playbook_favs.png`, `v19x9/38b_playbook_favs.png`; top modal title/instruction line.
- Suggestion: Use the established pixel-font header style, with wrapping or a shorter title rather than a fallback font.
- Effort: S. Criteria: C5.

### S16-1 — Let the venue panel show the ground, not just repeat its name and capacity.

- **[seen][judgement] S3**: The roughly 520×300 venue panel is a flat field containing the venue name/capacity again and a badge. It conveys less of a club-owned physical ground than the accompanying description promises.
- Evidence: `v16x9/16_arena.png`, `v19x9n/16_arena.png`, `v16x10/16_arena.png`; large left venue panel.
- Suggestion: Use a small pixel-art venue illustration for the current stage, retaining capacity and the club badge as overlays; let upgrades visibly change the ground.
- Effort: M. Criteria: C2, C6.

## Cross-cutting suggestions

- Use one modal coordinate/layering path for the scrim, panel and controls. Exercise it from both walk-out and corner, at the wide and standard canvases.
- Keep action text horizontal even where the hit area is radial; retain the existing buhurt action choices and mechanical effects.
- Add render checks for labels tied to changing panel height: BENCH, CHAMPION and multi-field footers. These are useful art/layout checks either assistant can write.
- Keep safe-area treatment consistent down to footer credits. Most centred menus use their margins purposefully; there is no blanket penalty for a 960-wide content frame.
- Preserve readable full event identities in the calendar. The market fee labels and dense modal headers are also good candidates for the existing nine-language fit checks, without assuming an unseen translation failure.
- Treat the coach and venue previews as opportunities to make it visibly your club while retaining the fixed palette, binary-alpha assets and locked list ratio.

## What I could not judge from stills

- Motion, sound, touch feel, actual physical-device readability, controller focus/navigation and the timing of tutorial/modal transitions.
- Non-English strings, scrolling states not supplied, and fight/notch or fight/Steam-Deck combinations omitted by the brief. No missing-viewport deductions.
- The coach mark shows a corner timer at 0:00, but a still cannot establish whether gameplay/timers continue under it; that needs a transition test.
- The input manifest calls `26c_corner_favourites` four favourites; both supplied images show two. Scores describe the visible two-card strip. The before/after `38`/`38b` images both show four stars but differ in their order. File `42_founding_step_4` is a CUSTOM state of Step 3 of 3, not a fourth required step.
- Whether the stale walk-out controls and missing playbook backing reproduce in the live build or originate in the shot setup. They are scored as visible weaknesses of the supplied renders, with that uncertainty explicit.
- The fake/test money is not scored as an economy defect; the stills do not validate probability estimates, level counts, league mathematics or purchasing behavior.

Audit files: `codex-review-data.json` contains the individual criterion scores and evidence mappings. `build_codex_score.py` checks complete manifest coverage, native sizes, finding references and a finding for every deduction, then calculates the means.
