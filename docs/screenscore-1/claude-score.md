# Screen Score #1: Claude

*8 Oct 2026, US Central. Blind: written before Codex's score, against the LOCKED
`RUBRIC.md`. Inputs: the 132 renders in `renders/` only. Sealed outside the repo;
SHA-256 in the README.*

Game score: **4.3 / 5** (4.26)   (S1: 0, S2: 13, S3: about 60)
Per viewport: v16x9 4.28 · v19x9n 4.30 · v19x9 4.22 · v16x10 4.28

The menus are solid and consistent. What pulls the score down is concentrated:
- overlays that leak whatever screen was under them;
- the contact wheel's rotated text;
- wide-phone letterboxing on the fight-side screens;
- two money units;
- a run of text sitting on panel borders.

## Priority fixes (S2 first, then by impact ÷ effort; no S1 found)

1. **S38-1 S2:** the playbook over the walk-out has no backing panel. "AWAY / Louisville, KY" and the walk-out's stat rows print through and collide with the overlay. Give it the opaque panel and dim that 26b has. Effort: S.
2. **S29-1 S2:** the walk-out's Back and "Walk out" buttons draw over the fight's card row behind the first-bout tip. Same family as S38-1: free or hide the splash when the fight opens. Effort: M.
3. **S26b-1 S2:** the playbook overlay's header and instructions are set in a smooth, anti-aliased sans, the only non-pixel type in 132 renders. Use the pixel face. Effort: S.
4. **S12-1 S2:** the destructive "Release" swaps sides between the two captain cards. Use one order on both. Effort: S.
5. **S25-1 S2:** the contact wheel's labels are set along the arcs at 45–60°. That's the hardest text in the game to read, at the moment with the least time. Keep the wedges and set the labels horizontal. Effort: M.
6. **S25-2 S2:** each wheel option shows two percentages ("takedown 14%" and "100% chance") with no key. Effort: S.
7. **S04-1 S2:** two money units in one header: "29 CC" next to "$174/$250 wages". The same mix appears across Team, Upgrades, Market and Create. Pick one unit. Effort: M.
8. **S09-1 S2:** footer value boxes (SQUAD MOOD "Flying", CLUB RATING "49") sit on the bottom border, clipping descenders. One cause of the cross-cutting border problem below. Effort: S.
9. **S40-1 S2 (v19x9):** a flat light-grey 100 px column down the left edge, with the Create screen pushed right under the mark-colour popup. It looks broken. Effort: M.
10. **S23-1 S2 (v19x9):** the walk-out, pre-fight, fight, corner, report and tips stay in a 960 box with ~105 px bands of a different grey either side. That reads as letterboxing. The list ratio stays locked; extend the backgrounds and stage bands full width. Effort: M.
11. **S10-1 S2:** the fighter page's left panel holds 14 rows and presses "Asks at renewal…" onto its border. Move the level block into its own strip above the +3 buttons. Effort: M.
12. **S16-1 S2:** the Arena screen's centrepiece is a placeholder box (name and badge only). Art is needed. Effort: M.
13. **S42-1 S2:** the first screen of a new career shows "art to follow" where the coach is, and the Face, Kit and Beard pickers change nothing visible. Art is needed. Effort: M.
14. **S3 quick wins, an hour each:**
    - "-33now" in records and "SEASONnow:" in the calendar are each missing a space;
    - the "Pit" fragment bottom-right on the week-1 hub;
    - BENCH label missing at 16:10;
    - give "Sign him" a reason when it's disabled;
    - same icon for Guide and Save/Load;
    - red "pass" marker on passing kit;
    - selected settings toggles read weaker than unselected ones.

## Cross-cutting suggestions

- **Overlay hygiene is the single biggest theme.** Every popup should own an opaque
  panel plus a dim, and the previous screen should be hidden or freed. Two separate
  leaks were found (S29, S38). A render test that diffs a known "empty" region of
  each overlay would catch both.
- **Text on borders.** Card footers (market, free agents), roster footer boxes,
  champion line (37b) and dilemma outcomes all sit on the bottom border. One rule in
  the UI kit (a minimum bottom padding of about 4 px at ×2) fixes the class.
- **One money unit.** CC is the game's currency; wages and the cap in "$" read as a
  second economy.
