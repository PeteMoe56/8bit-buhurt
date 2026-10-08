#!/usr/bin/env bash
## THE SCREEN SCORE SET (8 Oct 2026): every screen, overlay and fight state,
## labelled, at three viewports, with a MANIFEST.tsv a reviewer can score from.
##
##   bash tools/shot_screenscore.sh <out_dir>
##
## Viewports (logical canvas; the game is 960x540 with stretch aspect=expand):
##   v16x9     960x540   PC 1080p / 16:9 phones and tablets in landscape
##   v19x9n   1170x540   iPhone 11-class phone, notch faked (RB_INSETS=63,63) —
##                      menus only; the fight tools have no inset hook
##   v19x9    1170x540   wide phone, no notch (S24 Ultra class), fight + overlays
##   v16x10    960x600   Steam Deck (1280x800), menus only
## Everything is the same lived-in world the ink sweep uses (season 3, captains,
## a saved chalkboard), English, Godot 4.6.2 headless under xvfb.
set -u
cd "$(dirname "$0")/.."
d="${1:?out dir}"; mkdir -p "$d" shots
man="$d/MANIFEST.tsv"
printf 'file\tviewport\tcanvas\tdevice\tscreen\tstate\n' > "$man"
row() { printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$@" >> "$man"; }

MENUS=(
"01_start|Start|front door, career exists"
"02_title_slots|Title / save slots|three empty slots"
"03_settings|Settings|in a career"
"04_season_club|Season hub: FIGHT tab|cup quarter-final waiting, Backyard season 3"
"05_season_squad|Season hub: TEAM tab|levels waiting (+N), no man picked"
"06_season_armorer|Season hub: MAINTENANCE tab|1-star armorer, kit 84-94%"
"07_season_clubhouse|Season hub: UPGRADES tab|cap, camp, infirmary, insurance, arena"
"08_season_finances|Season hub: MANAGEMENT tab|finances, staff, coach card"
"09_roster|Squad (card view)|eight men, line of five + bench"
"10_fighter|Fighter page|Rail Calder, 3 levels to spend"
"11_market|Free agents|six men, one unaffordable"
"12_staff|Staff|two captains hired, 1-star armorer"
"13_coach|Your coach|2 skill points to spend"
"14_records|Records: The club tab|club records"
"15_guide|Guide|The table page"
"16_arena|Arena (venue)|Back field, level 0"
"17_chalkboard|Playbook editor (chalkboard)|formations tab, a saved shape"
"18_create_fighter|Create: fighter|custom fighter, 4 of 4 creations left"
"19_create_club|Create: club|name, kit and badge"
"20_create_grade|Create: grade|Sanctioned selected"
"21_bracket|Cup bracket|Milwaukee Open, quarter-final to fight"
"22_club_menu|Pause menu|open over the season hub"
)

menus() {  # $1 viewport tag  $2 WxH  $3 device  [RB_INSETS]
  local tag="$1" res="$2" dev="$3" ins="${4:-}"
  mkdir -p "$d/$tag"
  RB_INSETS="$ins" bash tools/bb.sh shot all "$res" "$d/$tag" >/dev/null 2>&1
  for m in "${MENUS[@]}"; do
    IFS='|' read -r f sc st <<< "$m"
    [ -f "$d/$tag/$f.png" ] && row "$tag/$f.png" "$tag" "$res" "$dev" "$sc" "$st"
  done
}

fight() {  # $1 tag  $2 WxH  $3 device
  local tag="$1" res="$2" dev="$3" o="$d/$1"
  mkdir -p "$o"
  cp_() { [ -f "$1" ] && cp "$1" "$o/$2.png" && row "$tag/$2.png" "$tag" "$res" "$dev" "$3" "$4"; }
  bash tools/bb.sh shot prefight "$res" >/dev/null 2>&1
  cp_ shots/prefight_splash.png 23_walkout "Walk-out (pre-bout splash)" "league bout, both clubs"
  cp_ shots/prefight_plan.png 23b_prefight_plan "Pre-fight plan" "formation + play chosen"
  bash tools/bb.sh shot melee "$res" 30 "$o/24_fight_live.png" >/dev/null 2>&1
  [ -f "$o/24_fight_live.png" ] && row "$tag/24_fight_live.png" "$tag" "$res" "$dev" "Fight (the list)" "live, frame 30, first-bout route tip showing"
  bash tools/bb.sh shot wheel "$res" approach "$o/25_contact_wheel.png" >/dev/null 2>&1
  [ -f "$o/25_contact_wheel.png" ] && row "$tag/25_contact_wheel.png" "$tag" "$res" "$dev" "Contact wheel" "prompt open: a man routed onto a free enemy"
  bash tools/bb.sh shot wheel "$res" third "$o/25b_contact_wheel_third.png" >/dev/null 2>&1
  [ -f "$o/25b_contact_wheel_third.png" ] && row "$tag/25b_contact_wheel_third.png" "$tag" "$res" "$dev" "Contact wheel" "prompt open: third man onto a clinch"
  bash tools/bb.sh shot corner "$res" >/dev/null 2>&1
  cp_ shots/corner_round.png 26_corner "Corner (between rounds)" "after round 1"
  cp_ shots/corner_sub.png 27_corner_sub "Corner: substitution" "sub picker open"
  cp_ shots/book_stars.png 26b_corner_playbook "Corner: full playbook" "favourites starred, two scrolling panes"
  cp_ shots/corner_faves.png 26c_corner_favourites "Corner: favourites strip" "four favourites"
  bash tools/bb.sh shot aar "$res" >/dev/null 2>&1
  cp_ shots/aar.png 28_report "After-action report" "bout fought, levels waiting"
  bash tools/bb.sh shot tip "$res" route "$o/29_tip_route.png" >/dev/null 2>&1
  [ -f "$o/29_tip_route.png" ] && row "$tag/29_tip_route.png" "$tag" "$res" "$dev" "Fight: first-time coach mark" "route tip showing"
  bash tools/bb.sh shot tip "$res" corner "$o/29b_tip_corner.png" >/dev/null 2>&1
  [ -f "$o/29b_tip_corner.png" ] && row "$tag/29b_tip_corner.png" "$tag" "$res" "$dev" "Corner: first-time coach mark" "corner tip showing"
}

overlays() {  # $1 tag  $2 WxH  $3 device
  local tag="$1" res="$2" dev="$3" o="$d/$1"
  mkdir -p "$o" "$o/_tmp"
  cp_() { [ -f "$1" ] && cp "$1" "$o/$2.png" && row "$tag/$2.png" "$tag" "$res" "$dev" "$3" "$4"; }
  bash tools/bb.sh shot dilemma "$res" >/dev/null 2>&1
  cp_ shots/dilemma.png 30_dilemma "Dilemma card" "card on the table, prices shown"
  bash tools/bb.sh shot promotion "$res" >/dev/null 2>&1
  cp_ shots/promotion.png 31_promotion "Promotion offer" "offer open"
  bash tools/bb.sh shot fixture "$res" >/dev/null 2>&1
  cp_ shots/fixture_sim.png 32_fixture_sim "Fixture card" "sim-it confirm open"
  cp_ shots/fixture_tape.png 32b_promo_ground_state "Promotion ground prompt" "State League needs fenced ground, over the hub"
  bash tools/bb.sh shot year "$res" >/dev/null 2>&1
  cp_ shots/year.png 33_records_this_year "Records: This year" "season so far, 5 fought"
  bash tools/bb.sh shot table "$res" >/dev/null 2>&1
  cp_ shots/table_bands.png 34_promo_ground_regional "Promotion ground prompt" "Regional League needs arena; 9048 CC is test money from the tool"
  bash tools/bb.sh shot trade "$res" >/dev/null 2>&1
  cp_ shots/trade.png 35_hub_week1 "Season hub: FIGHT tab" "week 1, league fixture waiting"
  bash tools/bb.sh shot history "$res" >/dev/null 2>&1
  cp_ shots/records_history.png 36_history "Club history" "records page"
  bash tools/bb.sh shot bracket_real "$res" >/dev/null 2>&1
  cp_ shots/bracket_pools.png 37_worlds_groups "Worlds" "group stage, 16 clubs in 4 pools"
  cp_ shots/bracket_done.png 37b_bracket_done "Cup bracket (Path of Honor)" "finished, champion shown"
  bash tools/bb.sh shot favs "$res" >/dev/null 2>&1
  cp_ shots/favs_before.png 38_playbook_favs "Playbook over the walk-out: picking favourites" "before"
  cp_ shots/favs_after.png 38b_playbook_favs "Playbook over the walk-out: picking favourites" "after, four starred"
  bash tools/bb.sh shot market_ask "$res" "$o/_tmp/ma" >/dev/null 2>&1
  for f in "$o"/_tmp/ma/*.png; do [ -f "$f" ] || continue
    b="$(basename "$f" .png)"; cp "$f" "$o/39_free_agent_$b.png"
    row "$tag/39_free_agent_$b.png" "$tag" "$res" "$dev" "Free-agent prompt" "$b"; done
  bash tools/bb.sh shot popups "$res" "$o/_tmp/pp" >/dev/null 2>&1
  for f in "$o"/_tmp/pp/*.png; do [ -f "$f" ] || continue
    b="$(basename "$f" .png)"; cp "$f" "$o/40_popup_$b.png"
    row "$tag/40_popup_$b.png" "$tag" "$res" "$dev" "Club tab popup" "$b"; done
  ## shot_calendar writes <dir>/cal.png into a directory that must already exist.
  mkdir -p "$o/_tmp/cal"; bash tools/bb.sh shot calendar "$res" "$o/_tmp/cal" 5 >/dev/null 2>&1
  [ -f "$o/_tmp/cal/cal.png" ] && mv "$o/_tmp/cal/cal.png" "$o/41_calendar.png" && row "$tag/41_calendar.png" "$tag" "$res" "$dev" "Calendar" "week 5 of a Backyard season"
  bash tools/bb.sh shot founding "$res" "$o/_tmp/fd" >/dev/null 2>&1
  for f in "$o"/_tmp/fd/*.png; do [ -f "$f" ] || continue
    b="$(basename "$f" .png)"; cp "$f" "$o/42_founding_$b.png"
    row "$tag/42_founding_$b.png" "$tag" "$res" "$dev" "New career (founding)" "$b"; done
  rm -rf "$o/_tmp"
}

menus    v16x9   960x540  "PC 1080p / 16:9"
fight    v16x9   960x540  "PC 1080p / 16:9"
overlays v16x9   960x540  "PC 1080p / 16:9"
menus    v19x9n  1170x540 "iPhone 11 class, notch 63/63" "63,63"
fight    v19x9   1170x540 "wide phone, no notch (S24 Ultra class)"
overlays v19x9   1170x540 "wide phone, no notch (S24 Ultra class)"
menus    v16x10  960x600  "Steam Deck 1280x800"
echo "$(($(wc -l < "$man") - 1)) renders in $d"