- **Wide phones.** The menus use the extra width well (hub, table, bracket). The
  fight-side screens don't. Full-width stage bands are cheap. The crowd and stands
  art in the side gutters is the real answer (DIRECTION's venue framing).
- **Panels with large empty areas** (title slots, guide, staff, arena venue, grade
  description, history, fight report): fine as margins, but several could carry
  the thing the player is deciding about, such as the harness ladder on Maintenance
  or the grade's effects next to its description.
- **Role colours** differ between the two free-agent renders (dark vs saturated).
  Pick one palette per role and use it everywhere.
- **Selection state:** settings toggles, the picked free agent (39) and the slot list
  (17) each show "selected" differently. One selected style, gold fill like the
  primary button, would unify them.

## What I could not judge from stills

- Touch targets in use, controller focus (Steam Deck), motion and timing (the wheel
  under a running clock), sound, and the eight other languages.
- Whether the empty bands bother players is [needs validation]. Whether the
  Spend-levels count overpromises is known from bake-off #2 (Codex's finding),
  so I left it out of the scores.

## Logical-screen means
| screen / state | mean |
|---|---|
| 01_start | 5.00 |
| 02_title_slots | 4.67 |
| 03_settings | 4.33 |
| 04_season_club | 4.28 |
| 05_season_squad | 3.94 |
| 06_season_armorer | 4.00 |
| 07_season_clubhouse | 4.17 |
| 08_season_finances | 4.17 |
| 09_roster | 3.83 |
| 10_fighter | 3.83 |
| 11_market | 4.00 |
| 12_staff | 3.83 |
| 13_coach | 4.83 |
| 14_records | 4.72 |
| 15_guide | 4.33 |
| 16_arena | 3.83 |
| 17_chalkboard | 4.00 |
| 18_create_fighter | 4.17 |
| 19_create_club | 4.50 |
| 20_create_grade | 4.50 |
| 21_bracket | 4.83 |
| 22_club_menu | 4.67 |
| 23_walkout | 4.25 |
| 23b_prefight_plan | 4.58 |
| 24_fight_live | 4.25 |
| 25_contact_wheel | 3.67 |
| 25b_contact_wheel_third | 3.67 |
| 26_corner | 4.58 |
| 26b_corner_playbook | 3.67 |
| 26c_corner_favourites | 4.67 |
| 27_corner_sub | 4.58 |
| 28_report | 4.08 |
| 29_tip_route | 3.58 |
| 29b_tip_corner | 4.58 |
| 30_dilemma | 4.67 |
| 31_promotion | 4.83 |
| 32_fixture_sim | 4.50 |
| 32b_promo_ground_state | 4.83 |
| 33_records_this_year | 4.00 |
| 34_promo_ground_regional | 4.83 |
| 35_hub_week1 | 4.33 |
| 36_history | 4.33 |
| 37_worlds_groups | 4.83 |
| 37b_bracket_done | 4.67 |
| 38_playbook_favs | 2.67 |
| 38b_playbook_favs | 2.67 |
| 39_free_agent_market_ask | 4.83 |
| 39_free_agent_market_picked | 3.83 |
| 40_popup_mark | 4.00 |
| 40_popup_town | 4.67 |
| 41_calendar | 4.50 |
| 42_founding_step_1 | 4.00 |
| 42_founding_step_2 | 4.50 |
| 42_founding_step_3 | 4.50 |
| 42_founding_step_4 | 3.83 |

## Scores (every manifest row)
| render | viewport | screen / state | C1 | C2 | C3 | C4 | C5 | C6 | score | S1/S2 |
|---|---|---|---|---|---|---|---|---|---|---|
| v16x10/01_start.png | v16x10 | Start / front door, career exists | 5 | 5 | 5 | 5 | 5 | 5 | 5.00 | 0/0 |
| v16x10/02_title_slots.png | v16x10 | Title / save slots / three empty slots | 5 | 4 | 5 | 5 | 5 | 4 | 4.67 | 0/0 |
| v16x10/03_settings.png | v16x10 | Settings / in a career | 4 | 4 | 5 | 5 | 4 | 4 | 4.33 | 0/0 |
| v16x10/04_season_club.png | v16x10 | Season hub: FIGHT tab / cup quarter-final waiting, Backyard season 3 | 5 | 4 | 4 | 4 | 4 | 5 | 4.33 | 0/1 |
| v16x10/05_season_squad.png | v16x10 | Season hub: TEAM tab / levels waiting (+N), no man picked | 4 | 4 | 3 | 4 | 4 | 4 | 3.83 | 0/1 |
| v16x10/06_season_armorer.png | v16x10 | Season hub: MAINTENANCE tab / 1-star armorer, kit 84-94% | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/0 |
| v16x10/07_season_clubhouse.png | v16x10 | Season hub: UPGRADES tab / cap, camp, infirmary, insurance, arena | 4 | 4 | 4 | 5 | 4 | 4 | 4.17 | 0/1 |
| v16x10/08_season_finances.png | v16x10 | Season hub: MANAGEMENT tab / finances, staff, coach card | 4 | 4 | 5 | 4 | 4 | 4 | 4.17 | 0/0 |
| v16x10/09_roster.png | v16x10 | Squad (card view) / eight men, line of five + bench | 4 | 4 | 3 | 4 | 4 | 4 | 3.83 | 0/1 |
| v16x10/10_fighter.png | v16x10 | Fighter page / Rail Calder, 3 levels to spend | 4 | 3 | 3 | 4 | 4 | 5 | 3.83 | 0/1 |
| v16x10/11_market.png | v16x10 | Free agents / six men, one unaffordable | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/1 |
| v16x10/12_staff.png | v16x10 | Staff / two captains hired, 1-star armorer | 4 | 3 | 4 | 4 | 4 | 4 | 3.83 | 0/1 |
| v16x10/13_coach.png | v16x10 | Your coach / 2 skill points to spend | 5 | 5 | 5 | 5 | 5 | 4 | 4.83 | 0/0 |
| v16x10/14_records.png | v16x10 | Records: The club tab / club records | 5 | 5 | 3 | 5 | 5 | 4 | 4.50 | 0/0 |
| v16x10/15_guide.png | v16x10 | Guide / The table page | 5 | 4 | 5 | 4 | 4 | 4 | 4.33 | 0/0 |
| v16x10/16_arena.png | v16x10 | Arena (venue) / Back field, level 0 | 4 | 4 | 4 | 4 | 4 | 3 | 3.83 | 0/1 |
| v16x10/17_chalkboard.png | v16x10 | Playbook editor (chalkboard) / formations tab, a saved shape | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/0 |
| v16x10/18_create_fighter.png | v16x10 | Create: fighter / custom fighter, 4 of 4 creations left | 4 | 4 | 5 | 4 | 4 | 4 | 4.17 | 0/0 |
| v16x10/19_create_club.png | v16x10 | Create: club / name, kit and badge | 5 | 4 | 4 | 4 | 5 | 5 | 4.50 | 0/0 |
| v16x10/20_create_grade.png | v16x10 | Create: grade / Sanctioned selected | 5 | 4 | 5 | 4 | 5 | 4 | 4.50 | 0/0 |
| v16x10/21_bracket.png | v16x10 | Cup bracket / Milwaukee Open, quarter-final to fight | 5 | 5 | 5 | 5 | 5 | 4 | 4.83 | 0/0 |
| v16x10/22_club_menu.png | v16x10 | Pause menu / open over the season hub | 5 | 5 | 5 | 5 | 4 | 4 | 4.67 | 0/0 |
| v16x9/01_start.png | v16x9 | Start / front door, career exists | 5 | 5 | 5 | 5 | 5 | 5 | 5.00 | 0/0 |
| v16x9/02_title_slots.png | v16x9 | Title / save slots / three empty slots | 5 | 4 | 5 | 5 | 5 | 4 | 4.67 | 0/0 |
| v16x9/03_settings.png | v16x9 | Settings / in a career | 4 | 4 | 5 | 5 | 4 | 4 | 4.33 | 0/0 |
| v16x9/04_season_club.png | v16x9 | Season hub: FIGHT tab / cup quarter-final waiting, Backyard season 3 | 5 | 4 | 4 | 4 | 4 | 5 | 4.33 | 0/1 |
| v16x9/05_season_squad.png | v16x9 | Season hub: TEAM tab / levels waiting (+N), no man picked | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/1 |
| v16x9/06_season_armorer.png | v16x9 | Season hub: MAINTENANCE tab / 1-star armorer, kit 84-94% | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/0 |
| v16x9/07_season_clubhouse.png | v16x9 | Season hub: UPGRADES tab / cap, camp, infirmary, insurance, arena | 4 | 4 | 4 | 5 | 4 | 4 | 4.17 | 0/1 |
| v16x9/08_season_finances.png | v16x9 | Season hub: MANAGEMENT tab / finances, staff, coach card | 4 | 4 | 5 | 4 | 4 | 4 | 4.17 | 0/0 |
| v16x9/09_roster.png | v16x9 | Squad (card view) / eight men, line of five + bench | 4 | 4 | 3 | 4 | 4 | 4 | 3.83 | 0/1 |
| v16x9/10_fighter.png | v16x9 | Fighter page / Rail Calder, 3 levels to spend | 4 | 3 | 3 | 4 | 4 | 5 | 3.83 | 0/1 |
| v16x9/11_market.png | v16x9 | Free agents / six men, one unaffordable | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/1 |
| v16x9/12_staff.png | v16x9 | Staff / two captains hired, 1-star armorer | 4 | 3 | 4 | 4 | 4 | 4 | 3.83 | 0/1 |
| v16x9/13_coach.png | v16x9 | Your coach / 2 skill points to spend | 5 | 5 | 5 | 5 | 5 | 4 | 4.83 | 0/0 |
| v16x9/14_records.png | v16x9 | Records: The club tab / club records | 5 | 5 | 5 | 5 | 5 | 4 | 4.83 | 0/0 |
| v16x9/15_guide.png | v16x9 | Guide / The table page | 5 | 4 | 5 | 4 | 4 | 4 | 4.33 | 0/0 |
| v16x9/16_arena.png | v16x9 | Arena (venue) / Back field, level 0 | 4 | 4 | 4 | 4 | 4 | 3 | 3.83 | 0/1 |
| v16x9/17_chalkboard.png | v16x9 | Playbook editor (chalkboard) / formations tab, a saved shape | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/0 |
| v16x9/18_create_fighter.png | v16x9 | Create: fighter / custom fighter, 4 of 4 creations left | 4 | 4 | 5 | 4 | 4 | 4 | 4.17 | 0/0 |
| v16x9/19_create_club.png | v16x9 | Create: club / name, kit and badge | 5 | 4 | 4 | 4 | 5 | 5 | 4.50 | 0/0 |
| v16x9/20_create_grade.png | v16x9 | Create: grade / Sanctioned selected | 5 | 4 | 5 | 4 | 5 | 4 | 4.50 | 0/0 |
| v16x9/21_bracket.png | v16x9 | Cup bracket / Milwaukee Open, quarter-final to fight | 5 | 5 | 5 | 5 | 5 | 4 | 4.83 | 0/0 |
| v16x9/22_club_menu.png | v16x9 | Pause menu / open over the season hub | 5 | 5 | 5 | 5 | 4 | 4 | 4.67 | 0/0 |
| v16x9/23_walkout.png | v16x9 | Walk-out (pre-bout splash) / league bout, both clubs | 5 | 4 | 4 | 4 | 4 | 5 | 4.33 | 0/1 |
| v16x9/23b_prefight_plan.png | v16x9 | Pre-fight plan / formation + play chosen | 5 | 5 | 4 | 4 | 5 | 5 | 4.67 | 0/0 |
| v16x9/24_fight_live.png | v16x9 | Fight (the list) / live, frame 30, first-bout route tip showing | 4 | 4 | 4 | 4 | 5 | 5 | 4.33 | 0/0 |
| v16x9/25_contact_wheel.png | v16x9 | Contact wheel / prompt open: a man routed onto a free enemy | 4 | 3 | 2 | 4 | 4 | 5 | 3.67 | 0/2 |
| v16x9/25b_contact_wheel_third.png | v16x9 | Contact wheel / prompt open: third man onto a clinch | 4 | 3 | 2 | 4 | 4 | 5 | 3.67 | 0/2 |
| v16x9/26_corner.png | v16x9 | Corner (between rounds) / after round 1 | 5 | 5 | 4 | 4 | 5 | 5 | 4.67 | 0/0 |
| v16x9/26b_corner_playbook.png | v16x9 | Corner: full playbook / favourites starred, two scrolling panes | 4 | 4 | 4 | 4 | 2 | 4 | 3.67 | 0/1 |
| v16x9/26c_corner_favourites.png | v16x9 | Corner: favourites strip / four favourites | 5 | 4 | 5 | 4 | 5 | 5 | 4.67 | 0/0 |
| v16x9/27_corner_sub.png | v16x9 | Corner: substitution / sub picker open | 5 | 5 | 5 | 4 | 5 | 4 | 4.67 | 0/0 |
| v16x9/28_report.png | v16x9 | After-action report / bout fought, levels waiting | 4 | 4 | 4 | 4 | 4 | 5 | 4.17 | 0/0 |
| v16x9/29_tip_route.png | v16x9 | Fight: first-time coach mark / route tip showing | 4 | 3 | 4 | 4 | 3 | 4 | 3.67 | 0/1 |
| v16x9/29b_tip_corner.png | v16x9 | Corner: first-time coach mark / corner tip showing | 5 | 5 | 5 | 4 | 5 | 4 | 4.67 | 0/0 |
| v16x9/30_dilemma.png | v16x9 | Dilemma card / card on the table, prices shown | 5 | 4 | 4 | 5 | 5 | 5 | 4.67 | 0/0 |
| v16x9/31_promotion.png | v16x9 | Promotion offer / offer open | 5 | 5 | 5 | 4 | 5 | 5 | 4.83 | 0/0 |
| v16x9/32_fixture_sim.png | v16x9 | Fixture card / sim-it confirm open | 5 | 5 | 5 | 4 | 4 | 4 | 4.50 | 0/0 |
| v16x9/32b_promo_ground_state.png | v16x9 | Promotion ground prompt / State League needs fenced ground, over the hub | 5 | 5 | 5 | 4 | 5 | 5 | 4.83 | 0/0 |
| v16x9/33_records_this_year.png | v16x9 | Records: This year / season so far, 5 fought | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/0 |
| v16x9/34_promo_ground_regional.png | v16x9 | Promotion ground prompt / Regional League needs arena; 9048 CC is test money from the tool | 5 | 5 | 5 | 4 | 5 | 5 | 4.83 | 0/0 |
| v16x9/35_hub_week1.png | v16x9 | Season hub: FIGHT tab / week 1, league fixture waiting | 5 | 4 | 4 | 4 | 4 | 5 | 4.33 | 0/0 |
| v16x9/36_history.png | v16x9 | Club history / records page | 5 | 4 | 5 | 4 | 4 | 4 | 4.33 | 0/0 |
| v16x9/37_worlds_groups.png | v16x9 | Worlds / group stage, 16 clubs in 4 pools | 5 | 5 | 5 | 5 | 5 | 4 | 4.83 | 0/0 |
| v16x9/37b_bracket_done.png | v16x9 | Cup bracket (Path of Honor) / finished, champion shown | 5 | 5 | 4 | 5 | 5 | 4 | 4.67 | 0/0 |
| v16x9/38_playbook_favs.png | v16x9 | Playbook over the walk-out: picking favourites / before | 3 | 2 | 2 | 3 | 2 | 4 | 2.67 | 0/1 |
| v16x9/38b_playbook_favs.png | v16x9 | Playbook over the walk-out: picking favourites / after, four starred | 3 | 2 | 2 | 3 | 2 | 4 | 2.67 | 0/1 |
| v16x9/39_free_agent_market_ask.png | v16x9 | Free-agent prompt / market_ask | 5 | 5 | 5 | 4 | 5 | 5 | 4.83 | 0/0 |
| v16x9/39_free_agent_market_picked.png | v16x9 | Free-agent prompt / market_picked | 4 | 4 | 4 | 4 | 3 | 4 | 3.83 | 0/0 |
| v16x9/40_popup_mark.png | v16x9 | Club tab popup / mark | 4 | 4 | 5 | 4 | 4 | 4 | 4.17 | 0/1 |
| v16x9/40_popup_town.png | v16x9 | Club tab popup / town | 5 | 5 | 5 | 4 | 5 | 4 | 4.67 | 0/0 |
| v16x9/41_calendar.png | v16x9 | Calendar / week 5 of a Backyard season | 5 | 5 | 4 | 4 | 5 | 4 | 4.50 | 0/0 |
| v16x9/42_founding_step_1.png | v16x9 | New career (founding) / step_1 | 4 | 4 | 5 | 4 | 4 | 3 | 4.00 | 0/1 |
| v16x9/42_founding_step_2.png | v16x9 | New career (founding) / step_2 | 5 | 4 | 4 | 4 | 5 | 5 | 4.50 | 0/0 |
| v16x9/42_founding_step_3.png | v16x9 | New career (founding) / step_3 | 5 | 4 | 5 | 4 | 5 | 4 | 4.50 | 0/0 |
| v16x9/42_founding_step_4.png | v16x9 | New career (founding) / step_4 | 4 | 3 | 4 | 4 | 4 | 4 | 3.83 | 0/0 |
| v19x9/23_walkout.png | v19x9 | Walk-out (pre-bout splash) / league bout, both clubs | 5 | 4 | 4 | 3 | 4 | 5 | 4.17 | 0/1 |
| v19x9/23b_prefight_plan.png | v19x9 | Pre-fight plan / formation + play chosen | 5 | 5 | 4 | 3 | 5 | 5 | 4.50 | 0/0 |
| v19x9/24_fight_live.png | v19x9 | Fight (the list) / live, frame 30, first-bout route tip showing | 4 | 4 | 4 | 3 | 5 | 5 | 4.17 | 0/0 |
| v19x9/25_contact_wheel.png | v19x9 | Contact wheel / prompt open: a man routed onto a free enemy | 4 | 3 | 2 | 4 | 4 | 5 | 3.67 | 0/2 |
| v19x9/25b_contact_wheel_third.png | v19x9 | Contact wheel / prompt open: third man onto a clinch | 4 | 3 | 2 | 4 | 4 | 5 | 3.67 | 0/2 |
| v19x9/26_corner.png | v19x9 | Corner (between rounds) / after round 1 | 5 | 5 | 4 | 3 | 5 | 5 | 4.50 | 0/0 |
| v19x9/26b_corner_playbook.png | v19x9 | Corner: full playbook / favourites starred, two scrolling panes | 4 | 4 | 4 | 4 | 2 | 4 | 3.67 | 0/1 |
| v19x9/26c_corner_favourites.png | v19x9 | Corner: favourites strip / four favourites | 5 | 4 | 5 | 4 | 5 | 5 | 4.67 | 0/0 |
| v19x9/27_corner_sub.png | v19x9 | Corner: substitution / sub picker open | 5 | 5 | 5 | 3 | 5 | 4 | 4.50 | 0/0 |
| v19x9/28_report.png | v19x9 | After-action report / bout fought, levels waiting | 4 | 4 | 4 | 3 | 4 | 5 | 4.00 | 0/0 |
| v19x9/29_tip_route.png | v19x9 | Fight: first-time coach mark / route tip showing | 4 | 3 | 4 | 3 | 3 | 4 | 3.50 | 0/1 |
| v19x9/29b_tip_corner.png | v19x9 | Corner: first-time coach mark / corner tip showing | 5 | 5 | 5 | 3 | 5 | 4 | 4.50 | 0/0 |
| v19x9/30_dilemma.png | v19x9 | Dilemma card / card on the table, prices shown | 5 | 4 | 4 | 5 | 5 | 5 | 4.67 | 0/0 |
| v19x9/31_promotion.png | v19x9 | Promotion offer / offer open | 5 | 5 | 5 | 4 | 5 | 5 | 4.83 | 0/0 |
| v19x9/32_fixture_sim.png | v19x9 | Fixture card / sim-it confirm open | 5 | 5 | 5 | 4 | 4 | 4 | 4.50 | 0/0 |
| v19x9/32b_promo_ground_state.png | v19x9 | Promotion ground prompt / State League needs fenced ground, over the hub | 5 | 5 | 5 | 4 | 5 | 5 | 4.83 | 0/0 |
| v19x9/33_records_this_year.png | v19x9 | Records: This year / season so far, 5 fought | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/0 |
| v19x9/34_promo_ground_regional.png | v19x9 | Promotion ground prompt / Regional League needs arena; 9048 CC is test money from the tool | 5 | 5 | 5 | 4 | 5 | 5 | 4.83 | 0/0 |
| v19x9/35_hub_week1.png | v19x9 | Season hub: FIGHT tab / week 1, league fixture waiting | 5 | 4 | 4 | 4 | 4 | 5 | 4.33 | 0/0 |
| v19x9/36_history.png | v19x9 | Club history / records page | 5 | 4 | 5 | 4 | 4 | 4 | 4.33 | 0/0 |
| v19x9/37_worlds_groups.png | v19x9 | Worlds / group stage, 16 clubs in 4 pools | 5 | 5 | 5 | 5 | 5 | 4 | 4.83 | 0/0 |
| v19x9/37b_bracket_done.png | v19x9 | Cup bracket (Path of Honor) / finished, champion shown | 5 | 5 | 4 | 5 | 5 | 4 | 4.67 | 0/0 |
| v19x9/38_playbook_favs.png | v19x9 | Playbook over the walk-out: picking favourites / before | 3 | 2 | 2 | 3 | 2 | 4 | 2.67 | 0/1 |
| v19x9/38b_playbook_favs.png | v19x9 | Playbook over the walk-out: picking favourites / after, four starred | 3 | 2 | 2 | 3 | 2 | 4 | 2.67 | 0/1 |
| v19x9/39_free_agent_market_ask.png | v19x9 | Free-agent prompt / market_ask | 5 | 5 | 5 | 4 | 5 | 5 | 4.83 | 0/0 |
| v19x9/39_free_agent_market_picked.png | v19x9 | Free-agent prompt / market_picked | 4 | 4 | 4 | 4 | 3 | 4 | 3.83 | 0/0 |
| v19x9/40_popup_mark.png | v19x9 | Club tab popup / mark | 4 | 4 | 5 | 2 | 4 | 4 | 3.83 | 0/1 |
| v19x9/40_popup_town.png | v19x9 | Club tab popup / town | 5 | 5 | 5 | 4 | 5 | 4 | 4.67 | 0/0 |
| v19x9/41_calendar.png | v19x9 | Calendar / week 5 of a Backyard season | 5 | 5 | 4 | 4 | 5 | 4 | 4.50 | 0/0 |
| v19x9/42_founding_step_1.png | v19x9 | New career (founding) / step_1 | 4 | 4 | 5 | 4 | 4 | 3 | 4.00 | 0/1 |
| v19x9/42_founding_step_2.png | v19x9 | New career (founding) / step_2 | 5 | 4 | 4 | 4 | 5 | 5 | 4.50 | 0/0 |
| v19x9/42_founding_step_3.png | v19x9 | New career (founding) / step_3 | 5 | 4 | 5 | 4 | 5 | 4 | 4.50 | 0/0 |
| v19x9/42_founding_step_4.png | v19x9 | New career (founding) / step_4 | 4 | 3 | 4 | 4 | 4 | 4 | 3.83 | 0/0 |
| v19x9n/01_start.png | v19x9n | Start / front door, career exists | 5 | 5 | 5 | 5 | 5 | 5 | 5.00 | 0/0 |
| v19x9n/02_title_slots.png | v19x9n | Title / save slots / three empty slots | 5 | 4 | 5 | 5 | 5 | 4 | 4.67 | 0/0 |
| v19x9n/03_settings.png | v19x9n | Settings / in a career | 4 | 4 | 5 | 5 | 4 | 4 | 4.33 | 0/0 |
| v19x9n/04_season_club.png | v19x9n | Season hub: FIGHT tab / cup quarter-final waiting, Backyard season 3 | 5 | 4 | 3 | 4 | 4 | 5 | 4.17 | 0/1 |
| v19x9n/05_season_squad.png | v19x9n | Season hub: TEAM tab / levels waiting (+N), no man picked | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/1 |
| v19x9n/06_season_armorer.png | v19x9n | Season hub: MAINTENANCE tab / 1-star armorer, kit 84-94% | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/0 |
| v19x9n/07_season_clubhouse.png | v19x9n | Season hub: UPGRADES tab / cap, camp, infirmary, insurance, arena | 4 | 4 | 4 | 5 | 4 | 4 | 4.17 | 0/1 |
| v19x9n/08_season_finances.png | v19x9n | Season hub: MANAGEMENT tab / finances, staff, coach card | 4 | 4 | 5 | 4 | 4 | 4 | 4.17 | 0/0 |
| v19x9n/09_roster.png | v19x9n | Squad (card view) / eight men, line of five + bench | 4 | 4 | 3 | 4 | 4 | 4 | 3.83 | 0/1 |
| v19x9n/10_fighter.png | v19x9n | Fighter page / Rail Calder, 3 levels to spend | 4 | 3 | 3 | 4 | 4 | 5 | 3.83 | 0/1 |
| v19x9n/11_market.png | v19x9n | Free agents / six men, one unaffordable | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/1 |
| v19x9n/12_staff.png | v19x9n | Staff / two captains hired, 1-star armorer | 4 | 3 | 4 | 4 | 4 | 4 | 3.83 | 0/1 |
| v19x9n/13_coach.png | v19x9n | Your coach / 2 skill points to spend | 5 | 5 | 5 | 5 | 5 | 4 | 4.83 | 0/0 |
| v19x9n/14_records.png | v19x9n | Records: The club tab / club records | 5 | 5 | 5 | 5 | 5 | 4 | 4.83 | 0/0 |
| v19x9n/15_guide.png | v19x9n | Guide / The table page | 5 | 4 | 5 | 4 | 4 | 4 | 4.33 | 0/0 |
| v19x9n/16_arena.png | v19x9n | Arena (venue) / Back field, level 0 | 4 | 4 | 4 | 4 | 4 | 3 | 3.83 | 0/1 |
| v19x9n/17_chalkboard.png | v19x9n | Playbook editor (chalkboard) / formations tab, a saved shape | 4 | 4 | 4 | 4 | 4 | 4 | 4.00 | 0/0 |
| v19x9n/18_create_fighter.png | v19x9n | Create: fighter / custom fighter, 4 of 4 creations left | 4 | 4 | 5 | 4 | 4 | 4 | 4.17 | 0/0 |
| v19x9n/19_create_club.png | v19x9n | Create: club / name, kit and badge | 5 | 4 | 4 | 4 | 5 | 5 | 4.50 | 0/0 |
| v19x9n/20_create_grade.png | v19x9n | Create: grade / Sanctioned selected | 5 | 4 | 5 | 4 | 5 | 4 | 4.50 | 0/0 |
| v19x9n/21_bracket.png | v19x9n | Cup bracket / Milwaukee Open, quarter-final to fight | 5 | 5 | 5 | 5 | 5 | 4 | 4.83 | 0/0 |
| v19x9n/22_club_menu.png | v19x9n | Pause menu / open over the season hub | 5 | 5 | 5 | 5 | 4 | 4 | 4.67 | 0/0 |

## Findings, by screen (working notes, verbatim)
Format: screen | C1–C6 | findings. Severity, [seen]/[judgement]/[needs validation], effort inline.

- 01 start | all vp 5,5,5,5,5,5 | none. Watermark tiles ok.
- 02 title_slots | 5,4,5,5,5,4 | S3 cards ~55% empty body; three identical "Start a club" — fine for empty state. S3 v16x10 dead band between cards and Back (60px) purposeful.
- 03 settings | 4,4,5,5,4,4 | S3 [seen] selected toggle (Corner/Right) = grey fill + gold outline while unselected = blue fill: selected reads weaker than unselected. Suggest gold fill for selected (as Play). Effort S. S3 "Credits & licenses" fills its button edge to edge in en — de/pl check.
- 04 season_club | 5,4,4,4,4,5 | S2 [seen] two money units in one header: "29 CC" and "$174/$250 wages" (also TEAM "$174 of $250", 11_market "$174/250") — wages read as dollars next to a CC purse; pick one unit. M. S3 [seen] v19x9n header "Coach, l." truncated. S3 [seen] table names truncate differently per viewport (v16x10 "Pittsburgh", "Oklahoma City"; v16x9 "Oklahoma City Free"). S3 table ends at row 6 leaving ~130px empty under it right column (16x9) — fine.
- 05 season_squad | 4,4,4,4,4,4 | S3 [seen] v16x10: BENCH label missing (gap where 16x9 shows "BENCH"). S3 [seen] RESERVE panel = one button + ~100px empty box; "Hire free agent (4 open)" and bottom "Free agents" do the same thing. S3 legend line "+2 = levels…" good. Wage $ vs CC again.
- 06 season_armorer | 4,4,4,4,4,4 | S3 [seen] the "pass" marker and label are red while every bar passes — red reads as failure; use neutral/white tick. S. S3 [seen] harness GRADE per man not shown (only "all kit Rust" in header); the buy is the screen's job → show grade per row. S. S3 [seen] two TRAVELING columns split 6/2, lower ~40% empty (16x9) — fine as purposeful? [judgement] right column could hold the harness ladder/prices. M.
- 07 season_clubhouse (UPGRADES) | 4,4,4,5,4,4 | S3 [seen] "Injuries -0 → -1", "Level 0 → 1" (insurance) labels don't say what moves; e.g. "Insurance lvl 0 → 1". S. S2(dup of 04) $ cap vs CC prices on same row "Cap $250 → $288 · 4 CC". Dense but ordered.
- 08 season_finances (MANAGEMENT) | 4,4,5,4,4,4 | S3 [judgement] Playbook + Team edit live under the YOU/coach card; they are squad tools — misplaced. S. S3 [seen] Finances panel ~40% empty below the sentence. "Total -31 CC" in red beside "29 CC in hand" reads as debt [judgement]; label "This year so far".
- 09 roster (cards) | 4,4,3,4,4,4 | S2 [seen] footer boxes SQUAD MOOD / CLUB RATING: values "Flying", "49" sit on/under the box's bottom border (clipped descenders) all 3 vp. S. S3 [seen] bench cards cramped: name, slot number, "rated 42", "kit 94%" touching. S3 ~90px dead band between bench and footer.
- 10 fighter | 4,3,3,4,4,5 | S2 [seen] left info panel overfull: 14 rows incl. two-line "Known for Burns Out / Goes early.", the gold "Each level: +3…" and "Asks at renewal $23/yr · 3y" pressed onto the bottom border (all vp). Move level block out to its own strip above the +3 buttons. M. S3 [seen] "Invest +3" smallest button on screen, text touching edges. S3 [judgement] bottom row of 7 controls (Back, Leave at home, Extend early, <, 1 of 8, >, Weapon) all same weight; pager reads as part of the row.
- 11 market | 4,4,4,4,4,4 | S3 [seen] card footer text ("Journeyman", "Marquee", "sign 1 CC") sits on the card's bottom border; descenders clipped (all vp). S3 [seen] "Reroll the list · 3 CC" text butts the button's left edge. S3 [seen] rating/ceiling stars tiny and dim (unfilled almost invisible). S3 v16x10 cards stretched with an empty mid-card band.
- 12 staff | 4,3,4,4,4,4 | S2 [seen] destructive "Release" swaps sides between the two captain cards (card 1: Release|Extend; card 2: Extend|Release) — same spot does opposite things. Fix one order (Extend left, Release right) for both. S. S3 [seen] captain cards ~50% empty inside; "Normal · 3y" unexplained (what is Normal?). S3 right column only fills top third.
- 13 coach | 5,5,5,5,5,4 | none above S3. S3 [judgement] ~60px empty band under title; name placeholder "Coach".
- 14 records (The club) | 5,5,4,5,5,4 | S3 [seen] v16x10: HELD BY and SET columns collide ("Hester Kerr · PC before you" no gap) — rows render taller/larger there. S3 [judgement] all five records "before you": no hint how close your men are.
- 15 guide | 5,4,5,4,4,4 | S3 [seen] content panel ~50% empty below six bullets (all vp). S3 [judgement] Guide/Title/Settings/Start use a warm brown ground, season screens navy: two palettes for the same UI kit — intentional "out of season" vs "in season"? If so fine; else unify.
- 16 arena | 4,4,4,4,4,3 | S2 [seen] the left half is a placeholder: an empty dark box with the venue name and badge where the venue picture goes (all vp) — the screen's centrepiece is missing art. M (art). S3 [seen] "each tick is a gate pay rise" sits on the VENUE panel's top border. S3 VENUE panel ~40% empty between "Next:" and the button.
- 17 chalkboard (playbook editor) | 4,4,4,4,4,4 | S3 [judgement] "Next bout opens in: 2-1-2" beside a selected "Strong Right" — two shapes named, unclear which is live. S3 [seen] instructions in small dim grey under the slot list. S3 right ~75% of the field is empty (by design: the list) — fine.
- 18 create_fighter | 4,4,5,4,4,4 | S3 [seen] "Sign him – 3 CC" disabled with no reason shown (empty name). Add "Name him first". S. S3 [seen] "29 CC" / "4 of 4 creations left" right-aligned to x≈840, not the 935 edge every other screen uses. S3 right column ~40% empty.
- 19 create_club | 5,4,4,4,5,5 | S3 [seen] "1 CC"/"2 CC" price banners cover the top of the locked badge art. S3 [seen] HOME TOWN button indented under its label, not aligned with the fields above.
- 20 create_grade | 5,4,5,4,5,4 | S3 [seen] SANCTIONED description box is a narrow column ~60% empty while WHAT IT CHANGES is wide; merge into one panel. S.
- 21 bracket | 5,5,5,5,5,4 | none. Clean; YOUR PATH panel is the right idea.
- 22 club_menu (pause) | 5,5,5,5,4,4 | S3 [seen] Guide and Save / Load use the same document icon; "Save & quit" uses ×. S.
- 23 walkout | v16x9 5,4,4,4,4,5 ; v19x9 5,4,4,3,4,5 | S2 [seen] v19x9: content stays in a 960 box with ~105px side bands of a different grey on both sides — reads as letterboxing, not design (same on 23b, 24, 25, 26*, 27, 28, 29*). Extend the walk-out's dark stage band full width. S. S3 [seen] stat block: "Base"/"Gas" labels sit ~120px from their stars; tiny 5-star rows.
- 23b prefight_plan | v16x9 5,5,4,4,5,5 ; v19x9 5,5,4,3,5,5 | S3 [seen] "kit 100%" grey-on-grey and #N name/role in the small face; good layout otherwise. Same side bands in v19x9.
- 24 fight_live | v16x9 4,4,4,4,5,5 ; v19x9 4,4,4,3,5,5 | S3 [seen] v19x9: the list + side panels keep their 16:9 width, ~110px dead each side (list ratio locked; the gutters are where the crowd/stands art was meant to go — DIRECTION). [needs validation] first-bout route tip sits over the centre of the list where the first drag happens.
- 25 contact_wheel | 4,3,2,4,4,5 (both vp) | S2 [seen] option text set along the arcs at ~45-60° ("takedown 14% / 100% chance / Clinch", "fall 23% / 5% chance / Bullrush") — rotated pixel text is the hardest thing to read in the game, at the moment the player has least time. Keep the wedges, set labels horizontal. M. S2 [judgement] two percentages per option ("takedown 14%" and "100% chance") with no key — which is the odds? S. S3 [seen] wheel covers the #4/#5 cards and the ICC panel; fine while open.
- 25b contact_wheel_third | 4,3,2,4,4,5 | same S2 rotated labels (dup of S25-1, cite here). S3 [seen] "Puts him down / 22% chance" in red on the blue wedge — lowest-contrast text in the wheel. S3 [seen] the two clinched men + #3 overlap into one pile with two rings; hard to see who is sent.
- 26 corner | v16x9 5,5,4,4,5,5 ; v19x9 5,5,4,3,5,5 | S3 [judgement] "1 down / 0 assists" — is "1 down" a down he caused or took? Label "downs caused". S. S3 [seen] ~70px empty under the last row inside the frame. Energy "61% → 91%" is a nice touch.
- 26b corner_playbook | 4,4,4,4,2,4 | S2 [seen] the overlay's header and instructions ("THE PLAYBOOK — tap to star, 2 of 4 · BACK IN 0:20", "IN THE CORNER, IN THIS ORDER — tap to move one left") are in a smooth, anti-aliased sans, not the pixel face — the only non-pixel type seen in 132 renders; breaks the 8-bit constraint. S. traced: likely a default Theme font on that Label. S3 [seen] third row of cards cut by the pane edge with a 4px scrollbar as the only scroll cue.
- 26c corner_favourites | 5,4,5,4,5,5 | S3 [seen] with 2 favourites the strip leaves ~110px empty between the cards and FULL PLAYBOOK; centre or let FULL PLAYBOOK move up.
- 27 corner_sub | 5,5,5,4,5,4 | none above S3. "same role" highlighted gold is good.
- 28 report | 4,4,4,4,4,5 | S3 [seen] two-row header (legend "AST assists · UP rounds… · OFF carried off" then DOWNS AST UP OFF XP LVL NEXT) is dense; legend could go in "?" S. S3 [seen] ~100px empty between the AAR cards and Spend levels. (Not scored here: bake-off #2 showed the "(5)" count can overpromise — Codex's finding, already approved for fixing.)
- 29 tip_route | 4,3,4,4,3,4 | S2 [seen] the walk-out's Back and "Walk out" buttons draw over the fight's bottom card row behind the tip (v16x9 and v19x9, x≈20-590, y≈465-505) — a layer from the previous screen bleeding through. Same family as 38/38b ("Louisville, KY" over the playbook). M. traced: walk-out splash not freed/hidden when the fight opens under a tip.
- 29b tip_corner | 5,5,5,4,5,4 | none above S3.
- 30 dilemma | 5,4,4,5,5,5 | S3 [seen] ~90px empty inside the card between the story and the three outcomes; outcomes then run onto the card's bottom edge ("CC -4 · team morale -5 · kit +8" at the border, v16x9). S3 [judgement] costs ("CC -7", "team morale -8") are the same grey as the prose while gains are green; make costs red/orange so the trade reads at a glance. S.
- 31 promotion | 5,5,5,4,5,5 | S3 [seen] v19x9 dialog ~35px left of the canvas centre. S3 [judgement] "Build now · 18 CC" buys two builds at once, while 32b says "one build a week" for the same two builds — the rule reads inconsistent across the two prompts. [needs validation]
- 32 fixture_sim | 5,5,5,4,4,4 | S3 [seen] the confirm sits on a bare background (no tabs, no dimmed hub) unlike every other dialog, which dims the screen behind. S3 lower half empty.
- 32b promo_ground_state | 5,5,5,4,5,5 | none above S3 (see 31 note).
- 33 records_this_year | 4,4,4,4,4,4 | S3 [seen] footer "-33now at full steel" missing space (both vp). S3 [seen] a second empty OPPONENT/ROUNDS/DIFF/AT header block on the right with no rows (5 bouts fit the left) — hide until row 6+. S3 "Fresno Brotherho." truncation.
- 34 promo_ground_regional | 5,5,5,4,5,5 | S3 [seen] header "Coach.," truncated in v16x9 behind the dim. (9048 CC is test money.)
- 35 hub_week1 | 5,4,4,4,4,5 | S3 [seen] a clipped text fragment "Pit" at the bottom-right corner (x≈885,y≈522 v16x9; same v19x9) — the ticker's text with no ticker bar. S3 [seen] v16x9 fixture card: "favorites by 18" runs into "2 CC" on one line.
- 36 history | 5,4,5,4,4,4 | S3 [seen] ~55% of the screen empty below five season rows; TROPHIES "Nothing yet." fine. S3 [judgement] "8th, relegated" red / "1st, promoted" green good.
- 37 worlds_groups | 5,5,5,5,5,4 | S3 "top 2 go through" said twice (subtitle + footer). Clean.
- 37b bracket_done | 5,5,4,5,5,4 | S3 [seen] "CHAMPION / Detroit Free" sits on the YOUR PATH panel's bottom border (descenders clipped). S3 [judgement] winning the cup gets the same quiet panel as "to fight" — champion moment underplayed (C6).
- 38 playbook_favs (over walk-out) | 3,2,2,3,2,4 | S2 [seen] the playbook overlay has no backing panel or dim: the walk-out underneath shows through and collides — "AWAY / Louisville, KY" printed across the overlay header "tap to star, 4 of 4"; the walk-out's Strength/Base/Skill star rows interleave with "IN THE CORNER, IN THIS ORDER" and the order buttons; stray "ns", "rating" fragments at the pane edges (both vp). Give the overlay the same opaque panel + dim the corner version (26b) has. S. Same smooth non-pixel header font as 26b.
- 38b playbook_favs after | 3,2,2,3,2,4 | same as 38 (dedupe: one finding, cite 38 + 38b, all 4 renders).
- 39 free_agent_market_ask | 5,5,5,4,5,5 | none above S3 (wage $ vs CC again: "$174/$1.8k wages").
- 39 free_agent_market_picked | 4,4,4,4,3,4 | S3 [seen] "Sign Vane · 55 CC" is armed but Vane's card has no selected highlight — the pick shows only in the button. S. S3 [seen] role header colours here (bright purple/green/orange) differ from 11_market's (dark green/navy/brown) for the same roles. S3 [seen] "STEP UP" yellow-on-purple low contrast; card footers on the border again.
- 40 popup_mark | v16x9 4,4,5,4,4,4 ; v19x9 4,4,5,2,4,4 | S2 [seen] v19x9: a flat light-grey 100px column down the left edge (x 0-100) with the CREATE screen pushed right; the popup is off-centre to the right — looks broken on wide phones. M. S3 popup lower ~25% empty between swatches and the footer.
- 40 popup_town | 5,5,5,4,5,4 | none above S3.
- 41 calendar | 5,5,4,4,5,4 | S3 [seen] legend header "THE SEASONnow: weekdays" missing space. S3 cup names cut to "BALTIMORE ." in day cells (legend carries the full name — fine).
- 42 founding_step_1 | 4,4,5,4,4,3 | S2 [seen] first screen of a new career: the coach portrait is a box reading "art to follow"; Face/Kit/Beard pickers change nothing visible. M (art). 
- 42 founding_step_2 | 5,4,4,4,5,5 | same as 19 (HOME TOWN indent; price banners).
- 42 founding_step_3 | 5,4,5,4,5,4 | same as 20.
- 42 founding_step_4 (custom grade) | 4,3,4,4,4,4 | S3 [seen] ten rows of value + tiny −/+ pairs (~28px) at 20px pitch — the densest control grid in the game; mis-tap risk on phones [needs validation]. Row pitch +6px fits. S.
