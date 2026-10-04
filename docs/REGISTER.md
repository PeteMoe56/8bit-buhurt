# Open questions register

Hedge Knight convention. **ASK** needs Pete · **REC** recommendation awaiting sign-off ·
**ASSUMED** baked in unchecked · **locked** decided, with the rationale recorded.

An item locks only when Pete answered it, or was shown the recommendation and had a
chance to push back on it specifically. A consequence derived from his decision is a
recommendation, not a decision.

---

## 01 — Portfolio and identity

| # | Item | Status |
|---|---|---|
| 01.1 | Does this merge with Hedge Knight, replace it, or ship alongside? | **locked** — Merge. Pete, 10 Sep 2026: *"Merge but take most story elements out. Hedge Knight is a drama rogue-lite, this is a light Retro Bowl style game that can use world elements."* The world bible transfers; the drama layer, the storylets and the narrative register do not. |
| 01.2 | Final store title. "Retro Buhurt" names the thing it copies. Candidates: The Lists, Full Harness, The Rail, Steel Season, Club & Crown. Trademark check needed. | **ASK** — repo is `RetroBuhurt` for now; nothing in code depends on the name. |
| 01.3 | Does the Hedge Knight card layer survive anywhere in this? | **REC** — no. The verb replaces it wholesale. Its 180-card budget and archetype work become roster and role content instead. |
| 01.4 | Mobile only, or Steam too? | **ASK** — Godot 4.6 Compatibility exports both; nothing built so far forecloses either. |

## 02 — The bout

**Rebuilt 10 Sep 2026.** Pete replaced the core loop wholesale: *"Bind, Carry, and whatever
else you used for actions/descriptors make no sense at all."* He is right — **bind** is a
longsword term for crossed blades and had no business in a melee, and it was mine.
**Carry** came out of the dossier glossary (#46), which means that list has at least one
entry that does not survive contact with someone who fights. Everything else sourced from
it is now suspect. Full spec in `docs/GAMEPLAY.md`.

| # | Item | Status |
|---|---|---|
| 02.1 | ~~The atomic unit is the clinch~~ | **void** — superseded by 02.10. The manufactured clinch is gone. |
| 02.2 | ~~The one verb: brace / drive / commit~~ | **void** — superseded by 02.11-02.13. |
| 02.3 | ~~Hero model: the captain's eye~~ | **void** — **there is no hero.** You direct the line; you never inhabit a man. This removes the whole hero problem rather than solving it. |
| 02.4 | **Round length: 60 s, best of three, 5v5** | **locked** — Pete, 10 Sep 2026: a real 5v5 is capped at five minutes, *"but for a mobile game, 45 seconds per round is good. Retro bowl doesn't use the 15min NFL quarter length for a reason."* Then set to 60: *"that should encapsulate most if not all fights."* The clock is a backstop, not the thing that ends a round. Open since the first session; answered by the man who fights. |
| 02.5 | Third point of contact as the only elimination | **locked** — survives the rebuild. |
| 02.6 | Marshal calls "Break!" on an inactive clinch | **locked** — survives, and now has a home: it is the clock that runs while you **Hold**. |
| 02.7 | **The stop rule** | **locked, corrected twice on 10 Sep 2026.** Final: the round ends the moment a side is **down to its last man while behind**. Legal end scores are **5-1, 4-1, 3-1, 2-1, 1-0** and nothing else. (First I had a 3:1 *ratio*, which is a different rule; then a wipe-or-three-to-one reading, under which 2-1 kept going and rounds finished 5-2 and 4-3 on the clock. Pete listed the legal scores explicitly and that settled it.) |
| 02.23 | **Nobody gets back up** | **locked** — Pete, 10 Sep 2026. A down is out for the round. |
| 02.24 | **Nine downs is the ceiling for one 5v5 round** | **locked** — ten would mean every man on the list is down, and somebody is always left standing. The suite counts the downs in every round of every bout. Measured worst: 7. |
| 02.28 | **1-0 is currently unreachable** | **ASK** — under 02.7 the round stops at 2-1, so the fight never gets to 1-1 and therefore never to 1-0. The listed score is legal but the rule as written cannot produce it. Either 1-0 is theoretical (the ceiling, not an outcome) or 2-1 should keep going, which would put the ceiling back in play. |
| 02.29 | **13% of rounds still reach the clock** | **REC** — 87% end on the stop rule with a legal score; the rest run out of time at 4-4, 5-2 and so on. "Most if not all" is satisfied by most. A longer clock or a faster grind closes the gap. |
| 02.25 | **Best of three** | **locked** — Pete, 10 Sep 2026. Take two rounds and the third is not fought. 39 of 80 mirror bouts settle in two. |
| 02.9 | **The line is Rail · Flanker · Center · Flanker · Rail** | **locked** — Pete, 10 Sep 2026. Rail and Flanker are close together on each side and stay paired unless split. ACTM already ships this as `groups = {5:[2,1,2]}` and its melee resolver already models lane shift and gang takedowns. Inherit it; do not re-derive it. |
| 02.10 | ~~Three units, split on demand~~ → **individual fighters, transient orders** | **locked, corrected 10 Sep 2026.** Pete overruled the three-unit reading: *"You should be able to put your finger on a fighter, draw a path either to a position or an opponent... once the route is done, the AI takes back over."* You address men one at a time, as fast as you like. Splitting a pair is not a command — it is what has happened once you draw one of them somewhere his partner is not. **The three-unit version was me over-constraining to protect a hands-on ceiling this design does not need**: an order that expires is itself the guard. |
| 02.11 | **Two drags: onto ground = a route, onto a man = go take him** | **locked** — Pete, 10 Sep 2026. |
| 02.12 | **Contact menus** | **locked (shape) / REC (effects)** — built as specified. The options open at a distance and **he holds there while they are up**; without that he crossed to contact in a third of a second and the buttons were unreadable. Answering commits him instantly, ignoring commits him on the timer, so "let him decide" costs nothing. |
| 02.13 | **"Break" frees your own man** | **locked** — Pete, 10 Sep 2026. He gets out; the enemy is left standing but disengaged. The counter to their gang. |
| 02.14 | **Strategy is locked for the round** | **locked** — Pete, 10 Sep 2026. Picked in the corner, lived with. |
| 02.26 | **A strategy is an opening PLAN that expires, not a permanent modifier** | **locked** — Pete, 10 Sep 2026: *"more where the team wants the fight to go, but once those strategies run their course, the AI tries to make best guess."* Implemented as five plan zones per strategy, live for ~18 s or until the side is down to two men. **My multiplier model was wrong**: a strategy is a shape, not a stat bonus. |
| 02.27 | **Difficulty is a behavior, not a handicap** | **locked** — Pete, 10 Sep 2026, on the beginner tier: *"like a new kid going through a motion but then once his taught direction stops, he doesn't know what to do."* Three tiers — Green / Seasoned / Elite — differing only in what they do once the plan expires. **No tier changes anyone's numbers.** A Green side keeps standing on its plan zone, takes the nearest man, cannot read wear, never gangs, never rescues, never escapes. Measured: Seasoned beats Green 88.3% on identical rosters. |
| 02.15 | Formation list — Line / Spearhead / Refused flank / Rail-heavy | **REC** — **formation is a positioning tool** (Pete, 10 Sep 2026), distinct from strategy. Spearhead is the sport's own word (glossary #64). |
| 02.16 | Strategy list — **Left rail push / Right rail push / Turtle / Strong left / Strong right** | **locked** — Pete's list, 10 Sep 2026. My four invented ones are retired. |
| 02.17 | "Bullrush" or the dossier's "check"? | **locked** — **Bullrush.** Pete, 10 Sep 2026. His word beats the glossary's. |
| 02.18 | Does the AI split pairs and gang your clinches? | **locked** — **Yes.** Pete, 10 Sep 2026. So **Break** is load-bearing and the third menu cuts both ways. |
| 02.19 | Three involvement levels: draw everything / position only / watch | **locked** — Pete, 10 Sep 2026. Same game at three depths; the watch level has to be able to win. Replaces the old auto-sim constraint. |
| 02.8 | Format ladder: 1v1 → 5v5 → 12v12 | **ASSUMED** — ACTM's `groups` already carries 12 as `[5,2,5]`. |
| 02.20 | **A clinch grinds your base down every second, and the stronger man grinds faster** | **REC** — *new, and the build does not work without it.* Stability only fell to a **Hit**, and Hit is not in the clinch menu, so two evenly matched clubs fought four and a half minutes and put **0.0** men on the ground. The grind is what makes strength and base matter continuously, and a gassed man wears down 1.9x faster — which is what makes the report's gas line causally true instead of decorative. |
| 02.21 | **Lane discipline** | **REC** — a man prefers opponents near his own patch of the list. Without it the whole melee slid into one corner and two thirds of the screen was empty ground. Caught by a render, not by reasoning. |
| 02.22 | **Only a man you sent gets a prompt** | **locked** — the other nine are decided silently by the AI. This is what keeps the screen calm enough to orchestrate, and it is asserted by a test. |

## 03 — Fighters

| # | Item | Status |
|---|---|---|
| 03.1 | Six stats: strength, base, technique, gas, aggression, weight | **REC** — every management decision has to arrive in the fight through one of these six or the fight cannot feel it. |
| 03.2 | "Gas", not "conditioning" | **locked** — the sport's own word for the thing (glossary #110), and it is the sport's recognised limiter. |
| 03.3 | ~~Seven roles: center, guard, flanker, grappler, striker, punisher, runner~~ | **void → replaced by 02.9.** The five positions are **Rail, Flanker, Center, Flanker, Rail** — a line, not a role taxonomy. The glossary list conflates *where you stand* with *what you do*; Pete's line is the first axis. Whether the second axis (grappler/striker/punisher/runner as functions) survives is **ASK**. |
| 03.4 | Kit condition as a stat, and availability as a hard gate | **REC** — this is the salary-cap substitute (§4) expressed on the fighter. A fighter can be your best and unavailable. |
| 03.5 | Does role affect stat growth and recruitment, or only field behavior? | **ASK** — currently behavior only. |

## 04 — Balance

| # | Item | Status |
|---|---|---|
| 04.1 | ~~The bind is a race, not a tug of war~~ | **void** — the bind is gone with 02.2. **ACTM's `melee_resolver.dart` is the reference implementation now**, and it is already tuned against real play rather than against my own sim. |
| 04.2 | ~~Old tuning~~ | **void** — `scripts/core/balance.gd` belongs to the dead design. The live numbers are `scripts/melee/tuning.gd`. |
| 04.7 | **Current tuning**: 46 s of live fighting per round, 13.3 downs per bout, 4.2 men gassed, mirror 49.4% over 400 bouts | **REC** — all in `scripts/melee/tuning.gd`. |
| 04.8 | **Strength and base must sit in the same range** | **locked** — the first roster gave every man a base ~10 points above his strength, because base had been written up in prose as "the quiet stat that wins rounds". The takedown formula reads `strength - base`, so that term was negative for nearly every pairing in the game and downs collapsed to zero. **A stat that sounds important in prose is not the same as one that is balanced.** |
| 04.9 | Orchestration is strong, and that is the point | **locked** — Pete, 10 Sep 2026: *"Thumb is supposed to be better, it engages the player."* Flagged as a worry; overruled. Drawing routes moves an even match 48.6% → 87.2% and that is intended. **The guard is C-2, not a cap on the thumb**: a 12-point-light roster played hard wins 0%. |
| 04.10 | ~~Rounds end well short of the clock~~ | **closed by 02.4** — the clock is 45 s now and rounds average 30 s of live fighting, so it is a real deadline: 4-4 and 5-5 clock endings show up in the sample. |
| 04.11 | **Green may be too green** | **ASK** — now 94.9% under the corrected stop rule. That is not a difficulty tier, that is a bye. Green needs one more thing it knows how to do. |
| 04.12 | Drawn rounds and drawn bouts are possible | **ASSUMED** — a clock expiry at equal standing draws the round (~5%). Bout tiebreak is rounds won → total downs → draw. |
| 04.3 | Orders had a dominant strategy, twice | **carried forward to 02.16** — the lesson survives the rebuild: the first pass had one good order and three dead ones, a counter-cycle fixed it and produced a *second* dominant order. The four strategies in 02.16 will do the same thing unless each is checked against the other three. |
| 04.4 | ~~Perfect input wins 92% of an even mirror~~ | **void** — no hero, no "perfect input". The half worth keeping is **a good player on a bad club still loses**, and it is *harder* to hold now that you direct all five. New guard needed. |
| 04.5 | ~~Skill ceiling at 0.90 alignment~~ | **void** — alignment was a property of the drag verb. The general lesson stands: **measuring balance against an unreachable ceiling biases every reading the same way.** |
| 04.6 | Bout tiebreak order: rounds won → total downs → draw | **ASSUMED** — draws run about 5% of mirror bouts. Remaining gas as a final tiebreak was considered and not taken. |

## 05 — Art

| # | Item | Status |
|---|---|---|
| 05.1 | 8-bit, load-bearing rather than decorative | **locked** — heraldry is already low-res, it solves the gray-blob problem, and it makes the art scope survivable solo. |
| 05.2 | Tincture rule enforced in code: never color on color, never metal on metal | **locked** — the rule exists because heraldry had to read at 200 yards through dust, which is the same problem as reading 5v5 on a phone. `Club.tincture_legal()`, asserted in the fixtures test. |
| 05.3 | Fighter footprint 24×32 px on a 540-wide portrait screen | **REC** — arrived at by rendering, not by opinion. At 15×22 the heraldry did no work at all. |
| 05.4 | Art outsourced (MLC Studio or similar) vs in-house | **ASK** — placeholder primitives are deliberately structured so sprites drop in without touching layout. |
| 05.5 | The list has a lot of dead space at 5v5 | **REC** — leave it. Fighters converge; a framing camera would fight C-5. Revisit at 12v12. |

## 06 — Tech

| # | Item | Status |
|---|---|---|
| 06.1 | Godot 4.6, Compatibility renderer, portrait 540×960 | **locked** — 4.6 is current stable (Jan 2026). Compatibility because the advanced renderers give 2D pixel art nothing and cost device coverage, battery and build size. |
| 06.2 | Sim is a pure `RefCounted` with a seeded RNG and no node dependencies | **locked** — buys determinism, headless testing at scale, and a replaceable render layer. |
| 06.3 | All tunables in one file (`balance.gd`) | **locked** — a balance pass is one file and a diff of that file is the whole change. |
| 06.4 | IAP wired on both platforms before the season layer | **REC** — direction doc §7 calls this the real friction point and says prototype it in week one. It is **not** done and is the next milestone. |
| 06.5 | No autoloads | **locked** — `Balance` is a `class_name` constant holder, so it resolves in `--script` runs where autoloads do not exist. |

## 07 — World

| # | Item | Status |
|---|---|---|
| 07.1 | Real countries, fictional federations, clubs, fighters and armorers | **locked** — inherited from Hedge Knight. |
| 07.2 | Russia excluded from the game entirely | **locked** — inherited. Not a country, not on the calendar, not among clubs, opponents or armorers. The war and sanctions are never referenced. |
| 07.3 | Tone: grounded and warm | **locked, narrowed** — inherited, minus the selectable persona register and the storylet layer, per 01.1. |
| 07.4 | Club split / schism as the "getting fired" substitute | **ASSUMED** — not built. Direction doc §4 calls it the one system people would talk about. |
| 07.5 | Currency name "Marks" | **ASSUMED** — no economy built yet. |

## 06b — Testing

| # | Item | Status |
|---|---|---|
| 06.6 | **GDScript lambdas capture locals by value** | **locked** — an `int` counter assigned inside a signal handler never reaches the outer scope. Two brand-new tests reported "0 illegal endings" and "0 bouts settled in two" because their counters were dead, and **both passed**. Arrays and Dictionaries are reference types and do carry the mutation, so every accumulator a handler touches is one. A test that cannot fail is worse than one that does. |

## 08 — Cross-project

| # | Item | Status |
|---|---|---|
| 08.1 | **Hedge Knight 03.15 needs re-opening.** | **confirmed by Pete, 10 Sep 2026** — *"Rail is real, rail anchor is your bad invention."* The coinage was ours and was right to go; **taking "Rail" out along with it was not.** HK's positional axis is missing a real position, and its "Guard" is likely a *function* rather than a position. HK 03.9, 03.10, 07.3, 07.4 and 13.3 all lean on 03.15. Not fixed here — it is a locked item in another register. |
| 08.2 | **The dossier glossary is not fully trustworthy.** | **locked** — glossary #46 ("carry / power player") did not survive contact with Pete. The naming rule still stands — search the glossary before coining anything — but a glossary entry is now evidence, not proof. **Where Pete would know it first-hand, ask him instead.** That was already the protocol's own rule; this is the second time ignoring it has cost a rebuild. |
| 08.3 | **ACTM's arena package is the melee reference.** | **REC** — `actm_arena` already carries the 2-1-2 lineup, lane shift (peel off / fall back), gang takedowns, contested-lane weighting, a seeded PRNG with replay hashing, and a localisation-safe event model that emits message keys rather than English. Port the model; do not re-derive it. |

## 09 — The pyramid

Built 10 Sep 2026 on Pete's instruction: *"let's make sure we have leagues and tiers for
this. Run it like reality and the leagues in soccer."* Full spec in `docs/LEAGUES.md`.

| # | Item | Status |
|---|---|---|
| 09.1 | **Four divisions, promotion and relegation** — Backyard Circuit 6 / State League 8 / Regional League 12 / National Division 16 | **REC** — tier names inherited from ACRTW's `ecosystem_leagues`, which already had exactly this ladder. Sizes are ACRTW's too. |
| 09.2 | **A pyramid rather than ACRTW's playoff brackets** | **REC** — ACRTW resolves each tier with a top-2 final or top-4 playoff. Promotion/relegation gives a bad season consequences *without ending the run*: you go down, and going down is a story that continues. |
| 09.3 | **Three points for a win, one for a draw; rounds are the goals** | **REC** — a bout is best-of-three and can be drawn, so football's scoring works unmodified. Order: points → round difference → rounds won → drawn lots. |
| 09.4 | **Drawn lots as the final tiebreak** | **locked** — the first version broke final ties on club id, and the player is club 0, so he won every tie in every division and floated to the top flight on a static rating. **A fixed ordering is never neutral, it just hides who it favours.** |
| 09.5 | **Single round-robin, N-1 events** | **REC** — buhurt clubs travel to events; there is no home ground, so home-and-away would borrow a structure the sport does not have. Lands every tier at 5 / 7 / 11 / 15 events, inside the direction doc's 10-14. |
| 09.6 | **Only the player's own bout runs the full melee** | **locked** — every other fixture resolves on club rating. The same division of labour ACTM makes in `meleeOddsBps`. |
| 09.7 | **Whatever a tier promotes, the tier above relegates** | **locked** — otherwise divisions leak a club a year. Asserted every season of a hundred-season run. |
| 09.8 | Progression curve: +6 power a season reaches the National Division in 7 seasons; a club that never improves averages tier 0.3 after 30 | **REC** — the climb is possible and the climb is earned, in two numbers. |
| 09.9 | **Worlds** — 16 clubs, four pools of four, top two into a bracket with a third-place match | **REC** — built 10 Sep 2026 on Pete's *"steal that from ACRTW as well"*. ACRTW runs 32 countries and eight pools; a quarter of the size, the same shape, and it fits a season you can finish on a phone. The National Division's top two carry the country; the other fourteen are foreign guests rated off the top flight's own band and **deleted again the same summer** — a guest that survives is a club with tier −1 waiting to walk into a loop over the pyramid. |
| 09.10 | **Two Invitationals a season, 8-club knockout** | **REC** — ACRTW's shape, ACRTW's cadence, **not ACRTW's gate.** It invites on National top-3; this game starts you in the Backyard Circuit, so that rule would mean no cup for seven seasons. Here it is the top three of *your own* division, which makes a cup run something a small club in a small league can have. |
| 09.10a | Invitational names — **Kings Cup**, **Path of Honor** | **locked, Pete 10 Sep 2026.** ACRTW's ("Apex, Not Apex", "Path of Acclaim") are its property and were not taken. |
| 09.11 | **Club power comes from the club, not from starter levels** | **locked, Pete 10 Sep 2026** — *"Club power should be your club power, not the starter levels."* The seam between the roster and the pyramid is closed: sell your Rail and it costs you points in May. |
| 09.11a | **Rated the way Madden and FIFA rate a team: each position gets a rating, and the club rating is the average of those** | **locked, Pete 10 Sep 2026** — *"it's just an average from position averages."* A position is its starter at 80% and his cover at 20%. This beats a flat squad average for the reason every sports game already knows: **it makes a hole somewhere specific cost you.** Five men averaging 70 with nobody behind the Center is not the same club as five averaging 70 with a Center who can be spelled, and a flat average cannot tell them apart. Kit rides inside each man's own rating rather than sitting outside as a club-wide fudge. |
| 09.12 | **Standing differential is the tiebreak, in the league and in the cups** | **locked, Pete 10 Sep 2026** — *"Points are based on how many up vs how many down. So a 5-1 would be 4 points. A 1-0 would be one point."* Table order is now points → **margin** → round difference → rounds won → drawn lots. ACRTW arrived at the same idea from the other side: its Worlds pool tiebreak is `fighter_diff`, and its live Worlds scores "men left standing in rounds won". **Pete's is the better number** — ACRTW's cannot tell a 5-1 from a 5-4, and knowing how convincingly you won is the entire job of the tiebreak. |
| 09.13 | A knockout cannot be drawn | **locked** — rounds, then margin, then the higher seed. That last step is what the seeding was *for*. |


## 10 — The melee, second pass (10 Sep 2026)

| # | Item | Status |
|---|---|---|
| 10.1 | **2-1 and 1-1 are not end scores** | **locked, Pete 10 Sep 2026** — *"2-1, 1-1 are still in play."* A round ends on a wipe or on three-to-one, and nothing else. That is precisely what makes a 1-0 reachable, and a 1-0 is the only way a round reaches the nine-down ceiling. Got this wrong twice: first as a 3:1 *ratio*, then as "trail ≤ 1 while behind", which made 2-1 an end score and 1-0 unreachable. |
| 10.2 | **Difficulty is `wear_read`, a threshold — not a set of booleans** | **locked** — see below. |
| 10.3 | **Eight fighters travel — five on the line, three on the bench** | **locked, Pete 10 Sep 2026.** One backup per role, so every place on the line has cover and the bench is exactly big enough to be a decision. Asserted in `MeleeClub.line_legal()`. |
| 10.3b | **Plus a reserve of five, who never appear at an event** | **locked, Pete 10 Sep 2026** — *"the Reserve can still hold 5 additional fighters. They will only appear outside of the fights/events in the roster menu. That way you may train/sign/cut into reserves, outfit them, and put them into active roster."* A squad is therefore at most 13. **Reserves do not count toward club power** — they are not at the event, so they cannot be what the league rates you on. The split is what makes a roster menu worth opening: a flat list makes every signing an immediate first-team decision, and a reserve lets you carry a man who is not ready yet. |
| 10.3c | **The eight is always eight** | **locked** — every roster verb refuses rather than leaving a club that cannot travel or cannot field a line. You change a full eight only with `swap_squad`, and you cut from the reserve. The first pass let each verb do the locally reasonable thing and two of them were wrong the same way: demoting the Center was allowed *because the bench Center covers his slot*, and cutting him was allowed for the same reason — both leaving seven men on the traveling list. **A rule about the whole squad cannot be enforced one fighter at a time.** |
| 10.3a | **Swap two men in from the bench each corner** | **locked, Pete 10 Sep 2026** — *"You should be able to swap fighters between rounds from the bench anyway. We'll be taking that from ACRTW."* A man who sat the round out recovers 62% of his tank; a man who fought recovers 30%. **That gap is the mechanic** — the bench is a way of buying wind. |
| 10.4 | **Standing out of position costs 6% of base and technique** | **REC** — without it the bench is just "field your five best every round" and Rail, Flanker and Center stop meaning anything. Applied through `Man.eff_base()` / `Man.eff_tec()` so it cannot be remembered in one formula and forgotten in another. |
| 10.5 | **ROLE is not SLOT.** Five places on the line, three jobs | **locked** — a Rail is a Rail whichever side of the list he stands on, so he covers the other Rail at full value and is *not* out of position there. `Tuning.POS_ROLE` / `Tuning.covers()`. Without the distinction a club of eight could not put five men out after losing one starter: the bench carries one man per role, not one per slot, and `starting_five()` quietly returned four men — which every caller downstream treats as a legal line. |

### 10.2 in full — what Green was, and what it is now

Pete asked what Green is so it could be fixed. It is one of three `Tuning.AiSkill`
tiers, and **no tier changes anybody's numbers** — a Green club hits exactly as hard
as an Elite one. The tiers differ only in what a side does once its opening plan
expires, which is Pete's own spec: *"like a new kid going through a motion but then
once his taught direction stops, he doesn't know what to do."*

The bug was that Green's `reads_wear` was a **boolean**, and false meant he never
attempted a takedown in a clinch **at all**. He held forever, never ganged, and never
finished as third man — so he had almost no route to putting anyone on the ground.
He lost **95%** of bouts. That is not a difficulty tier, that is a bye.

As a **threshold** the distinction is the one Pete actually described:

| | `wear_read` | `hunts_wear` | improvises | gang | rescues / escapes |
|---|---|---|---|---|---|
| **Green** | 0.40 | no | no | 0.0 | no |
| **Seasoned** | 0.55 | yes | yes | 1.0 | yes |
| **Elite** | 0.70 | yes | yes | 1.35 | yes |

`wear_read` is the stability at or below which a side recognises a man is ready to be
taken. Green can still **finish** an obvious opportunity — a man who is nearly gone,
right in front of him. What he cannot do is **set one up**: `hunts_wear` is what sends
a fighter across the list looking for a wobbling opponent, and it stays off for him.
A third man arriving on an occupied opponent finishes off `wear_read + 0.15`, because
that shot is freer than one thrown from inside a bind.

**Measured: Seasoned now beats Green 63.3% on identical rosters, down from 94.9%.**


## 11 — The season loop (10 Sep 2026)

Built on Pete's instruction after C-6. The seam between the fight and the world.

| # | Item | Status |
|---|---|---|
| 11.1 | **`Season` is the seam** — it owns the world and the club, hands the melee two clubs, takes four numbers back | **locked** — a fought fixture and a simmed one reach the table through one shape. Checked: the sim's own rounds and margin are the numbers in *both* clubs' rows. |
| 11.2 | **`ClubFactory` builds a whole club from a rating, seeded off the club id alone** | **locked** — no save data, and the club you play in October fields the same eight it fielded in March. |
| 11.3 | **The factory walks to its target rather than inverting the rating formula** | **REC** — it calls `MeleeClub.power()` each step and stops when it matches, so it cannot silently fall out of agreement when the rating changes. Hits every tier from 30 to 86 exactly. |
| 11.4 | **`Session` is static vars on a `class_name`, not an autoload** | **locked** — 06.5 rules autoloads out; static vars do the same job for mutable state and still resolve in `--script` runs. |
| 11.5 | `Season.tscn` is the main scene; `Melee.tscn` run directly still puts up the exhibition fixtures | **REC** — the melee screen falls back when nobody handed it a bout, so the old entry point still works for balance work. |
| 11.6 | Saving | **ASSUMED** — everything is deterministic from seeds and ids, so a save is a small dictionary. There is not one. Closing the app loses the season. |

### What rendering caught that eight suites did not

Three defects, all invisible headless, all found in the first four pictures of the season
screen — which is the third time on this project that **readability could not be reasoned
about**:

1. **The column header was drawn inside the first row's highlight box**, so it became
   unreadable the moment the player was top of the table.
2. **Two clubs called "Cross Timbers Free Company"** on the same table. Club 0 is renamed
   *after* the generator runs and "Cross Timbers" is in the name pool, so the generator
   could hand the identical name to somebody else. The first fix reserved
   `PLAYER_NAME.split(" ")[0]` — which is `"Cross"`, and the pool entry is `"Cross
   Timbers"`, so it matched nothing and the duplicate went straight through a second time.
   **A fix that cannot be seen working has not been seen working.** Now 0 duplicates and 0
   repeated leading words across 40 generated worlds.
3. **Long club names ran into the played column.** On a table screen that reads as broken
   rather than as long.

And one in the tool rather than the game: the shot tool moved the player into the National
Division to render the worst-case layout, which made it **seventeen** clubs — a division
size the game can never produce. The picture was of a layout problem that does not exist,
while hiding whether the real one fits. It swaps a club out now.


## 12 — The shell and the save (10 Sep 2026)

Built on Pete's instruction: *"let's build the Main Menus along with the save functions.
Using the Retro Bowl formats, we can build it loosely off of it, but not close enough that
they're identical."*

| # | Item | Status |
|---|---|---|
| 12.1 | **Title screen with three save slots**, each read by `SaveGame.peek()` | **REC** — Retro Bowl's shell is one save and a straight PLAY. Three slots instead, because this game's arc is a club climbing a pyramid over many seasons and people run more than one. `peek` pulls denormalised fields off the front of the file, so listing three slots does not mean rebuilding three worlds. |
| 12.2 | **The clubhouse is three tabs and a primary action** — CLUB / SQUAD / HONORS | **REC** — the shape a manager game settles on: the thing you came to do is one tap from opening the game, everything else is one tap from that. Loosely Retro Bowl's shell; deliberately not its layout and none of its vocabulary. |
| 12.3 | **The save stores the RNG STREAM, not just the seed** | **locked** — a world reloaded with a fresh generator resolves the rest of its season differently from the run that saved it: the fixtures you have not played yet quietly change. Same class as a table that re-sorts on reload, and invisible until a player reloads and notices the results moved. The test proves it has teeth by dropping the stream and checking the world *diverges*. |
| 12.4 | **Only the player's club is stored** | **locked** — every other club is rebuilt by `ClubFactory` from its id and current rating, exactly as during play, so a save cannot disagree with a fresh session about who is on Iron Crown's line. |
| 12.5 | **Hand-written serialisation, not `ResourceSaver`** | **REC** — fewer lines the other way, but it welds the save format to Godot's Resource serialisation, which changes between versions and is unreadable when a player's save breaks. |
| 12.6 | **A four-byte magic at the front of the file** | **REC** — without it a foreign or truncated file reaches `get_var`, which returns null but prints engine errors on the way, so one bad slot looks like a broken game rather than one bad file. |
| 12.7 | **Autosave after every event, before every bout, and every summer** | **locked** — saving before handing over to the melee matters: a bout is a scene change and several minutes of play, and a save taken only on the way back would lose the whole event to a phone call. |
| 12.8 | **Two-tap delete** | **REC** — the button changes its own label to "Sure?". A single-tap delete on a screen full of buttons eventually eats somebody's tenth season. |
| 12.9 | `UiKit` holds the palette and the text helpers | **REC** — two screens drawing the same palette from two sets of local constants is how a UI drifts. Same reasoning as `Tuning`. |

### The bug worth keeping

The squad screen draws its own rows and puts flat invisible buttons on top of them for the
hit boxes. **The two were computed by separate functions and started 22 pixels apart** — so
tapping a name selected the man above him, and the last row could not be tapped at all.

Nothing headless can see it, and because the buttons are invisible it does not show up in a
screenshot either. The only tell was that two functions were each doing their own
arithmetic about the same list. **If two pieces of code have to agree about a position, one
of them should be asking the other** — there is now one `_squad_rows()` and both read it.

Three smaller ones, all found by rendering: the SQUAD header collided with the tab
underline, the BENCH label was drawn 26 pixels up into the last man on the line because
that group had no gap to write its header into, and the title screen's buttons sat flush on
the panel border.


## 13 — Landscape, and the clubhouse (10 Sep 2026)

| # | Item | Status |
|---|---|---|
| 13.1 | **Landscape, 960x540** | **locked, Pete 10 Sep 2026** — *"This is a fully Landscape game just like Retro Bowl."* Every screen was built portrait and every one was re-laid-out. This is the cheap version of that mistake; the expensive version is finding out after there is art. It suits the melee: a buhurt list is wider than it is deep and a line of five is a horizontal thing, so the screen and the sport finally agree. |
| 13.2 | **The melee is drawn rotated a quarter turn** | **locked, Pete 10 Sep 2026** — *"Player team on left, enemy team on right. Fighters lined up bottom row."* The sim still thinks in a portrait list; `_to_screen` swaps the axes on the way out and back. **Nothing in the sim moves — this is a camera**, and keeping it a camera is what lets the melee suite go on measuring the same fight. Fighter cards are a row along the bottom. |
| 13.2a | The list does not fill the width and cannot | **ASK** — the sim's list is 300 across the line by 320 along the charge, which is very nearly square, and a square list in a 16:9 frame leaves gutters however it is turned. Filling the width means a longer charge axis in `Tuning.LIST_H` — a sim change with a re-measure attached, not a layout one. The gutters currently carry the hint and the counters. |
| 13.3 | **A literal salary cap, with almost no money in it** | **locked, Pete 10 Sep 2026** — *"This isn't a rich sport by any means."* The Backyard Circuit runs on about **two hundred dollars a season**. Not two hundred thousand. The National Division reaches the high hundreds of thousands, and barely. So the cap is a different order of magnitude in every division — $200 / $2.6k / $34k / $1M — and the wage curve is exponential to match: a rating-38 fighter costs $3 and a rating-86 fighter costs $69,229. **Money that only becomes real at the top is the truest thing this game can say about the sport**, and it changes what the climb means: in the Backyard you choose between two fighters, in the National Division between a fighter and a facility. |
| 13.3a | The curve and the caps are anchored **together**, on each division's band top | **locked** — the first attempt anchored them separately and a top-of-table Backyard club billed $793 against a $200 cap. Four times its own league's limit is not a tight cap, it is a broken one. Now the best club a division can field bills just inside that division's cap, checked for all four. |
| 13.3b | **The club you start with is a Backyard club, not the balance fixture** | **locked** — `MeleeRosters.player_club()` rates 65, which is State League strength, and the season had been starting the player with it in a division whose band is 30-46. He began the game as by far the best club in it. Invisible while the league only sorted on a rating; impossible to miss once the cap became a division's rule. The fixture stays exactly as it is because twelve melee checks are measured on it; `starting_club()` builds a rating-38 club through ClubFactory like everybody else's. |
| 13.4 | **Credits** | **locked, Pete 10 Sep 2026** — retires 07.5's ASSUMED "Marks". Small integers, spent on the cap, facilities and captains. |
| 13.5 | **Two captains, two roles each — primary and secondary** | **locked, Pete 10 Sep 2026** — *"Two coaches means all positions get taken care of, but one position is the focus."* Three roles and four coverage slots, so two captains cover everything and double up on one, and **that overlap is the focus rather than a thing you pick off a menu.** |
| 13.6 | **A captain's real effect is the AI tier of his roles** | **locked** — `MeleeSim.role_skills` is per-role rather than per-side, so a coached Rail can be re-forming the line while an untaught Center is still standing on his plan zone. **The hire screen and the list are the same decision seen twice.** |
| 13.6a | **A CAPTAIN HAS TWO SPECIALIZATIONS. TOTAL.** | **locked, Pete 10 Sep 2026** — *"Rails, Flankers, and Center. They get TWO of those, not three, not elite, not whatever the hell."* A role a captain specializes in is **taught**; a role no captain specializes in is not. Two tiers, because there are two states. **Elite is not something a club buys** — it is what the sim reserves for opposition at the top of the pyramid. |
| 13.6b | Two captains, four slots, three roles | **REC** — teach all three and the fourth slot is waste, or leave one untaught. The screen names the untaught role in red and says which role both captains are doubling up on. |
| 13.7 | **Facilities: Home ground, Training ground, Infirmary** | **locked, Pete 10 Sep 2026.** Each has to move a number that already exists — a facility that only feeds another facility is a progress bar with a name on it. Gate credits, a winter's training points, events off a knock. |
| 13.7a | Home ground does **not** create home fixtures | **REC** — 09.5 is locked: buhurt clubs travel and the league is a single round-robin. A traveling circuit still rotates who HOSTS, so your own ground is what lets you take a turn, and the level is the gate. No contradiction, but worth writing down before somebody "fixes" the fixture list. |
| 13.8 | **Injuries** | **locked** — the Infirmary needs something to heal. A man who goes down can take a knock and miss events; he stays on the eight and stays on the wage bill, so the bench covers, which is the whole point of carrying one. |
| 13.9 | Morale | **REC** — a read-out, not a lever. It moves with results and a better ground takes the edge off a bad weekend. You cannot buy it, which is what keeps it honest. |
| 13.10 | Credit and wage numbers | **ASSUMED** — a first pass. They want a tuning session of their own once somebody has played ten seasons. |

### The captain system, wrong twice, and why

Both wrong versions failed the same way: **I added structure Pete had not asked for.** First a
primary worth 2 and a second worth 1; then head-counts with an Elite tier stacked on top.
Each produced a state where a role could be *half-taught* or *better than taught*, and
neither is a thing that exists — a man has been shown how to fight that position or he has
not. The correction was not a tuning pass, it was deleting two systems I invented.

The tell was there both times and I did not read it: every version needed a paragraph to
explain what a captain does, and the real rule fits in a sentence.

### Widening the arena, and what it broke

`Tuning.LIST_H` — the charge axis — went from 320 to **760**, on Pete's *"widen the arena a
lot more. That should also add time to the rounds."* Both halves were the point: a near-square
list left gutters down a 16:9 screen, and it also made the charge almost nothing, so a round
was one long grind instead of a charge, a contact and a fight.

Two things fell out, both measured with `tools/probe_pace.gd` rather than guessed:

1. **A longer list at the old pace put 29% of rounds on the clock.** The extra time was going
   into *walking*, which is the opposite of what widening it was for. `SPEED_BASE` 30 -> 46
   gives 44s rounds (up from 38s, so longer as asked) with only 13-18% reaching the clock —
   fewer unresolved rounds than the narrow list produced.
2. **Gas stopped being the constraint, and C-4 caught it.** Walking was charged per SECOND,
   so a list two and a half times longer with men proportionally quicker cost exactly the
   same tank: nobody gassed, and the post-fight report could name a gas problem in **6 bouts
   of 40** instead of 40. It is charged per METRE now, which is the truer model and is
   self-correcting — widen the list again and the walking bill goes up on its own instead of
   quietly going away.

**A constraint expressed in the wrong units survives every test until the thing it depends on
changes size.**

3. **The difficulty curve inverted, and every one of Seasoned's behaviors turned out to be
   the reason.** Green beat Seasoned 79%. Instrumenting it rather than reasoning about it
   showed Seasoned finishing bouts on 0.32 of a tank against Green's 0.51 and putting down
   half as many men — so the probe handed Green one Seasoned trait at a time, and **every
   single trait made Green worse.** Improvising, hunting wear, escaping a losing hold: all of
   them are MOVEMENT, and on a list two and a half times longer movement stopped being free.

   The largest was `gang`, and it was in the wrong file entirely. `GANG_PULL`'s own comment
   has always said *"the strategy dial is what turns it on"* — but it was wired to the AI
   tier, Green 0.0 and Seasoned 1.0. On the narrow list that was worth a point either way. On
   the wide one it decided the fight: a side that avoids piles takes five clean fights in its
   own lanes, while a side that seeks them walks across the arena, arrives gassed, and leaves
   a teammate one-on-one behind it. **Green's 0.0 was not a handicap, it was the best
   strategy in the game.** Ganging is 1.0 for everybody now and goes back to the strategy
   dial where the comment always said it lived.

   With that removed the two tiers measured *even*, which is not a curve either. `wear_read`
   is the only tier trait that still measures as an advantage, so it now carries the whole
   difficulty curve alone and had to be spread from 0.40/0.55 to **0.14/0.55** to do it:
   Seasoned beats Green 67.1%.

   The three handicapped behaviors are deliberately left in. They are Pete's own description
   of a green fighter and an experienced one, they are what the tier MEANS, and the right fix
   is to make improvising cheap on a long list — not to delete the idea because the current
   implementation of it is expensive. That is a job of its own and it is open.

**Two guesses about this cost more than the instrumenting did.** I gated the wear-hunt and
the gang pull on distance first, on the theory that the AI was chasing across the arena; the
numbers came back byte-identical, because `-distance` already dominated both bonuses. The
probe that varied one flag at a time answered it in one run.

### Two bugs worth keeping

**Counting weight where the rule counts heads.** Coverage was scored 2 for a primary and 1
for a secondary, and the tiers read that score. Two captains each holding the Center as
their *secondary* scored 2 — identical to one captain holding it as his primary — so the
role both of them attend to came out no better coached than a role one of them owns, and
Pete's rule had no teeth. **He said "two coaches", so the number is captains, not points.**
The weighted score still earns its keep naming the focus.

**A rate too low to be a mechanic.** Injuries at 0.028 a down produced **0.08 knocks a
bout** across both clubs — about one every three weekends, so a squad might see two in a
season and the Infirmary would be a button nobody could feel. At 0.05 your own five pick up
roughly a knock every four events: often enough to matter, rare enough to be news. A
mechanic that fires below the player's noise floor is not a subtle mechanic, it is an
absent one.

Plus three the renderer caught on the new screen: a facility's effect line printed straight
through its blurb, `%-9s` padding lined nothing up in a proportional font, and a level-nought
Infirmary announced itself as "-0 events off a knock" — which reads as a broken number
rather than as a thing you have not built.


### The C-6 suite disagreed with itself

Widening the list moved the wall from 12 points of roster deficit to **4** — the fight is
more decisive now, so the thumb carries less. Fine, and worth knowing.

What was not fine: C-6a and the wall sweep were measuring **the same configuration** — a good
thumb in the tactical hole on an even roster — off two different seed bases, and came back
**58.3% and 42%.** Sixteen points apart. The suite could pass one check and fail the other on
the same fight. They share a seed base now, so the deficit-0 cell *is* the C-6a number and
the two cannot contradict each other, and the wall is the first deficit the curve goes under
fifty and **stays** under, rather than the first cell that dips.

This is the second time in this file the answer has been "the test was measuring the seed."
Sharing the base does not make either number more precise — at two dozen bouts a cell nothing
here should be read to better than about ten points — it makes the suite internally honest.


## 14 — The arena, settled (10 Sep 2026)

Pete: *"Bring the arena down 25%, bring up round timer to 2 minutes, do not have walking
effect stamina. Let's see how that does."* — and it does very well.

| | |
|---|---|
| `LIST_H` (the charge axis) | 760 → **570** |
| `ROUND_TIME` | 60 → **120** |
| `GAS_MOVE` | **0** — walking is free |
| `GAS_CLINCH` | 0.021 → **0.031**, see below |

| Measured | |
|---|---|
| Round length | **42s** of a 120s round |
| Rounds reaching the clock | **~2%** — everything else resolves on the stop rule |
| Downs per bout | 10.4 |
| Men gassed per bout | 6.9 |
| Seasoned over Green | **69.2%** |
| Round endings | 5-1 ×269, 4-1 ×73, 3-1 ×37, 2-0 ×6, 1-0 ×1 — and 10 clock endings in 396 |

That endings table is the best this has ever looked. Pete's original ask for the clock was
that it *"should encapsulate most if not all fights"*; at 60 seconds it was catching one
round in six, and at 120 with a 570 list it catches one in fifty.

**Walking is free, and that changed what the tank is for.** It has been charged per second
and then per meter, and both were wrong the same way — they made crossing the list the thing
that empties a man, when what empties a man is being in a bind with somebody. Armor is
heavy to fight in, not heavy to stand up in.

Removing it retired the tank a second time: only 3.7 men a bout ran out and the report could
name a gas problem in **15 bouts of 40**. C-4 caught it, as it did when the units were wrong.
`GAS_CLINCH` is raised to compensate, which is the honest place for it — **if a bind is the
only thing that empties a man, a bind has to empty him.** 27 of 40 now.

**Twice in two passes, taking a gas source away has quietly switched the tank off.** C-4 is
the only thing that noticed either time, which is a good argument for the constraint existing
and a bad sign for how visible the tank is anywhere else.

### The banners

The 25% reduction leaves about 130 pixels either side of the list, and Pete asked for *"team
banners or something"* there. Each club stands down its own side: its arms at the size the
men are wearing them, its short name, the rounds it has taken as three lamps rather than a
number, how many of its men are still up, and how many it has put down this round. The
scoreline came out of the top corners — a score up there and a club down each side was the
same fact printed twice.

Rounds are lamps because a best-of-three has exactly three: a number makes you read it, three
lamps make you glance at it, and this is a thing you check without looking away from a fight.


### C-6's tactical hole had to be re-derived, again

Changing the arena stales the pairing the C-6 suite hangs on, and this time it did more than
drift: **Refused flank + Strong left, which was the worst thing a player could do on both the
320 list and the 760 one, is a mild advantage on the 570 one.** The check that caught it is
the one that asks whether swapping the two setups moves anything — it came back at *minus*
twelve points, which is the suite telling you its own baseline is upside down.

Re-swept with `tools/diag_c6.gd`. The new hole is **Line + Left rail push, 36% hands-off**
against Refused flank + Right rail push — deliberately *not* the worst on the board, because
Spearhead + Strong left manages 14% and a hole the thumb cannot climb out of tests nothing.
C-6a is the claim that a good player *can* climb out of one.

| | 320 list | 760 list | 570 list |
|---|---|---|---|
| Thumb in the hole, even roster | 83% | 58% | **96%** |
| The wall (roster deficit where the thumb stops paying) | 12 | 4 | **8** |

The tool is now written to be run rather than read: it sweeps fifteen player setups, prints
them all, and names the worst and the best. **Re-run it whenever the arena changes** — the
pairing is a balance record, not a fact about the sport.


## 15 — How a round ends (10 Sep 2026)

Pete: *"Those 5-1 results is WAY too much, most should be 3-1, 5-1 is for heavily outgunned
teams."* He was reading a table where **5-1 was 66% of rounds in a MIRROR MATCH** — two
identical clubs, and two thirds of the time one of them lost nobody at all.

That is a cascade, and the arithmetic says so: a 3-1 needs six men on the ground and a 5-1
needs four, so **a fight that ends 5-1 is not a more decisive fight, it is a shorter one.**
Whoever took the first down won the round outright, because being a man up compounded faster
than the other side could trade back.

| | before | after |
|---|---|---|
| Even mirror, 3-1 or 4-1 | ~29% | **56%** |
| Even mirror, 5-1 | **66%** | **30%** |
| Twelve points light, 5-1 | — | **39%** |
| Downs a bout | 10.4 | 13.7 |
| Round length | 42s | 27s |

`CLINCH_GRIND` 0.026 → **0.048** is what did it, and the reason it works is the arithmetic
above: more wear means more downs, and more downs means the loser is not the only one losing
men. `TD_GANG` came down 0.16 → 0.06 on the way — being a man up should be an advantage, not
a conveyor.

**The knobs are coupled and the coupling is the whole problem.** Every setting that fixed the
distribution shortened the round, because the stop rule ends a round on downs: a round with
six downs in it is over sooner than a round with four. At `CLINCH_GRIND` 0.058 the
distribution was ideal — 3-1 at 41%, 5-1 at 14% — and rounds lasted **19 seconds**. 0.048 is
the point where both are acceptable rather than either being right.

Raising the grind also switched the tank off for the third time in three passes: shorter
rounds mean less time in a bind, and the report could name a gas problem in **2 bouts of 40**.
`GAS_CLINCH` 0.031 → 0.058 with `CLINCH_GRIND_GASSED` softened 1.9 → 1.45, and it is 39 of 40
now. **C-4 has now caught this three times running and nothing else ever has.**

### An hour lost to my own bookkeeping

Midway through, a configuration I had already measured came back completely different —
3-1 at 39% one run and 16% the next, at what I believed were identical settings. I spent a
while treating that as a determinism problem in the sim. It was not: my "revert" had put the
takedown values back and left `CLINCH_GRIND` at the previous experiment's value. **Printing
the constants took thirty seconds and should have been the first thing, not the fifth.**
`tools/probe_sanity.gd` exists now so it is one command.

### The third seed-measuring test

`_test_autoplay_competent` (C-3) and `_test_symmetry` are **the same measurement** — a mirror
match with nobody drawing anything. One ran forty bouts of it, the other four hundred. They
disagreed in the same run: 37.5% against 49.1%, and the small one failed the build.

C-3 now reads the symmetry run's number. **Two checks measuring one thing at two sample sizes
will eventually contradict each other, and the small one will be the liar.** That is three
instances in this file — C-6's pivot, C-6's wall, and now this — which is enough to call it a
house rule rather than a run of bad luck.

The new endings check is written with that in mind: it asserts on the **band** (3-1 and 4-1
together) rather than on which of them is the mode, because at a hundred rounds those two
trade places between seed sets and 5-1 moves nine points. Pinning the mode would be a check
that passes or fails on its draw.

### "Refused flank" is gone

Pete: *"I don't even know what 'Refused flank' is."* It is a real term out of military
history and it is not a term anybody on a list uses. **Third borrowed word caught this way,
after "Bind" and "Carry."** The formation is **Staggered** now, which describes the shape in
a word anyone can read off the screen. The register's standing rule keeps earning its keep:
where Pete would know it first-hand, ask him rather than the glossary.


### ~~C-6 IS RED, AND THE REASON IS SPEARHEAD~~ — resolved, and I had it backwards

Three of C-6's four checks fail after this pass. I am leaving them failing rather than
tuning until they go green, because what they are reporting looks like a real balance
problem and not a stale baseline.

Re-swept with `tools/diag_c6.gd` on the current arena:

| formation | win rate hands-off, across all five strategies |
|---|---|
| **Line** | 57-71% |
| **Staggered** | 43-57% |
| **Spearhead** | **21-36%** |

Spearhead is uniformly the worst thing on the board whatever strategy is bolted to it. Its
blurb promises a trade — *"breaks their line and shows them your flanks"* — and on this
arena it is not a trade, it is just worse.

That makes it the only genuine "tactical hole" left, and **the thumb cannot climb out of it**:
orchestrating moves an even match 65% → 82.5%, seventeen points, but inside Spearhead it
moves 41.7% → 45.8%. Four. So C-6a — *a great player should be able to thumb-manoeuvre a win
out of being out-positioned and out-strategized* — is currently **false**, and the honest
report is that it is false rather than a pairing I have not found yet.

Two things worth separating:

1. **Spearhead needs looking at on its own.** Either its depth offsets are wrong for a list
   this long, or a formation that strings the line out has no answer once the plan expires.
2. **C-6's baseline should probably not be a formation this broken.** A suite that encodes
   "the hole" as whatever currently loses hardest will keep re-encoding whatever is most
   broken at the time, which is how it ends up asserting that a bug is a design.

Both are open. The measurement is in `tools/diag_c6.gd` and takes about four minutes.


## 16 — The roles, from ACRTW (10 Sep 2026)

I reported Spearhead as a balance bug: 21-36% whatever strategy was bolted to it, against
Line's 57-71%, and the thumb could not climb out of it. Pete read the same numbers correctly:

> *"To be fair, spearhead is pretty dumb where you expose your center first. Centers are
> opportunists, not frontline."*

**The sim was right and the formation was a bad idea.** A shape that sends your Center in
first is not a risky play with an upside, and the measurement was reporting exactly that.
*A measurement that says a design option is terrible is not automatically a bug in the
measurement* — I spent a page arguing it was one.

Inverting the depths so the pairs lead and the Center holds did **not** fix it on its own:
still 14-36%. Then Pete: *"Check ACRTW for role explanations."* `COMBAT_AI_DESIGN_SPEC.md` §6
has them written down, in the NFL analogy the sport's own people use:

| | |
|---|---|
| **Rail** | the anchor of the shoulder pair — the line itself |
| **Flanker** | a linebacker. Offence alongside his Rail; he *can* cover, but covering is not the job. Rail and Flanker move as a bonded pair until an advantage appears or a play splits them |
| **Center** | a **free safety**. He picks up the open, loose man and **screens their reinforcements** — denying their help is a first-class action and it is his before it is anybody's |

**I had the Center exactly backwards.** An hour earlier I had given him a pull toward enemies
who were *already tied up*, reasoning that an opportunist wants a busy target. Wrong, and
wrong in a way the spec would have told me in one line: a busy enemy is not going anywhere,
and the man who decides a melee is the one still free to go and make it two-on-one somewhere
else. **The Center's job is to be the reason their free man never arrives.**

With him playing free safety, Pairs forward runs **21-57%** depending on the strategy — a
situational formation instead of a trap. And it is the first time the three roles do anything
different from each other at all: until now position was only a place to stand.

| | |
|---|---|
| Rounds | **32s** of a 120s round |
| Even mirror | 3-1 **38%**, 4-1 27%, 5-1 26% |
| Twelve points light | 3-1 21%, 4-1 34%, 5-1 **39%** |
| Seasoned over Green | 78.5% |
| Gas named | 37 of 40 |
| C-6: thumb in the hole | 20.8% → **91.3%**, wall at 8 points |

`BREATHER_TIME` 3.0 → 4.4 on the way: the Center intercepting loose men made engagements
follow each other faster and compressed the round to 24s. Stretching the ebb between binds
gives the round its shape back without touching the down economy, which was finally right.

### Still ASSUMED

**The formation formerly called Spearhead is "Pairs forward" and that name is mine.**
"Spearhead" came out of the dossier glossary (#64) describing the shape Pete just called
dumb, so it cannot keep the name — but the replacement wants his word, not mine. Fourth
vocabulary item to go through this loop after Bind, Carry and Refused flank.


## 17 — Nomenclature, fixed at the source (10 Sep 2026)

Pete: *"How about you either give formation examples and I can name them or delete them, then
let's go through nomenclature and describe what you think it is, and I can just correct you."*

**That is the process, and it should have been the process from the start.** Four terms have
now been caught individually — Bind, Carry, Refused flank, Spearhead — each one after it was
already written into code, tests and docs. Showing him the thing and asking him to name it
costs one message; naming it myself costs a rename pass every time.

### What changed

| was | is |
|---|---|
| Clinch | **Grapple** |
| clinched / breathing / down | **Grappled / Recover / Downed** |
| Technique | **Skill** |
| Kit | **Armor** |
| Weight in kilograms | **pounds** |
| Green / Seasoned / Elite | **Rust, Experienced, Hardened, Elite, World, Legend** |

Confirmed unchanged: Bullrush, Hit, Takedown, Hold, Escape, Break, Loose, Out, Strength,
Base, Gas, Aggression, List, Stability, Three to one, Margin.

**The pound conversion is a unit change, not a balance change.** `BR_PER_KG` 0.0040 became
`BR_PER_LB` 0.00181 — divided by exactly 2.2046 — so every bullrush resolves as it did.
*A unit change that moves the balance is a balance change wearing a disguise.*

### Six tiers, and what they are for

Rust → Legend describes **how good a CPU club is**, so it belongs to the league: Backyard
clubs fight Rust, State Experienced, Regional Hardened, National Elite, and Worlds guests
World. Your own men are on the same ladder but only two rungs of it — a role your captains
teach goes out **Hardened**, a role nobody teaches goes out **Rust**. The four above are
something you climb to meet, not something you buy.

### Formations are SPOTS now, and there are three

They used to be five depth offsets applied to a fixed lateral spacing, which meant every
formation stood the men in the same five columns and could only shuffle them forward and
back. Pete's first correction — *"2-1-2, Flankers are a little closer to their Rails"* — is a
**lateral** change, and the old data model could not express it.

A formation is five `Vector2` spots in the club's own frame. Which is also exactly what a
player-drawn formation has to be, so the Chalkboard has its data model already.

**The set-up line.** *"Don't start anyone more than 15% from the back rail, you can have the
Center touching, but keep everyone back behind a 15% mark, you can probably mark it on the
field."* It is `Tuning.SET_UP_LINE`, it is enforced by `Tuning.formation_legal()` — which is
what will police the Chalkboard — and it is **painted on the list on both sides**, because a
rule the player infers from where the men happen to stand is not a rule, it is a surprise.

- **A — 2-1-2.** Flat at 12%, each Flanker tucked in close to his Rail.
- **B — Depth.** Center on the back rail at 0, the pairs up on the line at 13-15%.
- **C — Strong left.** Left pair up and level at 15%, right pair back and level at 4%.
- ~~D~~ — *"It's the same as B, just remove it."* Gone. I had flagged C and D as possibly the
  same idea twice and was half right: it was B and D.

Moving everyone behind 15% changed the geometry enough to move the endings — 5-1 went back to
39% — so `GRAPPLE_GRIND` went 0.048 → 0.056 to put it back. **The endings check now merges two
seed bases into two hundred rounds**, because the same configuration read 26% and 33% off two
different hundred-round draws, and a threshold pinned to one draw is the fourth instance of
this file measuring the seed.

### Dead code removed

`scripts/core/`, `scripts/sim/`, `bout_scene.gd` and `Bout.tscn` — the entire first design,
unreferenced since the melee replaced it. They would have taken part in every rename above
for no reason.


### C-6 is one check red, and the shape of the bug is familiar

`the tactical hole is a real hole` fails: the pairing reads **50.0%** hands-off where the
check needs it under fifty. The other four pass — the thumb lifts that 50% to 70.8%, the wall
sits at 8 points of roster deficit, and sixteen points light is a shutout.

The instructive part is *why* the pairing is wrong. `tools/diag_c6.gd` picked it after
measuring it at **36%** — over fourteen bouts, where the suite measures over twenty-four.
**A tool that chooses a test's baseline must measure it the way the test will**, or it hands
over a number the test cannot reproduce. The tool now reads `N` straight off the suite.

That is the third shape of one bug: C-3 measuring the symmetry run's quantity at a tenth of
its sample, C-6a measuring the wall sweep's quantity off a different seed base, and now the
diagnostic measuring the suite's quantity at a smaller n. Each time the small reading was the
liar and each time it failed loudly enough to look like a balance regression.

**The deeper fix is that C-6 should not hard-code a pairing at all.** It has gone stale five
times — every arena change and every formation rewrite — which is most sessions that touch the
fight. It should sweep at run time, take the first pairing under about 45%, and assert on the
*relationship* rather than on any particular setup. The sweep is the expensive part and is
exactly why it was hard-coded in the first place; doing it properly means budgeting for it.
Open, and the next thing I would fix in the test suite.


## 18 — The Chalkboard, and Create (10 Sep 2026)

Pete, 10 Sep 2026:

> *I want the players to be able to create their own formations / Plays. We'll have a
> Create-A-Player, Create-A-Team, and "Chalkboard" to create formations and plays. You'll
> have to use credits to unlock up to 4 of each.*
> *Chalkboard - Formation will let the player position fighters behind the 15% line in any
> formation they want. Being able to save the formation and use it via drop down.*
> *Chalkboard - Plays will let the player draw the routes he wants his fighters to initially
> take. Plays can be check marked to be Formation dependent or universal.*

Built. `scripts/game/chalkboard.gd`, `scripts/game/workshop.gd`, two scenes, seventeen new
checks (`tests/test_chalkboard.gd`, `tests/test_create.gd`). Everything below is a decision
that was not in the instruction and had to be made to carry it out.

### A play is the TACTICS rung, and the gap under the thumb is load-bearing

Pete's ladder is **roster > thumb > tactics**. A drawn route already existed —
`MeleeSim.give_order` — and the lazy build was to have a play call it five times. That would
have handed the Chalkboard everything the thumb is worth:

* a man under a thumb-drawn order **opens the action menu** at contact, and answering it is
  the whole skill ceiling;
* a man under a thumb-drawn order **cancels his own recovery**, because the player's read
  outranks the AI's caution;
* both feed `orders_issued`, which is what **C-6 measures the thumb's value with**.

So `Order` gained `from_play`, and a play route does none of the three. It walks, it expires
into the strategy plan, and the man goes back to the AI. `test_chalkboard.gd` asserts it:
five men sent into the middle by a play raise **0 menus and 0 thumb orders**. Without that
flag, drawing four good plays once would have bought a player, permanently and for free,
most of what playing well is supposed to buy.

### Re-setting the line must not cost RNG

`Season.begin_bout()` assigns the shape after `MeleeSim.new()` has already set the line, so
the men had to be placed again. Setting the line rolls each man's first action timer, and
running it twice would have pulled ten extra numbers out of the stream — **moving every
seeded result in the game** depending on whether a caller happened to set a plan. `set_plan`
saves `rng.state` and restores it. Setup is not simulation.

This is the same family as the RNG-stream bug in the save (12) and it is worth naming: **any
function that both arranges the world and consumes the stream cannot be called twice.**

### Vector2 is 32-bit, and the line is drawn at 15%

A player who drags a man exactly onto the painted set-up line produces `0.150000005960464`,
the nearest float32 to 0.15, and the 64-bit constant refused **the one placement the line is
drawn to invite**. `Tuning.SPOT_EPSILON` (0.0005) closes it. The check still refuses a
thousandth past, which is what the test asserts — the epsilon is a float-width allowance, not
a slackened rule.

### Ids, not indices

A play bound to a formation stores that formation's **id**. Stored as an index, deleting the
first formation would silently re-point every play after it at the wrong shape — a player's
saved plan quietly doing something else, found weeks later. Deleting a formation a play is
drawn for is refused **by name**, because unbinding it silently is the same bug wearing a
politer face.

### The formation editor is drawn to true proportions

First version stretched the 15% band across two-thirds of the screen because that was the
space available. A positioning tool that distorts distance is showing the player a shape he is
not making. The field is now drawn at the list's real aspect and shows only as much of the
charge axis as the mode can reach — a narrow strip for formations, the whole approach for
plays. The ground past the line is grayed, so the clamp under the finger has a reason on
screen before the finger finds it.

### Create-A-Player is capped twice, and neither cap is soft

The roster is the **top** rung, so this screen is the one that can break the game by working
exactly as a player wants it to.

* **Rating** — your division's ceiling plus 6. Backyard caps a made man at 52.
* **Per stat** — the same ceiling plus 22.

The second is not belt-and-braces. Rating is a weighted mean, so **99 strength with ones
everywhere else rates 23** and sails through a rating cap — and then bullrushes a division
whose best man is 46. That is the hole somebody would actually find, and it has a check.

The salary cap is the third governor and it only bites near the top of a division, because the
wage curve is exponential: a club at rating 46 bills $125, at 48 bills $188, at 50 bills $287,
against a $200 Backyard cap. That shape is correct — the rating ceiling governs an ordinary
club, the cap governs a good one — but it means the cap check has to be run against a club
that is genuinely tight or it passes without proving anything.

### A club starts full, so creating is always replacing

Thirteen men is the roster rule and the starting club already carries thirteen. "Write a
fighter" is therefore **never** an addition — the first build shipped a feature that refused
itself on the first tap. `Workshop.create` takes the man he replaces, everything is validated
before anybody is cut, and a made man joins the **reserve**, never the line: he takes the same
walk onto the eight as a signed man, through the squad screen.

### Create-A-Team is free

The credits buy fighters, not colors. It edits your club's name, short name and heraldry,
and the only rule is the sport's own tincture rule, which already existed on `MeleeClub` and
is asked rather than reimplemented.

### Read of "up to 4 of each" — open

Taken as **4 formations, 4 plays, 4 made fighters**, with Create-A-Team as a one-of-one
because you manage one club. If Pete meant four *saved club identities* as well, that is a
small change to `Workshop` and nothing else.

### Still open from 17

The **strategies** have not had Pete's review: Turtle is mine and looks wrong, A/B and D/E
are mirror pairs (three ideas, not five), and **"Strong left" is now both a formation and a
strategy** — one of them needs renaming.

### Suite

66 of 67 green. The one red is C-6's hard-coded pairing, unchanged and documented in 17.


## 19 — The icon bank, and the end of the heraldry (10 Sep 2026)

Pete, 10 Sep 2026:

> *Let's change the charge color and charge name to something more modern day.*
> *We can have an Icon bank that they can buy with credits or later asset packs.*
> *Yes, 1 Create-A-Team for each save file.*

### The vocabulary is gone at the source, not in the labels

Charges, tinctures, fields, crests and the metal-on-color rule are out of the
codebase, the same way the nomenclature pass in 17 went — renamed where they are
declared rather than translated at the UI. A club now has a **kit**, an
**icon_color** and an **icon**; `UiKit.crest` is `UiKit.badge`; `MeleeClub.Charge`
is gone entirely.

**The mark is an id, not an enum.** `IconBank.ICONS` is an array of dictionaries
each carrying `id`, `name`, `pack` and `cost`, and the id is what a save stores.
An enum cannot grow with an asset pack without renumbering, and renumbering
would silently repaint every club that ever bought a mark. Ids are append-only
and the suite asserts they are unique.

Save VERSION went 1 → 2. A version 1 file would decode into a club with no
colors at all, so it is refused cleanly, which is the whole reason the version
is in the file.

### What survived: the rule, not the taxonomy

The metal/color rule was always a *proxy* for "can you read this across a
field", and a proxy stops being right the moment somebody adds a color. It is
now a measurement — `IconBank.contrast_ok`, a luma delta of 0.34 — and the check
that every kit × mark pairing the create screen can produce clears it is in the
suite.

It caught one immediately. The orange kit `b8541f` against the gold mark failed
by **three thousandths**, which is exactly the pairing a player would pick and
then squint at. The kit was darkened to `9c4416`; the rule was not loosened,
because the rule was right.

### A mark is only a mark if it READS, and that is not settled in code

`tools/shot_icons.gd` renders the whole bank twice — at badge size and at the
13 pixels a league table actually uses — and it was written and run **before
anything used the bank**. First sheet:

* **Axe** read as a flag on a pole. Twice more after that, too. A blade hanging
  off one side of an off-center haft *is* a pennant; it took moving the haft to
  the center, adding a back lug, and giving the blade a bearded fan before it
  read as an axe.
* **Hammer** read as the letter T. A block on a stem is a letter at any size —
  it needed a spike off the back to become a weapon.
* **Helm** read as a doorway, because the sight was implied rather than cut.
* **Bear** read as a cartoon mouse. Round ears on top of a round head always
  will; they went wide and low.
* **Shield** read as a pentagon, then as a letter Y after the first fix.
* **Horns** read as a cup until the tips turned up and a boss went between them.
* **Skull** had no eye sockets at all: they were drawn at **alpha zero**, which
  paints nothing.

That last one is the structural finding. Half these marks need a hole, and a
hole is the **kit showing through** — so `draw_icon` takes the kit color as well
as the mark color. No third color, which would turn to mud at 13 pixels.

**Seven of twenty marks were wrong, and every one of them looked fine in the
source.** The sheet cost ten minutes to write.

### One painter, not two

The marks used to be a match statement in `UiKit` *and* a second, slightly
different one in the melee's banner code — which is how a club could wear one
mark on the league table and another on the surcoat. Both now call
`IconBank.draw_icon`.

### The bank

Twenty marks in three packs. The four flat geometrics are free with every save
(`cost == 0` *is* the definition of the starter set, rather than a second list
that can disagree with it); the rest run 1–5 credits. A pack is a field on each
entry, so a later asset pack is a block added to the array and **nothing else** —
no new code path, no new save field, no new screen.

Ownership lives on `Workshop` and saves with the file, and `Workshop.rename` —
now an instance method for exactly this reason — refuses a mark the save has not
bought. That check is deliberately not on the screen: a rule enforced at one call
site is a rule with a hole in it.

On screen the shelf shows locked marks **drawn in the club's own colors**, not
padlocked. The question a player is answering is "do I want to wear that", and
he cannot answer it from a padlock. The first version dimmed both colors and
produced dark gray on dark red; the kit goes back to full and the mark goes
translucent instead, so the shape still reads.

### One Create-A-Team per save

Confirmed by Pete. The club, its colors and its collection of marks are all
per-save, and a new save starts the collection again. Create-A-Team stays
**editable** rather than one-shot — locking it after a single edit would strand
every mark bought afterwards. Say so if that is wrong; it is a one-line change.

### Suite

70 of 71 green — chalkboard 8, create 12, melee 14, cup 11, league 8, office 6,
save 5, season 5. The one red is still C-6's hard-coded pairing (17).


## 20 — Four strategies, and three liars in the suite (10 Sep 2026)

Pete, 10 Sep 2026, across three messages:

> *Turtle is fine. It just means all fighters make their way to a protective
> shell around the center on one of the sides. Strong Left Formation, Let's do
> Rush Left, Rush Right as the strategy.*

> *No. Rush Left and Rush Right is where the name side goes forward
> further/faster than the other side, but they're still staying in their lanes
> going forward.*

> *It means they go straight ahead unless the strategy calls for them to move
> differently. For these premade strategies, They should all be going straight
> except for Turtle.*

### A strategy is a DEPTH PROFILE

This is the structural change and it is worth stating on its own.

`push` is five numbers — how far up the list each man drives — and that is
usually the whole strategy. Where he stands across the line comes from the
**formation**, and he goes straight forward from it. A strategy that also
carried lateral positions would quietly undo the formation the player just
picked: a Rush drawn over Strong Left would drag the men back into standard
lanes, and the two screens would be fighting each other.

`lane` is optional and only Turtle has it, because only Turtle is supposed to
move anybody sideways.

**A rush is an echelon, not a slide.** The first version had it as a rail push —
the whole line sliding across and driving up one edge — which is a different
manoeuvre and not what the word means. Pete corrected it in one sentence.
"Further/faster" is depth only: the named side is given a zone further up the
list and everybody walks at the same speed. No pace lever was added.

Four strategies now, not three: **Rush left, Rush right, Turtle left, Turtle
right.** The two Turtles mirror by SLOT as well as by position — a right-hand
shell is not a left-hand shell with the x values flipped and the same men in the
same places; the man nearest the rail is the one whose own side it is.

### Three separate measurements in this suite were lying

All three were found in one evening, by one change, and they are all the same
bug: **a number that was only ever right by coincidence.**

**1. The pace check divided by three.** It took the whole bout, subtracted two
corners, and divided by `ROUNDS` — but a best-of-three is two or three rounds,
and more than half these bouts settle in two. Every one of those had a two-round
total divided by three and two corners taken off when one happened. The printed
number was never the round length; it was bout time over three, and it looked
like a round length only while the early-finish rate stayed put. Decisive plans
moved that rate and it fell under the floor while rounds were running
**thirty-two seconds**. `tools/probe_plans.gd` measured all nine pairings at
31–39s, which is what said the check was wrong rather than the fight.

**2. C-6's hole was two hard-coded constants** and had gone stale **five times**
— every arena change, every formation rewrite, every rebalance, and finally the
strategy cut, which deleted the enum value it named. It now walks every pairing
at **the same N the assertions use**, takes the first where a hands-off player is
genuinely losing, and asserts the *relationship*. Found in two pairings: 2-1-2 /
Turtle left against 2-1-2 / Rush left, **33.3%** hands-off, and a good thumb
lifts it to **83.3%**.

**3. The two ending cells were compared at different sample sizes.** The even
cell ran on two seed bases and the twelve-points-light cell on one. They read
33% and 36% — three points apart, which says a 5-1 no longer means anything and
Pete's rule is broken. `tools/probe_mix.gd` re-measured both at four bases:

| deficit | 3-1 | 4-1 | 5-1 | 3-1 + 4-1 |
|---|---|---|---|---|
| even | 26% | 37% | **31%** | 63% |
| 6 light | 19% | 41% | 32% | 60% |
| 12 light | 10% | 27% | **58%** | 37% |

The signal was never gone. A twelve-point deficit **nearly doubles** the 5-1
rate. The smaller cell was the liar, and it was the smaller cell *by
construction* because somebody had given it half the seeds.

**The house rule, sixth instance and the sharpest yet: two cells compared
against each other must be measured at the same sample size, or the comparison
is between their sample sizes.** Both cells now run four bases, and the suite
reads **32% even against 41% twelve points light** — a nine-point gap where it
had been three.

The probe's gap is wider than the suite's (31/58 against 32/41) and that is not
a contradiction: the probe mirrors the opponent's positions and the suite's light
cell does not, so they are two different fights. Both say the same thing, which
is the thing that was in doubt — **a 5-1 still means somebody was outgunned.**

### What was NOT tuned, and why

The echelon looked like a suspect for the ending mix, so `tools/probe_echelon.gd`
swept the stagger: spreads of 0.36 / 0.28 / 0.20 / 0.12 gave 5-1 at
29% / 33% / 32% / 25% over ~240 rounds each. **The steepness is not the lever** —
the whole sweep sits inside the five-point band the suite warns about. Pete's
echelon was left at 0.36 rather than flattened in pursuit of a number it does not
control.

That probe also had to be fixed before it could be believed: the first version
read `round_downs`, which is reset as the next round is set up, and reported 0%
for both 3-1 and 5-1. **A probe disagreeing with the suite about a quantity they
both measure is this project's oldest bug wearing a new hat**; it now reads
standing counts exactly as `tests/test_melee.gd` does.

### Datestamps

Every entry from 16 onward was stamped **11 Sep** and has been corrected to
**10 Sep**. The container clock is UTC and rolls over at 7pm Central, which is
the exact failure Pete has flagged before. Fixed across docs and code comments.

### Suite

**71 of 71**, and the twelve-light ending cell now reports a number that matches
reality. First time the whole thing has been green: melee 14, create 12, cup 11,
chalkboard 8, league 8, office 6, C-6 5, save 5, season 5.


## 21 — The Arena (10 Sep 2026)

Pete, 10 Sep 2026:

> *Adding to the Front Office, we want to be able to build and upgrade your own
> Arena/Stadium/Gym. Each upgrade unlocked via league advancement. You'll be able
> to run your own events from a demo that may raise a couple dollars all the way
> up to hosting the National Championship. We'll have each upgraded arena look
> better and better via ChatGPT image creator, and have logos placed, each
> upgrade making the logo go from really shitty quality to NFL level details.*

And on the detail:

> *Events pay Credits.*
> *Schedule them. All but Nationals is separate from the league. Demos are
> unplayed and pay little, you can host your own tournament but it takes 2 weeks
> to set up and you can set the budget. # of fans, popularity and reputation and
> podium finish dictate the reward money. You'll either lose a little money,
> break even, or win money.*

### The Home ground facility is gone, not renamed

Its blurb was *"Host an event each season. Better ground, better gate"* — it was
this feature in embryo, five levels of a progress bar with nothing behind it.
Keeping both would have given the player a Home ground level AND an arena level,
both feeding the same gate, with no way to reason about which to spend on. **Two
systems for one idea is worse than either.**

The remaining two facilities keep their original enum values (`TRAINING = 1`,
`INFIRMARY = 2`). Renumbering would have turned every stored Training level into
an Infirmary level in any save that survived — and save VERSION went to 3 so none
does, but a rule that only holds because of a second rule is not a rule.

### Unlocked by advancement, not by money

Six grounds, 40 seats to 12,000. Every other purchase in this game asks *have you
got the credits*; this one asks *have you earned the right*. A Backyard club with
9,999 credits is refused the Fenced ground and told to get promoted — which is
what makes climbing the pyramid worth something beyond a better fixture list.

### Reputation, and two findings from the sweep

Reputation is what turns capacity into a crowd. A national arena draws 2,481
unknown and 11,647 famous, and money alone does not fix it: spending big while
nobody has heard of you gets 3,713 and an expensive empty hall.

**Ten straight wins outranked a promotion** — 0.120 against 0.100. Since going up
is also what unlocks the next arena, that would have split the feature in half: a
big ground you cannot fill, or a full house in a shed. Promotion is 0.20 now, so
three of them take a nobody to a full arena. **The pyramid is how you get
famous.**

**The top budget was a trap.** Attendance clamps at capacity, so a famous club
buying the "All in" draw was paying eighteen credits for a house it was already
going to fill — and the biggest budget came out NEGATIVE at every reputation in
the sweep while the cheapest came out positive. A choice that is never right is
not a choice. Budgets now carry a `take` as well as a `draw`: a bigger show
charges more per head, so it raises the ceiling that the draw runs into.

| reputation | Shoestring | Proper | All in |
|---|---|---|---|
| 0.05 | −2 | −5 | −10 |
| 0.25 | +0 | −1 | +1 |
| 0.55 | +2 | +3 | **+8** |
| 0.95 | +4 | +8 | **+8** |

All three of Pete's outcomes exist, the worst booking in the game is −18 against
a top budget of 18 ("lose a little"), and a demo can never lose — that is the
floor of the economy, the thing a broke club does.

### The badge is painted, not swapped

Pete asked for the logo to go *"from really shitty quality to NFL level
details"*, and it is the club's **own** mark that improves — a player who picked
the Wolf watches his wolf get sharper. Four things make a cheap paint job look
cheap, and each is worth something: off-register, a ghost of the first pass,
thinned color that spends the contrast the bank guarantees, and no keyline.

None of it is a second set of shapes. It is the same `draw_icon` the league table
uses, drawn worse — so a mark added in a future asset pack gets the whole
progression for free and can never be the one that does not have it.

The mark also **shrinks by what it slips**. The shapes in the bank already reach
0.86–0.94 of the radius, so sliding one two pixels sideways pushed it straight
out through the edge of the badge, which reads as a rendering bug rather than as
cheap paint.

### There is no artwork in the arena screen, and that is deliberate

The first version drew each ground from primitives — stands, a crowd, a rope,
floodlights — on the reasoning that the levels needed to be legible while the
economy was being balanced. Pete, 10 Sep 2026: *"Let's not use your art for any
of this, just placeholders. I'll get ChatGPT to do that work."*

He is right, and the reason is worth writing down: **drawing it made a set of art
decisions that were not mine to make, and which the real images would then have
had to argue with.** A placeholder that looks finished is worse than an empty
one, because it quietly becomes the spec.

So the ground is an empty labelled SLOT — the level's name, the exact path it is
waiting for, the pixel size, and corner ticks so it reads as a frame rather than
as a panel that failed to draw. `_art_for()` checks `ResourceLoader.exists` at
draw time and fills the slot the moment a file is there. Drop
`art/arena/arena_0.png` … `arena_5.png` in and they appear; no rebuild, no code
change. `art/arena/README.md` carries the slot list and the sizes.

The one thing the game still renders itself is **the badge**, and it has to: it
is the mark the player picked out of the icon bank, so it cannot live inside a
fixed image. Pete asked for that directly — *"Yes, the badge itself gets
better"* — and it draws over the artwork when the artwork arrives, which is why
the slot spec says to leave that corner clear and not to paint a logo in.

### Open

The hosted tournament resolves on paper through `Cup.run_all`. **You still cannot
fight your own event** — `Cup.player_match()` remains orphaned, and it is now
orphaned in two places rather than one. That is the next thing.

### Suite

**80 of 80.** melee 14, create 12, cup 11, arena 9, chalkboard 8, league 8,
office 6, C-6 5, save 5, season 5.


## 22 — Fighting your own cup (10 Sep 2026)

`Cup.player_match()` was written the day the cups were built and **sat with no
caller for the entire project.** So did `Cup.player_finish`, which was declared
and never once assigned — every screen that reported a cup run printed an empty
string.

Neither was an oversight in the cup code. The cause was one line in
`LeagueWorld.auto_resolve_cups()`: **the world resolved every bracket on paper
before anybody could be asked about it.** A player could qualify for the Worlds,
win it, and never throw a punch — and by the time the Arena landed, the same
hole had swallowed a second feature, because a hosted tournament resolved itself
the same way.

### The seam is one flag

`LeagueWorld.hold_player_cups`. False by default, so the soak tests and the
auto-play path resolve every cup exactly as they always did — that is asserted,
not assumed (`the auto path is untouched`: six seasons, six Worlds, nothing left
holding). A real `Season` sets it true, and then a cup the player is still alive
in is left standing instead of being resolved around him.

`Cup.player_alive()` is derived from the bracket rather than stored as a flag,
because a flag would be a second source of truth for something the rounds
already know. Pools are the exception and are handled as one: nobody is out of a
pool until the pool is over.

### A cup tie is a bout, not a special case

`begin_cup_bout()` builds the same `MeleeSim` as a league fixture — same
captains, same drawn formation, same called play. The moment a cup tie becomes
its own kind of fight, the two paths start to drift.

Which means the melee screen **cannot tell them apart on the way back**, so
`Session.bout_is_cup` decides which book the result goes in. Posting a cup tie to
the league table is the sort of bug that looks like a scoring error for a
fortnight before anybody finds it; the suite checks the matchday does not move
and the table does not change.

The bracket stores `a` and `b` in draw order and **the player is not always
`a`** — so the four numbers out of the sim are flipped when he is the away name.
Checked directly, because getting it backwards would look like bad luck rather
than like a bug.

### You cannot walk away from a semi-final

`ready_to_roll()` is `season_complete() and not cup_pending()`. Without it a
player ends a Worlds run by pressing the button that starts next year, and the
cup quietly resolves itself around him.

### The hosted tournament goes through the same seam

Which is the whole reason it was worth building a seam rather than special-casing
the cups. `_settle_event()` now draws the field, builds the Cup, sims the opening
round around the player and **leaves it standing**. The gate is not counted until
the bracket is finished, because the podium is part of the payout and there is no
podium until somebody has won it — so `_settle_gate()` is split out and runs on
completion.

`tests/test_arena.gd` caught that change on its own and had to be rewritten: an
event is now a bracket you fight, not a payout that arrives.

### Suite

**87 of 87.** melee 14, create 12, cup 11, arena 9, chalkboard 8, league 8, cup
seam 7, office 6, C-6 5, save 5, season 5.

### Open

The cup screen shows the tie in front of you but **not the bracket** — there is
no way to see the draw, who is left, or who you would meet in the final. That is
the next thing, and it is a screen rather than a system.


## 23 — The tournament bid (10 Sep 2026)

Pete, 10 Sep 2026:

> *Let's make player made tournament a "start of year" process. Between seasons,
> a part of it is "Tournament Bid" where you can choose a certain week in the
> season to hold your own tournament. Then it becomes a static event yearly based
> on available weeks, we can give like 3 options per year. They choose one of
> them, and then I would personally try to bank up the arena as much as I could
> to get a big reward, creating a rewarded credit sink.*

Three dates on the table every summer, answered before the first matchday. The
date and the budget are both paid **on the spot, a season before the show** —
which is the whole bet. You commit against the ground and the reputation you
have today and find out next year whether the season you had was good enough.

The slots are not interchangeable: **Opening weeks** is cheap and draws badly,
the **Run-in** costs five times as much and draws best, because by then
everyone's season is on the line somewhere. `at` is a fraction of the season, not
a matchday, since a Backyard year is five events and a National one is fifteen —
so a promoted club is offered a longer calendar with later, dearer dates in it.

### Two traps, both the same bug, both found by measuring

`tools/probe_sink.gd` prints the best yearly net at every ground, paired with the
reputation a club realistically has when it owns that ground. First run:

* **the Run-in was a trap.** The cheapest date won at every single level,
  because attendance clamps at capacity and the prestige bonus bought a house the
  club was already filling. Identical in shape to the "All in" budget trap in 21.
* **every ground below a Sports hall had a gate of ZERO.** Not "a small crowd
  pays a little" — literally nothing, because a linear per-head rate that keeps
  a 12,000-seat arena sane rounds 170 people down to zero credits.

The permanent fix for the first is not a third dial. It is **to stop
saturating**: the top of the range — famous club, biggest budget, best date — now
lands just under a full house instead of a long way past it. Nothing is wasted,
every dial still pays, and the only way to earn more is a bigger ground. *The
arena is the lever and everything else is a multiplier on it,* which is exactly
the sink Pete asked for.

The second needed a **compressive gate**: `GATE_K × heads^0.72`. Capacity runs
300:1 and the credit economy runs about 60:1; a straight rate cannot serve both
ends, and a power under one turns the 300:1 in seats into about 20:1 in money.

### The sink, measured

| ground | holds | rep | best date | best budget | net |
|---|---|---|---|---|---|
| Back field | 40 | 0.10 | Opening weeks | Shoestring | −5 |
| Club gym | 120 | 0.18 | Opening weeks | Shoestring | −5 |
| Fenced ground | 400 | 0.34 | Opening weeks | Shoestring | −4 |
| Sports hall | 1,200 | 0.50 | Opening weeks | Shoestring | −1 |
| Arena | 4,000 | 0.68 | **Midseason** | All in | **+8** |
| National Arena | 12,000 | 0.86 | **Run-in** | All in | **+58** |

The whole ladder costs **138 credits** and the top of it returns **+58 a year**
before the podium — a payback around two and a half seasons, against a league win
worth 2 and a division title worth 6. And the best *date* now changes with the
ground, which is the sign the dials are doing separate work.

Small clubs still lose a little on a tournament, which is Pete's "lose a little
money" and is correct: below a real ground you run demos, and you bid anyway only
because a full-ish house builds reputation.

### The tests were green by luck

`test_save` failed a round trip whose numbers were perfect. There are **three
save slots and five test files that write to them**, and the suite runs in
parallel because the melee checks take five minutes on their own — so by the time
`test_save` read slot 2 back, `test_arena` had written its own season over it.

It had been that way for a while and passed anyway, which is the worrying part:
**a test that shares mutable global state with another test is not isolated, and
parallelism is what tells you.** `SaveGame.set_namespace()` gives each file its
own corner of `user://`.

(`namespace` is a reserved word in GDScript, and the parse error it gives —
"Expected variable name after var" — names neither the word nor the reason. The
field is `slot_prefix`, and the comment says why, so nobody loses ten minutes to
it twice.)

### Suite

**91 of 91.** melee 14, arena 13, create 12, cup 11, chalkboard 8, league 8, cup
seam 7, office 6, C-6 5, save 5, season 5.


## 24 — Fans and notoriety (10 Sep 2026)

Pete, 10 Sep 2026, replacing reputation outright:

> *All dates cost the same, the cost just grows with the league they're in. It
> gives players the obvious choice to set it far off and during the season,
> upgrade it as much as possible, win as much as possible for more fans, and get
> notoriety.*
>
> *Each arena runs off the amount of fans you have and notoriety. Notoriety can
> be from 1-125. 1 notoriety means no one comes. 125 Notoriety means sold out and
> people are trying to sneak in… 25 notoriety at backyard is pretty great, 50 at
> state, 75 at regionals, 125 at Nationals/worlds.*
>
> *Fans climb at gates as well… each level can have 25% over their max upgraded
> arena… 25% of fans usually never come to events.*

### Two numbers doing two jobs

* **Fans** — how many people follow the club at all. A pool, built over years,
  ceilinged at **125% of the ground you have built for them**.
* **Notoriety** — how many of them turn up. 1 to 125, and it *is* the turnout:
  at 125 every fan comes and a quarter cannot get in, which is exactly why the
  fan ceiling sits a quarter above capacity.

Neither is any use alone, and that is asserted: a full-following club at
notoriety 1 draws 800 of 80,000; a club everyone has heard of with 40 fans draws
40. Fans grow **logistically** — a win adds a fraction of the gap to the ceiling
— so a small club grows slowly, a club that has just built a bigger ground grows
fast into it, and nobody has to invent a per-division fan number. Upgrading the
arena is the sink seen from the other side.

Capacities: the first four grounds stay club-sized, then **Arena 12,000 and
National Arena 80,000**. Pete wanted the Regional-to-National step felt.

### All three dates cost the same

The first version priced them differently and gave the late one a bigger draw,
which turned the choice into a sum. Without that the decision is better: the
value of a later date is entirely **emergent** — it is however much club you can
build before the day arrives. The price is the *division's*, not the date's.

### Solving the gates instead of guessing them

Each summer notoriety becomes `(N + G) × DECAY`, so it settles at
`G × DECAY / (1 − DECAY)` — with DECAY 0.86, **G × 6.14**. Divisions run 5, 7,
11 and 15 events, so Pete's 25 / 50 / 75 / 125 need a season worth about 4, 8, 12
and 20. The constants are solved from that and then **checked against the sim**.

`tools/probe_notoriety.gd` took three goes to ask the right question, and the two
wrong versions are the lesson:

1. It followed a club up the pyramid and answered *"it reaches 125"* — true of
   any club that gets to the National Division, and silent about gates.
2. Fixed, it followed a club that got relegated by season seven and measured the
   equilibrium of a club that was **losing**.

"25 at Backyard is pretty great" is a claim about a club that **stays** in the
Backyard Circuit. So the probe now holds each division for twelve seasons at
three standards of club:

| division | title-winning | good | mid-table | Pete's gate |
|---|---|---|---|---|
| Backyard | 22 | 26 | 9 | 25 |
| State | 46 | 45 | 24 | 50 |
| Regional | 97 | 71 | 55 | 75 |
| National | 108 | 108 | 101 | 125 |

Close, and left close rather than tuned to the decimal — a soft gate measured to
three figures is a hard gate with extra steps.

One finding on the way: **the crowd bonus was drowning the season.** At double
the current rate it contributed sixty of a National club's hundred and seven, and
it is the same sixty whether you win the division or finish eleventh — so a
mid-table National club came out 104.7 against a champion's 107.5, and the
standard of the club stopped mattering at exactly the level where it should
matter most. A crowd should be loud; it should not be louder than the season.

### A real bug, found by the probe

`_clear_guests()` sent the Worlds guest clubs home at roll-over **while a held
Worlds bracket still named them** — so the next season asked the player to fight
club 55, which no longer existed, and the run fell over on an out-of-bounds. A
consequence of 22 that only shows up when a player holds a cup across a summer,
which is a thing no test was doing until this probe played twenty-two seasons.
The guests now leave when the bracket that invited them retires.

### Suite

**94 of 94.** arena 16, melee 14, create 12, cup 11, chalkboard 8, league 8, cup
seam 7, office 6, C-6 5, save 5, season 5. Save VERSION is 4.

---

## 25 — Combat Credits, the crowd band, and the bills (10 Sep 2026)

Pete read the Retro Bowl teardown and took all eight recommendations, plus the
career layer on top: *"What to steal: All 8. I do like our arena features right
now, the only thing I'd change is the currency and you can recommend those from
Retro Bowl… I like the potentials, the XP, Contracts, Player market, Dilemmas,
the upgradable salary cap, and the ground decay, you'll want to have to maintain
them, I like their crowd meter as well, I do like our gates due to Retro Bowl
staying in one league, we're promoting/demoting. For Currency, Combat Credits."*

That is several phases of work, sequenced by dependency. This section is **phase
one: the economy** — the currency, the banding, the upkeep. The career layer
(age, potential, XP), contracts and the market, and the dilemmas come after,
because all three want an economy that already means something to sit in.

### The currency

**Combat Credits, shown as `CC`.** One faucet, one currency, exactly as they do
it — `$` stays what it already was, a salary-cap constraint with no wallet behind
it. The dual-currency version was considered and dropped: a club in this sport
does not have a transfer budget, and a second number would have to be invented
before it could be spent.

Not copied: **their scarcity**. Retro Bowl's early-game credit drought is priced
against a 99-cent unlock, and a premium game has no reason to inherit a ramp that
exists to sell something.

### The crowd band — the single biggest thing they do better

Their fan meter is not decoration, it **bands the per-game payout**: a third full
pays one credit, two thirds pays two, above that three. A run of wins is worth
triple what the same run was worth in a bad year, and the meter is the first
thing a player learns to read.

Ours did none of that. Notoriety moved the gate **once a year** at roll-over and
every fight paid a flat 2 credits regardless — so the number the entire arena
system is built on never reached the wallet on a timescale anybody feels.

Now every league fight pays `crowd_pay()` for being watched, and the result pays
on top. The bands are **Pete's own division gates**, not new numbers:

| notoriety | band | word | CC a fight |
|---|---|---|---|
| 1 | 0 | Nobody | 1 |
| 10 | 1 | Talked about | 2 |
| 25 | 2 | A name locally | 3 |
| 50 | 3 | Known across the state | 4 |
| 75 | 4 | Known nationally | 5 |
| 105 | 5 | A household name | 6 |

So a band means *"you have arrived in this division"*, and the top band is worth
**three times a win** — who is watching matters more than who won, which is the
Retro Bowl relationship and the point of the exercise.

Two details that are the whole reason it works:

* **The word and the money change on the same tick.** They used to be two
  hand-written ladders in two places; they are now one array read twice.
  `note_word()` is `CROWD_WORD[crowd_band()]` and nothing else.
* **Every gate moves the money.** The first draft paid `[1, 1, 2, 3, 4, 5]`, so
  crossing 10 changed the word and nothing else. A meter with a dead segment in
  it teaches the player the meter sometimes lies, and then he stops reading it.

The pay is read **before** `note_after` moves notoriety, so a fight pays the band
the club had when it walked out. Paying after would let one win cross a gate and
then pay the new band for the fight that crossed it — a half-band of free money
on every crossing, and it reads as a bug the first time anybody notices.

The meter itself is drawn on the Clubhouse: six segments, the bands behind filled
solid, the band being worked on partly filled. A band you cannot see coming is a
band you cannot chase.

### The bug the banding uncovered

Putting a season's income next to a season's prices for the first time —
`tools/probe_economy.gd` — turned up something much larger than the thing it was
built to check.

**The ground's standing retainer paid a full National Arena 284 CC every summer
for doing nothing.** Nearly five times the cost of the arena itself, every year,
forever. A National club earned 394 CC a season against a 60-credit ground, which
means every sink in the game was decorative above the State League, and the
banding that had just been added was 19% of an income it was supposed to drive.

The exponent was the bug. At `attendance^0.62` the retainer grows nearly as fast
as the crowd does, so it was really *attendance, paid twice* — once there and
once through the event gate, where it belongs. At **`^0.30 × 0.72`** it grows
like the log of the crowd instead: 2 CC at a back field, 3 at a club gym, 6 at a
sports hall, 12 at an arena, 21 at a full National Arena. A tenth of what it was
at the top and almost unchanged at the bottom, which is the right shape for a
retainer.

The comment above that function already said *"Small — the events are where the
arena actually earns."* The code had disagreed with it since it was written.

### The bills

Pete: *"the ground decay, you'll want to have to maintain them."*

Retro Bowl decays facilities a level a season and makes you re-buy the step. Same
loop here with the price written on it: every summer each building bills **45% of
what its current level cost to build**, rounded up, and anything the club cannot
cover drops a level.

| building | upkeep a summer |
|---|---|
| Training ground / Infirmary | 2 at level 1, 5 at level 5 |
| Club gym | 3 |
| Fenced ground | 6 |
| Sports hall | 10 |
| Arena | 18 |
| National Arena | 27 |

**The bill is not the penalty — the rebuild is.** Skipping 27 credits on the
National Arena costs 60 to put back, and that asymmetry is what makes maintenance
a thing you do rather than a thing you weigh.

Two rules fell out of it:

* **The arena is paid first**, because it is the thing that earns. Letting the
  ground fall to keep a Training ground would trade the club's income for a
  coaching bonus, which is never the trade a player would have chosen.
* **A ground that drops takes its following with it.** `fan_cap()` is capacity ×
  1.25, so a National Arena falling to an Arena clamps 100,000 fans down to
  15,000. Ten years of building, gone with the building.

And it is what finally makes **relegation hurt.** A club that overbuilds and goes
down keeps the bills of the division it left while earning the income of the
division it landed in. Nothing else in this game punished overreach; the whole
economy was one-way until this existed.

No ground is profitable to simply own. The club gym washes its face exactly —
three credits in, three out — and every step above it is a commitment that has to
be earned back through the gate. That line is asserted, not eyeballed.

### What a season pays now

`tools/probe_economy.gd`, three seed bases, twelve seasons each, back half
counted, hosting a Proper show every year:

| division | club | notoriety | band | CC a fight | upkeep | net CC a season |
|---|---|---|---|---|---|---|
| Backyard | title-winning | 31.7 | 2 | 3 | 3 | 26.1 |
| Backyard | mid-table | 14.6 | 1 | 2 | 3 | 10.8 |
| State | title-winning | 57.3 | 3 | 4 | 10 | 38.8 |
| State | mid-table | 31.5 | 2 | 3 | 10 | 17.9 |
| Regional | title-winning | 90.6 | 4 | 5 | 18 | 68.6 |
| Regional | mid-table | 59.1 | 3 | 4 | 18 | 49.8 |
| National | title-winning | 107.5 | 5 | 6 | 27 | 185.5 |
| National | mid-table | 104.4 | 4 | 5 | 27 | 166.4 |

An **11× income spread against a 10× cost spread** on the arena ladder, which is
the relationship that was missing. It was 40× before the retainer was fixed.

### Left open, deliberately

**The National Division still earns more than it can spend** — 185 CC a season
against a 60-credit ground and a ladder that is finished by the time you get
there. That is an endgame content problem, not a balance bug, and the fix is the
sinks that phases two and three are bringing: contracts, the player market, and
making the salary cap repeatable the way Retro Bowl's is. Tuning the faucet down
before those exist would be tuning against a game that is about to change.

### The house rule, seventh instance

*Two checks measuring one quantity at two sample sizes will eventually contradict
each other, and the small one is the liar.* The first run of `probe_economy` —
one seed, a four-year window — reported a **mid-table Backyard club out-earning a
title-winning one**. That is not a finding, it is noise, and it was noise at
exactly the size that reads as a discovery. Three seed bases and a twelve-year
run put the order back the right way up. The probe now says in its own header
that it has been read as evidence once already.

### Suite

**98 of 98.** arena 16, melee 14, create 12, cup 11, office 10, chalkboard 8,
league 8, cup seam 7, C-6 5, save 5, season 5. Save VERSION stays 4 — upkeep
changes only the arena level and the facility levels, both of which were already
stored.

---

## 26 — The career layer (10 Sep 2026)

Phase two of Pete's eight. Fighters age, decline and retire; potential is a
second visible number with exactly one scarce way to raise it; XP is earned by
doing; and there is a replacement-level man so a club is never stuck. All four
were on his list by name.

### The one idea worth having: there is no single peak age

A gridiron player has one athletic prime and falls off it. **A buhurt fighter has
four, and they are years apart:**

| stat | peaks at | why |
|---|---|---|
| Gas | 24 | the tank goes first and goes hardest |
| Strength | 28 | roughly where a heavy athlete tops out |
| Base | 32 | not being put down is mostly knowing how |
| Skill | 35 | technique keeps compounding for a long time |
| Aggression | never | it is temperament, not an attribute |

So an old fighter is not a worse fighter, he is a **different** fighter: hard to
put down, technically the best man on the field, and empty by the third round.
Anyone who has stood on a list knows that man. The curve puts him in the game for
free, and it means a club's decision about a 36-year-old is a real one rather
than a sell-by date. It also lands on the roles this game already has — Rails
want strength and base, Centers want skill, everyone wants gas — so a club that
ages out of the Flanker slots and into the Rails is a thing that will now happen
on its own.

### The bug that would have made all of that decoration

The winter raised a fighter's **lowest** stat, which is the rule it had used
since long before any of this. `tools/probe_career.gd` played a career out and
the result was damning: by 32 a trained fighter read **68 / 68 / 68 / 67**.
Training had sanded every man in the game into the same shape, the four peaks
canceled out, and the entire claim the layer exists to make was false in the
only place it could be checked. The peaks were "reached" at 31, 31, 32 and 30 —
four different design numbers producing one undifferentiated slide.

The fix is a rule, not a weighting: **you cannot train a stat you are past the
peak of.** A 30-year-old's work goes into base and skill because gas and strength
are behind him. Under the peak the lowest stat still wins, so a club still trains
its weaknesses and the winter is still reproducible from a save without rolling
anything.

The same fighter after the fix, at 35: **58 strength, 74 base, 90 skill, 46
gas.** Peaks reached at 21 / 28 / 32 / 35, in the design's order.

And past all four peaks, training **holds the line**: a point buys back one of
the points that winter took, never more. Training visibly slows the fall and
never reverses it — a veteran who ended a winter better than he started it would
make age optional, which is the one thing this layer must never allow.

### Potential

A ceiling on `overall()`, not on any single stat: a fighter can rearrange himself
under it however his training goes, he just cannot exceed it. The starting gap is
drawn against how far he is from the last peak to arrive, so it closes on its own
as he ages and there is no second age table to keep in step.

Across a generated country (624 men): 7.0 points of room at 20-24, 4.2 at 25-29,
1.2 at 30-34, 0.1 at 35-39. 31% are already at their ceiling. The number binds
without being a second rating.

**One scarce way up, and one only.** The club names a single man its prospect for
the winter; he gains 3, and it needs a Training ground at level 3. Not buyable,
not repeatable within a year. A second route was considered and cut: anything you
can buy in bulk stops being a ceiling and becomes a price, and then potential is
just rating with extra steps.

### XP

Earned by doing, off the two numbers the post-fight report already shows —
downs caused and rounds finished standing. Nothing new is measured, so the screen
and the ledger cannot tell the player different stories. A bout pays 2, a down
pays 3, a round on your feet pays 1. Points cost 8, 12, 18, 26, 40 — rising, so a
club cannot bank three quiet years and buy a fighter a new career in one summer.

**A man who did not come on earns nothing.** That is the reserve problem stated
as a rule and the pressure that makes a squad a squad. A simmed event pays a flat
8 to the five who would have played, a little under an average afternoon: fighting
is rewarded without simming being a trap the player can't see.

### Retirement, and the replacement man

Retirement rolls after the winter, on the man he has become — a fighter who just
lost three points to age is likelier to go than the one he was in October. It
starts at 33 and is certain at 46, and it is steeper for a man who has sunk a
long way under his own ceiling. Late on purpose: buhurt is full of men in their
late thirties, and a game that pensioned them off at 32 would be describing a
different sport.

Which creates the hole that Retro Bowl's **"noname"** fills, and that is task 4
of the eight. A free, replacement-level fighter drawn nine points under the
division floor. It is not a convenience feature — it is what gives every other
number on the roster a meaning: a 62-rated fighter is not worth 62, he is worth
62 minus what you could have had for nothing.

**A second bug, found by the same probe.** The refill signed walk-ons only while
the club could not fill a *line*, so a squad that retired down to six men kept
traveling with six — legal on the day, and one knock from being unable to fight.
The 25-season run surfaced it as **a roster of five.** The eight now goes back to
eight.

### What a club actually does over 25 seasons

`tools/probe_career.gd`, one club, three conditions:

| condition | power after 25 seasons | retirements a winter |
|---|---|---|
| Neglected (no ground, no captains) | 65 → **21** | 0.7 |
| Managed (maxed ground, two captains) | 66 → **34** | 0.6 |
| Managed, with a market (simulated) | 66 → **75** | 0.5 |

The middle row looked like a broken winter and is not. A managed club still
slides because **it has no way to sign anybody** — every retirement is replaced by
a walk-on nine points under the floor, since that is the only inflow this game
currently has. The third row replaces retirees at the middle of the division band
instead, which is what a player market makes possible, and the club climbs and
holds. **The career arithmetic is sound; the missing piece is phase three.**

That is worth stating plainly because the obvious reading of row two is "tune the
decline down", and doing that would have broken row three the moment the market
arrived.

### Suite

**106 of 106.** arena 16, melee 14, create 12, cup 11, office 10, career 8,
chalkboard 8, league 8, cup seam 7, C-6 5, save 5, season 5.

Save **VERSION 5**: every fighter carries an age, a ceiling and banked XP, and a
version 4 file has none of them — it would load a squad of 26-year-olds with
ceilings equal to their current rating, a club that can never improve and never
retires anybody. Refused cleanly instead.

One detail worth keeping: **the prospect is stored by roster index, not as a
card.** Writing the card would decode into a copy, the winter would raise a
ceiling on a fighter nobody is fielding, and the man on the roster would be
untouched — invisible until somebody asks why the number never moved.

### Still open

The **cup screen shows the tie but not the bracket** — no way to see the draw.
Carried over from section 22 and still true.

---

## 27 — Contracts, the market, and the cap with no ceiling (10 Sep 2026)

Phase three. Contracts with the extend-versus-re-sign fork and the rookie
discount; a player market with Pete's coarse tiers in the pricing; and the
upgradable salary cap made unbounded, which he had already asked for and which
two separate measurements turned out to need.

### A contract is a number that does not move when the man does

`ClubOffice.wage()` read a fighter's rating and billed it, live. **That is not a
contract, it is a price tag.** A man who improved got more expensive the instant
he improved, so developing somebody was self-defeating and the salary cap
punished precisely what the training ground exists to do.

A card now carries the deal it signed — a wage and the summers left on it — and
`ClubOffice.wage()` becomes the MARKET RATE: what he would cost today. The bill
reads the deal. **The gap between the two is the whole game:**

- a young man on a long deal who has come good — cheap, and yours
- a veteran on a deal signed at his peak — expensive, and declining

Measured: improve a fighter by twenty points in every stat and the club's wage
bill does not move a dollar, while his market rate goes **$644 → $37k**.

### The fork

| | when | price |
|---|---|---|
| **Extend** | while the deal still runs | discounted by how much of it you tear up — bottoms at **72%** of market |
| **Re-sign** | once it has run out | full market rate, no discount |

A club that extends everybody early overpays for the ones who stall; one that
never extends pays full price for the ones who came good. Neither is right, which
is what makes it a decision. The discount is capped well short of free — at ten
percent a year and no cap a five-year extension lands at half price and the
correct play is to extend every man the day you sign him, which is not a fork, it
is a button. A man in his last year cannot be extended at all, for the same
reason: two buttons with two prices means the player picks the cheaper one.

**Rookie discount: 60% of market, under 24.** Keyed to age rather than newness —
a 33-year-old free agent is not a rookie however new he is to your books. It is
what makes the reserve worth filling and a walk-on worth more than his rating
says.

### Out of contract is a state, not an exit

A deal reaching zero removes nobody. It puts a man **out of contract** — on the
team sheet, marked, re-signable, for a whole season. Only a man who was already
out of contract and whom nobody re-signed actually walks.

Without that stage the player loses fighters to a number he was never shown
changing. With it, losing somebody is a decision he made by not making one, which
is a fair thing for a game to do to you.

**Whether he waits is rolled against the club's NOTORIETY.** A fighter will hang
on for a club people have heard of; a good fighter at a club nobody has heard of
will not. That is the arena system reaching a roster decision, which is the kind
of connection that turns two features into one game.

### The market

No draft. It is the one piece of Retro Bowl's structure that does not survive the
trip — buhurt clubs do not draft, there is no college system feeding them, and a
fighter picks who he trains with. The sport's actual mechanism is free agency, so
that is what this is: **six men a summer**, generated from the world seed and the
season number rather than stored, so a save carries who has been TAKEN out of the
pool and not who was in it.

**Pete's item 8 — "coarse tiers somewhere, so there is a seam to game" — is the
signing fee.** It is charged by band, not by rating:

| band | fee |
|---|---|
| Journeyman | 1 CC |
| Steady | 3 |
| Good | 6 |
| Strong | 11 |
| Star | 18 |

The widest band is **six rating points across**, so within it a better fighter is
free and the skill is taking the man at the top of a band rather than the one at
the bottom of the next. Bands are read against the division's own power range, so
"a good signing" means the same thing in the Backyard Circuit as at National.

Two walls, and both are real: **credits** get you to the table, the **cap**
decides whether you can sit down. Each refusal names the number that stopped it.

### The cap has no ceiling any more

Pete asked for the upgradable cap to work like Retro Bowl's. Two separate
measurements said the five-level version was actively breaking things:

- `probe_economy` (section 25) found the National Division earning **185 CC a
  season** against a ladder it had already finished, with nothing left to buy.
- `probe_market` found a club sitting on **1,100 unspent credits** unable to sign
  a single free agent, because the cap it had maxed out five raises ago had no
  room in it for anybody.

One system had a surplus and the other a shortage, and the same missing feature
caused both. It is now unbounded and priced to bite: `4 × 1.28^level` — 4, 5, 7,
8, 11, 14, 17, 22, 28, 36, 46, 59 — so the first few are ordinary club business
and the twentieth is a season's income. Twenty raises cost 1,983 CC and take a
National cap from $1.00M to $4.00M. **A sink with no ceiling and a rising price
absorbs a surplus without ever becoming the obvious buy**, which closes the item
section 25 left open.

### Does it close the hole?

`tools/probe_market.gd`, the same club for 25 seasons, one crude policy
difference:

| | power after 25 seasons |
|---|---|
| Ignores the market | 37 → **22** (replacement level) |
| Signs the best man it can afford | 37 → **33** (holds at the top of its division) |

And `probe_career`, re-run: neglected **21**, managed **23**, managed with an
inflow **52**. The market is the difference between a club that decays to the
floor and one that holds — and its ceiling is its division, which is correct. You
climb by winning, not by shopping.

### Three bugs, all found by checks that went red for the wrong reason

**1. The career probes were running the melee fixture as a career club.**
`MeleeRosters.player_club()` is a hand-written club rating **65** whose job is to
make seeded bouts reproduce. Dropping it into a career means dropping a
Regional-standard squad into a division whose band tops out at 46: it bills
**$8,134 against a $200 cap.** It never mattered, because nothing consumed the
cap as a constraint until the market did — and then every signing and every
re-signing was refused and the checks were measuring an impossible club. The game
itself was always right; it uses `starting_club()`. Section 26's absolute numbers
were from the wrong club and are corrected above; the relative comparison in it
survived.

**2. Created fighters were never put on a contract.** A card built by hand
carried `wage_agreed` of zero, `ClubOffice.billed()` fell back to his market
rate, and he was the only man in the game whose wage moved every time he
improved. He also carried the default ceiling of 70 — fine on a man written at
60, and on one written at 74 it means he arrives already finished.

**3. A rewritten test passed for the wrong reason.** `test_create`'s cap check
named a rating (52 against a club built at 48) and the contract layer moved the
bill under it — rookie deals at 60% of market meant the squad billed less. The
first rewrite swept for the wall at run time, found one at 56, and went green on
the refusal *"He rates 56; the Backyard Circuit caps a made man at 52"* — which
is the RATING cap, not the wage cap. Two rules guard that button and the sweep
had wandered into the other one. **A green test proving a rule it is not testing
is worse than a red one.** It now loads the squad so the swap lands exactly one
dollar over and asserts the refusal names the bill.

### The house rule, eighth instance

Not a sample-size instance this time but the same family: *a threshold written
down is a threshold that goes stale.* That is now the sixth hardcoded number in
this suite to drift out from under its own test. The rule the codebase has
settled on is C-6's: **sweep for the wall at run time and assert the shape** —
that a wall exists, that one step under it is allowed, and that the refusal is the
one you meant.

### Suite

**114 of 114.** arena 16, melee 14, create 12, cup 11, office 10, career 8,
chalkboard 8, league 8, market 8, cup seam 7, C-6 5, save 5, season 5.

Save **VERSION 6**: a fighter carries the deal he is on, and a version 5 file has
none — it would load a squad on no contract at all, everybody out of contract,
the whole club walking at the first roll-over.

### Where the eight stand

1. Band notoriety into per-event income — **done** (25)
2. Fighters age, decline and retire — **done** (26)
3. Potential, with one scarce way to raise it — **done** (26)
4. A replacement-level fighter and a tighter squeeze — **done** (26)
5. A dilemma between every fight — **open, phase four**
6. Contracts, the fork, the rookie discount — **done** (27)
7. Facility decay and the upgrade throttle — **decay done** (25); the
   one-upgrade-per-week throttle is still open
8. Coarse tiers with a seam to game — **done** (27), as the signing fee

Plus Pete's named extras: XP from production **done** (26), player market
**done** (27), upgradable salary cap **done** (27).

### Still open

- **Dilemmas**, phase four — the last of the eight.
- **The per-week upgrade throttle**, so a windfall cannot buy instant
  infrastructure.
- **The cup screen shows the tie but not the bracket** — no way to see the draw.
  Carried from section 22 and still true.

---

## 28 — The deck, and the number it spends (10 Sep 2026)

Phase four, and the last of Pete's eight: **a dilemma between every fight.** Plus
the half of item 7 that was still open — the one-upgrade-a-week throttle.

### The rule the deck is built on

Retro Bowl puts a small scenario in front of you after nearly every game and it
is the reason their season has a texture instead of a rhythm. The thing that
makes them work is easy to state and easy to break by accident:

**Every option has to cost something.** A dilemma with a right answer is a quiz,
and a player solves a quiz once and then stops reading. So there is no free option
anywhere in the deck — the choice is always *which currency you would rather
spend*, and the currencies are deliberately different in kind so they cannot be
compared with arithmetic:

| | |
|---|---|
| CC | the only money there is |
| morale | who waits for you, and who retires early |
| notoriety | what fills the seats |
| fans | the following itself |
| a man | his harness, his fitness, his deal, his ceiling |

Trading credits for morale is a decision. Trading credits for credits is not.

**Fifteen cards, thirty-eight options, and all of them about buhurt.** Harness
condemned at the gate. Somebody fighting for two clubs. A brewery that wants its
name on the rail. The marshal wanting a quiet word. A cool box in the back of the
van that is not full of water. The armorer who has not been paid since spring and
will not ask a third time. The generic version of this feature — *a player is
unhappy, give him money or don't* — would have been half the work and none of the
point.

The card the deck picks out a fighter for picks him **by rule where a rule reads
better**: the harness card finds the man in the worst kit, the winter-abroad card
finds the youngest, the paperwork card finds the best. A card about condemned
armor landing on the best-kept fighter in the club reads as a game shuffling
cards rather than as something happening.

### Morale was a progress bar with a name on it

The deck spends morale, so before the deck could exist morale had to *do*
something. It was a read-out: it moved with results, it was drawn on the
Clubhouse, and it reached **nothing** — which is exactly what this codebase threw
the Home ground facility out for being.

It now decides two things, both on surfaces that already existed and neither of
which touches the sim's seeded results:

* **Whether a man out of contract waits for you.** Men leave unhappy clubs.
* **Whether a veteran retires early.** A 37-year-old somewhere he is enjoying
  himself keeps going; the same man at a club that is no fun does not.

Measured: a 36-year-old out of contract waits **66%** of the time at a happy club
and **36%** at a miserable one, and retires in **24%** of winters versus **42%**.

### And then morale turned out to be broken

`tools/probe_dilemma.gd` played thirty seasons under three different policies and
**every one of them ended pinned at 0.05** — the floor. Morale added a flat swing
per result, so a club losing more than it won subtracted a little every week with
nothing pulling back.

That was harmless for as long as nothing read it. It stopped being harmless the
same afternoon it started deciding who waits and who retires: a struggling club
would have sat at maximum penalty forever, bleeding fighters it could never keep,
in a spiral with no bottom and no way out.

So morale is **logistic** now — the swing is scaled by the room left in the
direction it is going, the same shape `FANS_WIN_GAP` already used a few lines up
in the same file. It cannot reach either end, and it settles where the club's
record puts it:

| wins | settles at | word |
|---|---|---|
| 4 in 5 | 0.85 | Flying |
| 3 in 5 | 0.60 | Good |
| 2 in 5 | 0.47 | Fine |
| 1 in 5 | 0.26 | Restless |

Thirty straight losses drop it to 0.08 and **ten wins bring it back to 0.60**,
which is the property that matters: recoverable, not merely bounded.

The five words were then re-anchored on those measured equilibria. Against the old
thresholds a club winning four fixtures in five read "Good" and "Flying" was
unreachable — four of the five names had been describing a range the number never
visited.

### The bug that mattered most

The deck drew from `world.rng` — the stream every fixture, every cup draw and
every quick bout in the country comes out of. Three draws a matchday: the chance,
the card, the man.

`test_cupplay` went from seven green checks to five failures reading **"no cup
came up"**. The Invitational's draw had been reshuffled by a card about a brewery.

**A cosmetic system must never move the competitive one.** The deck now derives
its own generator from the world seed and the matchday, exactly the way the
tournament bid dates and the free-agent pool already do: deterministic, identical
across a reload, and costing the world's stream nothing.

### One job at a time

Item 7's remaining half. Retro Bowl lets you improve one thing at a time, and it
is not a fussy rule — it is what stops a windfall becoming an instant club.
Without it a player banks a good tournament and buys the ground, both facilities
and four cap raises on the same afternoon, and every decision the Clubhouse exists
to make interesting gets made in one undifferentiated blur.

**One upgrade per building per matchday** — not one upgrade total. Mending the
infirmary and raising the cap in the same week are different decisions about
different problems. Taking the same building up three levels while nothing else
in the world moves is not.

It closed a hole on the way. **Building the ground lived in the Arena screen** —
three lines of check, subtract, increment — so it was the one upgrade in the club
no rule could reach. A rule enforced at one call site is a rule with a hole in it,
and that is now the third thing this codebase has said it about. `build_arena()`
lives on the office; the screen asks, like the facilities and the cap already did.

Every test that stacked upgrades in one call now says `new_week()` between them,
rather than the throttle getting a back door for setup code. Escape hatches rot.

### Suite

**122 of 122.** arena 16, melee 14, create 12, office 11, cup 11, career 8,
chalkboard 8, league 8, market 8, cup seam 7, deck 7, C-6 5, save 5, season 5.

Save **VERSION 7**: a season carries the card on the table and the last few dealt;
a version 6 file would load mid-season with a dilemma the player had already
answered still blocking his next fight.

Two checks in the new file are there because they caught something:
`every option costs something` sweeps all thirty-eight options and found two free
ones on the first run, and `a card cannot break a clamp` fires every option in the
deck at a club already at every ceiling — every effect goes through the office's
own functions rather than writing its fields, so a card is the one thing in the
game that *could* push notoriety past 125 and cannot.

### Pete's eight, complete

1. Band notoriety into per-event income — **done** (25)
2. Fighters age, decline and retire — **done** (26)
3. Potential, with one scarce way to raise it — **done** (26)
4. A replacement-level fighter and a tighter squeeze — **done** (26)
5. A dilemma between every fight — **done** (28)
6. Contracts, the fork, the rookie discount — **done** (27)
7. Facility decay **(25)** and the per-week throttle **(28)** — **done**
8. Coarse tiers with a seam to game — **done** (27), as the signing fee

Plus his named extras: XP from production (26), the player market (27), the
upgradable salary cap (27).

### Still open

- **The cup screen shows the tie but not the bracket** — no way to see the draw.
  Carried from section 22 and the oldest thing on this list.
- **The arena and field art**, which Pete has said all along is the last job:
  *"The arena/field will be the art/animation at the end of this all."* The
  placeholders and their labelled slots are waiting.

---

## 29 — The mood, and ACRTW's audio engine (10 Sep 2026)

Two things, and the second was Pete's:

> *I like your recommendation, but I think we can have tournaments/playoffs be
> the normal menu, except stylized, and maybe some different music. Slightly more
> thematic in a "boss battle" sort of way as other 8-Bits do.*

> *Check ACRTW, we built an awesome audio engine in it. We can translate that
> here.*

### What Retro Bowl actually does with brackets

Worth recording, because the answer was got the hard way and contradicts what the
teardown had listed as unknown. Their web build is a **GameMaker HTML5 export**,
so the logic is readable JavaScript and the string table is plain text. Read out
of **v1.6.8 (18 Jul 2024)**:

- **14 teams, 7 per conference.** Seeds 1-4 are division winners, 5-7 the best
  non-winners. Only the **#1 seed byes**. The divisional round **reseeds**.
- 13 fixtures, advanced **one game at a time** with Play/Skip.
- A **legacy 12-team bracket still exists** for saves started before the change —
  detected by the playoff list having 11 fixtures instead of 13.
- Winning pays **+10 CC** on top of the 1-3 for a win, plus a ring on every
  player and both coordinators.
- Home advantage is real **only in AI-vs-AI sims**: +2 strength, wins ties by 3,
  and a 1-in-5 chance of an upset loss being flipped back.

And the screen itself is **extremely thin**: three-letter abbreviations, **no
seeds, no scores, no connecting lines**. A finished game dims *both* teams to 50%
alpha — the winner is not marked, you infer it from the next column. The tree is
carried entirely by column position and vertical alignment.

Their one genuinely good structural idea: **the bracket room IS the regular-season
standings screen.** Same room, same button, same title bar — it swaps instance
layers and the title from "Playoff Picture" to "Playoffs" when the season ends.
One screen all year.

### Pete's idea collapsed the problem

I had mocked up four bracket screens and recommended one. He is right and it was
the wrong shape: **a separate bracket screen is a second information architecture
to build, learn and keep in step.** A skin is not.

`UiKit`'s palette went from `const` to `static var` — one word — and all **218
places in this game that draw anything** now follow it. Team sheet, market,
clubhouse, the fight itself. No layout changed and nothing else in the codebase
needed editing.

| mood | look |
|---|---|
| NORMAL | warm parchment. A club in a hall on a Saturday. |
| CUP NIGHT | Kings Cup / Path of Honor — night blue, colder ink. |
| YOUR SHOW | your own tournament, warmer and brighter than anything else. |
| WORLDS | violet. Further from home. |
| THE FINAL | near-black with a red cast. The boss. |

Three rules make it work:

* **Only the ground and the ink move. `YOU` stays gold in every mood**, because
  it is how a player finds his own club on a table at a glance, and a highlight
  that changes color is one he has to re-learn five times.
* **It is keyed to the fight in front of you, not the calendar.** A mood that is
  on all season stops being a mood, so it is `cup_pending()` — one matchday at a
  time, a handful of times a year. The FINAL is checked before the competition,
  because a Worlds final is a final before it is a Worlds.
* **The fight wears it too, and that is where a boss battle lands.** A menu
  changing color is a theme; a *list* changing color is an occasion. The
  surround goes all the way to the mood, the fighting surface moves about a
  third, because a player reads a man's position against it fifty times a round.

Two bugs on the way. The banner went at the top first and was **invisible** —
`_header()` draws after it and owns that strip — so the ribbon moved to the
bottom band, the only strip on that screen belonging to nobody. And the melee
could not read `season.mood()` at all: the first thing that screen does when a
bout ends is post the result, which resolves the tie and sends the mood back to
NORMAL, so the report would have been drawn in a different palette from the fight
it was reporting on. `Session.bout_mood` is captured at handover.

### The check that earned itself immediately

Every palette is measured against the same luma rule `IconBank` already uses to
stop a club wearing a mark nobody can see — every text color against both the
ground and a panel, five moods. **It caught a mistyped hex on the first run:**
`"2c3away"` is not a color, and Godot's `Color(String)` accepts it without
complaint and returns black. Tightest pair across all five palettes is now 0.39.

### The audio engine, ported

ACRTW's `autoload/audio_director.gd` is 927 lines and genuinely good. What came
across, and why each piece was worth porting rather than reinventing:

* **The buses are created at RUN TIME**, not stored in a
  `default_bus_layout.tres`. A bus layout is a binary the editor owns while the
  names live in code; when they drift, every sound lands on Master with nobody's
  volume slider attached.
* **A catalog rather than paths at the call site** — each track carries its own
  volume, loop flag and fades, so balancing the mix is a diff of one dictionary.
* **A pool of twelve SFX players**, round-robin. Allocating per sound is how a UI
  tap stutters on a phone.
* **`play_music_or_stop`** — a missing track is not an error. This is the piece
  that matters most today, because there is not one audio file in this project
  and the whole system has to be silent and harmless until there is.
* **The WAV-versus-Ogg loop gotcha**, comment and all: `AudioStreamWAV` loops via
  the `loop_mode` ENUM, not the `loop` bool that Ogg uses. Setting `loop` on a
  WAV does nothing and reports nothing, so a track that should loop just stops,
  once, in the middle of a fight. Hard-won, and it would have been re-learned the
  expensive way.

**What had to change: ACRTW's director is an autoload Node**, and constraint 06.5
rules autoloads out. But audio genuinely needs to be in the tree. So this is a
static holder that owns one node and builds it lazily, parented to the **window**
rather than the current scene — so the music does not stop when the player walks
from the clubhouse into a fight. Same lifetime an autoload would have had,
without being one.

Also trimmed: ACRTW keeps **seven** catalogs (music, ambience, UI, combat, stone,
stingers, VO) each with its own near-identical play function. Right for a game
with a stone intro and voice acting; premature for one with no audio files at
all. One catalog with a `bus` on each entry does the same job in a fifth of the
lines, and splitting it later is a rename.

### One read, two systems

`UiKit.set_mood(m)` and `Audio.for_mood(m)` are called off the same value in the
same line. The room and the score cannot disagree about what occasion this is,
and that is the whole reason the audio was worth wiring the same afternoon as the
palette rather than later.

**The plan for the music is the same melody, differently arranged** — one tune
for the club, a heavier treatment for a cup night, the heaviest for the final.
That is how the 8-bit boss idea actually works: you recognise the tune and the
room has changed around it. `audio/README.md` is the brief;
`anthropic-skills:event-music` already does PD medieval tunes → MIDI → acoustic
and metal treatments → mastered OGG, which is exactly this shape.

### Suite

**127 of 127.** arena 16, melee 14, create 12, office 11, cup 11, career 8,
chalkboard 8, deck 8, league 8, market 8, cup seam 7, audio 5, C-6 5, save 5,
season 5.

The audio file prints a **stocktake** — *0 of 15 recorded* — because a catalog
that lists fifteen tracks and has none is a catalog that should say so out loud
every time the suite runs.

### Still open

- **15 audio files**, listed in `audio/README.md`.
- **The bracket itself.** The mood answers *what a cup feels like*; it does not
  answer *who is left in it*. The four mockups are in `shots/` and the tool that
  drew them is `tools/mock_bracket.gd` — the recommendation stands (the tree for
  eight-club cups, the "your road" panel grafted on, pools for Worlds), it is
  just no longer urgent.
- **The arena and field art**, still the last job by Pete's own instruction.

---

## 30 — The music (11 Sep 2026)

Four tracks written, mastered and in the game. Pete's brief: Retro Bowl's style
with medieval in it, escalating to *"iconic sounding boss music heavier with more
8-bit war drum and 8-bit metal"*, plus a champion celebration.

### What Retro Bowl's music actually is

**HeatleyBros' "8 Bit Joy" (2017) — 115 BPM, G major.** Not bespoke; a free-VGM
chiptune. Bright, major-key, perky NES.

So the idiom is clear, and the bend is **mode**. HeatleyBros is Ionian. Medieval
music is modal, and the one that reads as medieval to a modern ear is **D
Dorian** — minor with a raised sixth, the interval that makes a folk tune sound
like it is about a battle. Pulse and phrasing say arcade; the mode says 1350.

### Written, not sampled

Not a soundfont. The four voices of a 2A03 are synthesised directly, because
"8-bit war drums" and "8-bit metal" are techniques on specific channels rather
than textures a GM patch can approximate. Two pulse channels, a stepped
triangle, a held-random noise generator. A war drum is long-period noise plus a
pitch-dropped triangle thump — one without the other is a hiss or a click.

### Four passes of one bug, and the lesson is the measurement

Pete heard something wrong four times running and was right every time. The
history is worth keeping because the failure was not the bug, it was **measuring
the wrong quantity and believing it**.

1. *"Tailed off hard with just the drums in the middle."* A phrase is 16 beats.
   Each track laid two phrases into a **32-bar** song, so **75% of every loop was
   drums with nothing over them.** Nothing caught it because nothing was looking.
   Fixed by making an arrangement an explicit eight-slot FORM whose length is
   *derived* from the form rather than declared beside it.
2. *"Too chaotic, especially with that warble."* Vibrato was on by default for
   every lead note in every track, and the arpeggio rate was specified in beats
   so it drifted with tempo into 31-45 Hz — too fast for melody, too slow to
   fuse.
3. *"Way worse. A gun ray of sound into my ears. It even starts at 20 seconds
   into Cup Night."* That timing was diagnostic: cup's first arpeggio slot begins
   at **19.7 seconds**. The arpeggio was rebuilding the oscillator on every step,
   resetting phase 60 times a second — an impulse train with a full harmonic
   stack. Fixed with a continuous phase; off-harmonic energy fell 12,500×.
4. *"Still there."* And it was, because the technique itself was the problem.

### The finding that ended it

| | inharmonic energy |
|---|---|
| a held square, one note | 0.4 – 1.0 % |
| a sustained power chord | 0.1 – 0.6 % |
| **the same notes arpeggiated** | **37 – 55 %** |

Cycling three pitches at 48 Hz does not merely sound like a chord — it
frequency-modulates the oscillator at 48 Hz and throws sidebands either side of
every harmonic. **Fifty per cent inharmonic content is a ring modulator.**

A NES arpeggiates because it has five voices and physically cannot hold a chord.
This is written in Python with as many oscillators as it wants. **The technique
was never the requirement.** Root and fifth, held — same weight, same square
character, no modulation, and closer to what a power chord actually is.

### Three metrics that did not work, and why

This is the part worth remembering.

* **Energy above 5 kHz** says how BRIGHT a sound is. A square wave is
  legitimately bright — all of it sits on harmonics of the note.
* **Inharmonic energy across the mix** could not separate the cases: 8.0 %
  against 9.2 % on an identical bar, because a melody's note attacks smear the
  spectrum far more than the artefact does.
* **Inharmonic energy on the harmony channel** ranked **the clubhouse worst of
  the four** — the one track Pete never complained about — because a melodic line
  of short notes always reads as inharmonic and a sustained chord does not.

**A measurement that ranks the good case worst is not evidence**, and that should
have been the tell rather than something to trust. The check that works tests the
VOICES in isolation, where the margin is 150:1, plus a structural assertion that
no shipped arrangement calls `arp()` again.

Two more checks earned themselves immediately: `check_holes` (no run of
drums-only bars) and `check_no_harsh_section` (brightness per bar against the
track's own median), which caught a 12.5%-duty lead an octave up in cup's bar 17
on its first run. Both exclude the noise channel — a drum is supposed to be
broadband, and a check that fires on correct drumming is a check that gets
ignored.

### The final is its own song

Pete on the first version: *"literally just Cup Knight sped up."* Fair — same
phrases, same form, 24 BPM faster. **A boss should not sound like your own
theme**; it is the thing in front of you, not you.

So it is **D Phrygian** against the set's D Dorian. Same root, opposite
character: a flat second instead of a raised sixth. And a **riff** rather than a
melody — an eight-beat ostinato that hammers and never resolves, with i–♭II–♭VII
power chords that exist nowhere else in the set. Written outside the form system
on purpose: `lay_form` arranges a MELODY across slots, and forcing a riff piece
through it is exactly how you get a third arrangement of the club theme wearing a
different hat.

Measured: the themes share four pitch classes, and the boss has two the set never
otherwise uses.

### Where it stands

| | | |
|---|---|---|
| `club.ogg` | 118 BPM, D Dorian | −17.9 LUFS, 65.1 s, loops |
| `cup.ogg` | 146 BPM, D Dorian | −16.0 LUFS, 52.6 s, loops |
| `final.ogg` | 172 BPM, **D Phrygian** | −13.1 LUFS, 44.7 s, loops |
| `champion.ogg` | 152 BPM, D **major** | −13.5 LUFS, 28.9 s, one-shot |

Loudness climbs **5 LU** from clubhouse to final. Loops verified click-free at
the join — and a baked fade is *wrong* on a loop, because `Audio._begin()` already
tweens the entrance and a file fade would dip every time the loop came round.

**No screen is silent.** `Audio.FALLBACK` follows a chain until it finds a file
that exists: menu→club, fight→cup, hosted→cup, worlds→cup. Worlds is deliberately
NOT given `final` — the Phrygian theme is the boss, and lending it out leaves the
actual final nothing to escalate to. Worlds is the next track to write.

The **champion cue had nothing calling it**. It was written, mastered and shipped
and no code path played it, because `for_mood` cannot: winning is a moment, not
an occasion you sit in, and by the time the result posts the mood is back to
normal. `Audio.champion()` now fires when a cup is won.

### Suite

**133 of 133.** arena 16, melee 14, create 12, office 11, cup 11, career 8,
chalkboard 8, deck 8, league 8, market 8, cup seam 7, audio 6, C-6 5, save 5,
season 5.

---

## 31 — The set, finished and wired (11 Sep 2026)

Five music tracks, eight one-shots, thirteen of sixteen slots recorded, and every
one of them reachable from a real call site.

### Worlds is grand, not fast

The one design decision worth recording. Cup night is 146 BPM and driving; the
final is 172 and vicious. **Worlds is 138** — the slowest of the three big tracks
and the widest.

Escalating by tempo alone would have made it a halfway house between the other
two, which is the worst thing a climactic track can be. The boss got its own song
because a boss is the thing in front of you; Worlds is still YOUR club at the
biggest thing there is, so it keeps the melody and separates itself on a
different axis.

**The drone is what makes it sound far from home.** A sustained open fifth
running under the whole piece — D and A, never moving. It is the oldest device in
European folk music: every bagpipe, hurdy-gurdy and organum that predates
functional harmony by six hundred years. Nothing else in the set has one, and it
does more for *somewhere else, and old* than any amount of orchestration would.
The harmony still moves above it, which is the tension the piece runs on — a
chord that changes over a bass that will not.

### The one-shots

Built from the same four voices as the music, because a UI blip made with a
different synthesiser is a blip that sounds like it came from a different game.
Two rules carried down from the music — **no arpeggios anywhere**, and
**everything ends in a release**, because a one-shot that stops dead is a click
and a click on a button tap is heard a thousand times an hour. A third of their
own: a UI sound over about 120 ms starts to feel like the interface answering
back.

**They are peak-normalised, not loudness-normalised**, and that distinction
matters: `loudnorm` targets an integrated loudness *over time*, and a 35 ms blip
has almost no time. Run through the music chain it would have been dragged up
some 20 dB to hit a number meant for a piece of music, and a button tap would be
the loudest thing in the game.

### A sound nobody plays is a file, not a feature

The champion cue shipped with no code path calling it, and nothing noticed
because **a missing call sounds exactly like a missing file: silence.** So the
one-shots were wired at the same time as they were written, and a check now reads
the source to prove every catalog entry appears at a real call site.

* **Every button in the game ticks from one line** — `UiKit.button` connects the
  tap itself. Wiring it per call site would mean finding all of them, and then
  finding the one added next week; that is the "a rule enforced at one call site
  is a rule with a hole in it" this codebase has now said three times.
* **`UiKit.said(err)`** — every verb in this game returns `""` on success and a
  sentence on refusal, so one helper covers yes and no and no screen has to
  remember which sound means what. Seven call sites.
* **The melee takes its sounds off the sim's own signals** —
  `fighter_downed`, `marshal_called`, `action_resolved` — rather than polling, so
  each fires exactly as often as the thing actually happens. A man going down was
  the biggest event in the game and had no sound at all.

### The ladder, finished

| | | |
|---|---|---|
| `club` | 118 BPM, D Dorian | −17.9 LUFS, 65.1 s, loops |
| `cup` | 146 BPM, D Dorian | −16.0 LUFS, 52.6 s, loops |
| `worlds` | 138 BPM, D Dorian **+ drone** | −14.5 LUFS, 55.7 s, loops |
| `final` | 172 BPM, **D Phrygian riff** | −13.1 LUFS, 44.7 s, loops |
| `champion` | 152 BPM, D **major** | −13.5 LUFS, 28.9 s, one-shot |

Still to write: `menu`, `hosted`, `fight` — all three borrowing a neighbor, and
all three stop borrowing the moment their own file lands.

### Suite

**133 of 133.** arena 16, melee 14, create 12, office 11, cup 11, career 8,
chalkboard 8, deck 8, league 8, market 8, audio 7, cup seam 7, C-6 5, save 5,
season 5. (Recorded as 135 until section 34 re-added it.)

---

## 32 — Sixteen of sixteen (11 Sep 2026)

The last three tracks — `menu`, `hosted`, `fight` — and with them the audio set
is complete. Nothing borrows.

Each of the three exists because the slot it fills has a job the other tracks
cannot do, and that is the only reason to write an eighth version of the same
sixteen bars.

**`menu` — 100 BPM, −20.0 LUFS, the quietest thing in the game.** Deliberately
NOT the clubhouse loop. That one is in constant eighth-note motion, which is
right for a screen you work on and wrong for the first fifteen seconds of a game,
where the job is to set a tone and get out of the way. Long notes left long, and
**no drums at all for eight bars**. It carries a faint version of Worlds' drone:
a title screen and the biggest tournament there is are the two places worth
sounding *old* rather than merely medieval.

**`hosted` — 132 BPM, the brightest.** The one occasion in the game that is a
celebration rather than a test: you paid for it, it is your hall, and the people
in it came to see your club. 50% duty throughout where cup night thins to 25%,
and a harmony a **third** above rather than a fifth — the sweeter interval, and
the only place in the set it is used. No war drums anywhere near it.

**`fight` — and this one has a design constraint none of the others do: it plays
UNDER gameplay.** Everything else accompanies a screen you are reading; this
accompanies a fight you are watching and giving orders in, for three rounds of up
to two minutes. So it is written to be the *least* melodically prominent thing in
the set — the lead sits back, the rhythm carries it, phrases repeat without
ornament.

That is also what stops it from being cup night again, which was the trap the
final fell into. Measured on the channel RMS:

| | lead ÷ harmony |
|---|---|
| cup night | **3.01** — the tune in front |
| a bout | **1.07** — a groove with the tune behind it |

Same material, opposite balance. Tempo alone would not have done it, and the
final already proved that.

### The ladder, complete

| | | |
|---|---|---|
| `menu` | 100 BPM | −20.0 LUFS, 38.4 s |
| `club` | 118 | −17.9, 65.1 s |
| `fight` | 152 | −17.0, 50.5 s |
| `hosted` | 132 | −16.4, 58.2 s |
| `cup` | 146 | −16.0, 52.6 s |
| `worlds` | 138 | −14.5, 55.7 s |
| `final` | 172 | −13.1, 44.7 s |
| `champion` | 152 | −13.5, 28.9 s, one-shot |

**6.9 LU from the title screen to the boss**, monotonic through the occasion
ladder — and note that it is not monotonic in TEMPO, which is the whole argument
of the last three sections. Worlds is slower than a bout and twice as big;
`hosted` is slower than cup night and brighter. Loudness, density, register and
mode carry the escalation between them.

`Audio.FALLBACK` and `resolve()` stay. Nothing needs them today; they are what
keeps a mood added next year from being silent.

### Suite

**133 of 133.**


---

## 33 — Two questions worth the whole section (11 Sep 2026)

Pete, on the finished set: *"Why did you make menu slow again and why is world's so
close to menu?"* Both correct, and the second one is a repeat of a mistake this
register already records.

### The menu was a regression on a correction already given

He had told me once, plainly, that 112 BPM felt slow and that Retro Bowl is
upbeat. I measured it, agreed, and wrote it down: **115 BPM, G major, and what
makes it feel fast is note density.** Three tracks later I wrote the menu at
**100 BPM and 1.6 notes a second** — the slowest and sparsest thing in the set —
on my own reasoning that a title screen should set a tone and get out of the way.

That is a defensible idea about title screens in general. It is not what this
game's reference does: **Retro Bowl's title music IS "8 Bit Joy"**, and it is
perky. Nor is it what a title screen is for — it is the first thing anybody
hears and it is the game's calling card.

Now 124 BPM, 4.1 notes a second, busy from the first bar, full kit from the first
bar, and a two-beat pickup in front so it announces itself rather than arriving.
Loudness moved from −20.0 to −17.4: it sits with the light tracks instead of two
LU below all of them.

The lesson is not about tempo. **A preference the client has already stated
outranks my reasoning about the general case**, and if I think the general case
applies anyway, the thing to do is say so rather than quietly act on it.

### Two tracks shared the one signature in the set

Menu and Worlds were the only two with the **drone**, because I gave the menu "a
faint version of Worlds' drone" and wrote a justification for it in the same
breath. The drone is the most distinctive texture in the entire set — it is the
whole reason Worlds sounds like somewhere else and six hundred years ago.

Putting it in two places did not double its value, it halved it: the title screen
ended up wearing the fingerprint of the biggest tournament in the game, and
Worlds sounded like a slow menu.

**This is the same error as "the final is literally just Cup Night sped up"**,
which is in section 31 of this document. That one reused the MELODY where a
contrast was needed; this one reused a TEXTURE. Measured, it was visible before
he said anything:

| | bpm | notes/s | drums | drone |
|---|---|---|---|---|
| menu (old) | 100 | 1.6 | 0.005 | **yes** |
| worlds | 138 | 2.5 | 0.087 | **yes** |

Two tracks, one signature, and the sparsest and one of the densest — which is
exactly how a shared fingerprint hides in plain sight, because nothing about the
*numbers* says they will be confused.

The drone is Worlds' alone now, louder for it, and doubled an octave up.

### A rule worth keeping

**A signature belongs to one track.** If a texture is what makes a piece
identifiable, putting it anywhere else costs more than it gains — and the check
for it is not acoustic, it is a grep: which arrangements use this device, and is
the answer one?

### The ladder

| | | |
|---|---|---|
| `club` | 118 BPM | −17.9 LUFS |
| `menu` | 124 | −17.4 |
| `fight` | 152 | −17.0 |
| `hosted` | 132 | −16.4 |
| `cup` | 146 | −16.0 |
| `worlds` | 138 | −14.5 |
| `final` | 172 | −13.1 |
| `champion` | 152 | −13.5, one-shot |

**133 of 133.**

## 34 — Nobody wrote an A6 (12 Sep 2026)

Pete: *"Theres some high pitched parts in the menu song that cringe my ear."*

### The first measurement was wrong, and it was wrong in a way that looked fine

I reached for a spectrum and asked it for the **highest strong partial under
3 kHz**. It put menu and club within a few hertz of each other and explained
nothing, which should have been the tell straight away: a square wave's third
harmonic is louder than plenty of fundamentals, so that metric was reading the
*overtone* of a mid-register note and calling it the note.

Same failure as section 30, third instance now: **a metric that cannot separate
the good case from the known bad case is not evidence.** Club was the track
nobody had ever complained about and it scored the same as the one that hurt.

### Reading the score instead of the spectrum

The synth writes the notes, so the notes can be counted. Intercepting
`Song.lead` and tallying what each track actually asks for:

| track | highest notes written | above A5 (880 Hz) |
|---|---|---|
| `menu` | A6, A6, E6 | **34 of 291 — 12%** |
| `club` | B6, B6, F6 | 28 of 416 — 7% |
| `hosted` | B6, G♯6 | 32 of 365 — 9% |
| `cup` | C6, C6 | 8 of 188 — 4% |
| `worlds` | B6, E6 | 17 of 235 — 7% |

Menu had the highest share in the set and reached A6 repeatedly. There it is,
in one table, from the same data that had been sitting in the score the whole
time.

### Two reasonable decisions, multiplied

**Nobody wrote an A6.** The phrases top out around G5. What happened is that
`lay_form` built the counter-line from the *already-busied* phrase rather than
the original:

- `busy_shape=(0,2)` fills a held note with neighbor tones, some of them up.
- `counter={"semis":7}` harmonises a fifth above.

Applied in sequence, a G5 in the melody became B5 in the busy pass, and then
F♯6 in the harmony — and on the slots where both leaned upward, A6. Each
decision is defensible on its own. The bug is that one read the other's output.

Three fixes, in `tools/music/buhurt_music.py`:

1. **The counter reads `base_phrase`, not `phrase`.** Ornament and harmony are
   both derived from the melody; neither derives from the other.
2. **`CEILING = "C6"`, and `capped(note)` drops octaves until a note is under
   it** — applied to the lead and the counter both. A note that runs high gets
   moved, not refused, so the line keeps its shape.
3. **`check_register(name, fn, ceiling="C6", max_high_share=0.07)`** — reads the
   score by intercepting `Song.lead`, and fails the build on anything above the
   ceiling or more than 7% of notes above A5.

### What the fix caught that nobody had reported

```
menu    242 notes,  9 above A5 (4%),  0 above C6  ok
club    334 notes,  5 above A5 (1%),  0 above C6  ok
hosted  300 notes,  6 above A5 (2%),  0 above C6  ok
worlds  219 notes, 10 above A5 (5%),  0 above C6  ok
final   326 notes,  0 above A5 (0%),  0 above C6  ok
```

Club went 28 → 5 and hosted 32 → 6. The same compounding had been quietly
inflating **every** track that used a counter over a busied phrase; menu was
just the one that crossed the line into audible.

### The rule

**Derived passes derive from the source, not from each other.** Where two
transforms both act on one line, chain them off the original or the errors
multiply — and the result won't appear in either transform's own test, because
each one is behaving exactly as written.

And the sharper version of the older rule: **when a measurement ranks a track
nobody complained about the same as the track that hurts, the measurement is the
thing under test.** Count the thing you control — the score — before you go
measuring the thing you don't.

All eight re-rendered, re-mastered, ladder unchanged.

### Two things the suite run turned up on its own

**`test_melee.gd` takes 8m20s** — forty bouts a measure across thirteen
measures. The harness I ran it under capped each file at 300s, so melee was
killed mid-run and the suite carried on without printing a single word about it.
Fourteen checks vanished quietly and everything else was green. There is now a
`tools/run_tests.sh` with a 900s cap that reports `TIMED OUT` by name and exits
red, because **a harness that can silently drop a test is worse than no
harness.**

**The suite is 133 checks, not 135.** Section 30 had it right at 133. Between
30 and 32 the audio file went from 6 checks to 7 — and the total went from 133
to **135**. One check was added and two were claimed. Sections 32 and 33 then
copied the figure forward without re-adding the list sitting directly beneath
it, which is the house rule wearing its smallest possible hat: *a number
written down goes stale; derive it at run time.* `run_tests.sh` now counts
files and reports what it ran, rather than a document reporting what it
remembers.

### Suite

**133 of 133.** arena 16, melee 14, create 12, office 11, cup 11, career 8,
chalkboard 8, deck 8, league 8, market 8, audio 7, cup seam 7, C-6 5, save 5,
season 5.

Plus 26 music checks in `buhurt_music.py`: voices clean, no arpeggios, and
register / holes / brightness on each of the eight.

---

## 35 — Three tracks, one arrangement (12 Sep 2026)

Pete: *"Menu and club are the same again."*

Right, and **worse than he said.** Measured across all eight pairs rather than
the one he named:

| | menu | club | hosted |
|---|---|---|---|
| **menu** | · | **0.92** | **0.97** |
| **club** | 0.92 | · | **0.90** |

Menu and hosted had **identical drum grids, identical duty distributions,
identical bouncing bass and a 0.99 melodic contour match**, six BPM apart. Menu
and club, 0.92. It was not a pair, it was a **cluster of three** — the same
arrangement at 118, 124 and 132, wearing three different names.

### How three tracks converged without anyone deciding to

There was only ever one way to write a bright track in this file: `busy_shape`
for a lead that never stops moving, `bass_bounce` under it, 50% duty, full kit.
That combination is the clubhouse's design, it is a good design, and **every
track that needed to sound cheerful was therefore written the same way.**

The menu got there by being *fixed*. Section 33 removed its drone — correctly,
the drone is Worlds' — and replaced it with tempo and density. But density over
a bouncing bass **is** the clubhouse. I took away the one thing that made the
menu distinct and gave it back the one thing every bright track already had.

**This is the third instance:** the final was cup night sped up (§31), the menu
borrowed Worlds' drone (§33), and now three tracks share one arrangement. Every
time, Pete heard it. Every time, no check saw it — because every check in this
file looks at **one track**, and this failure only exists **between** tracks.

### The fix is three signatures, not three tempos

Each of the three now has a device no other track uses:

**`menu` — the tune stated, not run.** Plain phrase, staccato, ~2.1 notes a
second where club runs at 3.9. Octave-**doubled** rather than harmonised, so it
is heavy without being bright. The bass **walks** root-fifth-octave-fifth where
club bounces. **Call and response** — a three-note answering figure in the
melody's own sustains, the only melodic material in the set belonging to one
track. A **march** kit: backbeat snare, hats on quarters. A title theme has to
be singable after ten seconds; the clubhouse never does.

**`hosted` — it swings.** Nothing else here does. Applied on the *clock*, not in
the writing, so the tune, bass and kit all lean together. Plus **handclaps** —
two snares a sixteenth apart on the backbeat, because a room full of people does
not clap in unison. It keeps its third-above harmony.

**`club` — it gives ground.** 25% duty where menu is 50%, and the sparsest kit
in the set: no snare on two, no fills, hats on quarters. Its job is to be
*ignored* for minutes while somebody reads a team sheet, and **constant motion
and constant prominence are different things** — only the first is in its job
description.

| | before | after |
|---|---|---|
| menu / club | 0.92 | **0.65** |
| menu / hosted | 0.97 | **0.73** |
| club / hosted | 0.90 | **0.74** |

### The gate, and why it has a control bolted to it

`check_no_two_tracks_are_twins()` reads the score of all eight, scores every
pair on ten dimensions — melodic contour, drum grid, duty, density, bass
treatment, lead-to-harmony balance, sustain, mode, tempo, swing — and fails the
build above **0.88**.

That number is **calibrated, not chosen**. The check renders the clubhouse at a
different tempo and nothing else — *the literal failure mode* — and that scores
**0.95**. The real set tops out at 0.81. The gate sits in the gap.

And it asserts **both ends every run**: if the manufactured twin ever stops
scoring above the gate, the metric has gone blind and the check says so instead
of going green. That is section 34's lesson made mechanical — *a measurement
that cannot separate the good case from the known bad case is not evidence* — so
the measurement now proves it still can, every time.

Two dimensions went in specifically because the first version flagged pairs that
are fine: **lead-to-harmony balance** (cup 3.01, fight 1.07 — the documented
reason a bout is not cup night) and **sustain share**. Without those the metric
could not see the difference the design was already relying on.

### The rule

**A check that looks at one artifact cannot catch a similarity between two.**
Every check in this file was per-track, and every per-track check was green
through all three instances of this failure. The register had the rule written
down since §33 — *a signature belongs to one track* — and a rule in a document
is not a gate.

Closest legitimate pair is now **fight / cup at 0.83**, which is deliberate:
same material, opposite balance.

### The ladder

| | | |
|---|---|---|
| `club` | 118 BPM | −18.0 LUFS |
| `menu` | 124 | −17.5 |
| `fight` | 152 | −17.1 |
| `hosted` | 132 (swung) | −16.5 |
| `cup` | 146 | −16.0 |
| `worlds` | 138 | −14.5 |
| `final` | 172 | −13.1 |
| `champion` | 152 | −13.7, one-shot |

**133 of 133**, plus 27 music checks — the twin gate is the new one, and it is
the first that reads more than one track at a time.

---

## 36 — A licensed front door, and the set that had to meet it (11 Sep 2026)

Pete picked **HeatleyBros' "Game On"** (HeatleyBros IV, track 19) for the title
screen. It is in, the rest of the set moved to meet it, and the interesting part
of this section is the two things that are now *structurally* true rather than
remembered.

### I gave him the wrong objection first

My argument against HeatleyBros was that they are Retro Bowl's composer, so
using them makes this game derivative. **That was weak and I should not have led
with it.** They have hundreds of tracks; using *Game On* is not using *8 Bit
Joy*, and a game deliberately built in that mould sharing the idiom is arguably
the point.

Reading the actual licence produced the real objection, which is not about taste:

> "…a limited, non-exclusive, non-transferable, non-sublicensable, **revocable**
> license" (§1)
> "The Owner may **terminate this License at any time, with or without cause**."
> (§8)
> "Upon termination, all rights granted under this License immediately cease."

**There is no clause covering a game already released.** CC0 and CC-BY 4.0 are
both irrevocable; this is not. The lesson is the cheap one: *read the licence,
not the summary*. The plain-English "free for commercial use with credit" page
is accurate and omits the only sentence that matters.

### Two obligations, both made mechanical

A licence condition that lives in somebody's memory is a condition that ships
broken. Both are now assertions.

**It can be pulled.** `FALLBACK` runs `menu -> menu_own -> club`, and
`menu_own.ogg` is ours. Delete `menu.ogg` and `resolve()` walks to the
synthesised menu — no code change, no other file touched. Verified the only way
worth verifying: by actually deleting the file and re-running.

```
--- with Game On present ---     resolve('menu') -> 'menu'       17 of 17
--- menu.ogg deleted ---         resolve('menu') -> 'menu_own'   16 of 17
--- restored ---                 resolve('menu') -> 'menu'       17 of 17
```

`test_audio.gd` now asserts every entry in `LICENSED` has an owned fallback whose
file exists. **Untested insurance is not insurance.**

**It must be credited.** Failure to attribute is "a material breach", so the
credits screen is **generated from `Audio.LICENSED`** — the same dictionary the
fallback walks — rather than typed into the scene where it could quietly go
stale. A track cannot be in the game without being in the credits, and a test
asserts the loop closes.

That is the general rule worth keeping: **where a legal obligation maps onto
data the code already has, generate the obligation from the data.** A credits
list typed by hand is a second source of truth, and second sources of truth
drift.

### The settings screen exists now

There wasn't one. `Audio.set_volume` had been tested since section 29 and had no
UI at all — volume the suite could set and the player could not. Now: three
buses, eight notches each (countable at a glance, which a continuous bar is
not), persisted to `user://settings.cfg` through a static holder over
`ConfigFile`, because a volume that resets every launch is not a setting.

### What "fits alongside" may and may not mean

Their licence forbids using the music to "train, fine-tune, validate, test, or
improve any artificial intelligence, machine learning, neural network,
algorithmic, or generative system." So the line, drawn explicitly:

- **Used:** root **D**, tempo **129.2 BPM**, target **−17.55 LUFS** — the three
  production facts already measured in order to master the file into the mix,
  and already written into `CREDITS.md`. Tuning two instruments to the same
  pitch is not derivation.
- **Not used:** its melody, its harmony, its riffs, its arrangement. Nothing was
  transcribed and nothing was matched to its spectrum.

The luck is that the set was **already in D**. So the gap was never the root —
it was the *third*. Game On carries an F♯; D Dorian has an F natural.

### Musica ficta, which is a fourteenth-century answer to a 2026 problem

The bridge is not a compromise mode. It is the rule medieval singers actually
applied: **F is raised to F♯ when the line steps up into G**, because the half
step pulls into the note it is heading for. Descending, it stays flat. It is a
rule about *motion*, not a scale degree, which is exactly why it is written as a
pass over the phrase rather than into the mode:

```python
def ficta(phrase):   # only F->G, only ascending, only when adjacent in time
```

It fires twice per phrase — `PHRASE_A` at beat 8, `PHRASE_B` at beat 3. Applied
throughout the menu (which stands in for a licensed track, so it carries the
color) and at the **first and last slot only** of club, hosted, cup and worlds —
a cadential touch, not a wash.

It has to run **before** the busy pass and before the counter, or the harmony
keeps an F natural against a sharpened melody, which is a semitone clash rather
than a harmony. That is the same ordering bug as section 34, seen coming this
time.

Measured after: F♯ sits at **6.8–8.1%** across the set against F natural at
8.3–11.3%. Dorian still, with a little major light at the cadences — and the
front door and the clubhouse no longer sound like two games. Honest scale: this
is a subtle touch, two notes a phrase, not a transformation.

The menu also moved **124 → 129.2 BPM**, so the fallback is a true drop-in
rather than a track at a different tempo.

### The gate held through all of it

`check_no_two_tracks_are_twins` still reports **worst pair fight/cup 0.83**
against a 0.88 gate, control twin 0.95. Adding a shared color to five
arrangements is exactly the change that could have collapsed them together, and
the check that would catch it was already there — which is the first time in
this document that has been true in advance rather than after Pete said
something.

### The ladder, unmoved

| | | |
|---|---|---|
| `club` | 118 | −18.0 |
| `menu` | **129.2 (Game On, licensed)** | −17.6 |
| `menu_own` | 129.2 | −17.5 |
| `fight` | 152 | −17.1 |
| `hosted` | 132 swung | −16.5 |
| `cup` | 146 | −16.0 |
| `worlds` | 138 | −14.5 |
| `final` | 172 | −13.1 |
| `champion` | 152 | −13.7 |

**Rig holds, 9 checks.** Nine music slots, 17 of 17 recorded.

### Still open

- **A credits screen exists; the ship blocker is not fully closed** until the
  game can actually be reached through it on a device. The text is correct and
  generated; the obligation is satisfied only when a player can see it.
- The cup bracket, and the arena art.

---

## 37 — The draw (11 Sep 2026)

**The oldest open item in this document, closed.** It first appears in section
22 — *"the cup screen shows the tie but not the bracket"* — and was carried,
unchanged, through sections 27, 28, 31 and 36. Five deferrals.

The hole was specific: the game could always tell you **who you were fighting**
and never **who else was left**. That is the one thing a cup has that a league
does not, and it was the thing the screen hid.

### What got built

Pete picked the tree with the road panel grafted on, and pools for Worlds — the
recommendation that had been standing since the four mockups were rendered in
section 22.

* **The tree**, left, three-quarters of the screen. Full club names, seeds, and
  the score of any tie that has been fought, with a green bar on the winner.
  Retro Bowl's own bracket carries the shape by column position alone — no
  scores, no seeds, no connecting lines — because it is 480×270 with
  three-letter abbreviations. We have twice the resolution and one bracket
  instead of two conferences, so most of what they left out we can afford.
* **The road**, right, a narrow column. Your next opponent, how far you have
  got, and the champion when there is one. A tree answers *who is left*; it does
  not answer *who do I fight next*, which is the question the player actually
  arrived with. Having both on one screen is the entire reason this variant beat
  either alone.
* **Pools**, for Worlds. Sixteen clubs is the one shape a tree cannot hold at
  this size, so the group stage gets a **mode** rather than a layout.

### Three bugs, and all three were only visible once it was rendered

**The bracket had one column.** `cup.rounds` only grows as the cup advances, so
deriving the column count from it drew a single row of quarter-finals on the
first night — *a fixture list, not a draw*. The shape of a tournament is known
the moment the field is seeded; only the results arrive later. Columns now come
from the entrant count, and rounds not yet drawn get empty slots — which is also
the answer to "who might I meet".

**`row["margin"]` did not exist.** The league table keeps margin as for and
against, `mf` and `ma`. Asking a Dictionary for a key it does not have returns a
default silently, so every club in every pool showed a margin of exactly zero and
the screen looked *fine*. Same family as the mistyped hex in section 29:
a wrong answer that is well-formed enough not to raise anything.

**Losing in the quarter-finals printed OUT three times** — against the
semi-final and the final as well, which reads as being knocked out of rounds you
were never in. One "OUT", with the score, in the round you actually lost;
everything after it is a dash.

### The mockup had a club on minus one win

`tools/mock_bracket.gd` filled its pool tables with `2 - i`, so the fourth row of
every pool read **W = −1**. It sat in a shipped screenshot through five sections
of this register and neither of us caught it — I only found it by looking at the
image again while deciding what to build.

**Nobody adds up a mockup.** That is the hazard of settling a layout from a
picture: the picture is judged on whether it *reads*, and "−1" reads as a number.
The real screen takes its rows from `cup.pool_table()`, and `test_cup.gd` now
asserts the arithmetic it is reading — played equals won plus drawn plus lost,
nothing negative, every club in a pool exactly once. **16 rows across 4 pools,
every one reconciled.**

The general rule, which this project keeps re-learning in new clothes: **a mockup
is evidence about layout and nothing else.** Its data is set dressing, and set
dressing has no reason to be consistent unless something checks it.

### It wears the occasion

`UiKit.set_mood()` and `Audio.for_mood()` on entry, like every other screen, so a
Worlds bracket and a backyard invitational do not look or sound the same. That
came free — which is what the mood system was for.

### Suite

**136 of 136**, counted by `run_tests.sh` rather than by me — which is the point
of section 34's correction, and it caught me again: I wrote "134" from memory
and the runner said 136. Three checks went in this session, not one —
`licensed music can be pulled`, `every licensed track is credited`, and
`pool rows add up`.

arena 16, melee 14, create 12, cup 12, office 11, audio 9, career 8,
chalkboard 8, deck 8, league 8, market 8, cup seam 7, C-6 5, save 5, season 5.

### Still open

- **The arena and field art**, now genuinely the last thing, by Pete's own
  instruction from the beginning: *"The arena/field will be the art/animation at
  the end of this all."*
- The credits screen wants confirming on a device.

---

## 38 — The socket, not the picture (11 Sep 2026)

The last job, and it is not drawing anything. Pete, 10 Sep 2026: *"Let's not use
your art for any of this, just placeholders. I'll get ChatGPT to do that work."*

So the work is the **handoff**: every slot the game will ever load, at a real
path and a real size, with a fallback already on screen and a brief somebody
else can act on. `docs/ART.md` was referenced in `arena_scene.gd` from the day
the arena slot was built and **had never been written** — a pointer to a file
that did not exist, which is the quietest kind of broken.

### One table instead of six loaders

The arena had grown a private texture cache and a private path-builder. The
fight screen wanting art would have grown a second pair, and the two would have
disagreed about something within a fortnight — the same shape as the heraldry
that was once drawn by two slightly different `match` statements and put a club
in one mark on the table and another on the surcoat.

`ArtBank` is one table. A slot is a dictionary entry; `draw_slot()` returns
false and the caller draws its primitives. Adding art to a screen is one line
and an `if`.

### The thing that was easy to get wrong

The fight screen changes color with the occasion, and it does that by
**multiplying** the fighting surface by a mood color. Hand that a brown texture
and you get mud.

So `list_surface` and `list_ground` are specified **grayscale, mid-value** —
texture only, no color of their own, color supplied by the game. The arena
slots are full color because nothing tints them. That distinction is invisible
in the code and would have cost somebody two renders to discover, which is
exactly the kind of thing a brief exists to say out loud.

The other three rules in `ART.md` are there for the same reason: **no text**
(the game draws all of it, in its own font, and baked words are wrong in every
language and stale the day a name changes), **no logos** (the player picks their
mark out of the icon bank and the game draws it on top), and **nothing important
in the bottom-right** of an arena (the badge lives there).

### What is deliberately not art, and why that is written down

The fighters are not a placeholder waiting for sprites. Men are drawn as
silhouettes carrying their club's kit color and mark, and that **is** the answer
to the problem the whole art direction exists to solve — two armored clubs are
two gray blobs, and a four-man pile on a phone is only readable because the
color and the mark are generated per club. A fixed sprite cannot carry a color
the player invented.

Writing that into the brief matters more than it looks. Somebody handed "a
medieval fighting game needs art" will draw fighters, and they would be
beautiful and unusable. If sprites ever happen they need to be **colorable
masks**, not finished figures — a different and much larger job.

### The spec cannot drift from the code

`test_arena.gd` now reads `docs/ART.md` and asserts that every slot in
`ArtBank.SLOTS` appears in it at its real path and its real size.

That is the third instance of one pattern this week — the credits screen
generated from `Audio.LICENSED`, the fallback chain asserted against the same
dictionary, and now the art brief checked against the slot table. **Where a
document restates data the code already holds, assert the restatement.** It
matters more here than in either of the others, because this spec is an
instruction to a third party: a wrong path costs somebody a render rather than a
compile, and they have no way to find out it was wrong.

The suite also prints an art stocktake, the way the audio catalog does:

```
art: 0 of 8 slots filled — waiting on arena_0 … list_ground
```

Zero of eight, and the game is complete. That is the point of a slot.

### Suite

**137 of 137.** The new one is `the art spec matches the code`.

### Still open

- **The artwork itself**, which is Pete's to commission. Eight slots, all
  specified, all with prompts in `docs/ART.md`.
- The credits screen wants confirming on a device.

## 39 — The audit (11 Sep 2026)

Pete: *"let's go through it and a nice audit. We also need a start menu as
well."* Three readers went through the logic, the screens and the tests
independently. **Twenty-six findings, and the worst of them make the game's
numbers meaningless.** Everything below is fixed.

### The three that mattered most

**The demo button printed money.** `run_demo()` never set `booked`, and the
button's only guard was `booked == null` — so it came back on every rebuild of
the screen. Forty taps on a Backyard club is forty credits: both facilities, two
captains, the arena and four cap raises, in one sitting, from a button meant to
pay **one** credit for an empty week. Every price in the game was a suggestion.

It goes through the same per-week throttle as an upgrade now, rather than
getting a flag of its own — a second throttle is a second thing to forget to
reset.

**A hosted tournament was permanently broken by any reload.** The save stored
the booked event and stored the cup, and did not store the pointer between them.
`_finish_cup_round` asks `booked.cup == c` to decide whether a finished bracket
is your show; after a load the answer was always no. The gate was never paid,
`settled` stayed false, `_event_due()` was true on every later matchday, and the
same Invitational was drawn again every week — you fought your own tournament
forever, were never paid, and never got another bid.

The comment above it said the cup was deliberately not saved *because it is
deterministic*, which was true and beside the point: **nothing rebuilt it
either.** Save VERSION 8 stores the cup's id and `_relink_event` hangs it back
on. The show cup was also the only cup in the world with no id — every other one
gets one from `league_world.gd`.

**Four of every seven injuries cost nothing.** `_apply_injuries` wrote the knock
and `_after_event` then decremented **every** injury on the roster — including
the one just written. `INJURY_LENGTH` is `[1,1,1,1,2,2,3]`, so four of seven
knocks were gone before the screen redrew, and at `injury_relief() == 2` the
floor of 1 was decremented to 0 as well: **no knock ever kept anybody out**,
while the Clubhouse went on advertising "−2 events off a knock". The post-bout
report said a man was hurt and the squad screen showed him fit. A cup tie took
the same knock and cost a week, because that path does not tick the week — so
the identical injury was free in the league and expensive in a cup.

Injuries are applied after the tick now, and both paths call one function
instead of two copies of the rule.

### The one I had already written the lesson for

**Retirement rolls, contract patience and walk-on generation all drew from
`world.rng`** — the stream every fixture, cup draw and quick bout comes out of.
The *number* of draws depends on how many men are on your books, so cutting one
reserve in March moved every other club's rating drift and every cup draw for
the rest of the save.

That is the dilemma-deck bug, in a second place, with section 28's account of it
sitting in this document. They have their own stream now, re-derived each season.

### Three more that made a feature a lie

- **The prefight formation panel was a dead control.** `Season.begin_bout`
  always calls `set_plan(0, …)` with the shape from the Chalkboard, and
  `formation_spots` prefers `custom_spots` — so whatever the player tapped was
  discarded every time, and the HUD then printed the name of the shape the men
  were **not** standing in. The panel now only asks when the answer can be used,
  and the HUD names what you are actually in.
- **Third place did not exist** in any cup anybody fought through. `advance()`
  created the match; only `run_all()` ever played it, and the interactive path
  does not go through `run_all`. The 1 CC bronze was unreachable and every
  played bracket finished with an unplayed match in it.
- **Losing the Worlds pools left you "alive" forever.** `player_alive()` reads
  the bracket, and a club that failed to qualify has no match in it — so the
  Worlds was never resolved, never entered the honors, and `roll_over` replaced
  it each summer while fourteen guest clubs stayed on the books, accumulating.

### The training ground was burning most of its points

The share was handed out round-robin with no regard for headroom, and computed
*before* anybody aged. Training 5 advertises fifteen points a winter; three
eligible men each one point under potential were allotted five each, spent
three, and **twelve vanished** while the report said "gained 3". Points are
capped by headroom now, men about to decline are included because the decline
opens the room, and whatever the ground fails to spend goes round again.

### The start menu

The game booted straight into three save slots — a **file picker**. The first
thing anybody saw was an administrative question.

There is a front door now: the name, the two badges, Play / Settings / Quit, and
the credit the HeatleyBros licence asks for sitting on the screen its music is
playing on. Quit is hidden on mobile, where a Quit button reads as a bug and its
absence does not.

The delete confirm was also fixed while I was there. It turned "Delete" into
"Sure?" **in the same rectangle**, so a double-tap destroyed a career — the
exact failure the two-step was added to prevent. The destructive half now moves,
and brings a "Keep it" with it.

### Layout, three of them invisible until rendered

- The post-fight report panel was still **500 × 690** — the portrait rectangle
  from before 13.1, left behind when every screen was re-laid out. On a 540-tall
  screen it ran 250px off the bottom and stopped at x=520, so the right half of
  every report sat on bare ground. Derived from the label it is behind now.
- **The five position lanes were drawn across the charge axis.** They run Rail
  to Rail, which after the quarter-turn is the screen's *height*; they were at
  fractions of the width, so four lines cut the charge into fifths and read as
  extra marshal marks. The one marking that tells you where the five positions
  are was on the wrong axis.
- At National the table runs to sixteen clubs and row 16 sits at y=477–497. The
  cup button was at y=476 and hid the rank and name of a club **in a relegation
  place**.

### And the bracket I shipped this morning

Two bugs, both mine, both the failure this register already names.

**The tree and the road panel worked out the bracket's shape separately** — the
tree read the qualifiers, the road read the entrants — so in a Worlds the
player's quarter-final printed under ROUND OF 16 and the FINAL row said "not
there yet" after he had won it. Two halves of one screen contradicting each
other, in the section that says *a rule applied at two call sites is a rule with
a hole in it*. One function now, called by both.

**And the draw was unreachable the moment it got interesting.** The button lived
inside the cup-tie branch, so being knocked out took the bracket away — and the
CHAMPION line I wrote was code no player could reach. Same family as the
champion music cue nothing played, from section 31. I wrote a comment in
`session.gd` describing a capability that had no caller.

### The suite was counting itself wrong

**Six of fifteen files printed a total that did not match what they ran.** Arena
claimed 17 and ran 20; the cup seam claimed 7 and ran 9; melee claimed 14 and
ran 13. The headline had been hand-maintained all along, which is how it was
133 and then 135 and then 136 without anybody adding up.

Every file counts its own checks now, in `_ok`, and prints the counter. **A
number that says how much was verified is the last number that should be
maintained by remembering.**

Three assertions were also not capable of failing:

- **Pace** allowed 25 s to `ROUND_TIME` — and the sim ends every round at
  `ROUND_TIME`, so the upper bound was the engine's own ceiling. Tripling the
  round length passed. Banded on the measured figure now.
- **"The cost must climb"**, in two files, was written `costs[i] < costs[i-1]`,
  which passes a flat schedule. A rung that costs what the last one cost is not
  a ladder.

### The biggest hole: `quick_bout` had no test

It resolves **fourteen of every fifteen fixtures** and everything the league
believes about who is good comes out of it. The only thing behind it was the
climb tests — downstream, slow, and one of them a single seed — and its own
comment records that the Elo sign was once inverted.

**The first version of the new check asked the wrong question.** It measured
80 v 45, expected "decisive but not certain", and got 99.2% — which is correct.
`RATING_SCALE` is 22, so 35 points is four Elo doublings and a foregone
conclusion. But **80 v 45 is not a league fixture.** Divisions are 16 to 22
points wide, so the widest mismatch a table can produce is about a band, and
that is the number a season is actually made of.

Measured properly: even sides 51.5%, the full width of the Backyard band 91.0%,
a gap no division allows 98.8%, and margins widen with the gap. The check pins
the direction, so an inverted sign screams immediately instead of surfacing
thirty seasons later.

Same lesson as sections 30 and 34, now in a test I wrote myself: **the metric
was fine and the question was wrong.**

---

### Suite

**146 of 146**, and this is the first total in this document that was counted by
the code rather than by me. It went up from 136 because six files had been
under-reporting what they already ran, not because thirty checks were written.

arena 20, constraints 13, create 13, cups 12, chalkboard 11, clubhouse 11,
pyramid 9, cup seam 9, rig 9, career 8, deck 8, market 8, C-6 5, save 5,
season 5.

Melee now honestly says 13 where it claimed 14.

### Still open

- **The artwork**, eight specified slots, Pete's to commission.
- **The credits screen wants confirming on a device.**
- Four of the audit's smaller findings are deliberately left: the `play_index`
  reshuffle on deleting a play, `MeleeSim.swap_in` having no caller, the three
  different orderings of `blocked_by`, and the opponent's AI tier never being
  shown. None of them produces a wrong number; all of them are worth a pass.

---

## 40 — The roster, and the book (11 Sep 2026)

Pete, with eleven Retro Bowl screenshots: *"let's build rosters and fighters."*

### The layout is the sport, not the reference

Retro Bowl puts ten cards in a flat 2×5 grid and lets a position badge carry the
meaning. That is right for football, where the five men on a line are not
standing in a *meaningful* left-to-right order.

**In buhurt they are.** Rail, Flanker, Center, Flanker, Rail is a real
arrangement on a real line, and a roster screen that scrambles it throws away
the one piece of information the player is about to make a decision with. So the
five on the line run across the top in the order they stand, and the three on
the bench and five in reserve sit underneath, smaller, because that is exactly
how much they matter today.

Copying the reference exactly would have been easier and would have been wrong.

### The book did not exist

`_award_xp` has always read two numbers off every man after every bout — downs
caused and rounds finished standing, because that is what XP is paid on — and
then **thrown both away**. So a fighter had a level and no record: no way to know
whether the man on your Center had put three hundred people down or had four
quiet years.

They were already being counted. Writing them down costs nothing, and it is the
difference between a level and a career:

| | |
|---|---|
| `bouts` | events he turned up to, simmed ones included |
| `downs` | men he has put down |
| `best_downs` | the best single afternoon — a total says what he has done, a peak says what he is capable of |
| `rounds_standing` | rounds he finished on his feet |
| `knocks` | times he has been carried off |
| `honors` | cups won while on the eight — **the eight, not the five who were on the line for the final**, because a cup is won by an eight |

Save VERSION 9. Defaulted to zero on read rather than refused, unlike the career
fields in version 5: a version 8 squad with no record is a squad whose book has
simply not been kept yet, and zero is a true answer to that.

### Three things the screen tried to tell the player that were not so

All three were invisible until it was rendered, which is now the fifth time this
document has said that.

**The club badge on every card.** The first version of the fighter card put the
club's mark in the head band — the same badge, thirteen times, telling the
player something he already knew. There is no fighter art and there is not going
to be; the men are silhouettes carrying a kit color, which is the art
direction. **His number** goes there instead: the thing that actually identifies
one man at a glance, and the thing written on him in the fight.

**The XP bar was four times over-full.** It drew `xp / xp_cost(0)` and printed
*"34 / 8 xp"* — because `xp_cost` is the price of the NEXT point and it climbs
with each one taken, so banked XP buys several. It now walks the ladder the way
`Career.winter` does and reports the two facts the winter will act on: **2 points
ready**, and 14 of the 18 toward the one after.

**The ceiling tick was a picture of a rule the game does not have.** Each of the
four attribute bars carried a green tick at `potential`, which says a man has a
ceiling per stat. He does not — `potential` is a ceiling on his *overall*, and
the winter spends points wherever they do the most good. Four identical ticks
claiming four separate limits is worse than no tick at all, because it is
specific.

### The checks

A new file, and the second one is the interesting one.

- **Every man has exactly one card.** The screen builds its cards and its hit
  boxes off one list; this asserts that list and the club agree about who is on
  the books.
- **No card overlaps another.** Buttons are built at absolute positions, so two
  landing on each other is silent — the audit found a cup button sitting on the
  sixteenth row of a National table, hiding a club in a relegation place. Cards
  are drawn *and* tapped, so an overlap means a tap opens the wrong man. Thirteen
  rects, checked against each other, against the screen, and against the footer.
- **The book records what the sim counted** — and accurately, not merely
  non-zero: every man's counters must equal what that bout actually saw.
- **The book survives a save.**
- **Stars are monotonic.** A better rating can never draw fewer stars.

`_ready` is deferred to the first frame and a headless test never gets one, so
the test hands the season to the node directly and calls the real `_slots()`.

### Suite

**151 of 151**, sixteen files. Five of the new ones are the roster's.

### Still open

- **The artwork.** Eight specified slots in `docs/ART.md`, Pete's to commission.
- **The credits screen wants confirming on a device.**
- The four smaller audit findings from section 39.

---

## 41 — The regime, read rather than invented (11 Sep 2026)

Nine more Retro Bowl screenshots, and one instruction that changed how the
biggest piece of this section got built. I offered Pete four guesses at what the
Training Regime should trade. He answered: **"Look up how Retro Bowl uses
Training Regime."**

He was right to. The field had existed in `ClubOffice` for days as three words on
a screen — drawn, never settable, read by nothing — and I was about to invent a
mechanic for it when the real one was sitting on disk. Their web build is a
GameMaker HTML5 export and the scratchpad still had it from the bracket work in
section 29.

### What it actually does, out of the build

`s_training_regime_effect_on_morale`, `s_get_training_reg`, and the XP and
condition paths. `training_reg_of` / `training_reg_df`, default 2. **Four
effects at once**, which is why it is a decision and not a slider:

| | XP | morale a week | condition | injury odds |
|---|---|---|---|---|
| Light | **×0.6** | +0 to +2 | +10 on a big rest | **10%** of base |
| Normal | ×1.0 | — | — | 20% of base |
| Hard | **×1.5** | −1 to −3 | −10 on a big rest | **100%** of base |

The injury column is the one that bites, and it is the one I would never have
guessed: **Hard is not fifty per cent riskier than Normal, it is five times.**
Their code does it as early returns — `if reg==1 && irandom(9) return false`
lets one knock in ten through, `reg==2 && irandom(4)` lets one in five through,
and Hard has no early return at all. Development is bought with bodies.

My own four options had "training points against wear" as the recommendation,
which is the right *shape* and has none of the right numbers, and would have
missed the asymmetry entirely. **The reference existed; guessing at it was the
error, not the answer I guessed.**

(A GameMaker curiosity worth noting: in the morale switch, Light has no `break`
and falls through into Normal's. The net effect is what the table says, but it
reads as a bug until you follow it.)

### What changes in translation

Retro Bowl splits the regime by side of the ball because its staff are an
offensive and a defensive coordinator. **Ours are captains, and a captain covers
ROLES rather than a side** — so the regime is per captain and applies to the
roles he teaches. A role nobody teaches is trained nobody's way, which is Normal:
the man is turning up and doing what he has always done.

All four effects are wired to paths that already existed — `_award_xp` for the
multiplier, the week tick for morale and armor, and a gate in front of
`_apply_bout_injuries` for the knocks. That gate rolls on **its own stream**,
because an injury that consumed the world's RNG would make a squad decision
reshuffle the country, which is a bug this project has now fixed twice.

### One card, three screens

The roster grew a fighter card yesterday. The market and the staff room both
needed the same card today, and were about to grow their own copies — which is
precisely how the heraldry once ended up drawn by two slightly different `match`
statements and put a club in one mark on the table and another on the surcoat.

`UiKit.card` now, with a dictionary of facts. Three callers.

### Three screens

**The staff room.** Two captains as cards, what each teaches, and the regime as
three real buttons under the man it applies to — Retro Bowl puts them under the
coordinator for the same reason: the choice belongs to a person, not to the club.
**The trade table is on the screen where you pick**, because a decision whose
consequences live in a wiki is not a decision. And a coverage row underneath
naming any of the three jobs nobody is teaching.

**The book**, in two halves behind a tab row.

*Club records* had to wait for the fighter book that landed yesterday, and they
are stored on the **world**, not scanned off the roster. A man's book goes home
with him when he retires; the club's does not. "Most downs in one afternoon" is
the club's record whoever set it — so it is a name and a season written down at
the moment it happened. A scan would quietly lose everything every retired man
ever did, which is most of the history of any club worth having one.

*Your record* is seasons run, promotions, relegations, best finish, cups won and
cup runs — every one of them derived from `world.history` and `world.honors`,
both of which have been kept since section 20 and **never once added up**.

**Free agents as cards.** The market was a row list: legible, and it made every
man look like every other man. A signing is a comparison. Both prices are on the
card, because both have to clear — the fee in credits you spend now, and the
wage that then sits under your cap for as long as he does. A market showing one
of them lies about half its refusals. The fee is colored by whether you can
actually pay it.

### The collision check moved

The market's first version ran its second row into the Back button — **exactly
the failure the roster's card-overlap check exists to catch, on a screen that
check did not cover.** A rule enforced on one screen is a rule with a hole in it,
so the check now covers both grids. Three sections in a row have now recorded
some version of that sentence, which is either discipline or a tic.

Three new checks, and the regime one is the interesting one: it asserts all four
of its numbers actually differ, and specifically that **Hard is at least three
times riskier than Normal** — because a trade where both sides are the same
number is a slider with a label on it.

### Suite

**154 of 154**, sixteen files. Save **VERSION 9** already covered the fighter
book; the club's record book rides in the same world dictionary the honors do,
so it needed no bump — a version 8 world with no records decodes into a club
whose book has not been started, which is true.

### Still open

- **The artwork**, eight specified slots in `docs/ART.md`.
- **The credits screen wants confirming on a device.**
- The four smaller audit findings from section 39.

---

## 42 — The corner, which did not exist (11 Sep 2026)

The last four items on the audit's list, and the first of them turned out to be
three bugs stacked on each other in the game's most important mechanic.

### The bench was decoration for the life of the project

Decision **10.3a** is locked, in Pete's words: *"You should be able to swap
fighters between rounds from the bench anyway. We'll be taking that from
ACRTW."* `docs/GAMEPLAY.md` explains why in one line: a man who **fought** the
round recovers 30% of his tank in the corner, a man who **sat it out** recovers
62%, *"and that gap is the whole mechanic — the bench is a way of buying gas."*

`MeleeSim.swap_in` was written, correct, and commented. **It had no caller
anywhere in the project.** The rule was in the design doc, the code was in the
sim, and the two were never introduced.

That was the finding I went looking for. Two more were underneath it.

### Choosing a strategy skipped the recovery entirely

The corner ends in exactly one place — `corner_t <= 0` in `tick()` — and that is
the only place `_corner_recovery()` ran. But the screen ended the corner by
reaching in and calling `sim._set_the_line()` itself, which sets
`phase = CHARGE`, so `tick()` never took the corner branch again.

**A player who picked a corner strategy got no rest for anybody, all bout.**

The 30/62 split fired only when the player sat on his hands and let the clock
expire — **which is also the only path the suite took**, because `run_to_end`
never picks a strategy. The tested path and the played path were different
paths, and the mechanic lived on the tested one. Measured, before and after:

```
                 fought                sat
strategy picked  0.55 -> 0.55 (+0.00)  no recovery at all
clock expired    0.55 -> 0.85 (+0.30)
```

There is a `leave_corner()` now and both exits go through it.

### And the rest was credited to the wrong man

`_corner_recovery` decided the bench bonus by asking whether a man was in
`lineups` — which is the line for the round **ahead**. After a swap that is
wrong in both directions: the man coming OFF is no longer in it, so he took the
fighter's 30% *and* the bench's 62% on top; the man coming ON is in it, so he
took nothing at all, losing the exact rest he was brought on for.

`men` is who actually fought, because `_set_the_line` has not run yet. That is
the honest question and it is the one being asked now.

### A fourth: the corner screen said everyone was fine

`condition_of()` read `conditions`, which is only written **at a corner
recovery** — so during the round, and during the corner that follows it, it
still held what a man had at the *start* of the round. The corner screen asks
this of five men who have just fought two minutes and it was answering **100%
for all of them.**

That is the number the entire swap decision turns on. Reading it off the live
tank instead, the same corner now says:

```
Ward 0.48   Iles 0.47   Kerrigan 0.69   Vance 0.00   Ash 0.70
```

Vance is gone. *That* is a corner screen.

### The check that would have caught it

`the corner pays the men who sat` asserts the rule on **both ways out of a
corner** — which is the part that matters, since the bug was that the two ways
out did different things. Plus a swap case: the man taken off must get the
fighter's share and not the bench's on top.

### The other three

**Deleting a play slid the selection onto a different play.** `play_index` is an
index and `remove_at` shifts everything after it down one, so with
`["Crash", "Wheel", "Hold"]` and Wheel called, deleting Crash left index 1
pointing at **Hold**. The only guard was against running off the end. This
file's own header warns about exactly this hazard — for formations.

**Three orderings of one queue.** `blocked_by()` answers bid, then cup, then
dilemma. The club tab drained bid, then *dilemma*, then cup, and the drawing put
the dilemma first again. Nothing had gone wrong only because nobody had hit a
matchday with both a bracket waiting and a card on the table — at which point
the season says "deal with the cup" and the buttons offer you the dilemma. The
screen is in `blocked_by()`'s order now and `test_season.gd` reads the source to
keep it there, because **a comment cannot hold two files in step.**

**The opponent's AI tier is shown.** It decides whether the other corner
improvises once its plan runs out, hunts a wobbling man, makes the two-on-one —
Seasoned beats Green 63% on identical rosters. Your own side's tiers are spelled
out on the Clubhouse tab; the opponent's were nowhere, so the one number that
explains why the same rating feels harder two divisions up was invisible.

### The corner screen, three passes

Rendered rather than reasoned about, and it took three:

1. An eight-man bench sized itself and ran **off the right of the screen** into
   the scoreboard; the strategy blurbs wrapped into a paragraph and pushed the
   panel down into the fighter strip.
2. Squeezed to fit, the bench labels clipped `"Mear 100%"` to **`"Mear 10"`** —
   the number the decision turns on, truncated into a *different plausible
   number*. Name on top, wind underneath, position down to its initial.
3. Four strategies in a column still reached the strip. Two columns.

### Suite

**156 of 156**, sixteen files. Two new: `the corner pays the men who sat` in the
melee file, and `one queue, one order` in the season's.

### The audit's list is closed

All twenty-six findings from section 39 are done, including the four I had
deliberately parked — and the parked one turned out to be the biggest thing in
the document. **"None of them produces a wrong number" was wrong**: the corner
one produced no number at all, for every bout anybody has ever played, which is
worse. A finding triaged as cosmetic because the code *reads* fine is a finding
nobody has run.

### Still open

- **The artwork.** Eight specified slots in `docs/ART.md`, Pete's to commission.
- **The credits screen wants confirming on a device.**

---

## 43 — Morale, per man, with a bottom end (12 Sep 2026)

Pete: *"Have we done the dilemmas and personal quirks yet for the players and
staff?"* — and then, asked how far morale should go, **"Yes, with a toxic bottom
end."**

### What a mood is worth

The club has had a morale figure since the beginning. It was one number for the
whole place, and it was a read-out: nothing fought differently because of it.
Per-man morale is a different thing, and the reason is the shape Retro Bowl gave
it. Their own tip screen says both halves out loud:

> *"Players receive a +1 strength buff if their morale is angry or toxic."*
> *"Toxic players receive a +1 stamina buff."*
> *"Toxic players bring down the attitudes of team mates after a loss."*

**The difficult man is better at the sport.** That is the whole feature. He hits
harder, he lasts longer, nobody will take him off your hands, and he poisons the
room every time you lose. You keep him because he is the hardest man on your
line, and keeping him costs you.

So a `FighterCard` carries `morale`, seven words from Toxic to Exceptional, and
two bands that the fight itself reads:

| | strength | gas | when |
|---|---|---|---|
| angry | **+6** | — | below 0.34 |
| toxic | **+6** | **+6** | below 0.18 |

Proportional rather than their flat +1, because their stats read 1-10 and ours
read 1-99 — a flat point here would be a rounding error rather than a trade.
`melee_sim` now reads `fighting_strength()` and `fighting_gas()` at every site
that used to read the raw stat, and `tank()` reads the chipped gas, so the toxic
man genuinely outlasts the card.

The club figure is now the **average of the eight who travel**. A reserve who
never leaves the club does not set the tone in the changing room, and every
move that has no particular man in mind still goes through the club and is then
re-derived off the men, so the screen and the room can never disagree.

### The generator never produced a toxic man

`roll_morale` drew 0.62-0.92 and subtracted 0.34 from one roll in ten. Floor:
**0.28**. `toxic()` starts at **0.18**.

So the entire toxic half — the chips, the drag, the cut bonus, the seven words'
bottom two — was code the player could not reach. Nothing said so. The squads
looked fine, the fights ran, morale moved, the screens drew. It surfaced by
asking the generator for four thousand men and counting the tail, which is the
only way that class of bug ever surfaces: **a range's floor is not visible from
any single sample of it.**

The sour roll is now drawn on its own range (0.05-0.40 at one in ten) rather
than subtracted from the happy one. A number arrived at by arithmetic on
another number is a number nobody is watching. Measured: **3.6% toxic, 7.5%
angry** across four thousand men.

### Pete's captain correction

> *"We already covered this, each captain can cover up to two positions in their
> leadership. Rail/Flanker, Rail/Center, Center/Flanker. Which will always make
> one position have an overlap, making it so the teams will have a 'specialty'.
> Low Star staff can have no specialties or just one specialty. So a One Star
> will have no specialty but just generally help. Mid star staff will have one
> specialty, and High star can have two specialties."*

Every captain taught exactly two roles whatever his grade. A one-star and a
five-star were the same hire with a different number of stars drawn beside the
name — **the rating was decoration.** Three things followed from fixing it:

- `specialty_count(grade)` → 0 / 1 / 1 / 2 / 2. A one-star teaches nobody
  anything and still lifts the room (`presence()`), which is his job.
- The overlap two five-stars produce is the **club's specialty**, not the waste
  the screen had been calling it for a week. Men in that role train at ×1.25.
- **The price had to move with it.** It was a flat 5 CC, and a graded product at
  a flat price is not a decision — the only sensible move is to wait for a
  five-star, every time. Now 5 / 8 / 11 / 14 / 17. A new club holds 8 CC: it can
  buy the bottom of that list and not the top.

And the offer generator topped out at **three** stars, so a two-specialty captain
was a thing the code could build and the game could never sell. It also lived in
two screens — `season_scene` and `staff_scene` each carried their own copy of the
same hash — so the day the grade range changed, only one of them would have.
One `ClubOffice.offer()`, read by both. *A rule applied at two call sites is a
rule with a hole in it*, for the ninth or tenth time in this document.

### Three checks that were measuring their own setup

`ClubOffice.hire()` returns a reason it refused. **Five checks threw it away.**
The moment the price started climbing with the stars, three of them silently ran
against a club with **no captain at all** — and one of them reported that the
entire training regime had collapsed to ×1.0/×1.0/×1.0, which reads like a
catastrophic regression in shipped code and was a test that could not afford its
own fixture.

There is now a `_must_hire()` that says so. **A setup step whose failure is
invisible is a check that measures its own setup.**

The same afternoon produced the same shape twice more: the cut check picked a
man on the eight, got `MeleeClub.cut`'s refusal, threw *that* away, and then
measured a room nobody had left.

### The save was a lie, not a gap

`fighter_to_dict` did not carry morale. Every check in `test_save.gd` passed,
because the fingerprint did not read it.

A missing *book* decodes into something true — a squad that has not had a record
kept yet. A missing *morale* decodes into 0.70 for every man on the roster, which
means **a save-and-reload would cure the toxic fighter the player has been
managing round all season**, and take the +6 he was fighting at with him. Same
for the captains: a version 9 file has every captain on two specialties whatever
his grade, so a one-star hired under the old rules would reload teaching two jobs
he is not good enough to teach.

VERSION 10, refused rather than defaulted. Morale and the captains' shape are
both in the fingerprint now, so the round-trip check reads what it claims to.

### The card collided with itself

The roster note gained a mood and came out `"39 · age 26 · Exceptional"`, which
ran straight through the `"to 46"` ceiling note on the right of the same card.
Both were inside the card, so **every geometric check in the file passed**. What
was wrong was the width of the words.

Two fixes. The card now flags a mood only when there is something to act on
(below `Ok`), where the words happen to be short — a card that comments on every
mood comments on none of them. And there is a check that builds the note for all
seven moods, measures it in the font it is drawn in against the space the ceiling
note actually takes — measured, not the 90px max-width hint, which is a ceiling
on that string and not the room it occupies — and carries a positive control on
`"Exceptional"`, the string that broke.

The fighter screen made the mirror mistake twice: a 64-character sentence along
the bottom of a 280-pixel panel (clipped mid-word, tail into the third column),
then two short lines that fit and sat four pixels under the last stat's caption.
There is one line of room at the bottom of that panel. It is one line.

### Suite

**164 of 164**, sixteen files. Eight new: five on morale (`a mood is worth
something`, `the room is the men in it`, `a toxic man costs the others a loss`,
`cutting a man is read by the room`, `a squad arrives with a spread of moods`),
`the stars are what you pay for`, `nothing on a card runs into anything else`,
and `the register still describes the code` — which reads this section back and
asserts every figure in it against the constant it came from, because a register
that quietly stops being true is worse than no register.

### Still open

- **The artwork.** Eight specified slots in `docs/ART.md`, Pete's to commission.
- **The credits screen wants confirming on a device.**

---

## 44 — You, the kit, and the club coming apart (12 Sep 2026)

Pete: *"Alright, what's next? I know we're missing a few things. If you're out
of ideas, go back to Retro Bowl and look through it for more features."* Asked
which of four gaps to build, he said **all of them**.

So: four systems in one session, three of them read out of the shipped build and
one of them the thing this project's own direction document has called the
signature system since before a line of code existed.

---

### You

Everything in this game belonged to the club. The roster aged, the office banked
credits, the arena filled, and **nothing belonged to the person playing** —
twenty seasons of a well-run club read as twenty seasons rather than as a
career, because no thread ran through them that was yours.

`Coach` is that thread: a reputation other clubs can see, a lifetime record that
follows you out of the door, and the fact that you can leave.

**Reputation is Retro Bowl's `coach_rating`, and its shape is the interesting
half.** It does not decay a point a year. It is additive on success and
**multiplicative on failure** — all of these read out of the build:

| division finish | | cup run | |
|---|---|---|---|
| won it | **+4** | out in the first round | **+3** |
| second | **+3** | out in the quarters | **+4** |
| third | **+2** | out in the semis | **+5** |
| fourth | +0 | lost the final | **+6** |
| below that | **× 0.5** | **won it** | **+8** |

Clamped 1-20, which is theirs too. The halving is what makes the number mean
anything: a coach who climbs for six seasons and then finishes mid-table loses
**half of what he built**, so a reputation of 18 is evidence of sustained work
rather than of having once been good. Measured in the tests: a 16 who finishes
ninth watches his offer list fall from 28 clubs to 5.

**Who comes for you** is `s_team_interested`, four lines long and every one
doing work:

```
not your own club · your rating >= the club's rating
not your boyhood club before season 3 · 1 in 4 never call
```

The second line is the system. You are offered clubs you **out-rate**, so the
list is a ladder you climb rather than a lottery, and a bad season visibly
shortens it without a single line of code about punishment. The third is the one
I would not have written: **your boyhood club is barred until your third season
however good you are.** Offered in year one the dream job is a menu item; held
back three years it is the thing you are playing toward.

**Taking a job leaves everything behind.** The roster, the credits, the arena,
the captains, the trophy cabinet — all of it stays with the club. You arrive with
a reputation and a book, which is what a coach actually takes through a door. A
version that let you bring your best Center is a trade screen, not a career.

### The traits were on the wrong object

I read "coach trait" and started building nine perks belonging to the player.
The build disagrees: every one is read off `staff_hire`, and every description is
scoped — *"Instant morale boost for $pos players"*, *"Toxic players ($pos) have
no negative impact on teammates."* **They belong to the captain you hire, and
they reach the roles he teaches.**

Which is the better system, and it lands on an object that already has a scope. It
also makes the hire a real comparison: a four-star who teaches the two jobs you
need, against a three-star **Physio** whose men come out of the corner with
something left. A one-star teaches nothing, so his trait reaches nobody — the
stars stay the thing you are buying.

**And the price had to move with the stars.** It was a flat 5 CC. A graded
product at a flat price is not a decision: the only sensible move is to wait for
a five-star, every time. Now 5 / 8 / 12 / 17 / 24 (5 / 8 / 11 / 14 / 17 until 2 Oct 2026, row 30.90), against an opening balance of
8.

### Kit and availability — the cap this game was designed around

DIRECTION §4 has said this since day one:

> *"Salary cap → kit and availability. Nobody is paid. The cap isn't
> money-per-player, it's how many bodies you can put on a plane and how many
> harnesses you own that pass inspection. Bench depth is limited by armor, not
> payroll. This constraint has never been in a sports management game and it is
> completely true to the sport."*

**And the game shipped a money cap** — the literal Retro Bowl mechanic that
paragraph exists to replace — because a wage bill was the thing that was easy to
port. Meanwhile `armor` was a 0.78-1.0 multiplier on a man's base and nothing
else, and `available` had sat on every fighter since the first week with **no
code anywhere that ever set it false**.

Two numbers fix it:

- **Inspection.** A harness below **0.35** does not pass the marshals, and a man
  who does not pass does not fight. Armor is a gate now, so the Workshop stops
  being somewhere to put spare credits and becomes the difference between having
  five men and having four.
- **Places on the bus.** A club starts with a line and one man — **six** — and
  buys its way to eight at 6 and 10 CC. The bench is a purchase, which is what
  makes the corner's two swaps something you earned.

The starting party is six rather than the bare five the document literally says,
and that number came out of running it: **at five a club can make no swaps at
all**, so the entire corner layer — the screen, the swaps, the bench recovery —
is dead until the first purchase. A mechanic the player cannot touch in his first
season is a locked door, not a progression.

**Availability** is the half with no equivalent anywhere in the reference. Your
Center is a welder with a shift. One man at most, rolled at the top of the week
so it is on the roster screen *before* you pick a line, and it clears. Known in
advance it is a squad-selection problem; sprung at kick-off it would be a
punishment.

And "OUT 2" now says which of the three it is, because a knock waits, a harness
is a trip to the workshop, and a man who cannot get the weekend off is why you
bought a bench.

### The club splits

> *"Getting fired → the club splits. The signature system... half your roster
> walks out and founds a rival club across town that you now have to fight.
> Better than a pink slip: recoverable, generates a rival with a grudge, and
> populates that rival with your own former fighters. If the game has one system
> people talk about, make it this one."*

It replaces getting sacked and is better than it for a reason worth writing
down: **being sacked ends a thing; this starts one.** You keep your job. What you
lose is half your squad, and what you gain is a club in your own division made of
men who know exactly how you train.

It takes **a mutinous room and a bad season**, and never before season 2 — a club
that is winning does not fracture however unhappy it is, and a sound room
survives relegation. That conjunction is the difference between a system the
player can steer and a dice roll he resents.

**Who walks is who you left out.** Men are sorted by how little reason they have
to stay, and being left out of the line is its own grievance on top of morale. A
roster that loses its five best is a dice roll; a roster that loses the seven men
who never got picked is a consequence. At most half, and never so many that you
cannot field five — the whole argument for this over a sacking is that it is
recoverable.

The breakaway **takes over the weakest club in your own division**, because the
pyramid has a fixed club count and a seventh club in a six-club division breaks
every table in the world. That is also what actually happens: a breakaway group
absorbs a club that was already dying rather than building one from nothing.

### Six bugs, and what caught each one

**The morale fuse said one thing and the screen said another.** I set it at 0.30
because that sounded like a lot of unhappiness. `ClubOffice.morale_word()` calls
0.30 **"Restless"** — so the screen would have told the player his room was
restless while the rule treated it as ready to walk out. The check that caught it
asserts the fuse **against the word** rather than against a number, which is the
only version of it that could have.

**The breakaway fielded strangers.** The men who walk are, by construction, the
ones who were not being picked — so most of them arrive carrying `active =
false`. The rival was founded, filled its line with **walk-ons**, and sat the
five men who actually walked in its reserve. Every check passed: "can the rival
field five" was true. What caught it was a note printing `active_eight().size()`
as **0** next to a sentence saying the club was made of these men.

**An infinite loop with no output at all.** `while club.active_eight().size() <
ACTIVE_SIZE` promotes a reserve until the party is full — and the moment a club
could take fewer than eight, promoting a man could not move a number the cap was
holding down. It hung the entire suite for four minutes and printed nothing. The
loops now ask the club how many it can take rather than asking the constant how
many a full club takes.

**The save silently made the club better.** `travel_slots` is saved;
`MeleeClub.travel_cap` is a copy of it pushed on by `sync_power()`, and nothing
pushed it on load — so a reloaded club took the default eight while its office
said six. The round-trip check caught it as a roster that came back different.
Without it, it would have shipped as a club that quietly got two men better every
time the player reloaded.

**Availability diverged a reloaded world.** It drew from `_roster_rng()`, a
stateful season-long stream whose *position* is not saved. The winter drew from
it once a year and nothing noticed; drawing every week meant a reload restarted
the stream and rolled different men unavailable. `the world continues the same`
went red — which is precisely the check that exists to catch a save carrying less
state than the game is using. Seeding on (season, event) removes the state rather
than saving it.

**And I spent twenty minutes debugging the wrong thing.** Every call into the new
split file came back *"Nonexistent function 'fractures' in base 'GDScript'"* —
from a file whose statics the test was calling successfully two lines earlier. I
decided that was a parse-order cycle, moved a const, renamed the class,
reimported twice. It was a **parse error one function down**: `var grievance :=
1.0 - f.morale` on an `f` from an untyped `Array`. GDScript reports a file that
failed to compile as a plain resource, so every static call reads as a missing
function.

The lesson is this document's own, in new clothes: *a measurement that cannot
separate the good case from the known bad case is not evidence.* "Nonexistent
function" cannot tell a load cycle from a syntax error one line away, so it was
never evidence for either. Read the first error, not the loudest one.

### Two checks that were measuring the wrong quantity

Both went red for the same reason and neither was a regression.

`facilities reach something` asserted club power rose over a winter. That stopped
being a statement about the training ground the moment harnesses, availability
and a purchasable party all started pushing on the same number — club power can
come out fractionally **down** in a year the ground did its job perfectly. It now
measures the men the captain coaches.

`a squad survives its retirements` asserted a party of `ACTIVE_SIZE`. The club in
that fixture never buys a place, so it correctly travels six for thirty seasons —
and the check called that a failure to survive. "Full" is now a question with a
club-specific answer, so it asks the club.

### The levers

Four small things, and the first is the one that matters: **morale now has
somewhere to spend.** `msg_BoostMorale` — *"arrange a morale boosting event for
$num coach credits"*. Per-man morale went in with results, regimes, captains and
cuts all pushing it around and **not one thing the player could do on purpose**.
Once a week, deliberately weak: a morale button you can mash is a morale button
that deletes the toxic bottom end.

The **Hall of Fame** is tagged by hand on a man's own page while he is still
playing, and the card is copied — a man tagged at 41 stays at 41 after falling to
7. That is what separates it from the club records the game keeps for you: it is
a list of men *you* decided mattered.

**Refreshable lists** (3 CC) turn over a hire or free-agent crop that is
otherwise fixed for the year — the refresh count is part of the seed, so it is
genuinely different men and not a reshuffle. And **captains are on three-year
deals** now, extendable for 2 CC; when one lapses the roles he taught go untaught
that winter. Without it a five-star hired in season two is yours for twenty years
for five credits and the staff room is visited once and never again.

### Save version

**VERSION 11**, refused rather than defaulted. A file from before the coach has
no reputation, no lifetime record and no posts, so it would load a twenty-season
career as a man who has never taken a job — and the offer list, read off the
reputation, would come back empty for a coach who had earned the country.

The breakaway rosters are saved too, and they are **the only CPU rosters in this
game that are stored rather than generated**. Every other club is rebuilt from its
id and its power; a splinter rebuilt from a seed would be strangers wearing the
name.

### Suite

**186 of 186**, nineteen files. Three new files — `test_coach.gd` (8),
`test_kit.gd` (5), `test_split.gd` (5), `test_levers.gd` (4) — and 22 new checks.

### Still open

- **The artwork.** Eight specified slots in `docs/ART.md`, Pete's to commission.
- **The credits screen wants confirming on a device.**
- **Two pillars from DIRECTION §4 remain**: trials day (recruiting from open
  trials, poaching and crossovers, each with its own stat shape and attitude
  problem) and members and the federation (dues, and compliance gating nationals
  and Worlds).

---

## 45 — The last two pillars (12 Sep 2026)

Pete: *"Let's do the direct pillars."* The two remaining from DIRECTION §4 —
**trials day**, and **members and the federation**. With these the document's
four replacements for Retro Bowl's four structures are all built.

---

### Trials day

> *"Draft → trials day. Buhurt has no draft. You recruit from open trials,
> poaching from rival clubs, and crossovers — rugby, HEMA, military, strongman.
> Each source has a different stat shape and a different attitude problem. One
> trials event per off-season plus year-round poaching that costs goodwill."*

**The market already existed and this is not it.** `Market` is men who are
already fighters, priced by band, taken with credits — a transfer list. Trials
are the other half of how a club is actually built: people who have never worn a
harness turning up on a Saturday, and a club deciding which of them is worth a
winter.

The difference is in the **shape**, not the price. Measured across thirty
seasons:

| | rates | room to his ceiling |
|---|---|---|
| free agent | 45.7 | 3.6 |
| trialist | **38.9** | **15.2** |

A trialist is worse now and much further from what he could be, which is what
plugs him into the career layer. He is a winter's work, and the training ground
and the captains are what turn him into a fighter.

**And each source is visibly a different man.** Averaged over 200 draws at the
same target rating:

| | str | base | skill | gas | arrives |
|---|---|---|---|---|---|
| Open trial | 55 | 60 | 45 | 46 | 0.72 |
| Rugby | 59 | 68 | 31 | 56 | 0.78 |
| HEMA | 45 | 48 | **63** | 48 | **0.40** |
| Ex-forces | 57 | 66 | 41 | 52 | **0.88** |
| Strongman | **75** | 70 | 29 | **28** | **0.28** |

The attitude half is what the morale layer is for. The soldier turns up and does
what he is told. The HEMA man's technique is already better than your Center's
and he thinks he knows better than you. And the strongman arrives in the **angry
band** — which makes the toxic trade a thing you can go out and *buy* rather
than only stumble into.

**Poaching is priced in goodwill**, and goodwill is what fills a trials day.
That coupling is the whole design: you are buying finished fighters with the
thing that brings you raw ones. A hated club gets six men in the car park and a
liked one gets nine; three poaches take a normal club from six to five. It
recovers over a few summers, because a resource you can never rebuild is a
mistake you cannot recover from — the same rule the club split already follows.

A poach **moves a man across the world** rather than conjuring one: measured,
the club you took him from falls 32 → 30 and stays there. And he arrives
unhappy, because he has just been talked out of a club he chose, with money, and
he knows what that makes him. No club can be taken below a line — stripping a
rival to nothing is not a rivalry, it is deleting a fixture.

### Members and the federation

> *"Owner/fan pressure → members and the federation. Members pay dues and walk if
> you're unserious. The federation gates nationals and Worlds on results and
> compliance — kit standards, marshal certs, insurance. Two masters pulling
> opposite directions."*

**The tension took a rewrite to get pointing the right way.** The first version
had members leaving when the club was non-compliant — which made both masters
want the same thing and collapsed the whole pillar into one slider called *be
good*.

They pull opposite ways because they want opposite things out of the **same
credits**:

- **The federation** wants money spent on certificates, insurance and harness
  inspection. Every credit of it buys nothing on the field. Fall short and you
  are not entered for the cups, however well you have played.
- **The members** pay the dues that fund the club, and they walk when the club
  stops being worth turning up to: a bad room, a bus you cannot fill, a losing
  year, a club nobody in the sport will train with. Everything that keeps them
  costs the money the federation is asking for.

A Regional club of 24 members banks 24 CC of dues against an 11 CC paperwork
bill. Neither answer is safe: pay the federation and starve the squad, you lose
the members and then cannot pay the federation; spend on the squad and you win a
division you are not allowed to take a cup out of.

The check that protects this is `the two masters pull apart`, and the first
assertion in it is that compliance is **invisible** to the members. That is the
one that would have caught the first version.

**A certificate lapses; it does not decay.** A ground you cannot afford falls a
level, because a ground is a building. Insurance you did not renew is not
partial insurance — the level goes to nothing. A broke National club loses all
three outright.

**And the Backyard Circuit asks for nothing.** It demanded a kit certificate for
about ten minutes, and the suite said what that meant: `test_cupplay.gd` went red
five times with **"no cup came up"**. A brand-new club has no certificates, so
the gate barred it from every Invitational in its first season — the cup run that
is most of the early game, closed before the player had seen the screen that
would have explained it. The document says the federation gates *nationals and
Worlds*; it does not say it gates a field and a rail. Demands now run
**0 / 3 / 5 / 8** up the pyramid, so the paperwork is something you meet on the
climb rather than a wall at the start.

### Three bugs, all the same bug

Every one was a rule written against the constant eight, left behind when the
traveling party became a thing a club buys last session.

**`MeleeClub.sign()` marked men active who could never travel.** It set
`card.active = active_eight().size() < ACTIVE_SIZE`, so a club with six places
flagged its seventh and eighth signings for a bus they cannot board. It surfaced
as a trialist walking straight into a line he was not in.

**"The reserve is full at 5"** — a derived fact dressed up as a rule. With eight
traveling, thirteen on the books means five in reserve and the two statements
agree; with six traveling there are seven men not traveling, so the club was
permanently over a limit that no longer described anything and **could not sign a
single man from any source**. Trials, poaching and the free-agent list all
refused. `SQUAD_MAX` is the real rule; how those men split between the bus and
the clubhouse is a consequence of the cap, not a second thing to enforce.

**`line_legal()`** asserted a party of exactly `ACTIVE_SIZE`, which is now a
question with a club-specific answer.

The lesson is one this document has recorded before in other clothes: *a
constant that used to be a fact becomes a lie the moment the thing it described
becomes a choice* — and it does not announce itself, because every call site
still compiles and most of them still agree.

### And two checks that were asking a question where it does not apply

`the federation gates the cups` compared the invitation with and without
paperwork and got `false` both times, because the club was never in an invitable
position to begin with. It reported "compliance changes nothing", which was a
true statement about a club that was never going to be invited and told us
nothing about the gate. It now asserts the **rule** — barred refuses every
position, unbarred agrees exactly with the results half — which needs no league
table arranged around it.

The other asked whether being known fills a car park by passing `1.0` for famous
and `0.0` for unknown. Notoriety runs to **125**. Both were effectively zero, so
the check was asking the same question twice and reporting the answer as a
finding.

### Save version

**VERSION 12**, refused rather than defaulted. A version 11 file has no goodwill,
no compliance and no membership, and each of the three decodes into a lie rather
than a gap: a club with no goodwill is either loved by everyone or by nobody
depending on which default you pick; a club with no certificates is **barred from
every cup the moment it loads**; and a club with no members banks no dues and
cannot pay the federation it has just been told it owes.

### Suite

**193 of 193**, twenty-one files — one new file, `test_pillars.gd`, and every one
of its seven checks earned its place by going red first.

### DIRECTION §4 is complete

All four of the document's replacements for Retro Bowl's four structures are
built and checked:

| Retro Bowl | Retro Buhurt | |
|---|---|---|
| Draft | **Trials day**, poaching, crossovers | §45 |
| Salary cap | **Kit and availability** | §44 |
| Owner/fan pressure | **Members and the federation** | §45 |
| Getting fired | **The club splits** | §44 |

### Still open

- **The artwork.** Eight specified slots in `docs/ART.md`, Pete's to commission.
- **The credits screen wants confirming on a device.**
- **A tuning pass.** Four systems landed in two sessions and every number in them
  is a first guess that has never met a player. The economy in particular now has
  five claims on the same purse — wages, facilities, the bus, the paperwork and
  the captains — and nobody has yet played ten seasons against all five at once.

---

## 46 — Trials, poaching and goodwill come out (12 Sep 2026)

Pete, on the morning after they shipped: *"Remove the Trials day, Poaching, and
Goodwill. Those are not good ideas."*

So they are gone — all three, whole. Not disabled behind a flag, not left in the
code with the buttons taken off the screen. §45 is one section old and half of it
described a system that no longer exists, which is the most useful thing this
document can record: **the register is a log, not a design.** Nothing above has
been rewritten to pretend the afternoon did not happen.

### What came out

- `scripts/league/trials.gd` — the five sources, their stat shapes, their
  attitudes, the field size, the poach fee. Deleted.
- `scripts/game/trials_scene.gd`, `scenes/Trials.tscn`, `tools/shot_trials.gd`,
  `shots/trials.png`. Deleted.
- `Season.trials()`, `trials_open()`, `take_trialist()`, `poach_pool()`,
  `poach_cost()`, `poach()`, `POACH_MORALE`, `trials_done`, `trials_taken`, and
  the summer's reset of both.
- `ClubOffice.goodwill` and everything that read it: `goodwill_shift()`,
  `goodwill_word()`, the four constants, the summer's recovery, the save field.
- `Federation.MEM_GOODWILL` and the goodwill argument to `members_after()` —
  members no longer care what the rest of the sport thinks of you, because there
  is no longer a number for that.
- The Trials button on the market tab, the goodwill readout on the federation
  screen, and four of the seven checks in `test_pillars.gd`.

### What was underneath it, and is worth keeping in mind

Three of the four dead checks were doing real work, and two of them found real
bugs in code that is **still here**:

`MeleeClub.sign()` marking men active for a bus they could never board, and the
phantom "reserve is full at 5" that stopped a club signing anybody from any
source — both were found by trials tests, both were bugs in the travel cap rather
than in trials, and both stay fixed. A feature that gets cut can still have paid
for itself on the way through.

### The save version did not move

Every save this build writes is still a **version 12**, and every version 12
written by the build that had trials and goodwill still loads. The removed keys
are simply not read, and nothing that *is* read decodes into anything different.

That is worth saying explicitly rather than leaving as an omission, because the
reflex after a change this size is to bump. A version bump exists to **refuse a
file that would come back wrong**. A file that comes back right does not need
one, and bumping anyway would have thrown away Pete's saves for nothing.

### DIRECTION §4

The trials paragraph is struck through in the document with the date and the
reason, rather than deleted. The first half of it still stands and is still
solved — buhurt has no draft, and free agency is the answer, which the market has
been doing since it went in. What is cut is the second half.

Three of the four pillars remain built: kit and availability (§44), members and
the federation (§45), and the club splits (§44).

### And one trait that was left pointing at nothing

The **Scout** captain trait read *"More men at the trials."* Trials are gone, so
after the cut it described a system that does not exist — and the more
interesting half is that **no code had ever read it anyway**. It was the exact
state the training regime sat in for a week: a name, a description, and nothing
behind it.

It was passing the check meant to catch that, because the check asserted every
trait had a *description* rather than an *effect* — two different claims, and the
weaker one is the one that got written. Scout now adds three names to the
free-agent list, which is the better home for it in any case (the thing a scout
is good at is finding somebody nobody else has looked at), and the check now
measures the list rather than the dictionary.

### Suite

**188 of 188**, twenty-one files. Five checks fewer than §45, and all five went
with the code they were about.

---

## 47 — Twenty pictures, a thousand faces (12 Sep 2026)

Pete: *"I need an art list with prompts. We'll also make the fighter portraits
with AI. I would need about 4 different styles of armor, and a good amount of
different heads. There may be some good free packs online also."*

### Four harnesses and sixteen heads

A save holds well over a thousand fighters. Nobody draws a thousand portraits,
and a game that draws the same one on all of them has added a decoration rather
than a portrait. So a portrait is **two layers**: 4 harnesses × 16 heads is
**sixty-four men from twenty images**.

**Both layers share one 64 × 64 canvas.** That is the decision the whole thing
rests on. The alternative — a head at its own size, placed against an anchor —
requires every generated head to agree with every generated harness about where a
neck is, and an image model will not do that reliably twice running. One canvas,
each layer in its own region, stacked with a straight overlay and no arithmetic.

**The harness is read off the fighter's rating, not rolled.** Kit-bash under 45,
transitional to 57, gothic to 71, Milanese above that — four real historical
grades in the order a club can afford them. A scruffy man in a borrowed
brigandine *looks* like a Backyard fighter and a man in Milanese plate looks like
he belongs at Worlds, so the player reads a squad's quality off the cards before
he reads a number. That is constraint 05.1 — *load-bearing rather than
decorative* — actually earning itself rather than being quoted at.

The head is hashed off name and number, which are unique on a roster and never
change, so a man keeps his face through ageing, a re-signing, retirement and the
Hall of Fame.

### Two collisions that only pixels could have found

The portrait went in at the right of the card's header band — **which is where
the shirt number is** — and at the top-right of the fighter screen's left
panel, **which is where the age, weight and contract values are right-aligned
into**. Both were invisible, because there is no portrait art and `portrait()`
correctly draws nothing.

That is the trap the whole slot system sets: **a layout you cannot see is a
layout you cannot check**, and it surfaces on the day somebody drops in the real
file — by which time the person looking at it assumes the art is wrong.

So twenty throwaway placeholders were generated, dropped in, rendered, read, and
deleted. The card's face moved to the left of the band with the label stepping
aside for it; the fighter screen's moved into the header. Then a third thing the
render found that no amount of reasoning would have: **at the small card size the
label ran through the number anyway**, because a hundred-pixel card cannot carry a
face, a position, a number, a name, stars and a bar. Faces are now on the five men
on the LINE and not on the bench — which is a better hierarchy than the one I was
defending, and I did not think of it until a picture made me.

`art/` is back to holding nothing. The repo ships with zero art and every slot
falling back, exactly as before.

### The free packs

Searched rather than assumed, and the honest expectation is written into
`ART.md`: free CC0 packs will very likely furnish the **heads**, because a
generic 64×64 medieval head is a thing hundreds of people have drawn. They almost
certainly will not furnish the **harnesses**, because "brigandine vs transitional
vs gothic vs Milanese, as busts, at a shared canvas, with the head cut out" is
specific enough that it probably does not exist. Raid for heads, prompt for
harnesses.

Three licence traps are recorded there too, because all three have bitten real
projects: "free" on itch means free to *download*; CC-BY-SA reaches further than a
paid game wants; and attribution goes in the credits screen **the day the file
lands**, not the week before launch.

### Suite

**188 of 188**, twenty-one files. No new checks — but `the art spec matches the
code` now asserts 28 slots instead of 8, and it is the reason ART.md cannot
quietly describe a portrait layer the game does not look for.

---

## 48 — The face, and the one word that decided it (12 Sep 2026)

Pete, on three names set in the house faces: *"Merrick looks like Merri-ck, Ulme
looks like Ul-me, Coyle looks like Coyl-e."*

He was reading a bug, not a style. Every glyph I had drawn advanced the full
cell whether its ink filled the cell or not, so `i`, `l`, `r` and `t` left two
empty pixels beside them — and two empty pixels between two letters is exactly
what a word break looks like. Every one of his three examples tears immediately
after a narrow letter. The face was not ugly; it was **hyphenating names**.

The fix for my own faces was an hour: measure each glyph's ink, push it to the
left of its cell, advance by ink-width plus one. Then he asked for open-source
faces to compare against, looked at four, and said: *"If you can make
PressStart2P proportional, let's use that."*

### Press Start 2P has the opposite fault

It does not tear, and the reason is worth recording because it is a real design
decision and not an accident: **its narrow letters wear serifs that fill the
cell**. An `i` in Press Start 2P has a hat and a foot six pixels wide. That is
how a monospaced pixel face stays readable — it spends the empty space on the
letter rather than leaving it beside the letter.

What it has instead is width. `39 · age 26 · Toxic` came to 152 pixels, on a
card that has to carry a portrait, a position, a number, a name, stars and a bar
inside a hundred. Every full stop and every colon was costing a full eight-pixel
cell.

So: same drawing, ink pushed left, advance cut to ink plus one pixel. Eighty of
its two hundred and ten glyphs got narrower; the line above came down to 120,
a fifth off, and the tear cannot happen because there is no empty cell left to
read as a space.

**Digits were left alone at the full cell.** A season table with proportional
figures is a ragged table, and every screen in this game that shows a record, a
purse or a rating shows it in a column. `test_type.gd` asserts that `111` and
`408` measure the same to the pixel, which is the check that catches somebody
"finishing the job" on the digits later.

Two glyphs were drawn in by hand — `←` and `→`, the only characters the game
needs that the Latin subset lacks.

### The name is a licence condition, not a flourish

Press Start 2P ships under the SIL Open Font License with **Reserved Font Name
"Press Start 2P"**, and OFL §5 forbids a modified version from carrying a
reserved name. The derivative is therefore **Buhurt Plate**. That is not a
preference and it is not reversible by liking the old name better.

§2 requires the copyright notice and licence to travel with the font, so
`fonts/OFL.txt` sits beside it, and the original notice is preserved verbatim in
the font's own name table with the modification recorded after it.

The credit is **generated, not typed** — `UiKit.FACE_CREDIT` is declared beside
the face it credits, and the settings screen reads it, exactly as the music
credits read `Audio.LICENSED`. The failure this prevents is a face swapped in
one file while the credits screen goes on thanking the old one, which under the
OFL is a breach rather than a typo.

### Then Pete put half of ours back, and he was right

*"We can use ours for the smaller point fonts so it looks better, just use ours
with proportional version."*

The render settles it. Press Start 2P is drawn with **two-pixel stems** — that
is where its weight comes from, and it is exactly wrong for a dense table: a
roster set entirely in it at 8px is a wall, and `Exceptional` does not fit in
the mood column. Rail is 5×7 with **one-pixel stems**, sets the same table at
roughly two-thirds the width, and reads as quieter than the heading above it.

Four blocks were rendered — all Plate, all Rail, and the two mixed — and the mix
is plainly the best of them. The contrast between a two-pixel display face and a
one-pixel body face is a hierarchy we would otherwise have had to fake with
color. So:

| role | face | drawn on | for |
|---|---|---|---|
| body | **Rail**, ours | 5×7 | table rows, footnotes, anything dense |
| title | **Plate** | 7×8 | screen titles, names, headings |
| number | **Plate** | 7×8 | scores, purses, ratings — tabular digits |

Gorget and Maul stay in `fonts/` with no role. Nothing asks for them and nothing
is harmed by their sitting there.

### The one real cost, and the ten-minute fix for it

Rail was built on a **7-pixel em** and Plate is on an **8**. A pixel face is
crisp only at whole multiples of its em, so that gave the body face the ladder
7/14/21 and everything else 8/16/24 — two ladders that never meet, in a UI where
a heading and a row routinely want to be *the same size*. That is not a
cosmetic problem; it is "the same size" ceasing to be a thing a screen can ask
for.

So Rail was rebuilt with its seven rows of ink sitting inside an **eight-row
box**. The drawing did not change by a pixel. `build()` grew one optional
argument. All four faces are now on an 8px em and there is **one ladder: 8, 16,
24, 32 and nothing between.**

`test_type.gd` asserts it the way this codebase asserts everything — not by
writing 8 down somewhere, but by asking each face for its line height at each
legal size and requiring a whole number. A face that drifts off the em answers
with a fraction.

The sixteen scenes currently ask for 11, 12, 13, 14, 15 and 16, and every one of
those that is not 16 will land on 8. That is a re-layout, and it is the next job
rather than a side effect of this one. The scenes still draw in
`ThemeDB.fallback_font` until it is done.

### Suite

**234 of 234**, twenty-two files. `test_type.gd` is new: that both faces loaded
and neither is the silent fallback, that they are genuinely two faces and not
one file pasted into both roles, that narrow letters cost less than wide ones in
each, that Pete's three names specifically do not tear, that the digits still
line up, that both faces sit on whole pixels at every legal size, that `snap()`
cannot return an illegal one, and that the licence and the credit are present.

The first of those is the one that earns its keep. `UiKit._face()` falls back to
the engine's sans when a load fails, which is correct for a running game and
catastrophic for a check — rename the file, break the import, ship the wrong
folder, and every screen still draws, in a sans-serif, and no log says a word.

---

## 49 — The feel layer (13 Sep 2026)

Pete: *"now let's focus on the juice of it all"*, and then, asked how far to
take it: **everything that needs no art**, with the UI sounds synthesised here
rather than sourced.

`JUICE.md` had been a brief with nothing built. It is built.

### What the budget rule turned out to mean

The brief said *two juice effects may fire at once, never three*, and
implementing that literally would have shipped a real bug. A knockout freezes
the sim, shakes the screen and flashes the palette — count those as three
effects and the ceiling swallows the flash, so the biggest moment in the game
plays as an ordinary one, with nothing erroring and nothing to notice.

So **the ceiling counts EVENTS, not effects.** A caller announces one thing that
happened, with a rank, and the event applies whatever set of effects it owns.
Two events at once; a higher-ranked one evicts a lower-ranked one; an equal or
lower one is dropped and counted. A knockout can never lose to two taps, and
`test_juice.gd` asserts exactly that in both directions.

### The sim freezes; the screen does not

Hit pause gates the melee's **accumulator**, not its frame. `accum` keeps
whatever it had, so the ticks that were owed are still owed when the freeze
lifts — a freeze that dropped ticks would be a difficulty setting pretending to
be a flourish.

And the tick that counts the freeze down is deliberately outside it. A hit pause
that paused its own timer never ends, which is a hung bout rather than a
flourish; the suite proves it terminates by running a knockout's freeze to zero
against a 600-frame guard.

### The purse is watched, not hooked

Credits are written in twenty-nine places. Hooking all of them is twenty-nine
chances to miss one, and the missed one is always the one that mattered. So
`UiKit.purse()` both **draws the balance and reports it**, and a difference
between two sightings is a change worth popping. It cannot disagree with the
screen because it *is* the screen, and a seventh screen added next year gets it
by using the same helper as the other six.

Two rules fell out of that immediately. **First sighting arms it and pops
nothing**, or opening the game announces your whole balance as a gain. And
`SaveGame.from_dict` calls `forget_purse()`, because loading a save is not
earning — the number jumps because a different career is on screen, and
announcing that as a gain of four hundred credits would be a lie told with a
sound effect.

### One place a screen changes

There were **thirty-three** bare `get_tree().change_scene_to_file` calls and no
two screens had to agree on anything. They are now `UiKit.go()` and
`UiKit.back()` — the second is not decoration: `back` is `tap` transposed down a
fifth, the same sound in the other direction, which is a thing a player
understands the first time he hears it and never has to be told.

The wipe covers, the scene changes **behind full cover**, and the cover slides
off the far side rather than retreating the way it came — a curtain that comes
in and goes out on the same side reads as a mistake being undone. 130ms each
way, inside the brief's 200ms ceiling.

### Four more one-shots, from the same synthesiser as the score

`back`, `fanfare`, `wipe`, `type` — added to `buhurt_sfx.py` rather than
sourced, because a UI blip made with a different synthesiser than the music is a
blip that sounds like it came from a different game. `type` is deliberately
almost inaudible: it fires every second frame for the length of a paragraph and
anything with a shape to it is a machine gun by the third word.

Twelve one-shots now, and `test_audio.gd` still proves every one of them is
reachable from a real call site rather than just present in the catalog.

### The bug that six identical screenshots found

Every screen arms the layer from its own `_ready()`. `_ready()` runs *while the
root is adding that screen*, and **a node busy adding a child refuses to add
another** — so `tree.root.add_child(layer)` failed silently, `_node` was set
anyway, and nothing ever retried. The entire feel layer existed, ticked its
clock correctly, passed every unit check, and was parented to nothing.

Nothing errored. The suite was green. It took rendering a contact sheet of six
forced juice states and seeing **six identical screenshots** to notice.

That is the same trap this register has now recorded three times in three
different costumes — the portrait collisions, the font that falls back to the
engine's sans, and now this. **A layer you cannot see is a layer you cannot
check.** The add is deferred now, and `arm()` asks whether the node is *in the
tree* rather than whether the variable points at something, which is the
question it should have been asking from the first line.

### And one filter removed rather than kept

`Audio.play()` printed `Playback can only happen when a node is inside the scene
tree` on every headless call, and `run_tests.sh` had grown a line to filter that
error out of the suite's output. That is dirt under a rug: the next real
playback error would have been swept up with it. One `is_inside_tree()` guard in
`play()`, and the filter is gone.

### What is not built

Item 7's wider ambition beyond the twelve one-shots, and idle motion beyond the
typing cursor — the flag flutter and the breathing card both want art or a
selected-card concept that does not exist yet. The iris transition is specified
and unbuilt; the wipe is enough until somebody wants two.

### Suite

**279 of 279**, twenty-three files. `test_juice.gd` is new and drives the whole
layer by hand-cranked delta: the ladder has six rungs and not six hundred,
nothing it hands out is ever a fraction of a pixel, the third equal-ranked event
is refused and counted, a knockout evicts a tap and a tap cannot evict a
knockout, every freeze thaws, the flash is exactly two frames, half the trauma
is much less than half the shake, a popup rises 12px and holds and goes, six
popups from one source draw one, the purse is silent on first sighting and after
a load, a tap skips the typer, and the wipe changes the scene exactly once and
does it at 100% cover.

---

## 50 — The dashboard problem, and the hour spent fixing the wrong half (13 Sep 2026)

Pete: *"The juice here looks like a very large growing number of Claude games,
so we want to steer away from it and go more toward retro 8-bit."*

He was right about the symptom. The diagnosis was right too. Then I acted on the
wrong quarter of it and he stopped me in one line.

### What was actually wrong — four tells, three of them construction

**Every panel was a `draw_rect` with a one-pixel outline.** A hairline is a CSS
idea: it has no thickness, so at 960x540 it reads as a *division of space*
rather than as an object, and the whole shell became regions instead of things.

**The buttons were Godot's default theme** — gray rounded rectangles with a soft
vertical gradient, the loudest engine-default signal on any screen, and one that
no amount of pixel font covers.

**Selection was a tint**, which is how a table highlights a row on the web.

**And the palette was flat** — warm grays on warm browns, everything within a
few steps of everything else.

Three of those are *construction*. One is *color*.

### The evidence, which came off disk rather than off the web

Searching for 8-bit UI references returned listicles. The decompiled Retro Bowl
build already in the scratchpad returned the answer: it lists every sprite the
game ships, and there is **no generic panel routine**. There are seventeen
pre-drawn box sprites at fixed sizes — `spr_box_208x32`, `spr_box_416x144`,
`spr_box_448x80` — of which **sixteen are exact multiples of 8**, plus
`spr_box_flex` in three parts for whatever did not fit. Buttons the same:
`spr_button_32/40/50/64/74/90/104`. They ship `spr_scanlines`, and their
typeface is called **`fnt_tecmo`**.

Their panels are stamped pixel art. But the lesson is not "buy sprites" — **a
chunky frame drawn by code is indistinguishable from a chunky frame drawn by
hand.** What was missing was the chunk, and every change below is still
`draw_rect`.

### The mistake

Four constructions of the same screen were rendered and Pete picked the Tecmo
one — black grounds, saturated navy panels, NES primaries. So I put that palette
in, converted all five moods, rendered sixteen screens, and showed him.

> *"Oh dear god that is an eye sore. Revert that shit and let's mess with UI
> instead of base colors."*

Reverted inside the hour, and the useful part is why he is right. **Turning the
color up to eleven fixed nothing that was broken and broke the thing that was
not.** His grounds were never the problem — three of the four tells were
construction, and the fourth was the only one I changed globally. A mockup at
960x540 on a sheet of four is also not the same thing as sixteen real screens,
which is how I talked myself into it.

The grounds are now byte-for-byte what they were. Everything else changed.

### What stayed, and why each one earns it

**Panels are objects.** `panel()` draws a 3px frame and a 4px hard black drop —
no radius, no blur, no gradient, because a real machine could not have drawn any
of the three and each one is a tell.

**Buttons are skinned, not defaulted.** `UiKit.skin()` gives every button a
`StyleBoxFlat` with zero corner radius, a 3px border and a flat fill, and the
**pressed state moves the button** — the shadow goes away and the box shifts
down into where the shadow was, the way a physical key behaves. A hover tint is
a mouse idea and this game is played with a thumb.

**Three values, not one.** Ground, then panel, then control, then gold for
pressed. Gold only ever means *this is happening*, which is the same job it does
on a league table.

**`UiKit.row()` and `UiKit.dither()`** exist for inverted selection and 2x2
checkered grounds. Neither is called yet.

### EDGE was doing two jobs, and a wide frame proved it

`EDGE` was both **the color a box is drawn in** and **the quietest ink on the
screen**. Those want opposite things — a rule wants to be the brightest thing on
a panel, a footnote the dimmest — and at one pixel wide nobody noticed. At three
pixels of the same dark brown, a panel has no edge at all.

Split, and **`FRAME` is derived rather than declared**: `EDGE.lightened(0.34)`,
computed in `set_mood`. No new color enters the palette, every mood gets its own
frame for free, and Pete's grounds stay untouched. `FRAME_LIFT` is the single
dial in the whole look.

### Two bugs the contact sheet found

**The bracket rendered as a column of white bricks.** `panel(filled = false)` is
asked for by the bracket's match slots and the chalkboard's rows — groups drawn
*on* a panel, not panels themselves. They got a solid black drop each, and worse:
a 28px slot framed in 3px is 21% frame by area. Unfilled panels now take a 1px
rule and no drop, and the two cases stopped pretending to be one.

**Everything was one value of blue.** Found only by putting sixteen screens on
one sheet — each looked fine alone.

Both of those, again, from rendering and looking. Four sections of this register
now say the same sentence.

### And a check that earned its keep

`test_dilemma.gd` has an `every mood stays readable` check — every text color
measured against both the ground and a panel, across all five palettes, with a
0.30 luma floor. The Tecmo palette failed it: `UP` and `DOWN` came out 0.21 from
the lighter grounds. It was the only thing in the whole pass that caught a real
defect automatically, and it did it before a human saw the screen.

### What this did not touch, and what is now loudest

**The type.** Every screen still draws in `ThemeDB.fallback_font`; only buttons
were switched to Rail. So the contact sheet shows pixel-font controls against a
smooth sans everywhere else, and that mismatch is now the most obviously wrong
thing on the screen. **The font conversion is the gating job.**

Also untouched: the dead space on five screens, which no skin can fix; the
inverted selection row, which has a helper and no callers; dithering, same; and
the melee's own palette in `Tuning`.

---

## 51 — The icon bank, and six files out of two hundred and eighty (13 Sep 2026)

Pete: *"We need to make these menus more thematic. I see even Retro Bowl and
icons and stars in places... I'd like to see all the UI more 8-bit themed and
maybe something akin to menu flair. Also, UI icons. We have a bunch from ACTM,
ACRTW, and AMMA Relic Clash that may be useful."*

### What was on the machine

**ACRTW is a real library and almost none of it is importable.** 33 UI icons and
19 HUD ones, all smooth vector silhouettes at 96×96. Downsampled to 16 they turn
to mush; used at 96 they are three times the size of anything else on a 960×540
screen.

**But the list is the valuable half.** Fifty-two icon ideas already thought
through — and the HUD half in particular (anvil, round shield, shoulder armor,
wolf, fist, grab, high punch) is a buhurt vocabulary written down by somebody who
fights. That is worth more than the files.

**The real find was one Pete made himself fourteen months ago.** Kenney's
*Fantasy UI Borders*, CC0, 280 PNGs, imported into ACRTW in July with his own
`KENNEY_PICKS.md` mapping seven categories. White line-art on transparent, so it
multiply-tints to any color and one file serves all five moods. And it is
**geometric** — Greek-key, stepped and square corners, drawn on axis with hard
edges — which is precisely why it survives the trip onto a pixel grid where a
rounded ornament would not.

ACTM and Relic Clash were not reachable; the folder-access prompt timed out and
only `RetroBuhurt` and `ACRTW_Rebuild` were connected.

### The icons are code, not assets

`UiIcons` — 34 marks on a 16×16 grid, plus a two-glyph 8×8 cut for table rows.
This codebase already draws heraldry as pixel grids in `IconBank` and builds its
typefaces the same way, so this is the existing pattern rather than a new one,
and it buys four things an imported file never will: **no licence, no import
step, perfect grid alignment, and it recolors with the mood for free.**

**What makes a 16×16 icon read**, learned by drawing six that did not: a hard
silhouette and one pixel of internal negative space. Two-pixel strokes fill the
shape in — the first shield read as a bucket, the first helm as a box, the first
cuirass as a horseshoe. All six were redrawn.

**Runs, not pixels.** A naive mark is up to 256 `draw_rect` calls and a screen
with twenty of them is five thousand, every frame, on a phone, for decoration.
Ink is merged into horizontal runs and grown downward: **459 rects for 3,443 ink
pixels**, fourteen a mark, worst twenty-three.

### The stars were a smooth polygon, and the half was broken

`UiKit.stars()` already existed and already handled halves — my premise that they
were typed asterisks was wrong, and I nearly shipped a duplicate function on top
of it. What it actually drew was a **five-pointed polygon**, anti-aliased, with
diagonal edges: the single most un-8-bit thing on any screen that showed a
rating.

And it had a bug that had never been seen. A half star was drawn whole and then
**painted out on the right with `PANEL`** — correct on a panel and wrong
everywhere else. On the background, on a selected gold row, on a colored card
band it drew a dark brown rectangle through the middle of the star. Invisible
because half stars are rare and every screenshot that had one happened to have it
on a panel.

Two glyphs, an empty one underneath and a half on top, and the bug cannot exist.

### Six files, four screens

`content_stepped`, `crest_ornate_a`, `trophy_filigree`, `banner_double_rule` and
two heading rules — copied in with `KENNEY-LICENSE.txt` beside them. **CC0
requires no attribution, which is exactly why the licence text has to travel:
the file that proves we owe nobody anything is the only evidence there is.**

**Ornament is hierarchy, not wallpaper.** Six files belong on four screens — the
clubhouse, the trophy cabinet, the bracket, the title. A crest on every panel is
a crest on nothing.

### Read the asset before you use it

The first `rule()` stretched the whole 96px strip across the width and sampled
its "plain" ends from the outer quarters. It came out as a broken, dashed bar,
because **the strip is not symmetrical**: it is a plain double line for 78 pixels
and an ornament in the last 18 — a heading rule that terminates on the right,
meant to be mirrored for the left.

Dumping the pixels to the terminal and looking at them took one minute. Guessing
at the geometry took twenty and produced the wrong thing.

### The check that earns its keep

`UiIcons.draw()` with a name that does not exist draws **nothing** — no error, no
pink square, no log line. A typo in a button's mark is a button that silently
loses its icon and a player who notices six months later.

So `test_icons.gd` walks the actual source and asserts every name any screen asks
for is one the bank has. It found its own gap on the first run: the scan caught
direct draws and missed every button mark, which is where most of them are. Three
patterns now, and the check is **negative-controlled** — renaming `helm` to
`hemlet` in one scene makes it fail and name the file.

It also asserts the scan is still finding things, because a regex that quietly
stops matching turns the check into a check that nothing is wrong with nothing.

### What is not done

**The hint bar is built and called from nowhere.** `UiKit.hints()` works; it
landed on top of the clubhouse action row, because no screen reserves the 26
pixels a footer needs. That is a layout pass across sixteen screens, not a call,
and it is recorded rather than bodged in.

Six of the 34 marks could stand another pass. The window notch is on one panel
so far. And the type is still `ThemeDB.fallback_font` everywhere but the buttons,
which remains the gating job.

---

## 52 — Formatting, and the four-pixel tax nobody was charged for (13 Sep 2026)

Pete: *"Some of the formatting is bad, the New Names on free agents is over
another thing. Go through and make sure formatting looks good."*

### It was not that button. It was every button.

§50 gave panels and buttons a four-pixel drop shadow and drew it **outside** the
rect the caller asked for. So every control in the game silently became four
pixels wider and four taller than the space its screen had allocated, and
sixteen screens laid out flush against each other years of decisions ago all
began overlapping by exactly four. One of them happened to be visible enough to
notice.

Two ways out: add four pixels of gap to every layout by hand, or make the drop
fit in the space already given. The second is one edit and it is also the
correct model — **the rect you ask for is the space you occupy**, which is how a
sprite behaves and what every caller already assumed. The panel body shrinks by
the drop and the drop fills what it gave up; the button control shrinks the same
way. No layout moved.

### Then the sweep found three more, and only one of them was new

**"Roster" was sitting on the HONORS tab.** At y=70 with the tab strip at 72,
it covered the right 112 pixels of the fifth tab — so on the SQUAD tab the label
read HONORS and the tap opened the roster. Shipped, invisible.

**"The draw" was doing the same thing**, and its own comment explains why: it had
been moved *out* of the action row because at National the table runs to sixteen
clubs and it was hiding a relegation place. It traded a visible fault for an
invisible one.

**The team sheet had two column collisions at once.** The wage, right-aligned
into a 90-pixel box, ran back through the AGE column; the rating, right-aligned
into a 60-pixel box, ran back through the CONTRACT YEARS. On screen it read as
`$3 2` with a rating printed through the middle of it. Nine fields in 446 pixels
with nine magic numbers scattered through the drawing.

### And a fourth, underneath the third

`UiKit.clip()` cuts at a **character count**, which is the right tool for a
monospaced face and meaningless for a proportional one: "Wexley" and "MMMMMM"
are the same six characters and forty pixels apart. Names were clipped at 13
characters into a 138-pixel column, so most fitted and a wide one walked into the
position. Exactly the same shape of mistake as the font that advanced every
glyph the full cell.

`UiKit.fit()` measures instead. It takes the pixel budget and returns the longest
prefix that fits in it.

### What the checks are, and why each one exists

`test_layout.gd`, and every check in it is a bug that actually happened:

- **a button paints the rect it was given** — the four-pixel tax, asserted
  against `DROP_PX` rather than against 4, so deepening the drop cannot make the
  check quietly mean something else.
- **no control sits on another** — 147 controls across 19 pages, every tab of
  the season screen driven rather than only the default one, which is how the
  Roster button was found.
- **nothing runs off the edge**, and **every control is big enough to press** —
  a zero-width control looks exactly like a control that is not there.
- **no two columns on the team sheet touch** — `squad_columns()` hands the stops
  back measured in the font the screen is really using, against the widest string
  each field can produce.
- **nothing stands on the tab strip** — a REGION, not a state. Two buttons have
  now been parked there and the second only appears in a game state the sweep
  does not set up; declaring the strip off-limits catches whatever lands on it,
  however it got there.

### The two things that made it worth writing

**The first version could not see the bug it was written for.** It compared
`Rect2(position, size)` — and with the drop-shadow fault deliberately
reintroduced it still passed, because the shadow is not part of a control's
size. Every rect is now inflated by the drop, which is what the player actually
sees.

**Every check is negative-controlled.** Reintroducing the shadow fault fails the
footprint check; putting the Roster button back at y=70 fails both the overlap
sweep and the strip guard. A check that has never been seen to fail is a rumour.

### Two more, found by rendering

The mood ribbon was **20 pixels tall** and started at y=520; the action row ends
at 522 with its drop. Two pixels of gold under every button on a cup night —
nobody would have called it a bug and everybody would have seen it. Sixteen now.

And the Kenney crest was drawn flush around the clubhouse menu, so its 24-pixel
corner brackets landed **on** the buttons. The frame keeps the full span and the
buttons step inside it.

### Suite

**301 of 301**, twenty-five files. `test_layout.gd` is the twenty-fifth.

---

## 53 — Ten pixels, and what they uncovered (13 Sep 2026)

Pete: *"Bring the icons right a little bit, you can see they're all on the left
line of every button and things."*

He is right and the cause was an omission rather than a choice: the button style
boxes never set a **content margin** at all, so Godot used none. Every mark was
placed at the left edge of the content box, which is the inside of the
three-pixel frame, which is touching it. A mark hard against a rule reads as
part of the rule.

Ten pixels, in one constant. Then the ten pixels broke two things and both were
already wrong.

### A Button's size is a floor, not a ceiling

This is the part worth remembering. **Godot raises a Button's `size` to whatever
its contents need** — it does not clip. So a label that outgrows its box does
not truncate, the box grows and shoves itself into whatever is beside it.

`FORMATIONS` on the chalkboard was 124 pixels and fitted only because its
contents sat flush against the frame. With padding it needed 136, grew, and ran
ten pixels into `PLAYS`. The overlap sweep caught that one because the neighbor
was another control — so a new check names the **button** rather than the
collision, which is the difference between a fix and a hunt.

### And the padding had to give way before the label did

The three regime buttons under a captain are a third of a card wide. At full
padding "Normal" needed 72 pixels in a 68-pixel box, grew, ate its own gap, and
had its last letter drawn over by "Hard" — so it read as **"Norma"**, which
looks exactly like text clipping and is the one thing it was not.

`ICON_PAD` is now a **maximum**. Every button gets the full inset if its label
leaves room and as much as it can afford otherwise, so a label is never squeezed
to make space for its own margin. The three regime buttons are also packed by
their natural widths now instead of equal thirds: 192 pixels of content in a
204-pixel row, which is the only reason they fit at all.

### The check had never seen the screen

The worst finding. `test_layout.gd` opened every screen against a brand-new
season — which has **no captains hired** — so the staff screen's `_build()`
returned before making a single button, and the audit reported a clean sweep of
a blank page. Those three buttons had been clipping the whole time on a screen
the check was counting as green.

**Anything a screen only draws in a particular state has to be put into the
state**, or the check is measuring the empty case and calling it passed. The
audit's world now hires two captains, sets a regime and carries credits. It went
from 140 controls to 147 across 19 pages, and found the bug in the seven.

That is the third distinct way this suite has managed to be green about nothing:
a scan that stopped matching (§51), a rect that did not include the thing it was
looking for (§52), and now a screen that built nothing to look at.

### Suite

**302 of 302**, twenty-five files. `test_layout.gd` is at nine checks.

---

## 54 — The fight was not in any of it (13 Sep 2026)

Pete: *"Alright, I'm not seeing the arena/fighting UI in this."*

He was right twice over. The melee was not in the contact sheets — the panel
labelled ARENA in every one of them is the **ground upgrade screen**, not the
fight — and it was not in `test_layout.gd` either. The one screen in this game
with a clock running on it had never been measured.

### Three screens wearing one scene

`Melee.tscn` builds the formation picker before the bout, the corner between
rounds, and the report after it, and **only the first is up when the scene
opens**. Adding the path to the sweep found three more controls; driving the
three panels found seventeen. The audit is at 167 controls across 22 pages.

Same lesson as the staff screen in §53, twice in two days: a panel that only
exists in one phase is a panel the check never sees. `_pages()` now carries a
method to call after the scene settles, so a page is a *state* rather than a
file.

### What was actually wrong with it

**Every button in the fight was a raw `Button.new()`.** Five of them, never
touched, so the formation picker, the corner and the report wore **Godot's
default theme** — gray rounded rectangles with a soft gradient — while every
other screen in the game wore the game's. It also meant no tap sound in the one
place a player taps under time pressure.

**And the panels had no floor.** There was a scrim behind them and nothing else,
so the formation picker and the corner were read *through the fight*: the grid,
the men and the route marks all sat behind the words at 34% strength while a
player with a clock running tried to pick a shape. It is the least readable
thing in the game and it was on the two screens with a timer on them.

An opaque panel now sits under the box, derived from the container's own rect
because the corner's height changes with how many men are on the bench — the
report panel learned that lesson the expensive way in §13 and this is the same
fix applied to its neighbor.

### The number never gives way

Putting the game's own face on those buttons made them wider, and the corner's
five man-buttons started clipping: **"Ward 100"** for a man on 100%.

Fitting the whole string was worse — `UiKit.fit` produced "Vance 100." and
"Kerrigan.", which is a condition figure truncated into a *different* condition
figure, or into none at all, on the one screen where that number is the whole
decision.

So the number's width is reserved first and only the name is measured into what
is left. **A shortened name is a cosmetic loss; a shortened percentage is a
lie.** The panel also went from 620 wide to 720, because at 620 there was not
enough room for either.

### And the check that could not see it

`no button is smaller than what is in it` compares a control against its own
minimum size — and a button with `clip_text` reports a minimum that **does not
include the text it is about to cut off**. The corner sets `clip_text` on every
man, so it sailed through that check the entire time it was printing "Ward 100".

A clipping button is a legitimate thing to build; not knowing when it clips is
not. `no button clips its own text` measures every line of every clipping button
against the room it actually has — twelve of them — and it is
negative-controlled: padding a name out fails it with the string and the two
widths.

My first attempt at that control was itself wrong. Narrowing the panel did not
trip it, because the fit derives its budget from the panel width and simply
shortened the names further. That tested the fix, not the check.

### Suite

**303 of 303**, twenty-five files. `test_layout.gd` is at ten checks.

---

## §55 — the grade, and the measurement that overturned the reading

*13 Sep 2026.*

Pete, on fight pacing: *"There can be difficulty mode, and the enemy tiers are
the leagues and the team overall numbers. Stats hold that. The difficulties can
just be slight x1.05 or x.95 to what their overalls mean. Then if you have
Easy/Medium/Hard, you can add in +1,Normal,-1 tactical pauses. I think you should
be able to upgrade through either a rare coaching trait or facility upgrade. Not
speed controls, but you should be able to speed skip a round at a time."*

I had argued against a difficulty mode, citing a comment in `melee_sim.gd` about
AI behavior tiers as though it ruled out a global multiplier. It does not: the
leagues are how good the opposition **is**, and a difficulty mode is what its
numbers **mean**. Those are orthogonal, and Total War ships them as two separate
settings for exactly that reason.

### The survey, and the one I missed

Five games, for calibration: Total War (AI melee attack ×1.10 on Hard, ×1.15 on
Very Hard, melee defense ×1.20), Civ VI (+4 combat strength at Deity, but the
real load carried by +80% production and five free Warriors), XCOM 2 (hidden ×1.2
on the *player's* shots at Rookie, and a Legend tier whose defining feature is
that the lying stops), Fire Emblem (+4 to +16 hidden levels on every enemy), Slay
the Spire (twenty Ascension levels, only six of them stat multipliers).

Pete: **"You missed Retro Bowl, which has a literal difficulty setting."** He was
right, it is the reference game, and the decompile was in the scratchpad. The
teardown is in `claude/retro-bowl-teardown.md` Part 2. The architecture it
revealed is the one I had already argued for on other grounds — one signed
scalar, derived once from the setting at kickoff, read in thirty-seven places
downstream, with nothing reading the setting itself.

### The choke point had a hole in it before the grade arrived

`Man.eff_base()` and `eff_skill()` carried this comment:

> *Everything that reads either one reads these instead, so the penalty cannot be
> forgotten in one formula and applied in another.*

True of base and skill. Meanwhile `card.fighting_strength()`, `card.fighting_gas()`
and `card.tank()` were read straight off the card in **twelve** places. The
comment was accurate about the two stats somebody had thought about and silently
false about the other two — so the grade would have reached two of four contest
stats and been missing from the rest, and nothing in the suite would have said a
word.

There are four accessors now (plus `eff_tank`), they are the only way into a
fighting number, and `test_grade.gd` greps the file and fails on a direct read.
`card.overall()` is exempt in two lines and the exemption is named in the test,
because those are a man **sizing up** an opponent — a judgment, not a contest.
Scaling them would make a Full Steel side braver as well as better, which is a
second difficulty dial hidden inside the first.

The scale arrives as a **constructor argument**, not a field set afterwards:
`_build()` fills every man's tank from `eff_tank()`, so a scale that lands one
line late produces a sim whose men are the right strength and the wrong fitness.

### The measurement overturned the recommendation

I told Pete to raise his numbers — that ×1.05 was a third of what comparable
games spend. Then `tools/probe_grade.gd` ran it, 150 seeded bouts a column:

| ×0.94 | ×0.96 | ×1.00 | ×1.04 | ×1.08 | ×1.16 |
|---|---|---|---|---|---|
| 70.0% | 60.7% | 46.7% | 35.3% | 27.5% | 9.5% |

**His instinct was closer than my survey.** The reason is a property of this sim
that no amount of reading other games would have surfaced: every knob in that
survey moves one stat, or a few separately. Ours multiplies four contest stats at
once, across five men and three rounds, so a six-percent edge is not applied
once — it is applied to every contest in the fight, and it compounds. ×1.16
measured a nine percent win rate. That is not a setting, it is a different game.

Shipped at **×0.96 / ×1.00 / ×1.04**: +14 and −11 points against even.

The probe also puts ×0.97 at 56.7% and ×0.98 at 58.7% — the wrong way round, well
inside the noise at N=150. Steps finer than about two points of multiplier are
not distinguishable from chance, which is what sets `Grade.STEP` and what stopped
`test_grade.gd` asserting a three-way ordering it could never resolve. Its first
draft did, and failed on a run where Full Steel came out seven points *above*
Sanctioned. A test that fails on noise gets re-run until it passes, and then it
is decoration. It measures the two ends now, where the gap clears the noise by a
distance; the ordering of the scales themselves is asserted as arithmetic
elsewhere.

### The names

`Regime` owns Light/Normal/Hard, `AiSkill` owns Rust through Legend, `Mood` owns
Normal through Final and `League.Tier` owns the pyramid. A difficulty called
"Hard" would have been the fourth thing in this codebase wearing a word that
already means something else.

**Matched · Friendly · Sanctioned · Full Steel · The Hard List.**

The dossier is the naming authority per `world.md`, and `C:\Dev\HedgeKnight` is
not a connected folder — the access dialog timed out twice. These come off the
vocabulary already in the repo instead and are one dict to change.

### The two halves, and the smaller number is the bigger half

A pure multiplier is the flattest difficulty knob there is. Slay the Spire's
twenty levels are only six multipliers; Retro Bowl's Extreme shares its scalar
with Hard and gets all its extra bite from rules. So the grade also moves the two
things a corner is for:

- **Calls from the corner** — +1 / 0 / −1 on a base of two. A call stops the
  fight for one order or six seconds, whichever comes first. Not a round-clock
  cost: the clock is trivial to charge and the wrong currency, because nobody can
  judge what four seconds of a hundred and twenty is worth while deciding.
- **The corner itself** — 24s / 20s / 16s. The difference between two swaps and
  one.

The hold gates the same accumulator the hit-pause does, so the ticks owed are
still owed when the fight restarts. A hold that dropped ticks would be a
difficulty setting pretending to be a control.

### The Hard List

Retro Bowl's Extreme pins opponents to the top of the *game's* scale. Ours pins
to the top of **that club's own division** — the pyramid is the first difficulty
layer and flattening it would delete it. Two corrections found by testing it:

- It floored at 1.0, so a club already at its division ceiling — and a Worlds
  guest rated 90 against National's 86 — came out **softer than Full Steel**. It
  is Full Steel *plus* a rule, so it takes whichever is worse for you.
- A Worlds guest has tier −1, which clamped to Backyard's ceiling of 46 and
  exempted the best clubs in the game. Guests take the top of the pyramid.
- Capped at ×1.08, because the uncapped rule reached ×1.16 on a weak State club.

### Matched

I argued against adaptive difficulty on the grounds that a career is a ledger.
Wrong, and Retro Bowl is the proof: a career game with a permanent record that
ships adaptive as the *first* option. The difference from Resident Evil 4's
hidden 1–10 rank is not the mechanism — it is that theirs is a named setting the
player chose and the options screen describes. **Hidden is the problem; adaptive
is not.**

Ours reads margin (a 2–0 hardens twice as fast as a 2–1), starts on the easy side
of even, and **will not climb past its unproven cap until the trophy cabinet has
something in it** — their `ACH_WIN_MAJOR_SUB` gate, in our nouns.

### Tactician, not a facility

Pete offered a rare coaching trait *or* a facility upgrade. It is the trait. The
facility list was cut to two on purpose — *"two facilities feeding the same gate,
with no way to reason about which to spend on"* — and adding a third walks that
back; facilities are bought with credits, and a call you can buy is a call every
player has by season three. A trait makes it a hire: a four-star Tactician
against a three-star Physio whose men never gas.

Where it bends the reach rule, said out loud: every other trait applies only to
the roles its captain covers, and a call from the corner is not addressed to a
role. The clause that survives is the load-bearing one — `has_trait` already
refuses a captain with no specialties, so a one-star Tactician is worth nothing,
exactly like a one-star Physio. Roughly one offer in fifteen carries him.

### Skip round

Retro Bowl's `btn_skip_time` sets a flag, pushes commentary along, and **destroys
its own button**; `s_check_skip_time_button` refuses to re-create it while a skip
runs. Ours needs neither flag nor destroy: `skip_round()` returns with the sim in
CORNER or OVER, and `_sync_controls` shows the button only during a live round —
so it takes itself off the screen by the same rule that put it there.

It stops at the corner rather than the end of the bout, because the corner is a
decision point and skipping past it would spend your swaps for you. And it is the
**same `tick()` loop** the screen runs. That is the entire design: a skip through
a cheaper path would be a different fight, and the player would have no way of
knowing which of his results came from which. Five seeds, watched against
skipped, every man's state and position identical — and the moment somebody
optimises `skip_round` into something faster, that fails.

Skipping hands your clinch calls to the AI, so a skipped round is marginally
worse for you than a played one. That is the honest trade and the reason it is
not a difficulty lever in disguise.

### A third tab, because a button in a gap was a button on the badge

The grade went on the Create screen's club tab first, at (24, 310). The club
badge is drawn centerd at (116, 372) with a radius of 54 — spanning y 318 to 426.
The button sat on top of it. `test_layout.gd` would have caught it; reading the
numbers caught it first.

It wants the room anyway. This is the screen where a player picks how hard twenty
seasons are going to be, and five options each need a sentence. The panel prints
the multiplier, the call count and the corner length outright — this game puts a
two-digit overall next to every name on four screens, and a setting that quietly
changed what those numbers mean without saying so is the XCOM problem, which at
least does not print a stat line.

### The version did not move

A version 12 career is, by construction, a career fought at Sanctioned — that is
the only grade the build that wrote it had. It decodes into exactly what it was.
A version bump exists to refuse a file that would come back **wrong**, and
bumping would have thrown away Pete's saves to record a fact the default already
states. Same argument as the trials and goodwill removal. `matched_step` is
clamped on the way in, because its range narrowed once the win rates were
measured.

### Suite

**335 of 335**, twenty-six files. `test_grade.gd` is new, at thirty-two checks.

---

## §56 — the book

*13 Sep 2026.*

Pete: *"The 'How are we coming out' should just be a formation and strategy
playbook. Think Madden. Then you have it between every round as well."*

### What was wrong with two panels

The fight asked one question in two places. `_show_formation_panel` put up the
three formations, and picking one chained straight into `_build_corner`, which
carried the four strategies at the bottom under the line and the bench. So the
two halves of a single call were split across two screens — and only the
strategy half was ever asked again. **You could change your mind between rounds
about how hard to push, and never about the shape you pushed in.**

That is exactly the wrong way round. The shape is the thing the round you just
lost was telling you about.

### One page, twelve cells

A row per formation, the four strategies across it, one tap calls both. Twelve
cells is a page you read rather than a menu you walk, and it is the Madden
playcall shape: the formation names the group, the cells under it are what you
can run out of it.

It is one tap and not the real playbook's two, and the corner clock is the
reason. Formation-then-play is better browsing; between rounds you are not
browsing.

The call you are already running is lit in gold — the honest default between
rounds is "same again", and a player should be able to see what that is without
having to remember it.

### Your own shape is a row

`Season.begin_bout` hands the sim the Chalkboard's shape as `custom_spots[0]`,
and `formation_spots` returns custom spots over a named formation whenever it has
them. So the moment the book offers "2-1-2" as something you can tap, picking it
has to **clear** the drawn shape or the fight quietly keeps running the drawn one
— the ordering trap `set_plan` already has a paragraph about.

And once cleared it is gone, which would make the Chalkboard a **one-way door**:
pick a named formation in round one and your own board is unreachable for the
rest of the afternoon. It is stashed on the scene at the start of the bout and
appears as a fourth row, "Your shape" — which is what a custom formation *is* in
a Madden playbook, and it keeps the Chalkboard worth opening.

### The book comes up every bout now

It used to skip the panel entirely whenever the clubhouse had set a shape, on the
reasoning that the question had been answered upstairs. The question it was
asking — *how are we coming out* — genuinely had been. The book asks a different
one: what are we running, right now. That is not a property of the club, it is a
property of the next ninety seconds. You call a play before the snap whether or
not you wrote the playbook.

The pre-fight panel is the book **and nothing else**. It used to chain into the
corner, which meant a swap screen before a round nobody had fought yet.

### The clip, and the check that caught it

At 138 a cell has 118 pixels inside its frame and its padding. "Turtle right"
wants 122. All twelve cells rendered "Turtle righ", in the panel that decides the
fight.

`test_layout.gd` failed it and printed both numbers — which is the entire reason
§53 built that check, and the first time it has caught something I wrote after it
rather than before. Cells are 148 now: 96 + 6 + 4×148 + 3×6 = 712 in a 720 panel.

### A fourth page for the sweep

The book is three rows standalone and **four in a season bout**, and the corner
is already sharing its panel with the line, the bench and the swap note. The
tallest version of a panel is the one that runs off the bottom, and it was the
only one the sweep could not see — `MELEE_PANELS` drives a drawn shape onto the
sim and opens the corner now. 217 controls across 23 pages.

### Suite

**335 of 335**, twenty-six files. `test_layout.gd` holds at ten checks over a
twenty-third page.

---

## §57 — a real playbook

*13 Sep 2026.*

Pete, with a Backyard Football playbook page: *"I feel like we can do a real
playbook."* Then, on the mockups: *"Playbook 2, and make it scrollable for the
custom formations and plays."*

### The plays were already in the data

§56's book was a grid of words, and that was the ceiling I had assumed rather
than measured. Looking at their screen is what made it obvious: **a formation is
five spots, a strategy is a depth profile plus an optional lane, and
`Tuning.plan_target` already resolves the pair into a destination per man.** A
drawn play is five routes in the same coordinates.

So a play card is not an illustration somebody has to draw and then keep in step
with the sim. It is the sim's own numbers, plotted. Change a push value in
`tuning.gd` and every card in the game redraws correctly, including the ones
nobody has looked at since. `scripts/game/playbook.gd` is 180 lines and it is the
highest-value-per-line thing built this week.

The diagrams carry real information at a glance: Rush is a staggered echelon,
Turtle visibly converges on a rail, Depth pulls the Center back off the line.

### The axes match the fight

`melee_scene._to_screen` is `ORIGIN + Vector2(v.y, v.x) * SCALE` — push runs
across the screen, lane runs down it, lane 0 at the top. The cards do exactly
that. A card drawn the other way up would have been the only place in the game
where the fight points somewhere else, and it would have taught it to every
player before they ever saw a list.

### Two panes, both scrolling

Shapes down the left, what you can run out of the selected shape on the right.
Both scroll, and both have to: `Chalkboard` sells four formation slots and four
play slots, so a club that has bought them all brings **seven shapes and eight
calls** to this screen. A fixed grid would be a screen that silently stops
showing you things you paid for — which is the worst version of this bug,
because the credits are already gone.

The right pane is two sections, and they are two different things wearing the
same card. A **push** is a depth profile that runs all round. A **play** is five
drawn routes that fire at the charge and expire after `PLAN_TIME`, after which
the push is what the anchors read. They are not alternatives in the sim —
`set_plan` takes spots *and* routes and `strategies[team]` is live either way —
so calling a play keeps the push you are already on. `test_book.gd` asserts it,
because a play that quietly reset the push would turn every drawn call into Rush
left.

### Three things that had to be got right

**The card is one body behind two doors.** `card()` draws a panel then the face;
`card_face()` draws the face onto something that already has one, which a Button
does. It was two functions with the same forty lines for about a minute — the
exact fault this codebase has a house rule about, and a drawing duplicated at two
call sites is a card that starts rendering differently on the screen nobody is
looking at.

**The diagram is a child Control, not an override.** A Button paints its StyleBox
from `_notification`, so a script `_draw` on the same node is a race with the
engine that happens to come out right today. A child draws after its parent,
always. It also keeps the layout sweep honest without special-casing, since the
sweep collects Buttons, LineEdits and Sliders and a decorative Control is
invisible to it.

**The panes have to be told to stop growing.** A ScrollContainer recomputes its
minimum size when a child arrives, so a size set *before* the column went in was
immediately overridden by the column's own height — the pane grew to fit its
contents, which is the one thing a scroll pane must never do. And a plain Control
does not clip, so the cards that no longer fitted drew straight through the panel
floor and out the bottom of the frame. Size after the content is in, and
`clip_contents` on both.

### The sweep had to learn what a window is for

The book is the first thing in this game where *where a control is* and *where a
control is drawn* are different questions. The fifth shape card in a pane that
shows three has a global position four hundred pixels below the bottom of the
screen — and it is not off the edge, it is **next**.

`_seen()` returns the intersection of a control's rect with its scrolling
ancestor's visible rect; a control scrolled entirely out is dropped, and a
half-cut one is measured at the part you can actually see. The first version
answered yes-or-no and then measured the full rect, which still failed on the
half-card the pane was cutting.

Negative-controlled by moving `panel_box` to y 420: the edge check goes red, so
teaching it about scrolling did not blind it.

### 176 and not 196

At 196 the corner panel ran to y 530 of a 540 frame. Inside the edge, so the
sweep passed it — and close enough to it that the half-card the scroll was
cutting read as the screen running out rather than as a list continuing. A cut
card wants somewhere to be cut.

The cards themselves do **not** shrink in the corner. A card that gets smaller
under a clock is a diagram you can read everywhere except the one place you need
to. The pane gives way instead; that is what having one is for.

### The book is the first screen that reads the club's own content

Every other panel in the fight is built out of constants — five slots, four
strategies, three formations — and is therefore identical on every save. This one
lists what the club has bought and drawn, so it is the first screen that can be
wrong in a way only a particular save file shows: a formation slot unlocked and
not listed, a play tied to one shape appearing under another, a drawn shape
lighting up as live while the men stand in a built-in.

None of that is visible in a screenshot of a fresh season, which is the state
every other check in the suite opens the game in. `test_book.gd` builds a club
that has bought its slots and used them.

Its own fixture caught the point on the first run: the Wedge had Flankers at 16%
and a Center at 22%, `formation_legal` refused it correctly, and the test
reported "the book lists three shapes" — a bad fixture wearing a failed
assertion's clothes.

### Suite

**346 of 346**, twenty-seven files. `test_book.gd` is new, at eleven checks.

---

## §58 — fighter traits, and a gate built out of the Scout

*13 Sep 2026.*

Pete asked for a big list, some of it derived from Retro Bowl, and picked fifty
of fifty-two — Heavy Legs and Mercenary left on the shelf. Forty-one are wired
now; nine are held out of the roll.

### What Retro Bowl actually had

**Their mechanical trait list is the coach one, and we took it a week ago.**
`coachtrait_0..9` is where Experience, Talent Spotter, Motivator, Negotiator,
Fan Favorite, Physio, Likeable, Positive and Scout came from.

Their *player* traits are not in the build we decompiled. `s_get_random_trait`
reads a list out of a `Traits_CO.txt` we do not have, and of the three functions
that touch it every one only ever fetches `"name"`. It sits directly beside
`s_get_random_hometown` and is rolled the same way. **On that evidence their
player traits are biography, not mechanics** — so nothing here is copied from a
list, and saying otherwise would have been inventing a source.

What *is* derived is the shape of the coach traits, and four are worth having:

- an **arrival one-shot** that fires once and is done — LATE_BLOOMER
- a **per-week multiplier** rather than a flat bonus — SPONGE, KIT_MINDER
- a **negation** instead of a bonus; *"toxic players have no negative impact"*
  is a better trait than "+5 morale" — THICK_SKIN
- **a cost when he leaves**, which almost nobody copies and which turns a good
  trait into a decision — TALISMAN, still pending

### One table, not forty-one `if` statements

Every wired trait is a row of named effects in `FighterTrait.MOD`, and every call
site asks the same question: `FighterTrait.mod(card.trait_id, "grapple_grind", 1.0)`.
Multipliers default to 1.0 and additions to 0.0, so a man with no trait costs a
branch and nothing else.

The alternative — `if t == T.GRINDER` at twenty call sites — is the shape that
produced the Scout. **Forty-one traits is forty-one chances to do that again.**

### The gate, in three different kinds of check

`test_traits.gd`, 25 checks, and the three gates are deliberately not the same
kind of thing:

1. **Bookkeeping.** Every trait is in `MOD` or in `PENDING`, never both, never
   neither, and no wired trait has an empty row. The state that produced the
   Scout — in the enum, in the roll, wired nowhere — is now unrepresentable.
2. **The grep.** Every effect key in `MOD` is read somewhere in `scripts/`
   outside the trait file. This is the one that would have caught the Scout, and
   it is the one that caught something on its first run.
3. **The measurement.** For each wired trait, build the number it claims to move
   with the trait and without it on two otherwise identical men, and assert it
   moved in the direction claimed. This catches a key that is read into a
   variable nobody uses — which the grep cannot see.

### It failed twice on the first run, and both were real

**`plan_extra` was read nowhere.** ROUTE_RUNNER had a row, a blurb, a weight and
a card, and not one line of code. That is the Scout exactly, eleven days later,
caught in under a minute by gate 2 instead of by a player six months out.

Wiring it needed a change worth recording: `plan_t[t] = maxf(0.0, plan_t[t] - TICK)`
floored the plan clock at zero, **throwing away the one number a man who holds
his route longer needs** — how long ago the side stopped following it. The clock
runs negative now; `_plan_live` reads `> 0.0` either way, so nothing else
noticed.

**Firestarter did not chip**, and that one was the test's fault rather than the
code's. `angry()` is `morale < 0.34` — the band *above* toxic — and the check had
set both men to 0.95, comparing two contented fighters. A check that cannot fail
cannot pass either. Fixed to 0.25, and it then measured 71 against 66.

### Where the interesting ones landed

**BEAR and ANCHOR are one number from opposite sides** — `td_for` and
`td_against` both add into `_takedown_chance`, so a Bear against an Anchor is a
wash, which is the fight worth watching. POISON and THICK_SKIN are the same shape
in the morale sum: a club can field both and have them cancel.

**COLD_HANDS drops the AI tier** rather than nudging a number. The tiers are
already this game's model of how well a man decides; a flaw that invented a
second scale for the same question would be two models of one thing and one of
them would rot. It costs nothing while you answer his prompts yourself — he is a
man you have to watch, which is the whole trade.

**LANE_RUNNER is checked in one place.** `_out_of_pos` is the only opinion about
whether a man is standing wrong, because `out_of_pos` reaches every formula
through `_pen()` and a second opinion would be a man penalised in one calculation
and not another. The test asserts he is forgiven one slot and *not* two — without
that second half the trait is just "no penalty".

**LOYAL is not a probability.** He is skipped as a candidate in `who_walks`
entirely, because the value of the trait is knowing, in the summer the club
fractures, exactly who will still be there. A probability gives you a man who is
probably loyal, which is nobody.

**The sim is told what day it is.** BIG_OCCASION and FLAT_TRACK read
`sim.big_occasion`, set by the season from the bout mood — the sim does not reach
into `Session`, because a sim that does is a sim the tests cannot build, and
every balance figure in this project came out of a sim the tests built.

### The nine that are pending

WRESTLER, SECOND_WIND, LAST_MAN, PROUD, TALISMAN, PRIMA_DONNA, HOMESICK, GRUDGE,
HEAVY_HANDS. Each needs something the sim does not have — a grapple that can open
ahead, a man who can refuse a swap, a club id remembered on a fighter.

They are in the enum with names and blurbs and they will show correctly the day
they are wired. **Until then no fighter in the country has one**, because
`roll()` skips `PENDING` and a test asserts it over twenty thousand rolls. A
trait that does nothing is worse on a card than no trait at all.

### The version did not move

A save from before traits is a squad of ordinary men, which is exactly what it
was. `trait_id` defaults to `NONE` and nothing decodes wrong. Same argument as the
grade.

### Suite

**371 of 371**, twenty-eight files. `test_traits.gd` is new, at twenty-five
checks.

---

## §59 — levelling, and a port that had to be corrected to work

*13 Sep 2026.*

Pete: *"Let's rework the Levels. Winter shouldn't be the only time you can gain
levels. Go see how Retro Bowl does it."*

### How they do it

`s_has_xp_gain` is the whole model in one line:

```js
if (round(xp + xp_gain) < xp_level * 100) return false;
return true;
```

A player carries `xp`, a pending `xp_gain` from the last game, and an
`xp_level`. The bar is **his level times a hundred**, and it is checked whenever
the card is looked at rather than at a season boundary. The crossing, on the
player screen, is an animated drain — one point at a time — and on the level:

```js
xp = 1;  xp_level += 1;  attitude = clamp(attitude + 10, 1, 100);
```

Three things worth taking. The bar is **linear in the level**, which is a
decelerating curve with no table to maintain. The remainder is **not carried**,
so one enormous afternoon cannot buy two levels. And **levelling up lifts his
mood** — we did not have that, and it is the cheapest good idea in their whole
progression.

There is also a **paid** path: `msg_MeetingLevelUp1/2/3` offers extra reps, game
film, or an afternoon with a hall of famer, priced by
`s_get_meeting_cost_levelup` at `xp_level * 4` credits. And a refusal —
`msg_MeetingLevelUpNotNeeded: "$playername has reached his potential."`

### Ported literally, it breaks

`level * 100` works for them because **their XP income grows with production**: a
better player gains more yards and scores more, so he earns faster as the bar
rises. Ours does not. `xp_for` pays the same 2 + 3 a down + 1 a round standing in
season ten as in season one.

`tools/probe_levels.gd` measured the port against the winter it was replacing:

| | levels over 8 seasons | overall |
|---|---|---|
| the winter it replaces | 47 points | 50 → 61 |
| `level * 40`, uncapped | 6 | 50 → 51 |
| `level * 10`, uncapped | 14 | 50 → 53 |
| **`min(level, 3) * 8`** | **48** | **50 → 61** |

An unbounded bar walls a career at three points of overall. So the bar rises and
then **stops** — which is exactly what `XP_PER_POINT` already did: `[8, 12, 18,
26, 40]` and flat at 40 forever. The cap is not a fudge to hit a number; it is
the same admission that constant income needs a constant bar, made twice in one
file by two different people.

8, then 16, then 24 and 24 and 24. `test_traits.gd` asserts the eight-season
climb rather than the constant, so the tuning can move without the check
becoming a lie.

### Two other places their numbers do not transfer

**The mood lift.** +10 on a 1-100 attitude looks like a tenth of our morale, but
their levels are rare and our capped bar makes them frequent — six a season for a
man who plays. At 0.10 a level the probe had a fighter at **0.96 morale by his
fourth season**, which is not a happy man, it is a broken meter: nothing else in
the club could move him after that. A twentieth instead, 0.03.

**The price of a bought level.** Theirs reads the level because theirs *is* the
bar. Ours reads the **bar**, because a capped bar means the level keeps counting
long after the difficulty stops — a man is level 25 in his fourth season here and
would have cost 50 credits against a facility that costs 11.

### What was kept and what was dropped

The remainder **is** carried, and `drain` takes **one level a bout** instead.
Same intent as their `xp = 1` — a monstrous afternoon must not buy two — stated
where it costs nothing. At their income the rounding is invisible; at ours an
event is worth eleven against a bar of twenty-four, and discarding it would bin
something like a fifth of everything every man earns.

The point itself still goes through `_raise_one`, which the winter and the
training ground also use. A second opinion about which stat grows would be two
models of a career and one of them would rot.

### What the winter is for now

Ageing, the decline, and the **training ground's** allocation — the club's
investment. What left is XP being spendable only in the summer, which is what
made a man's earned afternoons sit in a drawer for nine months. `fell` still
reaches `_raise_one`, so a ground point can still hold back a loss the winter
just took; that was always the interesting half.

### The report, third time

Pete, twice: *"This is still heavily messed up."* It was. Two faults:

**The table columns collided.** Press Start 2P is a wide face — a character is
about the point size — and "AT HIS CEILING" right-aligned in a column 90px from
the one before it reached back 126 pixels and printed through the XP figure:
`+10AT THE4WINTER`. Every cell is a **short token** now, and the widest is
measured: `PEAK`, `LEVEL UP`, `19/24`.

**The news cards showed half a message.** 46 pixels tall with one line of body
and an ellipsis where the rest went. A notification that shows half a sentence is
worse than none, because the reader has to go somewhere else to find out what it
said. Taller cards, two lines, and every line rewritten to fit two — and the
filler went with it. *"Dues paid to the end of the season"* and *"Third, two off
the promotion places"* were cards that taught the player to skim.

### Suite

**380 of 380**, twenty-eight files. `test_traits.gd` is at thirty-four checks.

---

## §60 — a level you spend, and a negotiation about something other than money

*13 Sep 2026.*

Three things from Pete, and the first two turn out to be one idea.

### A level is his to spend, not the game's to allocate

*"Players should be able to upgrade fighters stats anytime the +1 level/level up
is available."*

§59 shipped an automatic level: `drain` called `_raise_one`, which takes the
**lowest stat under its peak**. That is a sensible default and a terrible
decision to take away from somebody — it means **a club can never build a
specialist**, because every point a man earns goes into whatever he is worst at.
A Rail you were deliberately making into a wall spends his career being made
slightly less bad at skill.

`Career.level_into(f, stat)` is the player's door and `level_up` is the club's.
They share `_took` — the bar, the count and the mood lift are one body, because a
level taken by the player and one taken by the club have to cost and pay exactly
the same. `_raise_one` stays and is still right where it is used: the winter's
**training ground** allocation is the club spending its own money on him, and the
club is allowed an opinion.

`raisable(f)` is the list, so a screen can gray a button instead of eating the
tap — a 38-year-old cannot buy his wind back, which was always the winter's rule
and was never visible anywhere.

A bout no longer spends the level. It says one is waiting.

### The rule the levelling economy rests on

*"The overalls and salary costs won't matter until you re-sign the players. So
you may run up a player's level, but you have to make sure you can pay them."*

This already held — `ClubOffice.billed` prefers `wage_agreed` — but it was an
implementation detail until levelling became free and frequent, and now it is
the **only** thing stopping a club levelling its way to a squad it cannot afford.
It is asserted now, and it is the check most likely to be broken by somebody
tidying that function: eight levels take a man from 50 to 52 overall and his bill
stays at $33 a week, and the day the deal ends he asks $50.

If a level ever raised his wage on the spot, levelling would become something a
club could not afford to do, and the feature would quietly delete itself.

### Negotiation, and it is not about money

*"We'll have to build negotiations off the Retro Bowl philosophy."*

Theirs, out of the decompile, is four rules:

| | |
|---|---|
| `s_get_new_salary` | `salary = rating * a per-position rate`. A formula. No offer, no counter-offer, **no haggling.** |
| `attitude <= 45` | `msg_CannotSignMoraleLow` — *"not interested in signing a new contract. His morale is low."* |
| `msg_ContractExpired` | *"He wants a $year year contract with a salary of $salary."* He states terms. |
| `msg_MeetingExtendContract` | extending early costs **credits**, and freezes the salary at today's. |

The core of it is the opposite of what a contract screen usually is: **you cannot
negotiate money. The price is the price. What you are negotiating is whether he
wants to be here at all** — and that was settled over the three seasons before
the conversation, by how you picked him, paid him and spoke about him.

We had `will_wait`, a probability. A probability says *you might get lucky*. A
refusal with a reason says *you did this*, and that is the better half of a
management game. So there is a **floor** now: at or under `MORALE_REFUSES` (0.45,
which is where 45 of 100 lands on our scale, between angry and the flag) he is
gone, and `will_wait` returns zero no matter how big the following is. Above the
line the old maths still decides, because a good man at a small club is still a
risk.

`Contracts.demand(f)` states his terms rather than the club setting them — wage
off what he is worth **today**, and years off his age: a man past 33 wants two
and the security, a younger one wants to get back to the table while he is still
rising.

### Suite

**390 of 390**, twenty-eight files. `test_traits.gd` is at forty-four checks.

---

## §61 — what his mood costs you

*13 Sep 2026.*

Pete: *"For negotiations, have a credit sink to 'negotiate' and raise his morale.
Have morale tie to the salary too. If someone likes it there and doesnt want to
leave, they are more willing to take a lower price. If someone is great but hates
it, you'll have to pay more."*

### The half of a wage that is not about how good he is

`offer()` prices the fighter. `mood_rate()` prices the **relationship**, and they
are deliberately two multiplications rather than one so a screen can show the
player which half of the number he is looking at.

Centerd on 0.70 — where a club starts, and where `will_wait` is already centerd —
so a club that never thinks about morale is neither rewarded nor punished, and a
club that does is doing it for a reason visible on the wage bill. Measured: the
same 72-rated 27-year-old asks **$2.8k glad and $4.3k grim**, a 1.51× spread, off
an identical $3.5k on paper.

Both ends are bounded, and the ceiling matters as much as the floor. Without it a
man one point above refusing outright would name a number no club could meet —
**a refusal wearing a price tag**, which is worse than the refusal, because it
wastes the player's time instead of telling him something.

### The credit sink, and their cost table is the good part

`s_get_meeting_cost_morale` prices a meeting off the man's **attitude band and
nothing else** — not his rating, not his wage:

> Toxic 4 · Bad 3 · Poor 3 · Ok 2 · Good 2 · Great 1 · Exceptional 1

**The worse his mood, the more it costs to move it.** That is the opposite of the
obvious design and it is right twice over: rescuing a ruined relationship should
be expensive and topping up a good one should be cheap, and because it ignores
his rating the price tells you about the relationship rather than about the
asset. A star and a squad man cost the same to sit down with, which is true of
people.

Our seven bands are their seven bands, so the table ported unchanged.

### And the conversation is worth more to the man who needs it

`morale_shift` scales by the room left, so one meeting moves a struggling man
**+0.105** and a contented one **+0.017**. Against a cost table that charges more
for the former, that makes rescuing somebody the better buy — which is the
behavior worth rewarding, and it fell out of two systems that were written
months apart agreeing with each other.

One conversation a week per man, on the same throttle the facilities use. Without
it a club with credits walks a toxic squad to delighted in an afternoon and
morale stops being a consequence of anything.

### Suite

**401 of 401**, twenty-eight files. `test_traits.gd` is at fifty-five checks.

---

## Pass 58 — the doors, and the button that did nothing

13 Sep 2026. *"Let's continue."*

Three systems from the last pass had complete data layers and no way in:
`Career.level_into`, `ClubOffice.negotiate` and `Contracts.demand` were all
callable and nothing called them. That is the Scout inverted — a trait with a
description and no code is a lie told to the player; a system with code and no
door is a lie told to nobody at all, which is worse, because nothing will ever
report it.

Opening those doors turned up something much larger on the way.

### Not one button in this game was connected to anything

`UiKit.button()` ended like this:

```gdscript
	skin(b, clampf((room - need) * 0.5, 2.0, ICON_PAD))
	return b
	## EVERY BUTTON IN THE GAME TICKS, from one line. ...
	b.pressed.connect(func() -> void: Audio.play("tap"))
	b.pressed.connect(on_press)
	return b
```

The tap-sound block was pasted in **after an existing `return b`**. Every screen
in the game built its controls, positioned them, sized them, skinned them — and
dropped the caller's callable on the floor. Back did not go back. Extend did not
extend. Every screen was a picture of itself.

**Four hundred and one checks across twenty-eight files did not see it**, and the
reason is exact and worth keeping. `test_layout.gd` measures a button's rect, its
label, its edges, its overlaps, its hit size, whether it clips its own text —
seven checks on the appearance of a control, and **not one of them ever pressed
one**. A hundred assertions about what a thing looks like say nothing about
whether it works.

So the house rule this pass adds: **a property nothing asserts is a property that
is not true.** It is the sibling of "a rule applied at two call sites is a rule
with a hole in it", and it is the more dangerous of the two, because the hole in
a rule is at least somewhere a reader can go and look.

A sweep of every `return` with live code under it at the same indent, across
every script in the project, found this one and no others.

### Two checks, because there are two ways to be wrong

`a button runs the callable it was built with` is the unit: build one the normal
way, emit `pressed`, count. `every button on every screen does something` is the
sweep: open all sixteen screens, walk every `Button`, assert something is
listening. Either alone passes the bug — the unit would pass a working
`UiKit.button` beside a screen that rolled its own `Button.new()`, and the sweep
would pass a `UiKit.button` that connects a tap sound and nothing else.

The sweep failed seven playbook cards on its first run, and **the check was
wrong, not the cards**. `Playbook.card_button` wires one closure that plays the
tap and then calls the callable; `UiKit.button` wired two separate connections.
Asking for "at least two" was asking about the implementation. `UiKit.button` now
wires the single closure that `card_button` already did, and the check is "is
anything listening" — which is the question.

Ninety-six buttons swept, none deaf.

### The screenshot that proved the empty case

`shot_fighter.gd` gave its man a level and took the picture. The row of `+1`
buttons was not in it — the man it picks is thirty-nine and already at his
potential, so `levels_waiting` was zero and the row never drew.

Under it, unseen: `bw := 168.0`, four buttons from x=24, running **164 pixels
into the meeting button** at x=556.

*A layout you cannot see is a layout you cannot check* has a second half, then:
**a layout you photographed in the state where it does not draw is a layout you
did not photograph.** The shot now ages the man to 26 and lifts his ceiling;
`test_layout.gd`'s `_world()` does the same, which is the fix that matters, since
the sweep had been measuring that screen with five controls missing — the same
blindness as the staff screen with no captains hired, noted in that file eleven
passes ago and repeated anyway.

The width is derived now: `MEET_X - GAP - L_X` divided four ways. A number that
has to agree with another number is a number that will stop agreeing.

### Three states, not two

`levels_waiting > 0` and `raisable` empty is a real man, not an edge case: a
thirty-eight-year-old under his potential is still earning levels and is past the
peak of all four stats, so there is nowhere to put one. The panel said
**A LEVEL IS WAITING** and drew four dead buttons — one function promising what a
second function refuses.

`Career.can_place()` asks both questions in one place. The panel now has a third
thing to say — *past every peak* — and the row does not draw at all.

### What is on the fighter's screen now

A row of `+1 Strength / Base / Skill / Gas`, each grayed when he is past that
stat's peak, so the screen says **why** a man cannot buy his wind back instead of
silently dropping the button — Pete, 13 Sep: *"Players should be able to upgrade
fighters stats anytime the +1 level/level up is available."*

**Asks next — $X/wk · Ny**, tinted by the mood multiplier, or *He will not sign
again* when `Contracts.refuses`. This is the whole reason a level is free today:
the point costs nothing now and shows up in the wage bill in two seasons.

**Sit him down · N CC**, always on the screen, so a club can see what a bad
relationship costs before it becomes a refusal.

### Suite

**404 of 404**, twenty-eight files. `test_layout.gd` is at thirteen.

### The peak stopped being a wall — and then that was the wrong reading

Pete, same day: *"Past peak but still leveling up is fine, just make it harder to
level up past a peak. Good gameplay hook too. Young people learn faster, but old
dogs can still learn new tricks, it just takes them awhile."*

I built it per-stat: each stat priced by its own peak, so a thirty-year-old paid
×1.50 for strength and ×2.50 for gas. It rendered nicely and it was not what he
said. His correction: *"I was talking about how fast he levels as in from Level 5
to level 6, leave the ability to gain all stats still. He's just slower at
leveling his main level is all."*

**One idea, and I turned it into four.** The tell was there in his own sentence
and I read past it — *how fast he levels*, not what he can spend it on. Four
peaks times four stats is the kind of elaboration that looks like rigour from the
inside; his version is one number on one bar, and it is a better hook because a
veteran is not shut out of anything. He is behind a younger man in the only
currency the career layer has, and the club decides whether the wait is worth
what he already is.

### Eight percent a year, either side of twenty-six

| age | rate | |
|---|---|---|
| 19 | ×0.70 | the floor — a kid climbs about a third faster |
| 26 | ×1.00 | par |
| 32 | ×1.48 | |
| 38 | ×1.96 | |
| 39+ | ×2.00 | the cap |

Twenty-six is par because it sits between the tank going (24) and strength
topping out (28) — the last age at which a fighter is improving at everything.
The floor is there because a bar that keeps shrinking makes the nineteen-year-old
the only signing worth making; the cap because past forty the honest statement is
*this is as slow as it gets*.

It stacks with the `xp` trait mod rather than duplicating it: Sponge and Plateaued
scale what a man **earns**, this scales what a level **costs**. A young Sponge
climbs fast twice over, which is what a rare trait on a rare age should do.

`raisable` is the 99 wall and nothing else. Where a level goes is the player's,
at any age.

### The probe was measuring a model the game had stopped running

`probe_levels.gd` hand-rolls `mini(level, cap) * step` in every row — which was
the whole rule when those rows were written and is now half of it. It reported an
unchanged 48 levels for a change that altered every bar in the game, because it
reproduces the formula instead of calling it. **A constant that used to be a fact
becomes a lie the moment the thing it described becomes a choice** — third time
this project has paid for that, and the first time it was a measuring tool
rather than a comment.

The new row calls `next_level_at` and ages the man a year a season:

```
from 19 to 27: 62 levels, overall 50 -> 64, per season [9, 8, 9, 8, 8, 7, 7, 6]
from 22 to 30: 52 levels, overall 50 -> 62, per season [9, 8, 7, 6, 6, 6, 5, 5]
from 26 to 34: 38 levels, overall 50 -> 59, per season [6, 6, 5, 5, 4, 4, 4, 4]
from 30 to 38: 31 levels, overall 50 -> 57, per season [5, 4, 4, 4, 4, 3, 3, 4]
from 34 to 42: 26 levels, overall 50 -> 56, per season [4, 4, 3, 3, 3, 3, 3, 3]
```

The 22-year-old's 52 levels sits beside the winter's measured 47 points, so the
port's baseline survives. And the taper is visible **inside one career** —
9, 8, 7, 6, 6, 6, 5, 5 — which is the hook, arrived at without a second system.

That row uses `level_into` deliberately. Every row above it uses `_raise_one`,
which refuses a stat past its peak, and past 36 that is all four — so an
automatic career printed `0, 0, 0` for reasons that had nothing to do with the
bar being measured. `_raise_one` stays as it is: it is the winter's training
ground, the club spending its own money, and its no-past-peak rule is what
stopped fighters being sanded into 68/68/68/67 by 32.

### What the screen says

`slow to learn` under the xp bar, or `picks it up fast`, and **nothing at all
between ×0.85 and ×1.30** — a label every fighter carries is a label that
distinguishes nobody. The bar itself already holds the fact (`12 / 48 xp` against
a kid's `12 / 17 xp`) but only for a player reading two fighters side by side.
The word says it on one screen.

And the row of `+1` buttons is four live buttons at every age.

### Suite

**410 of 410**. `test_traits.gd` checks the two halves as a pair — the bar is
longer **and** the stat list is identical — because a rule that only holds on one
side of that line is the rule Pete rejected. The two older checks that read
`next_level_at` now pin the age to `LEARN_PAR` first: a check that reads both
terms at once can only ever report "the product changed", which is the one thing
nobody needs telling.

---

## Pass 59 — the assist, and two things the mock shipped that the game did not

13 Sep 2026, continuing.

### Assists did not exist anywhere

Pete specified them in the corner spec — *"minimum stats (Takedowns/Assists)"* —
and again when he defined them: *"Assists can be 2nd most damage or effect on
enemy."* A grep for the word across every script in the project returned one hit,
in a comment about XCOM's aim assist. Not in the sim, not on the card, not on a
screen.

**One funnel, because the ledger is the point.** `_wear(victim, by, amount)` is
now the only way stability comes off a man at an opponent's hands: it subtracts
**and** it files who took it, in one call. Writing it as "subtract here, remember
to log there" is the two-call-sites rule this codebase keeps paying for, so there
is one call and it does both. Two sites feed it — the hit, and the grapple grind.

On a takedown, the top *other* contributor on the victim's ledger takes the
assist, provided his share clears `Tuning.ASSIST_SHARE` (15%). The thrower is
excluded from the credit but **not** from the total, which is the right way
round: the share asks "was this man part of it", and the man who threw it
obviously was. Measured against "everyone but the thrower", the second man in any
two-man takedown would qualify no matter how little he did — which is the
participation count every sport's assist column quietly becomes.

The ledger is wiped when he hits the floor. Without it, one long grapple in round
one pays assists for the rest of the bout.

Measured across five bouts: **30 assists on 63 downs**. Not one per down, which
is the check that says the stat is a stat and not a copy of the downs column with
a different heading.

It shows on the fight strip (right-aligned onto the position line, which has
carried one short word and nothing else since the strip was built, and stays
silent at nought) and in THE BOOK on the fighter screen. It does **not** pay XP —
`xp_for` is unchanged, because the level curve was measured and changing what
feeds it is its own decision with its own probe.

### `quit()` requests an exit, it does not return

`test_assists.gd` printed **THE ASSIST HOLDS (11 checks)** and then failed the
suite. The success branch called `quit(0)` and fell straight through into the
failure print and the closing `quit(1)`, which won.

Every other test file in this project uses if/else. Writing it as an early exit
was not reading them — and it is the same shape as the `return b` above: control
that kept going past where I meant it to stop. Twice in two passes.

### Two things the HTML mock shipped and the engine never did

Both from Pete's fifteen-change list, both done in the mock the same afternoon,
neither carried across:

- **SHAPE → FORMATIONS, OUT OF IT → PLAYS.** The book's column heads still read
  the old words in the built game.
- **"Shape:" on the season screen** is now "Formation:", because a game that
  calls the same thing a shape on one screen and a formation on the next is
  asking the player to hold two names for it. The clip drops 14 to 10 so the
  label is no longer than it was; `test_layout.gd` measures the outcome.

**This is the failure mode a mock has**: it is the version everybody looked at
and signed off, and not the version anybody ships. Worth a standing check — the
mock and the build agreeing is not something either one can assert about itself.

### And the corner still is not the corner Pete specified

Named here because the assist has nowhere to live on it. His spec: *"the 5
starters lined up top to bottom on left side with a (sub) box next to each...
minimum stats (Takedowns/Assists) and if they were downed... their health/stamina
... on the right side you have your four favorited plays."*

What the engine builds is **five buttons across**, position and name and
condition, the bench permanently on screen as a second row, and the full book
underneath. No per-man stats, no SUB boxes, no favorites — there is no
favorites concept in the codebase at all.

The layout and the stats are one job, not two: five across leaves about twelve
characters a man, and a vertical row leaves the width that "2 down · 1 assist"
needs. Not started rather than half-started.

### Suite

**421 across 29 files.** `test_assists.gd` is new at eleven, and its floor check
is written at the boundary — 14% fails, 16% passes — because a floor tested with
a token value is a floor nobody has measured.

---

## Pass 60 — the corner Pete actually specified

13 Sep 2026. *"Drop P1 corner completely, we're going with the between rounds
one."*

### What was dropped

Five buttons across, the bench permanently underneath as a second row, a sentence
about out-of-position, and the whole book below that. It answered *who comes off*
and nothing else — no takedowns, no assists, nobody's energy, no flag on the men
who had been put down. On the screen whose entire job is to report a round.

The reason is arithmetic: five across the panel is about twelve characters a man.
**The layout and the stats were one job, not two.** A row leaves 496 pixels.

### What replaced it

The spec, which has been written down since the playbook pass and was built in
the HTML mock the same afternoon:

- Five men **top to bottom**, each with number, name, position, `TD n` / `AST n`,
  a **DOWNED** flag with a red frame on the row, an energy bar showing what he
  has now and — in a lighter band behind it — what the corner is about to give
  him back, the figures as `8% → 38%`, and his condition **in a word**.
- A **SUB** box beside each man, opening a modal of the bench.
- The **four favorites** two-by-two on the right, **FULL PLAYBOOK** under them,
  the **CHOSEN** strip under that, and **FIGHT**.
- Before round one it is the same screen with a fixture line instead of a score —
  Pete: *"Let's make 'After a round' be the 'Before first round' screen too."*
  The bout used to open straight into the book, which asked the player to call a
  play before being shown one thing about the men who would run it.

### Choosing is not calling

Every card in the game used to apply the plan and leave the corner on the tap.
Now `_choose` stores the pair and `_apply_chosen` is the only thing that touches
the sim — Pete's *"Click Formation - Click Play - Click either Confirm or Cancel
... then hit Fight"*, and also the only order in which a player can look at his
line before committing a plan to it. `_call_from_book` survives as a thin
choose-and-call for the tools and probes that drive the screen from outside.

The corner **seeds** the choice from the shape the men are already standing in
and the push they are already on, because that is what FIGHT would run anyway. An
empty strip and a dead button would be the screen lying about a fight it is
perfectly able to start.

### Three things the picture caught that nothing else would have

**The marshal was shouting over the corner.** Forty-pixel text through the middle
of five men's numbers — `marshal_t` had no screen check.

**The round's popups kept rising over the panel reporting that round.** They live
on `JuiceArt`, a node above the scene, so nothing drawn in `_draw` could cover
them. `Juice.clear_pops()` now runs when the corner opens: a "DOWN" from the
round just ended, drawn on top of the summary of that round, is the fight arguing
with its own report.

**A scrim cannot cover a Button.** The sub popup dimmed the screen and left
FIGHT bright and pressable straight through the modal — the controls are on a
CanvasLayer above the Node2D that draws the dimmer. The popup now *is* the
screen: when it is open the corner builds nothing else. That is not a cosmetic
fix; it was a live control under a modal.

And the first version of `shot_corner.gd` photographed the corner's controls
floating over a live fight with no panel behind them, because `run_to_end` leaves
the sim in OVER and `_process` flips the screen away from a corner the sim is no
longer in. `skip_round` is the round the marshal would have run.

### Two figures that now come from one place

`sim.corner_lift()` / `corner_preview()` were pulled out of `_corner_recovery` so
the row can show the recovery. A screen that previews a number by recomputing the
rule beside the rule is a screen that will one day preview a number the sim does
not deliver.

`Tuning.condition_word()` is Pete's vocabulary from the same change list —
Fresh, Healthy, Tired, Beat Up, Injured — which had never been built either. A
percentage is a number you compare; a word is a thing you decide about. The row
shows both, because the bar is for reading across five men and the word is for
the one you are about to sub.

### Still owed

**Favorites are not chosen by anybody.** `_fav_calls()` returns the four calls
out of the live shape — a real default, and the only function that changes when
starring a play becomes a thing a player can do. Named here so it does not
quietly become the feature.

### Suite

**421 across 29 files.** `test_layout.gd` sweeps 198 controls now and the Melee
scene's share of them is the new corner, because the bout opens on it.

### And the sweep could never have caught it

Pete, on the shot: *"Format the 'Who comes on for Iles', Marsh is falling into
nevermind."*

He was right, and the interesting part is why `test_layout.gd` was green while it
was true. `Marsh` ended at y 228. `Never mind` began at y 228. **They do not
overlap** — by any arithmetic, and `Rect2.intersects` is false for rectangles
sharing an edge. The sweep asked the only question it knew how to ask and got the
right answer to the wrong question.

What Pete saw was the **drop shadow**. Every control in this game paints a 4px
shadow down and right inside its own rect, so two of them flush against each
other put one's shadow along the other's top edge and the pair reads as one tall
box with a line through it. *Zero gap is a collision to the eye even when it is
not one to the arithmetic.*

So the rule is now a clear `DROP_PX` between neighbors — checked by growing both
rects half a drop — with one exception that matters: **a flat button has no
shadow to fall on anything.** The squad screen's rows are invisible hit targets
over drawn text, deliberately two pixels apart so every tap lands on somebody;
holding them to a drop's clearance would be the check asking a control that
paints nothing to leave room for what it does not paint. Flat controls are still
held to not overlapping.

**The whole game was measured before the rule was switched on**: two flush pairs,
both on Create, both the tab row two pixels above the name box, both fixed. A
rule you enable without measuring first is a rule you are about to loosen.

### The popup had never been swept at all

Every check in that file opens a screen in whatever state it opens in, and a
modal opens in none of them — it needs a tap. So `_test_the_sub_popup_is_not_a_pile`
puts the screen into the state and then measures it, and it asserts the other
thing the first version got wrong: **nothing is pressable outside the popup while
it is open.** Anything a screen only draws after an interaction has to be
interacted with, or the sweep is measuring the closed case and calling it green —
the third time this file has had to write that sentence about itself.

Both new checks were run against the bug deliberately reintroduced. The overlap
version passed it; the gap version fails naming `Marsh · Center · 100%` and
`Never mind`.

### And the popup is one ladder now

The old geometry was `64 + shown * 54 + 46` for the box and `box.y - 54` for the
cancel — two expressions that have to agree about where the list ends, and did
not. `_sub_row_y(i)` is the ladder, everything counts off it, and the box is
whatever the ladder needs. Two numbers that must agree are one number written
twice.

The four-row cap went with it. It drew at most four bench men and hid the rest
with `visible`, which on a roster Pete has asked to be able to resize is a bench
with men on it that nothing can reach. The box grows instead.

The cancel is full width like the rows above it and knocked back a shade, because
at one row-gap it sat in the same rhythm as the bench buttons and read as a
fourth man — the one thing it must not read as.

### Suite

**423 across 29 files**, `test_layout.gd` at fifteen.

---

## Pass 61 — the favorites, and the index that would have lied

14 Sep 2026, continuing.

The thing the last pass named as owed: *"Favorites are not chosen by anybody."*
The corner had been showing four calls since it was built and nothing let a
player pick which four. Pete's spec has said *"on the right side you have your
four favorited plays"* since the playbook pass.

### Keyed by name, not by index, and that is the whole design

`plays_for` hands out each play's position in `plays`. `delete_play` uses
`remove_at`. So deleting a play slides every index after it down by one — and a
favorite holding index 1 would keep working, keep looking right, and **quietly
be a different play**. No error. No empty slot. The worst kind of bug there is.

So a favorite is `{shape, kind, key}` where the key is a push's id or a play's
**name**, resolved against `_book_calls` at read time. A name can go stale; a
stale favorite resolves to nothing and is pruned, which is a failure you can
see. Two plays sharing a name in one shape is possible and the first wins — a
naming problem the player can see and fix, not a silent substitution.

`test_favorites.gd` demonstrates the bug rather than asserting about it: it
starres the play at slot 1, deletes slot 0, and prints what slot 1 became.

```
pass  an index really would have moved under the star — slot 1 was 'Anvil', is now 'Wedge'
pass  and the name key still points at the play the player starred — 'Anvil'
```

A design decision whose reason is only in a comment is a decision the next person
undoes. This one fails a check.

### Refused at four, not rotated

The fifth star is turned away rather than pushing the first out. A list that
quietly forgets what you put in it is a list you stop trusting, and four is a
decision worth making.

### One grid, two jobs

The book gets a mode switch — *Pick favorites for the corner* — rather than a
star floated over every card. The cards sit in a `GridContainer`, which owns the
position of everything in it, so an overlay would have been a second positioning
system on the one screen that already scrolls. In star mode the lit card is the
starred one and a `★` goes on its label; the highlight still means "this is the
one you mean", and what it means you mean is what changed. One tap, one meaning
at a time, decided in `_tap_call` rather than in two callables built at two call
sites — which is how a grid ends up with cards that disagree about the mode after
a rebuild.

The mark is the game's own `★`, the one the fighter screen tags a man for the
Hall with. Two symbols for *this one is picked out* is two vocabularies.

### The fallback stays

A club that has starred nothing still gets the four calls out of the shape its
men are standing in. Every club begins with none, and an empty right-hand column
on a screen with a clock is worse than a sensible default. The half-full column
in `corner_faves.png` is the picture that can only have come from real
favorites — the fallback is all-or-nothing.

### And the panel ran off the bottom

Two buttons under the book put the panel at y 566 of a 540 frame with *Back to
the corner* off the screen. They are peers — one changes what a tap means, one
leaves — so they are a row, and `BOOK_H` drops 300 → 268. The page gives way,
because the buttons are the part you cannot scroll to.

The shot tool had no `Session.season`, so the book fell back to the built-in
formations and the star mode photographed **"0 of 4" on a board that did not
exist**. Fourth time this project has had a tool photograph the empty case.

### Suite

**434 across 30 files.** `test_favorites.gd` is new at eleven, and three of
those are about a save: they come back, a save written before favorites existed
loads with none, and a hand-edited one is coerced and capped rather than trusted.

---

## Pass 62 — the eight that were written and not wired

14 Sep 2026, continuing.

Nine traits had a name, a blurb, a rarity and a card, and no code. They were held
out of the roll by `PENDING` so none of them ever shipped a sentence that did
nothing — the honest version of a TODO. Eight of them are wired now.

| trait | what it needed | where it lives |
|---|---|---|
| Wrestler | a clinch that can open ahead | `_enter_grapple`, through `_wear` |
| Second Wind | a tank that can refill once | `_tick_timers` |
| Last Man | a side that can be counted | `_rally` |
| Proud | a control that can refuse | the corner's SUB box |
| Talisman | a room | `Season._award_xp` — see below |
| Prima Donna | the men who did **not** play | `Season._award_xp` |
| Grudge | a club remembered on a card | `FighterCard.grudge_club` |
| Heavy Hands | a harness that can be wrecked | `Man.harness` |

Wrestler's opening goes through `_wear`, so it counts toward an assist like
everything else done to a man — a trait that took stability off directly would be
a wrestler who grinds men down invisibly, which is the thing the assist ledger
exists to prevent. Second Wind fires at the bottom of the tank, not at the gassed
line, and it is in `_tick_timers` rather than at each of the seven places a tank
drains. Prima Donna loops the club's own eight and not `sim.men`, because the men
who did not play are exactly the ones `sim.men` has never heard of.

### The sentinel that was a legal value

`_rally` scanned each side for a Talisman with `var talisman := 0.0`, then
applied it with `if talisman != 1.0`. **Zero is not one**, so a side with no
Talisman multiplied its whole line by nought. Every man in the game fought at an
effective base of 0.00 for the length of this pass.

*A sentinel that is a legal value of the thing it stands in for is not a
sentinel.* It was caught in twenty seconds by a probe printing the fields, after
four unit checks failed with `rally 0.000` — which is what a field of zeroes
looks like when you only read the assertions.

### Talisman: three measurements and a finding

As written — a multiplier on everything while he stands — `probe_pending.gd`
measured **one man at +12.2 points of win rate**, against Last Man at +3.3 for
the same rarity. Cut from ×1.05 to ×1.02 it measured **+11.1**. It does not scale
down: this sim is sharp around parity (`grade.gd` already knew — a 4% opposition
scale is a whole difficulty rung) and a room trait pays its multiplier four times
over.

Moved to stability recovery: **+0.0**. In a busy melee men are grappled, not
recovering; the window barely exists. Moved to the corner: **−2.2**, inside the
noise, because the corner lift is clamped at a full tank and most men are near it
after one round.

**A room-wide effect in this fight is either enormous or nothing, with no
readable middle.** That is the finding, and the trait went where a room trait
belongs: morale, which is bounded by construction and already has measured
effects all through the club layer. While he is fit and on the eight everybody
else lifts; while he is on the books and cannot go out they drop by half as much,
which is what *guts it when he goes* means on a week a club can see.

`test_traits.gd` now asserts a Talisman changes **nothing** about how his side
fights — because a later pass reaching for `rally` to "just add the room back" is
exactly what that check is for.

Wrestler went 0.18 → **0.06** on the same evidence: +24.4 against Grinder's
+17.8, for a free effect on every clinch, when a hit is 0.08.

### The gate had a hole and a dilemma card was in it

`_test_every_effect_key_is_read_somewhere` searched every file for `"key"` in
quotes. `HEAVY_HANDS`'s `harness` passed it with **no code anywhere**, because
`dilemma.gd` has a card whose id is `"harness"`.

It matches the call shapes now — `tmod("k"`, `tflag("k"`, `mod(x, "k"` — and
nothing else, verified by adding a key nothing reads and watching it fail. A gate
an unrelated string can satisfy is a gate with a hole, and this one is the whole
defense against the Scout.

### Homesick stays pending, on purpose

*"A different man away from your own ground"* needs a home and an away, and this
game has neither: every event is at the club's own arena, which is the thing the
club builds and takes the gate from. Wiring it would mean inventing a
home-and-away fixture model to hang one trait on, and a design decision that size
does not get made as a side effect of a trait pass. `test_traits.gd` asserts the
pending list is exactly `[HOMESICK]`, so it cannot quietly grow again.

### Suite

**451 across 30 files.** `test_traits.gd` is at seventy-eight.

---

## Pass 63 — the map

14 Sep 2026. Pete, reading the note that left Homesick pending:

> *"Looks like we just surfaced that we need to add the 'City' selectable for
> your team. And we need to make arenas for home, away, and tournament games...
> It's actually fun running into these open spaces we didn't think about."*

The pending note said Homesick *"needs a home and an away, and this game has
neither"* and left it there. He read that as a missing feature rather than a
blocked trait, which it was. **A note that names what the game cannot do is worth
more than a workaround**, and this is the second time in two passes that writing
the limitation down plainly was what produced the feature.

### The cities were already there

`LeagueWorld.FIRST` — 46 entries used as the first word of every club's name —
is a list of places. Cross Timbers, Harrow, Saltmarsh, Old Kiln. A club called
"Harrow Brotherhood" has always been the brotherhood from Harrow; the game has
simply never been able to say so. The list is `CITY` now and every club carries
`city` as stored data, because the first word of a name is where a club is from
today and must not be tomorrow: a club relocates, and a player types his own
name.

`city_of()` falls back to the name, so a save written before this loads into a
world where everybody is somewhere.

### Picking a town is a swap

Forty-six towns and forty-six clubs, so every town is somebody's — "pick any
city" has to either rename a club out of existence or trade. It trades: whoever
holds Harrow moves into Cross Timbers and is renamed to match, second word kept,
because a brotherhood that relocates is still a brotherhood. Nothing is lost,
nothing is duplicated, and the map stays full. The checks assert one club to a
town after the swap.

The picker is on the title screen, twelve at a time out of forty-six with a
reroll and an *Anywhere will do* — a wall of forty-six is a list nobody reads.

### The host is a third element, and that cost a failing test to learn

`[a, b]` became `[a, b, host]` and **not** `[host, visitor]`, which is what I
wrote first and what reads better. `play_event` passes `pair[0]` and `pair[1]`
into `quick_bout` in that order, so swapping them redraws every simulated result
in every division — a save made yesterday replays into a different season.
`test_arena.gd` failed on it immediately, on a fixture two divisions away from
anything I had touched.

**New information rides alongside the old; it does not rearrange it.**

### Being clever in the generator was the mistake

The first host rule was a parity trick, `(round + slot) % 2`, and it measured
**0% to 89%** of fixtures at home across ten clubs. The circle method rotates
clubs *through* slots — the fixed club sits at slot 0 all season and its opponent
at slot n-1 — so a rule keyed on the slot is keyed on nobody.

Walking the finished fixtures and handing each to whichever club has hosted less
is three lines, correct by construction, and needs no argument. It measures 33%
to 67%. The check reads the outcome either way: *a scheduling rule nobody
measures is a rule that quietly gives one club every away day.*

### Three kinds of afternoon

`Venue` holds all of it — HOME, AWAY, NEUTRAL — and a cup tie is neutral ground
whoever is in it, asked through `pending_cup()` because that is how the rest of
the season already asks.

**The crowd is the only thing that hangs on it**, plus Homesick. Pete's call and
the right one on this project's own evidence: `grade.gd` measured a 4% opposition
scale as a whole difficulty rung and `_rally` measured a room-wide multiplier at
twelve points of win rate, so a "home advantage" multiplier here would not be a
nudge, it would be a handicap system nobody asked for. The gate is paid at home
and nowhere else — a club that took its gate on the road would never build an
arena, which is the whole of the Arena screen.

And **Homesick is wired**, ×0.93 away. Away and neutral cost him the same;
neither is his ground. The pending list is empty for the first time since it was
created, and the mechanism stays: `test_traits.gd` asserts every trait is either
rollable or named in it, so the next one that needs something the game lacks goes
in the array on the day it is written.

### The walk-out

One screen, three dressings, before every bout. Both badges, both names, both
records, the venue, and a button that says what the afternoon is — *OUT TO YOUR
OWN CROWD*, *OUT INTO THEIR HOUSE*, *OUT TO THE TOURNAMENT*. Home reuses the
club's own arena at the level it has been built to, which is why there are two
new art slots and not three: a third piece for the ground the player has already
bought would be the same room drawn twice.

Two things the render caught. The splash asked `Season.host_id()`, which
re-derives the venue from the fixture list — so it drew one venue's dressing
while naming another venue's town. The screen has already decided what kind of
afternoon it is; the host follows from that and nothing else. And the title
screen's Back button at its usual `(24, 96)` drew straight through the title
block: *a shared position is only shared where the thing behind it is.*

`test_layout.gd` caught the other one, and it is the same bug this scene had
three passes ago: **the report drew over a still-pressable splash button.**
`_hide_panel` only hides `panel_box`, and the splash's controls are positioned
absolutely on `ui`. A live control under a screen, twice.

### Art

Two slots, `venue/away.png` and `venue/neutral.png`, both 960×540 full-frame
backdrops rather than pictures on a screen — the names and records are drawn
across them and there is no panel behind, so `docs/ART.md` tells the artist to
keep the middle band quiet. The spec check that asserts ART.md and the code agree
caught the omission on the first run, as designed.

### Suite

**473 across 31 files.** `test_venue.gd` is new at eighteen.

---

## Pass 64 — a real map

14 Sep 2026, straight after. Pete:

> *"Let's go with real US cities so they can have a radius with the 'homesick'.
> Then have a little button for Europe with European cities for our
> international fans over there. I think little things like that will be great
> gems for this game."*

The invented towns worked and could not do the one thing that made them worth
having. **Homesick was a flat 7% whether the away day was ninety miles or two
thousand**, because Harrow is not anywhere and the distance between two made-up
towns is not a number.

### Forty-eight and fifty

`Cities` holds two maps — 48 American cities, 50 European — each with its area
(the state or the country) and a real latitude and longitude to two decimals.
Two decimals is about a kilometer, three orders of magnitude finer than anything
that reads it; precision is free here and a wrong coordinate is the kind of thing
a player from that city notices immediately.

Distance is haversine. The earth is not a sphere and the error is about half a
per cent, which is nothing against bands hundreds of miles wide — using the cheap
formula and saying so beats using the expensive one and implying the answer is
surveyed.

**The distances are checked against ones I already knew.** A haversine with a
sign error still returns plausible-looking numbers, so `test_venue.gd` measures
five known pairs — Detroit–Cleveland 90, New York–Los Angeles 2,445,
Dallas–Houston 225, London–Manchester 162, Warsaw–Kraków 157 — and fails on any
of them. That is the only way to know a map is right.

### Homesick is a radius

| distance | effect |
|---|---|
| under 120 miles | nothing — this is a local derby |
| 120 to 1,500 | comes on, straight-line |
| over 1,500 | the full trait, and no worse |

The cap is there because a man who gets worse the further he goes with no floor
is a man you cannot take to the Worlds. The trait should make a club think about
a squad, not forbid a fixture.

### The region belongs to the world

Picking Europe does not put a European club in an American league — it generates
a European one. *A pyramid whose clubs are four thousand miles apart is not a
pyramid, it is a travel budget.* The region is set before `_build_pyramid`,
because a region applied afterwards is a world full of American clubs with a
European flag on it.

That caught a real one on the first run: `MeleeRosters` hands over a club with a
fixed name, so a European career founded an American club in a European league —
one row on the table from a town nobody could travel to. It relocates to a free
town on the right map, and the check asserts every club in a European world is
in Europe.

### Both screens, one relocation

The picker is on the title screen (twelve at a time, a reroll, an *Anywhere will
do*, and a button naming the map you are **not** on — a toggle labelled with the
state it is already in is the oldest bad button in software) and on the Create
screen's CLUB tab (four towns and a reroll, because a relocation is a decision
you make about one town at a time). Both call `Season.set_city`; there is one
relocation in this game.

The area line under each card is drawn rather than put in the button — a two-line
button either clips the second line or shrinks the first, and the first is the
one being chosen. It needed the row pitch opened from 12 to 24: drawn inside the
card it sits under a Button on a CanvasLayer and is invisible, which is the third
time this project has learned that in four passes.

### The same re-derivation bug, again

The splash printed **"at home" across an away splash**. `Season.miles_travelled()`
asks `venue_kind()` for itself — exactly the pattern that had this screen drawing
one ground while naming another's town an hour earlier, fixed once for the host
and not for the distance.

*The screen decided what kind of afternoon this is; everything on it follows from
that.* Both now come off `_venue_kind()` and nothing else.

### Two bugs the map fell over on the way past

**A club the player named came back renamed.** `SaveGame` builds a Season with
the saved club and *then* restores the saved world, so the constructor's
map-safety ran against a fresh world. Its first version called `set_city`, which
renames — and a club called "Bonk Works" was read as being in the town "Bonk",
found off the map, relocated, and loaded as **"New York Works"**. Every load.

`test_create.gd` caught it, because it has asserted a renamed club survives a
save since long before there was a map. Two fixes: the constructor sets the town
and does not rename (*placing a club is all it needs to do; renaming one is the
picker's job*), and `_city_of` returns **empty** rather than guessing the first
word — a guess indistinguishable from an answer is worse than no answer, and that
guess is what made the rename rule fire on a name the player had chosen.

**A bracket survived the summer.** `roll_over` never resolved the season's cups.
`auto_resolve_cups` holds any cup the player is still alive in, which is right
during a season and wrong at the year's end: the season those ties belonged to is
gone, and the held bracket carried into the next year still asking for a fixture.

`test_season.gd` has asserted *"the cups resolved rather than left hanging"*
since it was written — through a proxy, `honors >= 3`, which passed on a world
where the player happened to be knocked out of enough of them. Changing the city
list moved two generated names, the same seed kept him alive in both, and a bug
that had been there the whole time surfaced.

**A check that passes because of what the world happened to do is a check waiting
for the world to do something else.** It counts open brackets now, and
`_close_the_season_cups` decides them on rating at the roll over — the player's
own included, because he did not play them and the year is over, which is what a
forfeit is.

### Suite

**487 across 31 files.** `test_venue.gd` is at thirty-two.

---

## Pass 65 — the face goes in

14 Sep 2026. The oldest thing on the list: **sixteen scenes still drew in
`ThemeDB.fallback_font`** while every button in the game drew in Buhurt Rail. It
is in every screenshot in this register — a proportional sans label beside a
pixel-face button, on the same panel — and it has been the single loudest reason
the game read as two games.

It stayed outstanding because of one line in `test_layout.gd`'s own header:

> WHAT IT CANNOT SEE: drawn text. `draw_string` leaves no node behind, so a label
> running into a number is still only findable by rendering.

Buhurt Rail is **25 to 55 per cent wider than the fallback at the same size**.
Turning it on moves every string in the game at once, and not one check in five
hundred could see a single one of them.

### So the drawing writes itself down

`UiKit` keeps a ledger behind a flag: `text()`, `right()` and `mid()` record the
rect they are about to draw, and those three carry every piece of text in every
game screen (`melee_scene` draws its HUD raw and is the exception, named in the
new file's header along with panels, which are rects with no association to the
text on them — that is what the green does not cover).

`at` is a BASELINE, which is what `draw_string` takes, so the recorded rect runs
from `baseline - ascent`. Getting that wrong by a line would have measured the
gap above every string instead of the string.

`test_ink.gd` reads it back and asks the two questions a wider face actually
causes: does anything run off the frame, and does anything run into a control.
It also asserts **the ledger can fail** — draws one string off the edge and
checks it is caught — because a ledger that records nothing passes both sweeps in
perfect silence.

### It found four bugs before the font was touched at all

The instrument was calibrated on the existing build first, and the existing build
was not clean:

- **The title screen's tagline ran underneath the Back button.** Every visit,
  since the button was added.
- **The market's wage-bill panel was the same rectangle as the New names
  button** — the bill and its bar drawn underneath a control, invisible for the
  life of the screen.
- The Create tab's town block, which *I* put in last pass, ran through the badge
  and its label ran through the kit-color button.
- The mark bank's captions fell one pixel outside their own hit targets, so the
  bottom of each word was not clickable.

That last one is why the check refuses to treat a partly-covered label as a
deliberate one. A wordless button that *wholly* contains a string is that
string's hit target — the mark bank is built that way so tapping the name picks
the mark — and a check that called that a fault would be demanding the caption be
unclickable. Partial overlaps are still faults.

### And then the face went in

Sixteen scenes, one `sed`. Eight strings off the frame across three screens —
far less than the width ratio threatened, because most layouts had slack:

- the **type credit** on Settings ran to x 973 of a 960 frame. It is generated
  from the licence data and its length is not ours to choose, so it is two lines
  now. *A credit that is cut off is a licence condition that is not met.*
- **"FIVE TIMES"** in the staff table's risk column ran to 971 — and was the only
  cell in that table not written as a multiplier anyway. It reads `×5` and the
  shouting moved into the sentence under it.
- two **Arena** lines about what a bid costs, both sentences a player reads before
  spending credits. Broken at the clause rather than shrunk, because the figure
  is the thing being decided on.

### The check written for a bug caught the same bug from the other side

`test_layout.gd`'s team-sheet check exists because the squad row once printed a
wage through an age and a rating through a contract. Its fix was to make the
column stops **measured data** rather than nine magic numbers.

Those stops were measured in the fallback font. The moment the face went in,
`position` ran 6px into `armor` and `age` ran 7px into `wage` — and the check
named both, by field, on the first run. Re-cut at six pixels between every field
with eight spare at the end; the name budget gave way from 130 to 100, because a
clipped surname is a cosmetic loss and a wage printed through an age is a lie.

### Suite

**491 across 32 files.** `test_ink.gd` is new at four, over 612 strings and twenty pages.

---

## Pass 66 — the bottom half, twice

14 Sep 2026. Pete's ask from the fifteen-change list — *"After the bout looks
great. We can use the bottom half for status/trait changes as well"* — got built
as two panels of prose. Then:

> *"If that mock is the After action, go with the one we mocked up that showed
> 'After the bout'. That one looked WAY better. At least use the layout or
> format and you can put in the playoff picture or standings and notable items."*

He is right and the reason is worth writing down: **a bout produces a table** —
six men, seven figures each — **and prose is the wrong container for a table.**
The mock had it laid out on the afternoon it was drawn and the engine never got
it, which is the same failure as the playbook's column headings two passes ago.
*A mock everybody signed off is not a feature.*

### The screen, on the mock's own numbers

Three regions. **THE AFTERNOON** is the men, a row each: downs, assists, rounds
up, times off, XP earned today, level, and a last cell that says the only three
things it can — he went up, he is at his ceiling, or how far off he is.
**THE CHANGING ROOM** is what they think, in cards sized to their own text.
**AFTER ACTION REPORT** is the cards along the bottom: the table and the playoff
picture, the gate, the following, and every man the afternoon changed.

Both panes take the wheel, and which one moves is decided by where the pointer
is — the way it is decided in every other application, and the only way that
needs no extra control on a screen that already has one.

### Every quip is earned by something that happened

There is no bag of generic lines dealt at random: a man speaks because he put
three people down, or because he was empty by the second round, or because this
is the third bout he has watched from a bucket. *A report where half the voices
are filler teaches the player to skim it, which is the same as not having it.*

One voice a man, decided first-reason-wins with the reasons written worst-first —
so a fighter who gassed *and* was put down twice says the thing about the tank,
which is the one the club can do something about. The first render had Calder
saying both, one card above the other.

### The mock's own warning, and the mock's own bug

The HTML file carries a comment about right-aligned tokens running backwards into
the column before them — it records that an early cut printed "AT HIS CEILING"
through the XP figure — and then leaves `lv` at 530 and `next` at 556.
**Thirty-six pixels for a cell whose widest token is "LEVEL UP".** Ported
straight across, the header row read `LVLNEXT` and the LEVEL UP ran back through
the level number.

**A note beside a number is not a check on it.** Every column is now the width of
the widest thing it can hold, and `test_ink.gd` asserts that as arithmetic — each
column's widest possible token measured in the real face against the gap to the
stop before it, plus the same for the headers. Put the mock's figures back and it
fails naming the token and the shortfall: `next: 'LEVEL UP' needs 60 in 54`.

That check lives in `test_ink.gd` because this screen is in the ink ledger's
blind spot — the report draws with raw `draw_string` inside `melee_scene`, which
that file's header names as the exception. It is also the screen most in need of
it: a right-aligned string that outgrows its column runs *backwards*, which is
the least visible way for a layout to break.

### And the gate reports what the club was paid

`crowd_came` is for demos and shows; a league fixture never calls it. An
attendance figure on this screen would have been `ClubEvent.attendance()` run
again after the fact — an estimate of a number, printed as if it were the number.
The credits are a fact.

### The prose version, kept

`Season.last_changes` — written at the moment each thing happens, rather than
recomputed — is what feeds the bottom row of cards, and `test_season.gd` still
reads the `_note_change` calls out of the season's source and fails if a kind has
no heading. That was the right half of the first attempt; only the container was
wrong.

### Suite

**504 across 32 files.** `test_ink.gd` is at eight, `test_save.gd` at six. (This line read 497 while the
banners summed to 496 — see THE SOAK below. Counted, not typed.)

---

## THE SOAK — what eight seasons found that 496 checks did not

`tools/soak.gd` plays a whole career through the real doors: `begin_bout()` →
`run_to_end()` → `post_bout()`, plus `pending_cup()` / `sim_cup_tie()`, eight
seasons deep, and prints a line per season rather than asserting anything.

    godot --headless --path . --script res://tools/soak.gd

**IT IS NOT A CHECK, IT IS A WALK.** The suite proves the rules. This finds the
rules nobody wrote — and on its first complete run it found four bugs, three of
them in shipping code, none of which any assertion could have reached, because
every one of 496 checks started from a healthy club on a league Saturday.

### 1. THE HARD LIST WAS DOING NOTHING

```gdscript
if opp_id == -1 or not world.clubs.has(opp_id):     ## WRONG
```

`world.clubs` is an `Array[Dictionary]` **indexed by club id**, not a dictionary
keyed by one. `.has()` on a typed array asks "does this array contain this
value", so it was handed an `int` where it wanted a `Dictionary`, threw a
container-type error, and returned `false` — every time, for every id.

So `opposition_scale()` took its no-club fallback on **every bout in the game**
and graded against an invented power-50 tier-0 club. THE HARD LIST is the only
grade that reads the opponent: its whole identity is `ceiling_scale(power, tier)`,
pinning the opposition to the top of their own division. Against a fictional
Backyard side it floors at 1.0 and clamps up to `STEEL` — which is what FULL
STEEL already gives you. **The hardest difficulty on the options screen was the
second-hardest difficulty, at every tier, against every club.**

The guard is now a bounds check, which is the only question an array can answer.
A guard that can only fail is no more a guard than one that cannot.

`test_season.gd` — *the opponent is a club*. The first draft of this check
asserted "stronger club, harder fight" and failed honestly, because that is NOT
the claim: the ceiling rule is a *division* rule, so a side already at the top of
National grades at its own rating while a side adrift at the bottom of the same
division gets lifted to the ceiling above it — 86 power grades x1.04 and 33 power
grades x1.08, and both are correct. What the check asserts instead is the
property the bug actually broke: **some club must move the number off the
fallback**, and within one division the man further below the ceiling is the
harder afternoon.

### 2. A SHORT LINE ADDRESSED THE WRONG MEN, THEN CRASHED

```gdscript
m.idx = team * 5 + i     ## WRONG the moment a side can field four
```

`starting_five()` is honest when a club comes up short: it returns a **four-long
array**, not five with a hole. `_build()` then numbered its men as though it had
always been handed five.

With four on team 0, team 1 lands at `men[4..7]` carrying indices `5..9`. Every
one of them is off by one, and `idx` is not decoration — `partner`, `target`,
`wear[by.idx]` and the assist ledger are all **lookups into `men` by `idx`**. So
damage was recorded against the wrong fighter, men attacked the wrong fighter,
partners were somebody else's partner, and the last man's index addressed nobody
at all: `Out of bounds get index '9' on base 'Array[Man]'`, inside `_put_down`.

*A constant that used to be a fact becomes a lie the moment the thing it
described becomes a choice.* `m.idx = men.size()` is the only definition that
cannot drift, and it is identical to the old one whenever both sides field five.

**This is reachable on an ordinary weekend.** A Backyard club travels
`office.travel_slots` men — six, until it buys a seat. One knock and one man who
cannot get the time off, and it walks to the list with four. The soak hit it in
season four of eight.

`test_roster.gd` — *a short line still numbers its men*. Injures men until the
club can only raise four, builds the sim, asserts every index addresses its own
man and every stored index is in range, then **fights the bout to the end** —
because the crash lives in `_put_down` and only happens once somebody goes down.

### 3. A CUP TIE DID NOT KNOW WHO IT WAS FIGHTING

`begin_cup_bout()` began life as a copy of `begin_bout()` with the roles block
factored out. A copy drifts. It set the corner clock, the occasion and the
opposition's coaching by hand, and **never set `opponent_club_id`, `venue` or
`miles` at all** — so a cup sim ran on the defaults, `-1` and `Kind.HOME`.

Three traits and a screen, silently off, on the biggest fixtures in the game:

* **GRUDGE** compares `card.grudge_club == sim.opponent_club_id`. Against `-1` it
  can never fire — the one fixture where a grudge is most likely to matter.
* **HOMESICK** reads `sim.venue`, and `homesick_scale` returns 1.0 flat on
  `Kind.HOME`. Nobody was homesick on a trip nobody was away for.
* The **splash before the charge** draws the arena for `sim.venue`: the home
  arena, for a tie on neutral ground.

And the matching half, in `_award_xp`, which **both** bout paths call:

```gdscript
m.card.grudge_club = opponent_id()     ## the LEAGUE fixture list
```

Correct on a Saturday, wrong on a cup night. Lose a tie to Bristol and your man
swore lifelong revenge on **whoever you happened to play next in the league** —
by name, on the after-action report. The sim already carried `opponent_club_id`
to *apply* a grudge while the season used a different source to *form* one: two
sources for one fact, and they disagreed exactly where it showed.

The fix is structural rather than another copied line. `_dress_sim()` now takes
the fixture and hands over everything:

```gdscript
func _dress_sim(sim: MeleeSim, opp_id: int, kind: int, dist: float) -> void:
```

Both doors call it. The roles block was never the shared part — **the fixture is
the shared part.** This is the FOURTH time these two functions have disagreed
about the same night: the injury tick, the grade, and now who and where.

`test_cupplay.gd` — *both doors dress the same sim*. Does not check the cup; it
checks that no field the league fixture fills is left at its default here, walked
field by field against the other door rather than against a list somebody has to
remember to extend. It reports the discrepancy in its own note: *"league vs
Albuquerque Household, cup vs Raleigh Retinue on Neutral, 511 miles."*

### 4. A GUARD THAT COULD NEVER ANSWER YES

```gdscript
while rival.starting_five().has(null) and guard < MeleeClub.SQUAD_MAX:
```

`starting_five()` does not pad with nulls — it returns a short array and says so
by its size. So the breakaway club's walk-on loop never ran once, and a splinter
was whatever the split left it, line or no line. Now `.size() < LINE_SIZE`.

### AND ONE THE SOAK GOT WRONG ABOUT ITSELF

The first run flagged "roster down to 6, short of an active 8" for five straight
seasons. Six is **correct**: a club travels `office.travel_slots` men and a
Backyard side that has never bought a seat travels six, which is what
`party_size()` says and what `_fill_squad()` correctly tops up to. The flag was
comparing against the game's maximum instead of the club's own number — *a check
telling you about itself rather than about the game.* It now reads
`club.party_size()`, and a second flag was added for the thing that actually
bites: `starting_five().size() < LINE_SIZE`, a club that cannot make a line on
the day.

### WHAT THE WALK SAYS WHEN NOTHING IS WRONG

    s1 Backyard Circuit  5 bouts 2 ties · 13/13 fit · rating 31 · $25/$200 ·  11 CC
    s4 Backyard Circuit  5 bouts 0 ties ·  5/ 6 fit · rating 24 ·  $6/$200 ·  68 CC
    s8 Backyard Circuit  5 bouts 0 ties ·  5/ 6 fit · rating 20 ·  $6/$200 · 143 CC

A club nobody manages rots: 31 to 20 over eight years, thirteen men to six, out
of the top three by season three and therefore out of the cups — `invited()` gates
on division position, so the ties stopping after season two is the game working,
not the game failing. Credits pile to 143 unspent because the soak plays the
bouts and not the manager. **That is the shape a career should have if you do
nothing, and reading it is the point of the walk.**

### THE RULE THIS ADDS

> **A state nothing constructs is a state nothing tests.**

Every one of 496 checks built a healthy club and played it on a league Saturday.
The short line, the cup night and the pyramid's far end were all reachable in
ordinary play and none of them had ever been *built* — so the bugs living there
were not missed, they were unreached. The suite proves the rules; a walk finds
the rules nobody wrote.

**Suite: 499 across 32 files, green at this point.** (The register previously
read 497; the banners summed to 496 before this work, so that figure was one out
— counted now, not typed, which is the same rule this file applies to every other
number. It reaches 501 in THE INK, PART TWO below.)

---

## THE INK, PART TWO — the three screens the sweep could not see

`test_ink.gd`'s own header used to name its blind spot and stop there:

> **WHAT THIS STILL CANNOT SEE:** `melee_scene` draws its fight HUD with raw
> `draw_string` — forty-nine calls that never touch UiKit.

Forty-nine had become **sixty-two** by the time anybody closed it, which is what
a named gap does if naming is all that happens to it. *A note beside a number is
not a check on it.* The three screens behind that note — the splash before the
charge, the corner between rounds and the after-action report — are the three
most recently rebuilt from Pete's mocks, and therefore the three most likely to
be wrong.

### THE DOOR: `UiKit.raw()`

Converting sixty-two calls to `text()` would have **moved every one of them**:
`draw_string` takes a BASELINE and the kit's doors take a top. So the new door
takes `draw_string`'s own arguments in `draw_string`'s own order and forwards
them verbatim:

```gdscript
static func raw(ci: CanvasItem, font: Font, at: Vector2, s: String,
		align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1,
		size: int = 16, col: Color = Color.WHITE) -> void:
	_note(font, s, at, size, align, width)
	ci.draw_string(font, at, s, align, int(width), size, col)
```

The conversion is then the textual substitution `draw_string(` →
`UiKit.raw(self, `, and the pixels are identical **by construction**. That is a
claim the shot tools can check, so they did: nine PNGs across the splash, the
corner, the sub popup, the starred book and the report, compared byte for byte
before and after. All nine identical, and identical again after the two changes
below.

`_note()` also gained a guard it had always needed: a width of `-1` is
`draw_string` for "no box", and an alignment inside no box is a left alignment.
Without it the ledger placed every centerd string at `x - (w + 1) * 0.5` and
reported ink in the margin.

### THE SWEEP FOUND FOUR THINGS, AND THREE OF THEM WERE THE SWEEP

This is worth writing down plainly, because it is the ordinary shape of turning
an instrument on: **the first thing a new check finds is usually itself.**

**1. THE SHOT TOOLS WERE NOT REPRODUCIBLE.** Three of the corner tool's four
pictures changed between two runs with **no code touched at all**.
`melee_scene._ready()` opens a standalone exhibition with `_new_bout(randi())`
and Godot seeds the global stream randomly at startup, so every run drew a
different bout, a different opposing formation and a different five men.

A tool that produces a different picture every run cannot answer the only
question a shot tool exists for — *did my change alter this screen?* — because
the answer was always yes. All six melee shot tools now `seed(20260914)` first,
and the corner's four pictures are stable across runs.

*A check that passes because of what the world happened to do is a check waiting
for the world to do something else* — and a picture that changes on its own is
the same fault seen from the other side.

**2. THE SPLASH DREW A WHOLE FIGHT AND PAINTED OVER IT.** The `Screen.SPLASH`
branch sat at the BOTTOM of `_draw()`: the list, the grid, ten men, every route,
the scoreboard, the strip, the hint and the call bank were all drawn in full,
every frame, and `_draw_splash` then covered the lot with an opaque arena.

The sweep is what surfaced it, by reporting the walk-out button sitting on top of
five men's position labels. The ledger reads what was DRAWN and cannot tell ink
under an opaque picture from ink a player can read — so **a screen that draws
what cannot be seen is a screen no check can measure**, quite apart from being a
whole melee frame's work for nothing. The branch now returns at the top, beside
the report, where it always belonged.

**3. THE CORNER'S SCRIM IS THERE TO MAKE THE FIGHT UNREADABLE.** Unlike the
splash this one is deliberate — the fight shows through at 28%, dimmed, which is
the point of a scrim. But the sweep then reported the scoreboard's own headers
colliding with the corner's buttons: a complaint about pixels nobody can read.

So the ledger learned about covering:

```gdscript
static func ledger_cover() -> void:
	if _ledger_on:
		_ledger.clear()
```

Called immediately after the scrim and **before** the panel, so the corner's own
text still counts. Deliberately blunt — everything before the cover, gone — and a
partial cover is not a cover and must not call it.

**4. AND THE CHECK LET ITSELF IN THE SIDE DOOR.** Reaching the fight with
`n.set("screen", 1)` went wrong twice over. It leaves the SPLASH's own button on
the tree, because that button is torn down by `_clear_corner()` inside the press
handler and not by the screen changing — so the sweep reported the walk-out
button over the men during a live fight. And the sim was still in its corner, so
`_process` hauled the screen straight back and the sweep then measured a fight
that drew **nothing at all**.

The fight is now entered the way a player enters it, through `_call_from_book()`
→ `_apply_chosen()`, which is the one place the sim is touched.

> **A check that reaches a state by a road the game does not have is measuring a
> state the game cannot be in.**

### WHAT IS SWEPT NOW

`_test_the_fight_screens_hold_their_ink()` drives four states — the splash, the
fight, the corner after a round, and the report after a full bout — and runs both
of this file's questions against each: does anything leave the frame, and does
anything land on a control. **407 strings and 1,009 text-control pairs that no
check in the project had ever looked at.**

The states are driven the way `tools/shot_corner.gd` drives them, for the reason
that tool's header gives: **a screenshot of the empty case is the mistake this
project has now made twice.** A corner over a fight that has not started
photographs five of seven fields blank; a report before a bout has been fought
photographs nothing.

Proved able to fail: a splash label pushed to x=700 with a long tail is caught at
`1056,64 runs to 1304,76`.

### STILL NOT SWEPT

Panels. They are drawn rects with no association to the text sitting on them, so
a string can still run off the right edge of a panel and nothing will know. Named
in the header — and the header now also says, in as many words, that naming a gap
is not closing one.

### `UiKit.hints()` — THE CLAIM, NOT THE CODE

`season_scene.gd` carried the line *"`UiKit.hints()` exists and works"*. It has
**never been drawn**, on that screen or any other: fourteen lines with no caller,
so "works" is a claim nothing has checked and should not be written down as
though it were a fact. The note now says so, and says the real reason it has no
caller — a footer needs 26 pixels RESERVED across every screen that wants one,
which is a layout pass rather than a call. Wire it or delete it; leaving it there
untested is the third option and it is the one that rots.

**Suite: 501 across 32 files, green.**

---

## THE WALK, PART TWO — the manager, and the save underneath him

The first soak fought every bout and touched nothing else. That career was an
eight-season decay, which is the correct shape for doing nothing — and it meant
**seven of the eight tiers, every promotion, every invitational, the market, the
staff room and every facility in the clubhouse were never reached at all.** A
passive walk constructs exactly one state: the bottom.

So `tools/soak.gd` grew a policy, `_manage()`, and it is deliberately a DULL
one: re-sign who you can, buy the cheapest thing on the list in a fixed order,
take the best man you can afford, keep the eight full. **It is not trying to be a
good manager and it must not be tuned into one** — a policy clever enough to
avoid the game's rough edges walks around exactly what the tool exists to find.

### WHAT TWENTY MANAGED SEASONS SAY

```
s1   Backyard  6 of 6 · pw 38 (band 30-46, rivals 34) · summer  +8 CC
s3   Backyard  6 of 6 · pw 29 (band 30-46, rivals 36) · summer +15 CC
s8   Backyard  5 of 6 · pw 28 (band 30-46, rivals 36) · summer  -1 CC
s12  Backyard  5 of 6 · pw 27 (band 30-46, rivals 40) · summer  -5 CC
s20  Backyard  6 of 6 · pw 22 (band 30-46, rivals 40) · summer  -3 CC

the arc: club 38 -> 22, rivals 34 -> 40, purse 4 -> 3
climbed: never left the bottom rung
```

Never promoted. Finishing last almost every year. **These are balance calls and
the code has not been touched for them** — the walk was taught to SAY them
instead, so that after any tuning change one run answers whether it worked. Three
things compound:

**1. RIVALS HAVE A FLOOR AND THE PLAYER DOES NOT.** `_drift_ratings()` pulls
every CPU club a quarter of the way to its division's midpoint each summer and
clamps it six either side, so a division holds its level by construction. The
player's rating is his roster, which has no such rule. He falls through the
bottom of the BOTTOM tier's band by season three and there is no rung underneath.
Flagged as *"club power %d fell below its own division's floor of %d"*.

**2. THE SUMMER GOES CASH-NEGATIVE AT SEASON EIGHT AND STAYS THERE.** Prize
money and the gate scale with finishing position; arena upkeep, facility upkeep
and federation dues do not. Finish last, earn nothing, cannot sign, finish last.
The balance then pins at zero, which is why it is invisible on the credits line
and has to be measured by bracketing `roll_over()`.

**3. THE STARTING EIGHT AVERAGES AGE 32.** The roster averages 28.5 and is
healthy. But `active_eight()` takes the depth chart in rating order and the
highest-rated men are the oldest — Orme 38, Dorn 39, Harker 35, Tarrow 33 — while
Quillan 19, Innis 21 and Poole 22 sit in the reserve earning no bout XP. **The
club's future is on the bench and its present is past peak.** `tools/probe_ages.gd`
prints the profile; it is the cheapest of the three levers to move.

### AND TWO THAT WERE THE TOOL'S OWN FAULT

Worth recording because both are the ordinary shape of a new instrument.

- The first policy **extended every extendable man every summer** — a hundred and
  fifty extensions across twenty seasons, most on deals with years still to run —
  and spent the club's entire income on paperwork. It finished every year on four
  credits and bought nothing, which reads as a game with no economy and was a
  manager with no sense. *A dull policy is not a stupid one.* It now extends only
  in a man's last year.
- `player_position()` **is already 1-based** (`return i + 1`, and -1 for not
  found). The walk printed `pos + 1`, so every line for twenty seasons read
  **"7th of 6"** — a position outside its own division, and it took reading the
  function rather than reading the output to notice. Every consumer in the game
  treats it correctly; only the tool did not.

## THE SAVE — five seasons, a breakaway, and a reload

`test_save.gd` had five checks and they were all on fresh or shallow states:
`_test_the_world_continues_the_same` saves two events into season one and
continues with `skip_event()`, where nobody throws a punch. That is the right
check for the schedule and the stream, and it is not the state anybody's save
file is in.

### FIRST, WHAT THE FINGERPRINT WAS NOT LOOKING AT

The file already carried the warning, and it proved itself again:

> **MORALE IS IN THE FINGERPRINT**, and it had to be added the day morale went
> per man: it was dropped from the save for an afternoon and every check in this
> file still passed, because none of them was looking at it. **A round-trip check
> only covers the fields it reads.**

Everything it read was the state a NEW club has. None of it was the state a
CAREER has. `_career_print()` now adds: credits, travel slots, cap level, arena
level, members, market refreshes, every facility, every federation certificate;
per man his `years`, `wage_agreed`, `level`, `xp`, `potential`, `trait_id` and
`grudge_club`; `market_taken`; the trophy cabinet; and the world's RNG seed and
state — that last one so a divergence can be reported as *"the stream was at a
different position"* rather than as *"diverged at character 464"*.

All of it round-trips. The save was already carrying it; nothing was checking.

### THEN THE BUG: A BREAKAWAY LOSES ITS WALK-ONS

`_test_a_deep_career_survives_a_reload()` plays five seasons with every bout
FOUGHT, saves, then plays three more twice — once from the original and once from
the reload — and requires the two to end in the same place.

They did not. `tools/probe_reload.gd` pinned it to one event:

```
event 3:  DIVERGED
   orig  v2 0-2 (0-6) | rng -7933012235188752686 | me 25
   back  v2 2-1 (5-2) | rng -7933012235188752686 | me 25
   the opponent they fielded:
     orig  Detroit Old Guard pw24 | Poole  Vane  Tarrow  Hale  Ewart
     back  Detroit Old Guard pw0  | Poole  Vane  Tarrow
```

Same fixture, same seed, identical RNG state afterwards — and one side fielding
five men against the other side's three.

A splinter is **the one CPU roster the save stores.** Every other club is rebuilt
from its id and its power and needs no storage; the breakaway is the exception,
because the whole point of it is that it is made of specific men you used to
pick. And `_maybe_split` stored `carried` — the men who WALKED — while the club
it actually built was `rival`, which is those men **plus the walk-ons signed to
fill the line behind them.** Those walk-ons are in `rival.power()`, and that
power is what the league table is built on.

They were not in the save. So a reloaded career rebuilt the breakaway from the
carried men alone, a club of three that cannot field five, rated zero — and
handed the player a walkover he had not earned. The bout that decided his season
came out 0-2 played straight through and 2-1 reloaded, and the divergence spread
from there through the table, the drift, and his own development.

**What the save has to carry is the CLUB, because the club is what plays.**

Note the sequence: this only became reachable when the `starting_five().has(null)`
guard was fixed earlier the same day. Before that the walk-on loop never ran, so
both sides built the same crippled club and agreed — badly. Fixing one hole is
what let the next one produce a wrong answer instead of two matching wrong ones.

### AND THE CHECK HAD TO BE MADE TO FAIL

Reintroducing the bug did **not** fail the first version of this check: the
career it happened to walk happened not to fracture at the right moment. *A check
that passes because of what the world happened to do is a check waiting for the
world to do something else* — and that applies to the failing direction just as
much. The breakaway is now **built on purpose**: the room is put on the floor
before the last summer so `fractures()` fires, the test asserts a splinter exists
and can field five before the save is even taken, and with the bug back it
reports *"3 men on its books"* and diverges at the first table row.

Three other empty cases were caught the same way and are worth listing, because
all three passed while covering nothing:

- The "carrying something" guard was an `or` across three conditions and passed
  on two thirds of an empty career. It is three separate assertions now.
- The market never sold anybody anything: **the books are full at thirteen** and
  a career club is at thirteen, so a policy that only signs never signs. It cuts
  the worst reserve first now, which is what the refusal tells you to do — and is
  also the only road in the file to `Season.release()`.
- `market_taken` is **cleared at the top of `roll_over()`** — that clearing is
  what opens a new summer's list — so a career saved at a season boundary has an
  empty one BY DESIGN. The shopping trip happens after the last roll-over now, so
  the save actually carries it.

**Suite: 502 across 32 files, green.**

---

## THE CAREER RUNS UPHILL NOW — two bugs under a balance problem

The twenty-season walk said the career ran downhill: club 38 → 22 while its
rivals held 38, never promoted, finishing last. That read as a tuning problem.
Underneath it were two bugs, and both were invisible to every check in the suite
for the same reason: **nothing was looking at the bottom of a range.**

### 1. THE GROUND RETAINER PAID NOTHING, IN ALL TWENTY SEASONS

`tools/probe_purse.gd` breaks the summer into its lines, because `roll_over()`
lands prize money, the gate, the dues and every bill inside one call and the
balance simply pins at zero:

```
     pos  prize  gate  dues | arena  fac   fed  = net   purse
s1    6      0     0     8 |     0     0     0 =   +8     13
s8    6      0     0    14 |     3    10     0 =   +1      5
s12   6      0     0     9 |     3    10     0 =   -4      4
s20   5      0     0     4 |     3     5     0 =   -4      1
```

**A column of noughts.** Prize money pays the top three only, so a struggling
club's entire income was its members' dues — which fall as it loses. That is the
death spiral, and it had one cause.

`gate_income()` read `attendance()`, which is capacity times `turnout()`, which
is `notoriety / 125`. A club that has not made a name sits at the notoriety FLOOR
of 1.0, so its turnout is **0.008**, and twelve followers times 0.008 is 0.096,
and `int()` of that is zero. Not a small gate: no gate, for as long as the club
is unknown, which at the bottom of the pyramid is forever.

> **A multiplier that can legitimately reach zero annihilates whatever it is
> applied to.**

Same shape as the sentinel that was a legal value of the thing it stood in for,
and the guard that could only fail: the fault is never the number, it is that
nothing downstream can tell *very small* from *not there*.

And the intent was written down. Every figure in the retainer's own comment is a
CAPACITY — *"2 CC at a back field, 6 at a sports hall, 11 at an arena, 22 at a
full National Arena"* — and those are exactly what `capacity^0.30 x 0.72`
produces. A retainer is a fact about the GROUND: *"the federation rotates who
hosts, and a better ground takes a bigger turn."* What the CROWD is worth is
`crowd_pay()`, paid per home fight off the notoriety band, which already floors
at 1 for a club nobody has heard of and says why in its own comment: *"a club
nobody has heard of is the club that most needs a trickle."*

The comment's last line, written the last time this function was wrong, reads:
*"The events are where the arena earns. That sentence was already in this comment
and the code disagreed with it."* It disagreed again, in the other direction.

**How it hid.** Both existing retainer checks open with the same two lines:

```gdscript
o.notoriety = ClubOffice.NOTORIETY_MAX
o.fans = o.fan_cap()
```

They were written to catch a retainer paying too MUCH — at `^0.62` a National
Arena paid 284 CC a summer — so they pinned the club at its ceiling and asked
what came out. Neither could see the other end of its own function.

> **A check pinned at one end of a range is a check on one number.**

`test_office.gd` — *the retainer pays a club nobody has heard of*. Every ground,
at the notoriety floor, must pay; it must pay the SAME figure at the floor as at
the ceiling, because a retainer that moves with the crowd is the event gate
wearing a second hat; and the four figures must be the four the comment promises.
Against the old code it reports a column of noughts.

### 2. A SQUAD WAS A FLAT DRAW ACROSS A TWENTY-YEAR CAREER

`ClubFactory._fighter` drew `randi_range(AGE_MIN, AGE_MAX)` — 19 to 39, flat. A
nineteen-year-old and a thirty-eight-year-old had exactly the same chance of
being on the line. The eight that travels is the line plus the bench (the reserve
slots draw from their own younger band and do not travel), so a club could field
five men all past their peak and never see the youngsters on its own books. The
starting eight averaged **thirty-two** against a learning par of twenty-six: its
future on the bench earning no bout XP, its present already on the downslope.

Nothing was wrong with any single number. `roll_age()` averages two draws — a
triangle instead of a flat line, one extra roll, no table and no new constants.
Both tails survive; the middle is where the men are. Starting eight: 32 → 27.

**How it hid.** Every check in the suite reads ONE club, and one club drawn from
a flat band looks like a perfectly ordinary squad.

> **A distribution is not something a check on one instance can see.**

`test_roster.gd` — *a squad is shaped like a squad*. 960 traveling men across
120 generated clubs, split into thirds of the career span: a triangle puts most
of them in the middle third, a flat line puts exactly a third there. It now reads
**14% young / 69% prime / 17% old**; against the flat draw, 28 / 45 / 27 and a
failure. Note that the MEAN barely moves — 29.4 against 28.9 — so a check on the
average would have passed on both. Only the shape check sees it.

## THE THREE CAREERS

The walk now runs the same twenty seasons three times, and that is a fix to the
tool as much as a feature of it. With one policy, every time the policy changed
the career came out differently — which meant **the walk had stopped measuring
the game and started measuring the policy.** A tool you can tune until it agrees
with you is not a measurement.

```
did nothing  never moved a rung  ·  club 35 -> 21 against rivals 34 -> 35
thrifty      climbed             ·  club 37 -> 31 against rivals 34 -> 39
spender      never moved a rung  ·  club 37 -> 32 against rivals 34 -> 38
```

**If all three ended in the same place there would be no management game here.**
They do not. Doing nothing collapses through the floor of the bottom division and
spends seasons unable to field five — the short-line state that would have
crashed the sim before this morning's index fix, now reached routinely. Thrift
reaches the State League. Spending does not.

That last one is the game teaching a lesson, and a good one. The spender starved
its staff room: `_buy_a_man` used to stop after a single signing and therefore
ran out of money before it reached the captains *by accident*, hiring twelve
across twenty seasons. Let loose it made forty-two signings and hired none — and
**an uncovered role fights Green, a measured 63% loss rate.** The club that
bought twice as many men finished eleven points behind its rivals instead of
five. Coaching beats squad churn.

The policy order is now the order a person uses — keep, build, staff, then shop
with what is left — and the shopping has a bar on it: a man worse than the worst
man already traveling is a fee and a wage for nothing.

### WHAT IS STILL PETE'S TO CALL

All three careers still end behind their rivals over twenty years, and the
thrifty club yo-yos: promoted season 7, relegated season 9. The ladder is
climbable now; whether fourteen seasons or seven is the right pace, and how hard
a promoted club should find its new division, are dials rather than defects. The
walk flags all of it by name, so one run answers whether a change worked.

The remaining structural asymmetry, stated plainly rather than fixed: every CPU
club is pulled a quarter of the way to its division's midpoint each summer and
clamped six either side, so a division holds its level by construction. The
player's rating is his roster and has no such floor. That is defensible — his
club IS his men, and that is the game — but it means the pyramid pushes back and
the player alone has to push forward.

**Suite: 504 across 32 files, green.**

---

## WHAT ARE YOU ACTUALLY TESTING? — an audit, and a noise floor

Pete, 14 Sep 2026: *"what exactly all are you testing here, because there's still
trainings, facilities upgrades, coaching levels and focuses, and whatever else we
have that can help a team win."*

The honest answer was **less than half of it**, and the way to answer it was to
measure rather than to claim. Every verb a screen calls, against every verb
`tools/soak.gd` called:

| system | pulled? |
|---|---|
| clubhouse — travel slots, wage cap, arena, certificates | yes |
| facilities — training ground, infirmary | yes |
| squad — market, signings, cuts, extensions, re-signings, promotions | yes |
| captains — hiring | yes |
| **training regimes** (`set_regime`) | **never** |
| **captain contract extensions** | **never** |
| **the morale lever** (`boost_morale`) | **never** |
| **the matchday** — formation, play, corner, grade | **never** |
| **the queue** — dilemmas, event bids | **never** |
| `take_job`, `negotiate`, `swap_squad`, `refresh_staff` | never |

So *"the ladder is climbable"* really meant *"the ladder is climbable by a
manager who ignores training, coaching contracts, kit, tactics and every card the
game deals him."* That is a much weaker sentence than it sounded.

### THE RULE THAT LIVED IN THE VIEW

`Season.blocked_by()` says a bid, a cup tie or a dilemma must be dealt with
before the next matchday — and **`season_scene.gd` is the only thing in the
project that ever asked.** `begin_bout()` does not check it, so every walk, probe
and save test has fought straight past the queue since the day it was written.

That is not only tidiness. **A dilemma card is the only thing in the game outside
the workshop that puts condition back into a man's armor** — the armorer's bill
and its cousins are the kit economy — so a walk that never answers one is a walk
where kit only ever goes one way.

### THE REGIMES, MEASURED AT LAST

`tools/probe_regimes.gd` — same club, same seed, twenty seasons on each setting:

```
regime    power   armor   knocks   best   fit/books   line
Light        30     0.91        1     45        8/9     5/5
Normal       23     0.64        2     49       9/10     5/5
Hard          0     0.43        5     42        5/9     4/5
```

A whole career on Hard ends with a club that **cannot field five** — power reads
0 because `MeleeClub.power()` has nothing to average. That is `REGIME_INJURY`
doing exactly what it says (every knock lands, always, against one in five on
Normal), and it is a dead end with no road back: the same shape as the economy
spiral the retainer fix closed. Light is quietly the strongest over a long
career, because it is the only setting that puts armor back and it cuts knocks
to a tenth.

## AND THEN THE MEASUREMENT TURNED ON ITSELF

`tools/probe_ablate.gd` runs the same club, the same seed and the same policy
twenty seasons over — once with everything on, then once with each system off on
its own. The first table was beautiful:

```
without signing anybody        -5 power
without travel slots           -3
without training regimes       +0
without morale nights          +1
without picking a formation    +2
without training + infirmary   +2
without answering the card     +3
without extending captains     +4
```

It said the clubhouse was decorative and half of it actively harmful. Then the
noise floor, which should have been measured first:

```
the SAME settings across five seeds gave [26, 32, 22, 24, 28]
mean 26.4, spread 10
```

**Every row was inside it.** The table was not a finding, it was a coin, eight
times. And it retroactively killed an earlier claim in this register — *"thrifty
climbed, spender didn't, so the decisions are real"* — which was two single
careers separated by a few points.

> **A number with no error bar is not a measurement, and a walk is a sample.**

Three things survive the floor, because none of them rests on one noisy career:
the retainer paying 0 at every arena level (a direct measurement, and a column of
noughts in twenty consecutive seasons); the age distribution (960 men across 120
clubs); and the career running downhill (a 15-point fall against rising rivals,
in every policy and every seed).

### TWO FIXES TO THE INSTRUMENT

**1. COUNT WINS, NOT THE FINAL READING.** Club power at season twenty is one
number read once at the end of a noisy process. A career contains a hundred
bouts, and the question was *"what can help a team WIN."* Counting wins is a
hundred samples per career instead of one.

It did not rescue the table — everything still sat inside a fourteen-point
spread — but it surfaced something the power reading had hidden: **the club wins
17.4% of its bouts across twenty seasons, in a six-club division where an average
club wins about forty.**

**2. PAIR THE COMPARISON.** Most of the variance is not the system, it is the
WORLD: five seeds are five different countries with five different sets of
rivals, and they win between 12% and 26% of their bouts on identical settings.

So each seed becomes its own experiment — run it with the system and without it,
take the DIFFERENCE, and the world cancels: same rivals, same fixtures, same
generated men on both sides of the subtraction. The mean of the differences is
the same number as the difference of the means; the SPREAD of the differences is
what gets smaller, and the spread is what decides whether a row means anything.

The verdict column is a sign test, which is the only honest one at five samples:
**an effect that is real points the same way in every world it is measured in.**
One that changes sign between seeds is a coin however big its average is.

### WHAT THE WALK DOES NOW

Every lever above is wired: the queue is drained the way the season screen drains
it, regimes are set per policy, captains' deals are extended, the room gets a
night out when morale drops, and a shape goes on the board.

One of those was a policy bug caught on the way in. `_pick_a_plan` first cycled a
new formation every season so that twenty seasons would see all of them — which
is not a dull manager, it is a manager with no plan, drilling his men for a
different line every year. **Coverage of the formations belongs in a test, where
it costs nothing; a career walk should play the way a person plays.**

---

## THE SIM IS FAIR, AND COACHING IS THE GAME

The ablation said every system was inside the noise. That was true and it was
also the wrong table, because **the lever list left out the biggest thing in the
game.** `STAFF_DEALS` ablates EXTENDING a captain's deal — nearly the same club
as re-hiring one — so every condition in it had captains, and coaching itself
never appeared as a variable at all.

`tools/probe_fair.gd` asks the question the walks could not. Two identical clubs
built from one id, so the two squads are the same men; nothing else set.

```
bare — no coaching either side     side 0 won 32, lost 28  (53.3%)  rounds 71-70
player coached, CPU at Backyard    side 0 won 51, lost  9  (85.0%)  rounds 109-25
player coached, CPU at National    side 0 won 22, lost 37  (36.7%)  rounds 61-82
```

Two findings, and the first one had never been checked in the life of the
project.

**1. THE FIGHT ITSELF IS EVEN.** Identical clubs, no coaching either side: 53% and
71-70 on rounds across sixty bouts. There is no thumb on the scale for side 0 or
side 1. Everything the career walks were reporting is therefore a fact about
CLUBS, not about the melee — which is worth knowing before a single balance
number is touched, and nothing had ever established it.

**2. COACHING IS A FORTY-EIGHT POINT SWING.** The same club wins 85% against a
Backyard-coached opponent and 37% against a National-coached one. That is the
difficulty curve of the whole pyramid living in one control, and it dwarfs
everything the first ablation ranked — which is why those rows read as noise.
They were noise, next to this.

`probe_ablate.gd` now carries `L.COACHING` as its first lever, so the table
measures having captains rather than the paperwork on the ones you have.

### WHAT THIS MEANS FOR THE 17.4%

A twenty-season club wins 17.4% of its bouts. The sim is even, so that is not the
fight — it is the club. Over those twenty seasons the player's rating falls from
about 37 to between 22 and 32 while every rival converges on its division's
midpoint of 38 and stays there. **The gap opens by roughly half a point to a
point of club power every season, and nothing in the management layer measurably
closes it.**

That is one asymmetry, stated precisely, and it is the thing to fix before
anything else is tuned: `_drift_ratings()` gives every CPU club a floor and a
ceiling around its band, and the player's club — which is his roster — has
neither. The question is not whether the player should have a floor; he should
not, his club IS his men. The question is whether a club that trains, coaches,
signs and keeps its squad fit should net out ABOVE zero drift against a side
pinned to the middle of its division. Today it nets out below.

---

## THE DEVELOPMENT LEDGER — it is not ageing, it is the door

The recommendation was to fix the one asymmetry: a club that trains, coaches,
signs and keeps its squad fit should net out above zero drift against a side
pinned to its division's midpoint. Before changing a number, `tools/probe_ledger.gd`
counts the two sides of that ledger per season — what a year TAKES off a club
against what it GIVES — so the lever is a number rather than a guess.

```
     age-loss  ground  bout-XP  in-out  |  net  ·  club
s1         -5       0        3       0  |   -2  ·    37
s3         -6       0        2       0  |   -4  ·    37
s4         -6       3        4       0  |   +1  ·    37
s5         -3       3        1    -106  | -105  ·    31
s6         -3       0        2     -28  |  -29  ·    30
s8         -2       1        3     -19  |  -17  ·    28
s10        -5       3        2       0  |   +0  ·    28
s12        -2       0        2      -3  |   -3  ·    24
```

**Ageing, the training ground and bout XP roughly cancel.** In every season where
nobody left, the net is between -4 and +1 — flat. Every season that moves the
club is a season where **men walked out of the door**: -3, -8, -19, -28, -36, and
-106 the year a breakaway took half the squad.

So the decline is not development failing to keep up with age. It is that **what
leaves is better than what replaces it**: a forty-rated man retires or refuses a
deal, and the club signs a market man banded to its tier — the affordable ones
sitting at the bottom of that band — or takes a walk-on at the division floor.

That reframes the fix completely. More training will not touch it; the
replacement pipeline is the lever, and the game has no youth intake beyond
walk-ons at the floor. Retro Bowl's answer to the same problem is the draft, and
the worse you finished the better your pick — a floor built out of the thing that
knocked you down. **That is a design decision and it is Pete's, so nothing has
been built for it.**

### AND THE BIGGEST LEVER OF ALL WAS NEVER PULLED

The first run of the ledger read **zero in the bout-XP column for twelve straight
seasons**, and that was the finding that led here.

`_award_xp` banks XP and then notes on the report *"has a level waiting — spend
it on his card"*, because placing a level is a DECISION: which of a man's five
stats goes up. The fighter screen offers five buttons and
`Career.level_into(man, stat)` takes one. So a man only improves by fighting if
somebody opens his card — and **no headless walk had ever opened a card.** Every
career this project has measured was fought by a manager who let every level his
men earned sit unspent, for twenty years. Calder finished season one with 49 XP
against a bar of 10: four levels, standing.

It was hiding behind a dead function. `Career.drain()` exists, its own comment
says it is *"called after every bout"*, and **nothing in the project calls it.**

> **A comment asserting a call is not a call.**

`tools/soak.gd` now spends them — `_spend_the_levels`, lowest raisable stat
first, deliberately dull so the walk is not running a stat-priority experiment on
top of everything else it measures.

And it changed the twenty-season arc by almost nothing: 37 → 24 instead of
37 → 22. Which is exactly what the ledger predicts, because levelling is worth
+0 to +4 a season and the door costs -8 to -106. **The measurement was right and
the missing lever was real; it just is not the lever that matters.**

### THE PROBE THAT READ ZERO TWICE

Worth recording, because the first fix did not work either. Having wired the
levels, the column STILL read zero — because the probe spent them at the TOP of
the loop, before the snapshot, so the improvement happened outside the window
being measured. The men were levelling; the probe was looking the other way.

> **A column of zeroes is a claim, and a claim wants checking against the thing
> it is a claim about.**

---

## THE DOOR, BROKEN DOWN — and the same fault a third time

The ledger said the club declines through the door rather than through age.
`tools/probe_door.gd` separates that into its three possible causes —
retirement, a man out of contract who walked, and the split — and prints what the
club got back for each, because *"worse than what left"* is a claim and a claim
wants a number.

```
s2   retired 1 man  worth  36 · walked   0 · signed back   0  |  net  -36  club 34
s5   retired 3 men  worth 102 · walked   0 · signed back   0  |  net -102  club 31
s6   retired 1 man  worth  27 · walked   0 · signed back   0  |  net  -27  club 30
s8   retired 1 man  worth  39 · walked   0 · signed back  19  |  net  -20  club 27
s11  retired 2 men  worth  48 · walked   0 · signed back  46  |  net   -2  club 25
s12  retired 0      · walked  79 · signed back  66  |  net  -13  club 23
```

**It is RETIREMENT, not contract walkaways** — the guess in the previous section
was wrong, and the -106 season was three men hanging it up at once rather than
the breakaway it was assumed to be. That is the whole value of splitting a total:
the aggregate was right and every word of the explanation was not.

And the replacement column is the other half. The club loses 36, then 102, then
27 points and **signs back nothing at all**. `_fill_squad` tops up BODIES to the
traveling party size, so a club with ten men left after losing its best three is
"full" and no replacement is triggered. **Quality is never replaced, only
headcount.** That is defensible — signing the replacement is the player's job and
that is the game — but it means every retirement is a permanent net loss unless
the player notices, and nothing tells him a number went down.

## THE PATTERN: A TERM NORMALISED AGAINST THE TOP IS DEAD AT THE BOTTOM

Three instances now, in three unrelated systems:

| where | the term | what a new club gets |
|---|---|---|
| `gate_income()` | `notoriety / 125` via `turnout()` | **0 income**, twenty seasons running |
| `Contracts.will_wait` | `pull = notoriety / 125` | **7%** of a thirty-point lever |
| `Career.retire_chance` | morale measured against 0.7 | a flat **+8 points** on every roll |

> **A term normalised against the TOP of the game is dead at the BOTTOM of it —
> and the bottom is where every career starts and where the player spends his
> first ten hours.**

A designer reading `+0.30` on `PULL` sees a thirty-point lever for being a club
people want to play for. A new club climbs from notoriety 1 to maybe 10 across
its first ten seasons and collects seven per cent of it. The constant is not
wrong; the CURVE is, and the curve is invisible in the constant.

### THE FIX, IN A SHAPE THE GAME ALREADY USES

`CROWD_GATES` is `[10, 25, 50, 75, 105]` — the game's own answer to "how well
known are you", and its first band lands at 10 of 125. So going from nobody to
talked-about IS the first tenth of the scale, and it ought to be worth a great
deal more than a tenth of the effect.

```gdscript
var pull := sqrt(clampf(notoriety / ClubOffice.NOTORIETY_MAX, 0.0, 1.0))
```

No table, no new constant. A fifth of the whole swing now lands in that first
tenth, and it still reaches exactly +0.30 at the top, so nothing about a famous
club changes. A 40-rated man at a Backyard club stays 50% of the time instead of
47%.

### AND THE PATTERN IS A CHECK NOW, NOT A NOTE

`test_office.gd` — *nothing a new club owns is pinned at zero*. For a club at the
notoriety floor it asserts that the ground retainer pays, that a fight in front of
nobody pays (the crowd banding already gets this right and says so in its own
comment — *"a club nobody has heard of is the club that most needs a trickle"* —
so it is asserted to stop the good example rotting), and that a club's pulling
power is distinguishable from zero.

Then the part that is really the lesson: **the climb out of obscurity has to be
worth a real share of the curve.** Against the straight ramp it reports *"getting
from unknown to 'talked about' is worth 7% of the whole curve"* and fails. That
check would have caught the gate retainer too.

### STILL PETE'S

The third instance is untouched. `retire_chance` adds `(0.7 - morale) * 0.22`,
and a losing club sits at morale 0.33 — so a bad run adds eight points to every
retirement roll, which costs the club its best men, which makes the run worse.
Retirement is already 19% a winter for a 34-year-old at his ceiling and 37% for a
36-year-old six points faded. Whether a bad season should accelerate the end of
careers is a feel decision, not a bug, and how brutal it should be is the dial.

---

## THE MEETING CARD — Pete sent the screen over

Pete, 14 Sep 2026, with a screenshot of Retro Bowl's roster meeting: *"Looking
through Retro Bowl, I found this in roster meetings. I'm sure it'll help us with
our game."*

One panel per man, his name across the top, arrows to page through the squad, and
four rows — each a READ-OUT, a BUTTON and a PRICE IN CREDITS:

```
MORALE     100%        Boost Morale         1 CC   (blacked out — already full)
CONDITION   90%        Boost Condition      2 CC
XP LEVEL       5       Level Up            20 CC
CONTRACT  $32m (2Y)    Extend Contract     34 CC
```

Checked against our fighter screen before building anything, and **three of the
four were already there**: "Sit him down · N CC" is the morale row, priced off
his mood; "Extend · $N/wk" is the contract row; and the paging arrows and the
name header were already the same shape. The screen has carried the comment
`## ---- the meeting` since it was written.

The two that were missing were not omissions. Both were holes.

### CONDITION — a stat that could only ever fall

`armor` multiplies straight into `eff_base()` (`lerpf(0.78, 1.0, armor)`), it is
taken off every week by the HARD regime, and the **only** thing in the entire
game that put any of it back was the luck of the dilemma deck dealing the
armorer's bill. Roll the wrong cards for five seasons and there is no road at
all.

That is the same shape as the ground retainer that paid nothing and the pulling
power that collected seven per cent of itself: **a system the player cannot
reach.** Third instance of the pattern, found from a different direction — not by
a walk this time, but by holding the game up against another one.

`ClubOffice.repair_kit()` — priced off the DAMAGE rather than off the man,
exactly as `negotiate` is priced off his mood rather than his rating, because an
armorer charges for the work in front of him and does not ask what the fighter
is worth. 1 CC at a scratch, `KIT_COST_FULL` (5) at a wreck, `KIT_STEP` (+0.16) a
visit — the same size as the deck's own best card, so the two roads to a repaired
harness agree about what a repair IS. One visit a week per man, on the throttle
every other per-man purchase uses; without it a club with credits walks a wrecked
squad back to new in an afternoon, which is a vending machine rather than a
decision.

### XP LEVEL — the function was written for this and never called

```gdscript
## BUYING ONE, which is their meeting — "go through some extra reps on the
## training field", at `xp_level * 4` credits.
static func level_cost(f: FighterCard) -> int:
```

`Career.level_cost()` has carried that comment for months, has never had a
caller, and was sitting on the dead-code list in the objectives audit **the same
day the screenshot arrived**. Somebody had this exact screen in mind, wrote the
price, and never wired the button. The audit could say it was dead; only the
screenshot could say what it had been for.

`ClubOffice.buy_level()` wires it, and it **buys the XP, not the point**. Placing
a level is a decision — which of five stats goes up — and that decision is the
whole of the row above it on this screen. Buying the man to the bar and letting
the player choose keeps both halves: the credits answer *can he improve*, the
buttons answer *at what*. It refuses to sell a second level while the first is
standing, because a man with a free point should be told to spend it rather than
sold another.

### WHERE THEY LIVE

The band at `LEVEL_ROW_Y` already held the row of +1 buttons, and a level waiting
is a state the player clears on sight — it is a free point. So the band is empty
almost always, and the two purchased rows live there when it is:

```
Extra reps · 8 CC   |   Armorer · 3 CC   |   Sit him down · 4 CC
Back  |  Stand down  |  Extend · $1/wk    |    <   >
```

The trade-off, stated rather than hidden: while a level IS waiting, the +1
buttons take the band and the two purchases are not reachable until it is spent.
One tap, on a screen he is already on.

### AND THE SHOT TOOL PHOTOGRAPHED ONE ARM OF THE BRANCH. AGAIN.

`shot_fighter.gd` had already been fixed once for this — its own comment records
taking a man who was thirty-nine and at his ceiling, so the +1 row never drew and
the screenshot proved the layout of the empty case. It was fixed by forcing a
level to be waiting.

Which meant that the moment the OTHER arm of that branch existed, the tool could
not see it. First render after the build: the +1 row, exactly as before, and no
sign of the two new buttons.

> **A branch has two arms and a screenshot has one frame.**

It takes both now — `fighter.png` with a level waiting, `fighter_meeting.png`
with the purchases — by clearing the man's XP and rebuilding between captures.

`test_office.gd` — *the meeting sells what it offers*: the armorer raises the
harness, quotes what it charges, refuses a whole harness and a skint club, comes
back the following week but not twice in one, and stays inside its cap at the
very bottom of the scale; extra reps leave `overall()` untouched and leave
something in `raisable()` to put the point into.

**Suite: 507 across 32 files.**

---

## THE PRICES ARE VARIABLE — and ours had stopped being

Pete, 14 Sep 2026: *"it should be known that those CCs are variable on Retro
Bowl, you may need to deep dive the mechanism through that."*

He is right, and the dive did not need the internet. **The answer was already in
this register**, at line 5834, from a decompile session months ago:

> There is also a **paid** path: `msg_MeetingLevelUp1/2/3` offers extra reps, game
> film, or an afternoon with a hall of famer, priced by
> `s_get_meeting_cost_levelup` at **`xp_level * 4` credits**.

And the screenshot confirms it to the digit: XP LEVEL 5, Level Up, **20 CC**.

### WHAT OURS WAS DOING

`Career.level_cost` read `next_level_at(f) / LEVEL_COST_DIV` — the XP BAR
divided, not the level multiplied — and carried the sentence *"rising with the
level for the same reason the XP bar does."*

**The bar does not rise.** It deliberately stops: `min(level, 3) * 8` gives 8, 16,
24, 24, 24 forever, because our XP income is flat where theirs grows with
production, and this register spends a page explaining why an unbounded bar walls
a career at three points of overall. That cap is right. The PRICE inherited it:

```
level    1   2   3   4   5   6   8  10  12  15
ours     2   4   6   6   6   6   6   6   6   6
theirs   4   8  12  16  20  24  32  40  48  60
```

Six credits from level three to level fifteen. A club with money buys every level
for every man for the rest of the career, and **the one purchase that should get
harder as a fighter gets good was the only one that never did.**

> **A cap that exists for one reason does not belong to every number that happens
> to read through it.**

### THE FIX, AND THE HALF OF IT THAT IS OURS

```gdscript
const LEVEL_COST_PER: int = 2

static func level_cost(f: FighterCard) -> int:
	return maxi(1, int(round(float(maxi(1, f.level)) * float(LEVEL_COST_PER)
		* learn_rate(f))))
```

Priced off the LEVEL, like theirs, at **half their rate** — our credit economy is
smaller (a Backyard club nets eight to nineteen a season) and this register is
explicit that *"not copied: their scarcity."*

The `learn_rate` term has no equivalent in Retro Bowl and it is the better half:
**a man slow to learn is dearer to push.** 7 CC for a twenty-year-old at level
five against 20 for a thirty-eight-year-old at the same level, off the same curve
the XP bar already reads.

`test_office.gd` now asserts the property the comment claimed — the ladder RISES
across levels 1/3/5/8/12 — and that the age term survives. Against the old code
it reports `the level price stops rising: [2, 6, 6, 6, 6]`.

### THE OTHER THREE WERE ALREADY VARIABLE

`tools/probe_prices.gd` prints all four ladders, because the claim "our prices
scale" is worth a table rather than a reading of the source:

| row | priced off | range |
|---|---|---|
| MORALE | his mood word | Toxic 4 · Bad 3 · Ok 2 · Exceptional 1 |
| CONDITION | the damage to the harness | 1 at a scratch · 5 at a wreck |
| XP LEVEL | his level × 2 × learn_rate | 2 · 6 · 10 · 16 · 24 · 30 |
| CONTRACT | his wage and years left | 1–4 on a starting club |

Every one is a fact about the MAN IN FRONT OF YOU rather than a fixed tariff,
which is the thing Pete was pointing at.

## THREE MOCKUPS, ON REAL PRICES

`tools/mock_meeting.gd` draws the card three ways on one man off a real starting
club — **A** their shape (four rows, read-out / verb / price in its own box),
**B** two columns with the price on the button, **C** the strip as currently
built.

Every number on all three is called from the live function — `negotiate_cost`,
`kit_cost`, `Career.level_cost`, `Season.extend_cost` — so **a mock cannot
flatter a price the game does not charge**, which is exactly what the
after-action mock did when its column widths were invented rather than measured.

The man is toxic, on a 46% harness, at level five with a year left on his deal:
something wrong in every row, because a card whose every value is already at its
best is a picture of four disabled buttons.

### THE ONE RULE WORTH TAKING WHATEVER THE LAYOUT

**A disabled control still shows its price.** In their screen Boost Morale at
100% morale is blacked out and STILL reads 1 CC. The player learns the lever
exists before he needs it, which a hidden button cannot teach him. All three
mocks carry it.

---

## THE MEETING CARD, BUILT — layout B with the effects showing

Pete, 14 Sep 2026: *"Let's go with B and add the affected stats underneath. Then
when you hit the buttons, you can actually see the effect (bars filling, Toxic
rising to next level, condition counting up in both areas, and contract/salary
counting up to new numbers."*

Four cells, two columns, the price ON the button — one control instead of two,
which is what every other button in this game already is. Under each purchase,
**the stat it moves**, because a purchase whose effect you cannot see is a
purchase you take on trust, and that is the difference between a shop and a
decision.

| row | bar | and underneath |
|---|---|---|
| MORALE | his mood, in his mood's color | Strength 41 → 47 · Gas 30 → 36 |
| CONDITION | the harness | Base 48 → 42 · Inspection passes |
| XP LEVEL | xp against the next bar | To the next 32 xp · Ceiling 99 |
| CONTRACT | the wage bill against the cap | Wage bill $23 of $200 · Years left 2 |

### THE NUMBERS COUNT, AND THEY COUNT IN STEPS

Every value is drawn through `_roll()`, which **remembers only where a number
came from**. The destination is read live off the card every frame, so a roll can
never finish showing a value the man does not have — which is the failure mode of
caching both ends and the reason this caches one.

Progress goes through `Juice.ladder` at six steps, like everything else that
moves in this game. A number COUNTS in whole jumps rather than sliding; a smooth
tween on a pixel screen is the one thing the juice rules exist to prevent, and a
counter is exactly where it would creep in.

One door for all four purchases, `_buy(which)`, which snapshots every number the
card can move in one place. Four separate handlers would mean a roll somebody
forgets to start — a value that snaps while the three beside it count, which
reads as a bug in the ones that worked.

`shot_fighter.gd` photographs the roll mid-flight, because *"you can actually see
the effect"* is a claim about MOTION and a screenshot has one frame. The armorer
takes a harness 42% → 45% → 50% → **58%**, Base climbs 48→42 to 48→44 beside it,
and the purse counts 60 down to 57. Five captures now: the +1 row, the door, the
card, the roll and the roll landed — and the "finished" shot had to be moved 28
frames later, because the first one was taken four frames in and caught the
counter still at 50%.

### A SCRIM CANNOT COVER A BUTTON. STILL.

Third time this project has paid for it — FIGHT was pressable through the
corner's sub popup, the report drew over a live splash button, and the first
build of this card left **Back, Stand down, Extend and both paging arrows armed
underneath it.** A Control is a node, not paint: dimming the pixels behind a
modal leaves every hit target under it live.

The card does not draw over this screen's controls now, it REPLACES them —
`_build` returns early when it is open and builds nothing below.

### "IT DEFINITELY NEEDS BETTER FORMATTING"

It did. The first build drew morale with two text lines and no bar, condition
with a bar at one baseline, and the level and the deal with a bar at a different
one — **four arrangements rather than one shape**, because each row was laid out
where it happened to fit. The read-out sat at x=60, the button at 210 and the bar
at 140 wide under a 250-wide button: four numbers that had to agree and did not,
so the columns sat 16px from one edge of the panel and 36px from the other.

Everything is measured off `CARD` and `COLS` now. `CELL_W` is derived from the
panel width, the padding and the gutter; `BTN_W` is what the read-out leaves;
the bar runs the FULL cell rather than stopping at the width of the box above it,
because it answers the button beside it as much as the box, and a bar that stops
short of the control it belongs to reads as belonging to neither.

> **A number that has to agree with another number is a number that will stop
> agreeing.** Written on this screen's own `+1` row months ago, about a hardcoded
> button width. The card had to learn it again.

## 24 — THE PAGE THAT NEVER REDREW, AND THE LADDER

Pete, 14 Sep 2026, on eight Retro Bowl screenshots: *"I agree with your
recommendations for this. Let's build these into the game!"* — the
recommendations being (1) record the difficulty each bout was fought at, (2) show
what a choice costs before it is made, (3) a one-page season review, (4) group the
table by what a club is chasing, (5) band the post-match readouts. One and two are
in. Three is in. What four and five turned up on the way is the rest of this
section.

### A BRANCH HAS TWO ARMS AND A SCREENSHOT HAS ONE FRAME — TWICE MORE

The priced dilemma options rendered on the first try, and the shot showed them
sitting over **the tournament bid's two buttons**. The button block was moved onto
`blocked_by()` in section 22 and the DRAWING was left reading `dilemma.is_empty()`
— so a season that opens with a bid AND a card on the table printed the card, its
three answers and their new prices, above buttons that answered something else.
One queue; the drawing asks it now.

Then the panel's body was blank. `Juice` was ticking perfectly — a probe read 115
of the card's 118 characters at frame 420 — while the shot of that same frame
showed nothing at all.

> **An animation on a canvas that only redraws on rebuild is a still frame.**

`SeasonScene` asked for a frame in exactly two places: `_rebuild()` and the dev
mood override. So the typewriter, the blinking cursor, `type_skip` for a player
who reads faster than the machine prints, and a comment explaining how it avoids
restarting every frame had all been dead since the day they went in. Every check
in `test_ink.gd` calls `queue_redraw()` before it looks, which is the one thing
the screen could not do for itself — so *"a dilemma card prints itself without
being asked"* opens the ledger and lets thirty frames pass while asking for
nothing. It reads 0 strings against the bug and 10 with the fix.

### A MIXED ANSWER IS THE ONLY KIND WORTH THINKING ABOUT

`Dilemma.costs()` first returned strings and `tone()` painted the row one color.
"Just the eight" spends four credits, annoys the room and **buys kit**, and the
row printed `kit +8` in red because the other two fields outvoted it. Direction
per figure now, off one read of one dictionary, so the words and the colors
cannot disagree. `tone()` is gone rather than left lying around.

### THE SEASON REVIEW, AND WHAT IT COST TO FILL IT

Fourth tab in the book. Opponent with an `@` on the away days, rounds, the DIFF
swing, and the grade each week was fought at — the column Pete's note is about:
a manager who drops to FRIENDLY for a month and climbs back out should be able to
see that he did. `year_summary()` lives on the season, not in `_draw()`, because
*a total of what happens to be on screen is not a total* and a total computed
inside a draw call is a total nothing can check.

The shot tool then wanted a division long enough to fill both columns, and could
not get one. Writing `clubs[me]["tier"]` by hand put the club in a table that did
not contain it and threw on every draw — *a state reached by a road the game does
not have is a state the game cannot be in* — so it had to be reached by winning.
It was not reached. That is section 24's real finding.

### THE LADDER

Three careers, same seed, each a real walk through the real doors.

| manager | squad | power | finishes |
|---|---|---|---|
| renews nothing | 13 → 6 | 37 → 20 | 5th, 6th, for ever |
| renews everybody | 13 → 6 | 37 → 20 | 5th, 6th, for ever |
| renews and SIGNS | holds at 10 | 37 → 20 → 41 | promoted once in 45 seasons, relegated at once |

Renewing every contract every winter changes **nothing**: 100% of re-signings
succeed and the squad drains anyway. It is not contracts — it is retirement with
no refill. `_fill_squad()` tops the club up to `party_size()`, which is
`office.travel_slots`, which starts at five. A club of six satisfies it for ever,
so a squad only ever shrinks unless the player buys travel slots or signs men.

The starting thirteen are also a COHORT — all 26 to 30 — so they age out
together and the cliff lands on every career at once, around season 5 to 9.

And the division the player is sinking out of cannot sink with him.
`_drift_ratings()` holds every AI club inside its tier's band, clamped to
[24, 52] in the Backyard Circuit and pulled toward 38 every summer; the player's
number is his actual roster. He can fall below a floor the division cannot reach.

> **A number the game guarantees for one side and computes for the other is a
> comparison between two different things.** Third time this project has found
> that shape — `gate_income`, `will_wait`, `retire_chance`, and now the whole
> table.

This is a balance decision, not a bug, and it is Pete's to make. The measurement
is here; nothing has been tuned.

### A REFUSAL THAT NAMES ANOTHER DOOR IS A PROMISE ABOUT THAT DOOR

Found while chasing the drain, and real on its own. `resign()` told every man
still under contract to *"Extend him instead"* — including the man on his LAST
year, whom `can_extend` refuses on purpose, and the man already on the longest
deal the club can write, whom it also refuses. Two dead ends, both reading like
advice, both hit every single winter by the one fighter a manager thinks about
most. Nothing errored. Nothing looked stuck.

The bound was briefly widened to take the last year, which `test_market.gd`
caught in one run: extend and re-sign would then be the same button with two
prices and nobody would ever pick the dearer. The bound went back; the sentences
were fixed. Last year now reads *"Let it run out, then re-sign him"*, which is
the road that works, and the check walks every legal length of deal rather than
the one that had gone wrong.

### THREE PROBES IN A ROW THAT DID NOT DO WHAT THEY SAID

The spender's fourteen seasons came back **byte for byte identical** to the
walker's: `buy_level` buys the XP and a level then sits waiting to be PLACED, and
the probe never placed one. The keeper re-signed everybody and lost his squad
anyway: it acted on `years <= 0` and men at `years == 1` fell down the gap
between its two branches. Both probes threw away every return string.

> **An error you do not read is an error that did not happen.**

Each of those was reported as a finding about the game before it was found to be
a finding about the instrument. The rule that keeps catching them is the old one:
*a number with no error bar is not a measurement* — and a policy that produces
the same number as its opposite has no error bar, it has a bug.

### THE TABLE, BANDED

Sixteen clubs in the National read as a ladder you count down, when the question
the player is actually asking is which of three things he is in the middle of.
The four-pixel edge stripe marks a row; it does not group one.

It had to cost NO height — sixteen rows at 22 already end at 514 on a 540 screen,
so captions or gaps between the bands would push the bottom club off the bottom
of the division. A ten-percent wash of the band's own color behind the whole
row groups them for nothing, and the stripe stays for the exact edge. The
player's own row keeps its highlight and takes no wash: it has to read as HIS
first and as a relegation place second.

### THE PURSE RAN OUT OF ITS BOX AT FOUR DIGITS

Found in a screenshot taken for something else. `probe_rich.gd` handed a club
3,000 credits a year to see how far the ladder could be climbed, and the header
came back reading `41616 CC` straight through the mood word beside it. Measured
afterwards: the box left 94 pixels and **`4096 CC` needs 98** — four figures, a
bank a player reaches in two seasons, in a readout that rides the header of every
screen in the game.

`test_ink.gd`'s own header has named this hole since it was written — *panels are
drawn rects with no association to the text sitting on them* — and naming it was
all that had ever happened to it. It is closed for the one readout that grows
without bound: the box is 150 wide now, thousands print as `41.6k CC`, and the
check reads `PURSE_BOX`, `PURSE_AT` and `PURSE_SIZE` off the screen's own script
rather than retyping them, because a check that retypes the box it is checking
passes for ever after somebody moves the box.

The first format was wrong too, and the check caught it in one run: 99,999 printed
as `100.0k`, the longest string the function could produce, from the one value
the threshold was supposed to keep short. The branch is taken on the rounded
figure now.

### WHAT A SCREEN SHOWS BEFORE THE FOLD IS WHAT THE SCREEN IS ABOUT

The after-action cards were six identical boxes in one grid — the table, the
gate, the following and three fighters, side by side and indistinguishable. Two
bands now, THE MEN and THE CLUB, off a `kind` on the card rather than off its
position in the array.

Banding made a fold that was always there suddenly matter. The pane shows one row
of three before it scrolls, and with the old order that row was a league position
the player can read off the table screen, a gate receipt, and a follower count —
while the men he had just watched fight were the part he had to go looking for.
The men go first.

Two more things fell out of it. Nothing on that pane clips, so a card straddling
the bottom drew its full height anyway, under the button, with its second line of
text reading through it — it fitted before only because the grid was one row.
Whole cards only now. And the pane has scrolled since the day it was built
without ever saying so, which is the same as not scrolling; it says `more v`.

### THE CEILING

`probe_rich.gd`, the aggressive end of the ladder question: 3,000 credits a year,
the cap raised three times a season, every contract renewed, and the best man on
the market signed over and over until the books are full. Forty seasons.

It wins the Backyard Circuit four times and finishes **8th of 8 in the division
above, every single time**, relegated at once. Club power plateaus at about 40
against a second tier whose band is [40, 58] and whose pull is toward 49.

The mechanism is in `Market.pool(..., world.player_tier(), ...)`: the market is
scaled to the division you are IN.

> **You can only ever buy a squad good enough for the division you have already
> left.**

So a club cannot assemble a promotion-worthy squad before going up, and once up
it is relegated before it can build one. Four candidate levers — a market that
reaches one tier above, a season's grace for a promoted club, a softer pull on
the AI band, or faster development — and all four are Pete's call. Nothing has
been tuned.

## 25 — THE SHAPE OF THE SCREEN

Pete, 15 Sep 2026: *"This will be played on Mobile. Deep dive Retro Bowl to see
what other platforms they use and what they do for their aspect ratios"* — then
*"Lets do exactly what Retro Bowl did except for the fighting arena."*

### WHAT RETRO BOWL DOES, MEASURED RATHER THAN REMEMBERED

I was sure it was a portrait game. It is not, and the first thing the research
did was correct me: load the web build in a portrait viewport and it prints
**"Rotate your device to play like a pro"**. Landscape only, no portrait mode.

It ships on iOS and Android (Jan 2020), Switch (Feb 2022), browser via Poki, and
Google Play's Windows/Chromebook path. Built in **GameMaker** — Simon Read
mentions coding in it while watching game film. The licensed line (NFL Retro
Bowl '27, Retro Bowl College+) is Apple Arcade.

The native app and the web build do **different things**, which is the finding:

* The **web** build is locked to 16:9. Resized through a range on Poki: at
  1200x420 it pillarboxes to a 630x354 band — 1.78, dead-on 16:9 — and at 4:3 it
  letterboxes top and bottom. Fixed virtual resolution, bars both ways.
* The **shipped app** does not. App Store assets are 1286x594 (19.5:9) for
  iPhone and 1656x1241 (4:3) for iPad, and both fill edge to edge. Same screens,
  two shapes: the draft grid sits in a centerd band with ~220px of margin each
  side on the phone, and on the tablet the same screens grow VERTICALLY — the
  press-interview screen opens a huge gap between title and content while the
  currency stays pinned top-left and the answers stay pinned to the bottom
  corners. The field camera trades width for height: ~35 yards across with the
  sidelines cropped on 19.5:9, ~30 yards with the whole field visible on 4:3.

No fixed virtual resolution, no bars, no stretch. Elements anchored to real
screen edges; the middle absorbs whatever shape it gets.

### WHAT WE WERE ACTUALLY SHIPPING

Two things, and the first is a bug nobody could have seen from a screenshot.

**`display/window/handheld/orientation` was 1.** Printed from the engine's own
enum rather than trusted to memory: `SCREEN_PORTRAIT = 1`. A 960x540 landscape
game configured to lock handhelds to portrait. It is 4 — `SENSOR_LANDSCAPE` —
now, so the handset can be held either way up.

**`stretch/aspect` is `expand`, which is the right call, and nothing read it.**
`expand` does not letterbox; it hands the game a bigger canvas. Measured with
`tools/probe_viewport.gd`:

| screen | canvas |
|---|---|
| 16:9 | 960x540 |
| 19.5:9 (iPhone) | 1170x540 |
| 20:9 | 1200x540 |
| 21:9 | 1260x540 |
| 4:3 (tablet) | 960x720 |

So the design is never squeezed — it always gets at least 960x540 and gains the
rest in one axis. But `UiKit.SCREEN` was `const Vector2(960, 540)` and every
right edge in the game was a literal measured off it, so on a handset the
background itself stopped at x=960 and a **210-pixel strip of raw clear color**
ran down the right of every screen, gold bottom bar included.

`shots/aspect_1170x540.png` is the first frame this project ever rendered that
was not 960 wide. It took four minutes to find a bug that five hundred and
forty-odd checks had been green through for a month.

> **A suite that only ever renders one shape is measuring one shape.**

### THE FIX

`UiKit.SCREEN` is gone. `UiKit.screen()` reads the live root viewport, cached per
frame; `right_edge(m)`, `span(m)` and `bottom(m)` are the three measurements
every screen actually takes. Making it a FUNCTION rather than a static var was
the point — the compiler found all hundred-odd call sites the day the const went
away, instead of me finding them one screenshot at a time. A variable would have
needed somebody to refresh it, and a screen that forgot would draw last frame's
shape.

Then the layouts. Right edges, panel widths and the button row re-anchored across
twelve screens; `ACTION_INSET` replaces `ACTION_Y` so the button row is 64px off
the bottom of whatever canvas there is — still exactly 476 on every handset,
because a handset never changes the 540, and properly at the foot of a tablet
instead of floating two-thirds up it. The club tab's two columns now split the
live width (47.5% to the fixture, the rest to the table) because with both pinned
to their own edge the extra width opened as a hole down the MIDDLE rather than as
margin at the sides. The header's purse and mood ride the right edge beside the
Menu button. The league table's stat block hangs off the right edge instead of
sitting at a fixed `TABLE_X + 240` with the highlighted row running past it.

### TWO CHECKS, BECAUSE THE FIRST ONE COULD NOT SEE IT

`test_ink.gd`'s frame is live now and the runner runs it at 960x540, 1170x540,
1260x540 and 960x720. That immediately failed its own canary — the one that
deliberately draws a string off the frame did it at x=920, which at 1170 wide is
comfortably ON the screen. **A canary pinned to a number the frame no longer has
is not a canary.**

But the ink sweep reads a ledger of `draw_string` calls, so it can tell you a
label ran off the frame and never that the frame was unpainted. `test_shapes.gd`
renders sixteen screens and looks at the pixels: five samples down the far right
of each, failing on any that is still the clear color.

It took two goes to be worth anything. The first cut failed a screen only when
the WHOLE right column was bare, and pinning the season screen's background back
to 960 did not trip it — the gold bar and the table rows still reach the edge, so
one lit sample out of five passed a screen with a 210-pixel hole in it. It also
passed its first run at 960x960, a shape no device has, because it read the
viewport on frame zero before the window had settled. Both are fixed, and it now
fails the original bug with `4 of 5 samples down the far right are bare` and
passes the fix — verified by reintroducing the bug on purpose.

> **A check that does not verify the state it set up is a check that will one day
> pass without entering it.**

### LEFT FOR THE ARENA CHAT

`scripts/melee/melee_scene.gd` was not touched. It keeps its own
`const SCREEN := Vector2(960.0, 540.0)` — 28 references — so it is self-contained
and nothing above reached into it. Four decisions belong to whoever is settling
the fight screen's pixel scale:

1. **That const.** The corner, the fight HUD, the report and the splash are all
   laid out against it, `SKIP_AT` included, so every fight screen stops at 960 on
   a handset exactly as the management screens did. The same
   `UiKit.screen()` / `right_edge()` / `span()` helpers are there when wanted.
2. **The full-screen art slot.** `list_ground` is drawn at line 1036 into
   `Rect2(Vector2.ZERO, SCREEN)`, and `ArtBank.fit()` scales-to-fit and CENTERS —
   so a 960x540 backdrop on a 1170 canvas sits centerd with ~105px bare each
   side. Wider source art, tiling, or a crop: an art call, not a layout one.
   `art_bank.gd` has three 960x540 slots declared (`venue_away`, `venue_neutral`,
   `list_ground`).
3. **What the camera shows on a wider screen.** Retro Bowl's answer is more
   world horizontally and the HUD pinned to the real edges. Ours is the same
   question and the melee sim owns it.
4. **`display/window/stretch/scale_mode` is `fractional`.** This is the pixel
   scale lever and it is a real tension. Fractional gives no bars but a
   non-integer device scale on almost every phone — 2532/1170 is 2.164 — so one
   art pixel does not land on a whole number of device pixels. `integer` gives a
   perfect grid and brings the bars back. Retro Bowl took the no-bars route. The
   project already runs nearest-neighbor filtering with 2D transform and vertex
   snapping on, which is what keeps fractional crisp; whether that is good enough
   at the scale the art is authored to is the art chat's call, and changing it
   changes every screen in the game, not just the fight.

## 26 — THE CODE LIST AND THE HOUSEKEEPING

Pete, 15 Sep 2026: *"Let's get you done all all the code and housekeeping."* Every Code
and Housekeeping row on the Ship List, in one pass.

### SIXTEEN FUNCTIONS WITH NO CALLER, RESOLVED

Wire it or delete it; the third option is the one that rots. Ten were wired, five deleted,
one handed to the arena chat — and four of the wires closed a real gap rather than tidying
a lint warning.

| | |
|---|---|
| `events_this_season` | the same expression was written out inline in four places |
| `over_cap` | both wage-bill footers said THAT you were over and never BY WHAT |
| `can_afford_wage` | the market colored the FEE by whether you could pay it and left the WAGE plain — *"a market that shows one of them lies about half its refusals"* was already written on that screen, about that card |
| `can_boost` | the night-out button looked live every week and spent a tap to say no |
| `next_tier` | its own comment says *"the Clubhouse screen wants this"*; the screen never asked, so the division a build needs was only visible inside a refusal you had to earn by trying |
| `is_flaw` | see below |
| `routes_of` | the chalkboard scene reached into `plays[i]["routes"]` by hand |
| `drain_all` | see the migration below |
| `dither` | its comment says it *"belongs on a meter track"*; every bar in the game drew a flat track |
| `breathe` | see below |
| `sync_player_power` | **deleted** — an exact duplicate of what `Season.sync_power()` does on its own line 297. 23 callers on one, none on the other |
| `wearable` | **deleted** — the Create screen draws the whole bank as a shelf, dimmed and priced, on the principle that *you cannot want a thing you cannot see*. A filtered list is the wrong answer to that screen's question |
| `events_left` | **deleted** — the fixture card says it better: "EVENT 4 OF 5" is the same two numbers arranged so you see the distance and the whole |
| `hints` | **deleted** — see below |
| `Juice.frame` | **deleted** — a public getter for a counter nothing outside the file wanted |
| `cancel_order` | **arena chat** — its only possible caller is in `melee_scene.gd` |

### THE GAME HAD NEVER NAMED A FIGHTER'S TRAIT

Wiring `is_flaw` turned up something bigger than the helper. `FighterTrait.name_of()` and
`blurb_of()` had **no caller anywhere in `scripts/game/`** — nine wired hooks moving
numbers the player could feel and could not name, on a screen that lists his weight.

"Known for" is on the fighter card now, colored by `is_flaw`, with the blurb under it.
That color is the whole reason the function exists: *a pool with no downside is a stat
wearing a nicer hat*, and printing Prima Donna in the same color as Talisman would hide
the half that costs you something.

It cost 30 pixels the panel did not have. The first fix grew `COL_H` by 14 and the panel's
new bottom ran under the +1 button row — which the ink sweep did **not** catch, because
the text was inside the panel and the panel was the thing in the wrong place. The list pays
for it out of its own rhythm instead: six rows at 22 instead of 24, which is invisible.

### THE HINT BAR IS GONE, AS A DECISION

Fourteen lines never drawn on any screen. Wiring it was never a call — it wanted 26 pixels
reserved at the foot of sixteen scenes, which is a layout pass, and the screens had just
been re-anchored to a canvas that changes shape. **A function with no caller is not a
feature, it is a question nobody answered.** The git history has it now, which is new.

### THE SAVE MIGRATION

Strict equality was right while the only v11 files in the world were on this machine and
wrong the moment anybody else has a career — this project moved the version four times in
a month, and each move would have wiped every player's club.

`VERSION_MIN = 11` is a floor and `_migrate()` walks a file forward one version at a time.
The floor is 11 rather than 1 deliberately: versions 1–10 predate a career worth keeping
and no file of them exists outside this repo, so claiming to migrate them would be claiming
to have checked something nobody can check. **A migration nobody can test is a promise, not
a path.** A file newer than this build is refused too — it can carry fields this one would
silently drop.

`Career.drain_all()` is what pays out the levels an old file owes, run after the decode
because `_migrate` works on a raw dictionary and levels live on decoded cards. It was
written for exactly this — *"for a save loaded from a build that had no levels, where a
man may be owed several"* — and had no caller for months for want of a migration to call
it from.

### PANELS, SWEPT AT LAST

`test_ink.gd` opened by admitting it could not see them: *"panels are drawn rects with no
association to the text sitting on them."* Named from the day it was written, and naming
it was all that ever happened to it.

`UiKit.panel()` writes its rect to the ledger now and the sweep pairs the two lists —
for each string, the INNERMOST panel containing its left edge, because panels nest and the
meeting card sits over the three it is a decision about.

Three on the first run: a credits line 17px over, the fighter panel's footnote 88px over,
and the tournament card's subtitle 53px over — **clipped mid-sentence in the oldest
screenshot in `shots/`**, where it read as a sentence that stops rather than a sentence
that was cut. Then it caught the first fix for the first one, which wrapped the line and
pushed the line below it out of the bottom of the same panel. That is what a check is for.

The slop then had to come down from three pixels to one, because three was enough to pass
a line sitting visibly outside the fighter panel in a screenshot on the same screen.
**A slop that hides a real overflow is not tolerance, it is the check declining to answer.**

### EVERY SCRIPT PARSES

`shot_menus.gd` had been broken against a facility enum that moved underneath it —
`HOME_GROUND` became the arena — for long enough that nothing in the repo remembered. A
tool that fails loudly the moment anybody runs it sounds self-correcting and is the
opposite: nobody runs it, nobody sees it, it rots.

`run_tests.sh` parses every `.gd` in `scripts/`, `tools/` and `tests/` with `--check-only`
before it runs anything. One second, and it covers what no test does: the instruments.

### FOUR SLOTS THE PLAYER CAN ORDER

Favorites could be starred and unstarred and never arranged, which is the one thing four
slots want: the corner offers them in list order, so the first is the one you reach for
under a clock. `promote_favorite` / `demote_favorite` — a swap, not a drag, because a
drag needs a pointer the corner has no time for and two taps on a list of four is the same
job with one thumb. The control belongs on the corner screen, which is `melee_scene.gd`,
so that half is in the arena hand-off.

### THE DOCS THAT WERE LYING

`README.md` is rewritten. It described a portrait game with no meta layer — *"no season,
no calendar, no roster management, no economy, no menus outside the bout"* — when all
sixteen of those screens existed, and it said **"Portrait, 540×960"** in three places while
the project shipped a 960×540 landscape game whose handheld orientation setting was set to
portrait.

That is the clearest evidence this project has produced for a rule it had been treating as
tidiness: **a stale doc is not harmless, it is a wrong answer nobody is checking**, and
this one plausibly wrote itself into `project.godot`.

`CREDITS.md` opened with "SHIP BLOCKER. There is no credits screen in the game yet" — the
screen exists and generates itself from `Audio.LICENSED`. A solved problem still advertised
as a blocker costs exactly as much attention as a real one. What is still outstanding is
named instead: the menu track is on a revocable licence and `menu_own` is an empty slot.

`docs/LEAGUES.md` listed five things as unbuilt. All five were built. Corrected with what
each one actually is now.

And ten `[NEW]` markers in `fighter_trait.gd` said their hooks needed building while
`PENDING` — the constant `is_wired()` actually reads — was empty. **When a comment and a
constant say different things about the same fact, the comment is the one that will be
believed and the constant is the one that is true.**

### UNDER GIT

671 files, one commit, on `main`. No version control since 10 Sep, so no history, no
branches and no way to bisect anything. `shots/` is tracked on purpose: half the findings
in this register are "the screenshot showed something no test could see", and a repo that
throws them away throws away the record of how the layout got the way it is.

The README's own documented workaround for the sandbox's lock problem did not survive
contact — `mv` could not move `.git/index.lock` either, because the sandbox refuses to
unlink it at all. It took a delete-permission grant for that one folder. The README still
carries the `mv` recipe because it is right for the tmp objects; the lock needs the grant.


## 27 — THE COUNTER, THE STRIP, AND THE THIRD KIND OF INVISIBLE

15 Sep 2026. Pete: *"Lets go export targets, IAP, favorites, and cancel order."* Four
items off the ship list. Export targets and the store were built in section 26; this is
what finishing them cost, and what finishing the other two turned up.

### A function inserted into the middle of another function

The clubhouse tab rendered as a flat gray rectangle with no UI on it at all. The cause was
a helper — `_role_col_w()` — that had been written into the body of `_draw_office()`
rather than after it, splitting the function in two and orphaning everything below it.

The tool that took the screenshot **reported two successful writes**. It wrote two PNGs of
a blank frame and said so cheerfully, and the run's stderr, which was not read, carried
the error. This is the same house rule as before and it keeps coming back in new clothes:
**an error you do not read is an error that did not happen.** The fix in the loop was to
pipe every render through `grep -E "SCRIPT ERROR|wrote"` so a silent failure cannot be
read as a success again.

### Text over text is the one thing the ink sweep cannot see

`test_ink.gd` finds a string off the frame, a string on a control, and a string running
off its panel. A string printed *through another string* is none of those: both are on the
frame, on no control, inside the same panel. It is perfectly placed and unreadable.

Three of them were on the clubhouse tab at once. `PLACES ON THE BUS` and `13 fit on the
books` printed as `PLACES ON THE BUS13 fit on the books`. `6 of 8 places` ran into the
bench note. The training blurb — 462 pixels against a 440-pixel column — printed straight
through `ON THE LIST` in the next column.

Every one of them was the same shape: a label drawn at a left edge, a note right-aligned
to a right edge inside a hand-typed width, and nothing anywhere that knew the two could
meet. **Two things anchored to opposite edges of one row are two things that will
eventually touch.**

`UiKit.pair()` is the answer: one call that draws the label, measures it, and gives the
note whatever is left. The note is the half that gets clipped because the label is the
half that says what the row is. If there is no room at all the note is dropped rather than
drawn through the label — the only other honest answer.

### And a clipped sentence is invisible too

Fixing the collisions produced a second fault immediately: `13 fit on the boo.` and
`1 on the bench · 1 sw.` The overlap was gone and the meaning was still missing, and
nothing in the suite could see that either.

So `UiKit.fit_px()` — the same cut as `clip_px`, except that having to cut is **recorded**,
and `test_ink.gd` fails on the recording. The two doors are deliberately different things:

| door | for | a cut is |
|---|---|---|
| `clip_px` | a club a player named, a fighter off the generator | the layout working |
| `fit_px` | a label, a note, a blurb — words *we* wrote | a fault |

A name can be any length and cutting one is correct. A sentence we wrote for a column we
chose that does not fit means one of the two is wrong, and a cut sentence reads to a
player as a broken game rather than as a long name. The check carries its own negative
control, same as the ledger's: it sets up the exact fault and confirms the recorder sees
it, so a refactor that quietly stops recording fails here rather than in the next
screenshot.

Three strings were shortened and one blurb rewritten. The suite reads 658 strings across
20 screens and reports **0 cut short**.

### A scrim cannot cover a Button — the fifth time

The coaching-credits shop is a modal, and `_rebuild()` had the right guard in the wrong
place: the `if shop_open: return` sat *below* the tab row, so the modal covered five tab
buttons in the drawing and left all five of them live. A tap on CLUBHOUSE behind the shop
changed the tab underneath and the player found out on the way back. The guard moved to
the first line after the wipe.

The same edit orphaned the gold tab underline — a mark pointing at a control that is no
longer there — which moved below the guard too. **A modal that hides a control has to stop
drawing what the control was for, not just the control.**

### Taking back a route

`MeleeSim.cancel_order(idx)` had been written, and had had no caller since the day it was
written. You could drag a man somewhere and the only way out was to drag him somewhere
else — which is not a cancel, it is a second wrong instruction on top of the first.

It is a tap now, in the branch that already means *this man, and I am not drawing*. Only a
route the player drew: a called play's routes carry `from_play` and are the plan the whole
line is running. No confirmation is drawn because three things change in the frame the tap
lands on — the route line goes, the card border drops from ROUTE to EDGE, and the card
stops saying "on a route".

### Where a reorder control does not go

`promote_favorite` and `demote_favorite` had passed seventeen checks for a week with
nothing calling either one — a tested verb no player could reach, which is the most
convincing kind of dead code, because the suite is green. **A function with no caller is
not a feature, it is a question nobody answered**, and a green suite is not an answer.

The hand-off note had suggested up/down taps on the corner. That was wrong twice: the
corner is the one screen in the game with a clock on the player, and a two-by-two grid has
no up and down — it has four positions, so arrows on it would point in a direction that is
not on the screen.

The strip went under the playbook in starring mode instead: no clock, a mode already named
"picking favorites", and a left-to-right order that is exactly the order the corner grid
fills. It cost 68 pixels, and those pixels came **out of the book's height, not out of the
panel** — `panel_box` grows downward from a fixed y, so anything added to it comes off the
bottom of a 540-pixel frame. The first cut pushed "Done picking favorites" half off the
screen. One constant, subtracted once.

Both new controls are held by a source check as well as a behavior check, because the
thing that was missing for a month was not the behavior. It was the caller.

### The toolchain disagreed with itself

15 Sep 2026, immediately after the export work. The test container ran
**4.6.stable**; the machine that will actually ship the game runs **4.6.2**. A
green suite on an engine nobody builds from.

That is not a cosmetic split, because **export templates are matched to the patch
number** — a 4.6.2 editor will not use 4.6.stable templates and the error it
gives says nothing useful. The container is on 4.6.2 now and the whole suite was
re-run there: 629 checks, 43 files, no failures, and the Linux export rebuilt and
launched on the new engine.

The way it surfaced is worth keeping. `android_check.ps1` had `4.6` typed into it
in two places, so on Pete's machine it looked for templates in a folder that will
never exist and told him, confidently, that his engine was wrong. Same rule as
section 25 and for the same reason: **a number that has to agree with another
number is a number that will stop agreeing.** So nothing in `tools/` carries a
version any more — `run_tests.sh` finds whichever engine is there and prints its
version every run, and `godot_find.ps1` asks the binary and derives the template
folder from the answer.

One trap found underneath it. `Godot_v*_console.exe` on Windows is a **198 KB
stub** that relaunches the main `.exe` beside it by exact filename. Pete's folder
had the stub and nothing else, so it exited with *"Main executable ... not
found"* — which reads as a broken engine and is a missing file. `Find-Godot` now
tries every candidate and accepts only one that answers `--version` with a real
version string, which is the difference between reporting a symptom and
reporting the cause.


## 28 — THE AUDIT (27 Sep 2026)

A fresh-eyes read of the code (no docs), 75 findings, then phases 0-4 and 7-9 of
the fix list done end to end. Phases 5 (store/export) and 6 (Steam) and the art
were left out on Pete's call. The list is the project doc `code-audit-27-sep`.

| # | Item | Status |
|---|---|---|
| 28.1 | **The gate could not go red.** `test_save` crashed in its fingerprint (`office.members` no longer existed) and asserted nothing; `test_book` printed ~700 engine errors; the runner read exit codes only. | **locked** — a file passes only on exit 0 + banner with N>0 + no SCRIPT/Parse error + no unlisted engine ERROR. |
| 28.2 | Fast gate / balance tier split (`RB_TIER`). | **locked** — test_melee 465 s -> 43 s in the gate; the statistical measures and C-6 run in the balance tier, which is not optional before a balance change. |
| 28.3 | A save that will not open was DELETED on Continue. | **locked** — set aside as `.bad-<time>`, never deleted; RBH2 container (length + MD5) verified before decoding; `.tmp` -> rename, `.bak` kept and used. |
| 28.4 | Bought credits: wallet emptied before the season saved; lost on a job change. | **locked** — claim saves first; `ClubOffice.bought` follows the coach. |
| 28.5 | Four traits never fired in real bouts (fixture set after `_build`); Cold Hands inert; Engine pure downside; Slippery backfired. | **locked** — `MeleeSim.dress()`; each held by `test_audit_melee`. |
| 28.6 | A sub inherited the subbed man's afternoon (stats, XP, harness, injury). | **locked** — per-card ledger, `sim.fought()`. |
| 28.7 | Android back quit the app from anywhere. | **locked** — `AppLife`; each root screen's `go_back()`. |
| 28.8 | Fight screen drawn from x=0 on a 1200-wide phone canvas. | **locked** — centred frame, painted gutters. |
| 28.9 | Pacing package (16 Sep) applied; START_POWER **50** not 48. | **REC** — measured on the five bases after the audit fixes: 48 gave 12.1, 50 gives 11.3 with the old manager. |
| 28.10 | **The measuring manager never answered the federation**, so every pacing number before today was a club barred from every cup and Worlds. | **locked** — `ProbeManager` raises the missing rule. With it: title **12.0** mean (10.8-13.0), power at 20 seasons 72 (was 87), Worlds won 0.4 times a career. The "procession" was league titles, not Worlds. |
| 28.11 | Federation paperwork now visibly holds a National club to ~72 power in the sim. | **locked for playthroughs** (Pete, 27 Sep) — the weight stays as it is; title 12.0 is the starting point to play against. |
| 28.12 | Market proxies re-measured: slack 21/22/42/89; shelf tops moved with the list's 98th percentile. | **REC** — the stored ones had drifted before the package. |
| 28.13 | Two weapon classes: sword-and-shield, polearm. | **locked** (Pete, 27 Sep) — pole reach x1.15, takedown +0.04, easier to bullrush, escapes x0.9; shield bullrush brace x1.05. Symmetric mirror stays ~50%. Generated by role via a hash so the generation stream did not move. |
| 28.14 | Localisation: `UiKit.t()`, 482 strings wrapped, `locale/strings.csv`. | **ASSUMED** — not registered until a column is filled; the font needs accented glyphs first. |
| 28.15 | Quitting the app mid-bout. | **locked: forfeit and warn** (Pete, 27 Sep). `Season.mark_bout_live` is saved as the bout starts; a load that finds it records a 0-2 forfeit (league or cup), re-saves at once, and the season screen says so. The fight's pause screen warns. |
| 28.16 | Skill in the transfer market. | **locked** (Pete, 27 Sep): a stranger's ceiling shows as a range 10 wide, narrowed 2 per star of your best captain (exact at five stars); your own men are exact; the market list is ordered on what the club can see. `Season.potential_range`. |
| 28.17 | 1-0 unreachable under the stop rule; Green wins ~95%. | **locked for now** (Pete, 27 Sep). |
| 28.18 | season.gd / club_office.gd / season_scene.gd split into helper classes with wrappers. | **locked** — behaviour-identical (five-base score unchanged to the decimal). `tools/extract_group.py` did it and is kept. |
| 28.19 | `_backup_20260914/` held duplicate `class_name ArtBank` and `Tuning`, and Godot's class cache resolved `Tuning` to the backup. | **locked** — deleted. Open the editor once so it rescans. |


## 29 — OVERNIGHT HARDENING (27-28 Sep 2026)

Ten items, worked unattended after the audit. Store/export, Steam and art stayed out.

| # | Item | Status |
|---|---|---|
| 29.1 | **Monkey**: `tools/monkey.gd` taps random buttons, draws routes, pauses and backs out through the real screens. | **locked** — 6 seeds x 12,000 steps, ~60 seasons: no script error, no stranded or stuck screen. `bb monkey`. |
| 29.2 | **Invariants**: `tests/test_invariants.gd`, every matchday of 6 careers x 25 seasons, 314 mid-career saves round-tripped. | **locked** — found: the week's kit wear ran after the rating sync, so each simmed fixture used last week's power and a reload changed results. `_apply_regime` syncs last. Title 12.04 (was 12.0). |
| 29.3 | **Flows**: `tests/test_flows.gd` presses the real buttons through five journeys. | **locked** — found: every career starts in the Saltire (a 1 CC mark), so Create refused a plain rename. `Workshop.keep_worn()`. |
| 29.4 | Source-grep tests replaced by behaviour (melee tap, favorites strip, nav, store fence via `Store.release_rules`, the club tab's queue order, audio call sites). test_grade's win-rate measure moved to the balance tier. | **locked** — found: `crowd` and `type` sounds were never played; `type` now ticks every third typed letter, `crowd` on a win. **REC** — both are Pete's to veto. |
| 29.5 | **Speed**: tmod/tflag cached per card, the tank computed once. 159 -> 130 us a tick (desktop), fingerprint unchanged. | **locked** — Skip Round ran up to 3,600 ticks in one frame (~0.5 s desktop, seconds on a phone); it now runs in 10 ms slices as a fast-forward and ends exactly where the sim's skip ends. |
| 29.6 | probe_pace on `ProbeManager`; probe_run pays the federation. | **locked** — probe_run: TOP 3.0 at four grades. **Open**: 3.6-14.6 buildings lost a career to unpaid summers, most at Friendly. |
| 29.7 | UI: flash tones (refusal / good news / question), no sticky hover on touch, `UiKit.back_button` / `corner_back`, `Season.staff_offer`. | **locked** — the soak had been hiring from seed 31337's staff list. |
| 29.8 | Is reading the scouting range a skill? `tools/probe_scouting.gd`. | **Open** — no: even the true ceiling buys nothing (title 11.90-12.35 across all readers). Men grow ~2 a season from ~8 below their ceiling and spend 8% of seasons at it, so the ceiling rarely binds. Pete's call on what should make it matter. |
| 29.9 | Draft translations, 8 languages x 427 strings. | **ASSUMED** — unreviewed drafts, unregistered. Found: the extractor had mojibaked every key with a dash; fixed and held by test_audit_ui. English-fragment sentences made whole. |
| 29.10 | **The scouted ceiling made worth reading** (Pete, 28 Sep: "go for it"). The ceiling drifts up +4 whenever a man nears it, so the rolled ceiling never bound; what it decides is SPEED (a level pays 1 + gap/3 points). Free agents now draw the gap on a skewed curve over 1.8x the old room (`Career.free_agent_potential`, hash-drawn so the market stream is unmoved). | **REC** — youth manager reading the range vs signing on today's rating: **1.80 seasons and 6.0 power** (old shelf 0.25 / 4.3). Held by `tests/test_scouting.gd` (balance tier, floors 0.75 / 3.0; fast tier holds the shelf's shape). Pacing 12.04 -> **12.40**. A sharper scout (oracle vs midpoint) still buys nothing measurable; a wider blind range (15, 3 a star) was tried and did not change that, so the approved 10 / 2 stands. |
| 29.11 | Making a good scout pay. Researched (FM, OOTP: scouting pays where the market prices on what everyone sees and only you see the truth); tried a reputation premium on fees, 30% outright misreads, and the ceiling drift off. | **Open** — none separated the true ceiling from the no-scout read (all within ~0.3 seasons; the premium also slowed pacing to 14.5, reverted). On a six-man shelf a few points of error rarely changes the pick. Where FM's scouts also pay is COVERAGE (more names found) — the captain Scout trait already does that. `ProbeManager` gained Read.BLIND and a value-for-money mode. |
| 29.12 | Buildings lost to unpaid summers. | **locked** — `tools/probe_upkeep.gd`: a club that keeps a reserve loses 0 at every grade; probe_run's 4-9 are its spend-to-the-bone policy (Friendly most because it earns most and banks least). New: `ClubOffice.summer_bill()` on Finances (red with the shortfall) and a once-a-season warning in the last two matchdays. Held by test_audit_season. |
| 29.13 | The body face (81 glyphs) had no "—", "=" or "|", so English drew them in the phone's system font. | **locked** — LanaPixel (OFL, eishiya; 8,339 glyphs, Latin/Greek/Cyrillic/Japanese) sits behind every Buhurt face as a fallback, crisp settings; it draws only what a face lacks. All nine string columns now draw in pixel fonts (held by test_audit_ui). The Hall button's ★/☆ became the pixel icons. +1.4 MB. Its glyphs are 11 px-native, so at other sizes they are not pixel-perfect: an art pass may want its own accented letters in the Buhurt faces. |
| 29.14 | **Difficulty reaches the money, and a Custom grade** (Pete, 28 Sep: "absolutely" / "a custom slider for these options with advanced settings"). Dues and federation renewals scale by grade: Friendly x0.8, Sanctioned x1.0, Full Steel and the Hard List x1.2, Matched x0.8-1.2 on its ladder; buildings are not scaled. A sixth grade, CUSTOM, has five dials saved with the career (strength x0.90-1.10, calls -2..+2, corner -8..+8 s, bills x0.5-1.5, the Hard List rule). The grade tab prints every dial for every grade; on Custom each row has - and +. | **REC** — `probe_upkeep`, first title: Matched 11.4, Friendly 10.9 (was 11.7), Sanctioned 13.0 (unchanged), Full Steel 19.1 (was 17.7), Hard List 20.0 (was 18.6), Custom at defaults 13.0. Zero buildings lost at every grade. Held by test_grade (bill shown = bill taken at three grades; dials clamp, reach the fight and survive a save without writing history). |
| 29.15 | The Hard List at a 20.0-season first title once bills scale x1.2. | **locked** (Pete, 28 Sep): "pretty on par for hardcore" — stays x1.2. |
| 29.16 | Scouting that pays through coverage. `tools/probe_coverage.gd`: 3 extra names on every shelf are worth ~+4.6 club power over a career (returns flatten after 6); the title season does not move. | **REC** — the Scout trait now finds 1 + his stars (3 at two stars, the old flat number; 6 at five; a one-star man scouts nothing, like every trait). The market shows 12 cards (six a row); the ceiling range moved to the star row and "over cap" replaces the wage. Pacing 12.40 -> 12.24. Held by test_scouting. |

| 29.17 | **Every drawn string through the table, in every language.** A settings LANGUAGE row (Automatic + English in release; the eight drafts, marked "(draft)" in their own language, only in debug builds — `Settings.SHIPPING`). ~218 rules-layer messages wrapped (`tools/l10n_wrap2.py`); stored names (clubs, cups, book lines, hall positions) stay English in data and translate where drawn. | **ASSUMED** — 1,194 keys, all 8 languages full, unreviewed (machine drafts). `tests/test_untranslated.gd` pseudolocalizes 22 screens and fails on any drawn letters outside the table: 194 escapes -> 0. It used to skip any line with a translated part in it; it now peels the translated parts and checks the rest, which found English glued onto keys on Squad, Create, Federation and Fighter. |
| 29.18 | English plurals and slot words in keys (`"%d event%s"`, `"You %s."` + "take it"). | **locked** — `UiKit.tn(one, many, n)` picks between two whole keys (the CSV table has no plural forms); the fight verdict is three whole sentences. Slavic languages use a "label: %d" form that reads for every count. The extractor harvests both tn keys. |
| 29.19 | Column headings touching in German ("JRJETZT"). | **locked** — test_layout now wants a 4 px gap between headings in every language, not just no overlap; German NOW is IST, Polish MAX stays MAX. `bb shot locale` loads Settings first so a screen builds in the asked language. |
| 29.20 | The untranslated sweep reached only screens at rest. | **locked** — it now also drives the fight (live, paused, corner, report) and the club tab under each of the 18 dilemma cards: 44 screens and states. Found and fixed: the report's seven column heads, the corner's three, the news bands, the fighter-card status words (down / clinched / breathing / loose), the gate line; ordinals were English ("3rd") everywhere — now four keys a language words itself (`UiKit.ordinal`). |
| 29.21 | A value put into a translated sentence is invisible to the sweep (it lands inside the brackets). | **locked** — a third check reads the source for English literals among a `UiKit.t(...) %`'s values (dictionary keys and comments cut out). Found four in the dilemma outcomes: "morale %s" % "up" read "moral up" in Spanish; each is now two whole keys. Proven by a planted regression. test_layout also measures the fight report's 9 px heads in every language (French MISES AU SOL ran 18 px into its neighbour; four languages shortened). |
| 29.22 | Balance tier after scouting, coverage, difficulty and languages. | **locked** — green (6 runs): scouting edge 1.80 seasons / +5.9 power; invariants 2,436 checks. 1,216 keys, all 8 languages full. |
| 29.23 | **Every screen fits in every language.** test_ink and test_layout take `RB_LOCALE`; the suite runs both in all 8 drafts at 960x540 (the narrowest shape), 2 at a time, +2.5 min. First run: 7 of 8 languages failed, ~60 strings — off panels, off the screen, cut, and buttons growing into each other. | **locked** — fixed at the helpers, so a reviewer's longer wording still fits: `UiKit.button` steps its type down to 10 px before it will grow (and resets the size Godot grew it to before it was in the tree); `text_fit` / `right_fit` / `para` step down up to 3 px, then cut and record; `right` and `mid` no longer let Godot clip silently; `wrap` breaks unspaced Japanese; the staff regime row shares its card in proportion. Hand-split sentences (title slot, fighter record, coach) are single keys now. ~35 draft strings shortened. Found an English bug the old 40-character clip hid: the coach's offer line was always cut. Placeholders ("His name") are now translated and swept. Suite 68 runs green. |
| 29.24 | **Tech-debt pass**, measured: 73 scripts / 35,766 lines (38% comment); 1,434 functions, 4 never called, 36 called only by tests or tools; 2 copied regions; 5 functions over 80 code lines; no engine warnings beyond harness noise; all 126 comment references to test and tool files resolve. | **locked** — the finding that mattered: the club tab's comment said it asked `Season.blocked_by()` and the code asked each question itself, promotion first where the season puts it last. In real careers a dilemma and a promotion offer were pending together 13 times in 32 seasons, and the screen offered "Take it" while the season wanted the dilemma. The tab dispatches on `blocked_by()` now; `tests/test_queue.gd` plays 4 careers x 8 seasons and reads the real tab at every new combination (it fails on the old code). Also: the four dead functions removed (one was an unbuilt honours asterisk — the records screen already writes each event's grade); position colours and the favourite lookup kept once each (`_fav_name` said it reused the lookup and did not). The long functions are icon tables and screen builders, left alone until they can be playtested. |


## 30 — THE FRESH-EYES FIX RUN (29 Sep 2026, overnight)

Six independent auditors graded the game C− (project doc `grading-28-sep.md`). Pete: "make this into 4 big chunks … go continuous". Decisions that need Pete are in `morning-29-sep.md`.

| # | Item | Status |
|---|---|---|
| 30.1 | **Clinch-menu takedown spam won 100% of bouts.** A player's clinch answer landed the instant it was tapped and a missed takedown leaves the man tied up, so every tap was another roll while the AI rolled once per ACT_CLINCH (2.2–3.4 s). | **locked** — the menu takes no answer until the man's clinch clock allows (`MeleeSim.clinch_ready`) and a ready answer lands at once; the menu's own clock only runs while he is ready and its suggestion stays current; the fight screen fades the buttons and fills the bar toward ready. A first cut that queued early answers was a trap (a choice made 3 s before it landed: 22% vs 57% hands-off) and was replaced. `probe_fightskill` (from the audit): smart spam 100% → 30%. Held by `tests/test_clinch.gd` (fails on the old sim). **Open → morning list**: always-TAKEDOWN still beats the AI's own clinch judgment, 77.5% vs 57.5%. |
| 30.2 | Cup nights read the previous bout's mood (`Session.bout_mood` set after `begin_cup_bout`): cup ties never got BIG_OCCASION / FLAT_TRACK, the next league bout did, and a reload changed it. | **locked** — `_dress_sim` asks `Season.mood()`. Pacing unchanged (12.24). |
| 30.3 | 13/13 on the books with fewer than five fit forfeited every week without a word. | **locked** — hurt men stop travelling first; at a full book the weakest *unfit* man is released (trade value paid) to make room for the walk-on, and the note says so. |
| 30.4 | The club you leave on `take_job` kept its roster only in the unsaved cache; a reload rebuilt it from the factory. | **locked** — it becomes a stored roster (`splinter_rosters`): saved, wintered, power read off the men. |
| 30.5 | A save with a good hash and a missing field loaded a half-built world; `peek` called it healthy. | **locked** — `SaveGame.decodable` checks exactly the fields the decoders index without a default (a test reads the decoders and keeps the lists honest); such a file opens from `.bak` or reads as broken. |
| 30.6 | The wallet was deleted before the new one was renamed in. | **locked** — old wallet steps aside to `.bak`; load tries live, `.tmp`, `.bak`. Double-credit after a failed wallet write → morning list (billing design). |
| 30.7 | An odd cup field silently dropped its middle club (unreachable today). | **locked** — now an engine error, which fails the gate. |
| 30.8 | The Club tab panel title was English in every language and asked promotion first (the queue bug's twin); `UiKit.window` drew titles outside the ledger, so the string and ink sweeps never saw any window title. | **locked** — keyed on `blocked_by()` and translated (a dilemma now reads A DECISION); `window` notes its title; cup rounds get a display `Cup.round_label()` (the stored `round_name()` stays English — it is compared against). Cup names are proper nouns and stay English, like the divisions. |
| 30.9 | Runtime English the sweep could not reach: arena date/budget words, crowd word, "holds %d", "beat / lost to / drew with" (now three whole sentences), chalkboard errors, "over by", "sim", facility effects, "%dy", "1 years", "out %d event(s)", the OUT tag, the chalkboard's R/F/C. | **locked** — 47 keys, all 8 languages. |
| 30.10 | Mistranslations: "knock" (an injury) rendered as a blow in es/fr/it; es "El Salón" (the Hall), "Llena la casa o cárgala", "Amarga cada evento…"; fr "armure qui branle"; ja 々 not in the pixel font. | **locked** — lesión/blessure/infortunio throughout; the rest reworded; ja quarter-finals ベスト8. |
| 30.11 | Text drawn in `UiKit.EDGE` (the border colour) at 1.18:1 against the ground — venue column, Armorer headers and prices, Chalkboard "Locked", Create labels, the squad key. | **locked** — every text draw in EDGE / EDGE+0.25 is DIM now (4.3–4.9:1). The ledger records each string's colour and test_ink fails any drawn below 3:1 against both grounds (dark lettering on light markers exempt). |
| 30.12 | Arena placeholder printed `res://art/arena/arena_0.png / 520 × 300` to the player; Federation's standing line and upkeep printed through each other; Chalkboard's empty message ran across the field's centre line; Bracket's YOUR ROAD name overflowed; the report's CTA straddled its frame; the slots screen's Back sat against the tagline; Create's tabs showed no selection. | **locked** — each fixed and screenshotted. The staff regime table's columns were rebalanced so the injury word fits in every language. |
| 30.13 | Fight HUD overlap (HOLD / SKIP ROUND over lane 5), touch targets, onboarding, hub centring at 19.5:9, money and match vocabulary, pacing, job-hopping. | **Open → morning list** — each needs a design call or a phone. |
| 30.14 | **The suite missed half of 26 real mutations** (the audit's run): takedown formula inverted, round tie-break flipped, the three-to-one stop, table tie-break, prize money upside down, the physio making knocks longer, harness prices, cup seed tie-break, the ceiling clamp, the fee's division, the queue order, a dropped save field, the market's red wage. | **locked** — `tests/test_rules.gd` pins each rule as the rule it is (10 checks); test_edges compares the WHOLE save dict across a round trip of a lived-in season and reads the market's over-cap card colour off the ink ledger; test_queue pins bid → cup → dilemma → promotion. `tools/mutants.py` (`bb mutants`) re-breaks 15 rules one at a time and reports CAUGHT / SURVIVED / STALE: **15 of 15 caught**. |
| 30.15 | A test that could not fail (`test_season.gd`, `… or true`); the runner printed SUITE GREEN having run nothing (naming only test_shapes); the parse sweep launched the engine 235 times (~12 of ~15 minutes). | **locked** — fresh-report check by identity; zero runs is red; `tools/parse_all.gd` parses all 240 scripts in one engine in ~13 s (a planted parse error is caught). |
| 30.16 | **Play would refuse the export**: an APK (not an AAB), target SDK 35 (Play needs 36 for new apps from 31 Aug 2026); INTERNET and ACCESS_NETWORK_STATE requested with no network code; backup off; 20.8 MB of a 32.6 MB pack was archive audio, a full licensed album MP3, source art and review images. | **locked** — gradle build, AAB, target 36, min 24; network permissions off; backup on; exclusions extended in all three presets (pack **32.6 → 15.0 MB**). test_export holds each. Needs the Android build template installed once from the editor (docs/EXPORTING.md step 5) — **Pete**. |
| 30.17 | Licence texts did not ship; Godot's MIT text and its third-party notices were nowhere in the game. | **locked** — the three licence files are in every preset's include_filter; Settings → Licences shows Godot's licence and component notices (from the engine) and the OFL/CC0 texts in full. test_export holds it. |
| 30.18 | tap, wipe and type sounds did not exist (the tap is the most frequent sound in the game) and test_audio passed anyway. | **locked** — rendered from `tools/music/buhurt_sfx.py`, which already defined them; test_audio now fails on any missing sound. 21 of 21 present. |
| 30.19 | 69 autosave calls ignored failure — a full phone lost progress silently. | **locked** — `Session.save_failed`; the season screen says so once per failure run. Held by test_edges. |
| 30.20 | Default Godot boot splash; stale docs (EXPORTING's "icons are empty", audio's "four of seven", the 130 µs tick). | **locked** — crest splash on the ground colour; docs corrected. Privacy policy drafted (project doc `privacy-policy-draft.md`) — **Pete** hosts it and fills contact/date. |
| 30.21 | Cup finishes were translated on the night and SAVED — with the English round name glued in ("fuera en la quarter-finals"), both the arena's LAST TIME OUT line and the honours cabinet, and a language change never fixed them. | **locked** — `player_finish` and `finish_label()` store English; `Cup.finish_words()` draws either in the language on screen (whole sentence per round, capital raised after translation); an old translated save passes through unchanged. 10 keys, 8 languages. Held by test_edges. |
| 30.22 | **Second fresh-eyes audit** (29 Sep, 4 AM; project doc `grading-29-sep.md`): overall C (was C−). Code B+, Design C, UI C, Text C+, Tests D+ (a new mutation set: 7 of 21 caught), Ship C−. | Recorded. The morning list gains #11–#15. |
| 30.23 | Code: a dilemma re-targeted onto another man when the roster moved; a released prospect stayed banked; a cup missing a field loaded as null; fighter pos/armor unchecked on load. | **locked** — the card keeps its man's name; release clears the prospect; `Cup.NEED` checked by `decodable`, older cup fields defaulted; pos and armor clamped. test_edges. |
| 30.24 | Text: the ticker had no translation at all; helper labels (`_stat`, `_book`) unextracted; AI skill names, Records tags, Hall positions, "over by", "nobody yet", store messages, fighter verbs, money templates raw; the slot's tier name saved translated; tier names translated in Polish only; the Licences screen credited the wrong fonts as OFL. | **locked** — 59 keys × 8 languages; relegation tag is "relegated", not the floor's "down"; money templates and decimal mark translatable; tier names in every language. Held by test_edges (ticker in es). |
| 30.25 | UI: fight not centred at 4:3; slot Delete hung 16 px off its card; the market bill figure floated off its panel at wide sizes. | **locked** — screenshotted at 960x720, 960x540, 1260x540. |
| 30.26 | Tests: 14 of the audit's 21 mutations survived (relegation order, knockout margin, purse by division, healing, sim/practice XP, availability, tired speed, bench recovery, bout tie on downs, ground condition on load, Toxic band, retirement age, kit colour). | **locked** — `tests/test_loop.gd`; `tools/mutants.py` now 29 breaks, **29 of 29 caught**. |
| 30.27 | `.gitignore` ignored `/android/` while EXPORTING said to commit it. | **locked** — stays ignored (stock template, regenerated); the doc says so and when to change that. |
| 30.28 | Polish from the second audit: club names cut at 24 characters with room to spare on the table; a Strength/Gas BOOST drawn in the alarm red; the walk-out's opponent mark (navy) invisible on the black band; "HOME / Their ground" in a standalone bout; lists joined with a fixed English ", "; the name fields in Godot's stock sans and grey box. | **locked** — `clip_px` to the room before the numbers; red only when he fights below his number; marks on their kit plate as in the fight banner; "Home ground"; `t(", ")` (ja 、); `UiKit.skin_edit` on every LineEdit. Screenshotted. |
| 30.29 | **Pete's decisions of 29 Sep** (project doc `decisions-29-sep.md`): one league up a year (#8/#9), the ground before the division and a binding cap (#13), the hoarding note (#12), paid sessions (#11), restart-not-forfeit after an app kill (#16), American English and "event"/"bout" (#7, #20), Back bottom-left (#14), an 11 px floor (#15). | **locked** — `Jobs.MAX_TIERS_UP` 1; `Arena.BUILD_AHEAD` 1 and promotion refused without the ground; `TIER_CAP` 250/1000/12000/450000 (`bb probe wages`: top-division p90 bill 208% of the unraised cap); `Season.hoard_note`; `Season.restart_abandoned_bout`; `tools/rekey.py`; `UiKit.MIN_PX` 11. Held by `tests/test_climb.gd` (5) and test_loop. test_arena, test_market, test_office and test_invariants rewritten to the new rules, not skipped. |
| 30.30 | **#1 reversed.** +0.15 on every AI's clinch throw flattened tactics (C-6 swap −4.2, needs 8). | **locked** — `ai_clinch_throw` 0; a missed PLAYER takedown costs 15% of the tank (`pmiss_gas`), a player takedown on a man under 0.5 balance +0.20 (`pread`). n=240: spam edge +26.9 → +6.9, a sensible thumb +9.4 over hands-off, tactics unchanged (11.9 → 15.4 in C-6). The rule found: a change to EVERYONE'S clinch flattens tactics; a change to the player's own choices does not. |
| 30.31 | **#11 price.** Full-rate sessions at a quarter price took every man to his ceiling: reading the scouted range fell from 1.8 seasons to 0.55 (test_scouting red). | **locked** — `session_price_scale` 1.0 (Pete). Scouting 1.10 seasons / +5.9 power; first title 12.32 seasons (`bb bases`) — Pete: fine. |
| 30.32 | **The contact wheel** (Pete: Blood Bowl pause at contact). A man you sent freezes the fight at contact and asks: Bullrush / Hit / Grapple (Takedown / Hit / Break on a held man), Cancel; odds in green/yellow/red; a red "fall %" under Bullrush; FROM BEHIND; hold a route's end to RUN; a free enemy may grab or trip a runner. | **locked** — `melee_scene` wheel, `MeleeSim.contact_odds`, `pass_odds`, `from_behind`; back hit ×2 (held ×1.5) and back bullrush +0.2, bullrush fall — **the player's only**, because on everyone the fall cost hands-off 5 points and the back bonus closed C-6's hole (25% → 54%). `bb shot wheel`. |
| 30.33 | **#10's extras** and the free-swing trap. A swing before a chosen Hit doubled it (a thumb won C-6's worst setup 100%); keeping the cooldown instead ATE the chosen Hit (Hard List outscored Full Steel). | **locked** — a chosen HIT is the free swing (lands at once, full weight); other acts get `swing_share` of a blow first. Mate grip +0.15 for 3 s. Routes now beat hands-off on every grade (running +3.1 to +4.6, busy +4.2 to +5.8, n=240); spam-sending −9. |
| 30.34 | **The wheel on the difficulty panel** (Pete: "place this in the combat difficulty slider"). | **locked** — `Grade.TABLE` swing/fall/pass: Friendly 75/10/8, Sanctioned 50/20/12, Full Steel 25/30/16, Hard List off/30/16; MATCHED interpolates; CUSTOM dials; three rows on Create → GRADE. The dials move feel (grabs+trips 2.0 → 3.3 a bout) more than result; the grade's weight stays in scale, calls and corner. |
| 30.35 | The route probes walked the flank loop twice (`send_free` appended its waypoints twice): every "routed" figure in the flank and first wheel grids was understated. | **locked** — fixed; `sent_contacts` per bout and a `helpbusy` policy added to `probe fightskill help3`. |
| 30.36 | The 11 px floor cut 38 draft-translation lines (es 9, fr 9, pt_BR 7, de 6, it 4, pl 3); the market's bill figure lost its last character in seven languages. | **locked** — each replacement measured first with `bb probe width`; "%s rules" is the league name alone in es/fr/de/it/pt_BR (Pete: fine); the bill says the currency once (`pair_money`). **Suite GREEN, 74/74; balance tier green.** |
| 30.37 | Still open from Pete's list at the first landing. | **Closed by 30.38–30.42.** |
| 30.38 | **#3** HOLD / SKIP ROUND sat over lane 5 and covered the men fighting there. | **locked** — both in the top bar either side of the clock, calls-left pips beside HOLD. Screenshotted at 960x540 and 1170x540. |
| 30.39 | **#4** Touch targets were 44 px. | **locked** — `UiKit.HIT_MIN` 56, strips up to 12 px; `_fit_slop` cuts a strip to half the gap to any button above or below, so a gap is shared and never taken. `test_audit_ui` holds both; mutant #33. |
| 30.40 | **#5** Onboarding: a new club was asked for its tournament bid before it had fought, and had the Armorer in front of it. | **locked** — `Season.first_bout_done()`; the bid waits (offers stay on the table), the Armorer tab appears after bout one and the tabs close up. Two one-time coach marks (Pete: "Draw a route", "The corner"), per device in `Settings.tips_seen`, holding the fight / corner clock until "Got it"; off in the test runner (`RB_NO_TIPS`). `bb shot tip`. test_season, test_audit_ui; mutants #32, #34. |
| 30.41 | **#6** Wide-phone side strips. | **Mockup** (`Claude outputs/side_strips_mockup.png`): crowd + venue at three ground levels, home side cheering a down. No build, per Pete. |
| 30.42 | **#2** Play Billing was a seam calling methods that do not exist on the current plugin (`startConnection`, `consumePurchase(id)`). Premium **$4.99**, three CC packs (Pete). | **locked** — the first-party plugin's `BillingClient` API: connect → product details (localized prices on the shelf) → purchase → `on_purchase_updated` → credit → `consume_purchase(token)`; the wallet (v2) keeps a **claim receipt** of credited tokens, so a re-delivered purchase is consumed again and never credited twice, across relaunches; PENDING credits nothing until paid; canceled says so. `tests/fake_billing.gd` drives it all in `test_store` (24 checks); mutants #30, #31. Pete's one-time steps in docs/EXPORTING.md. **Suite 74/74, balance green, mutants 34 of 34.** |
| 30.43 | **Bullrush on a wobbling man** (Pete, 30 Sep: "below 50% balance would help a bullrush pretty heavily", rolled into combat difficulty). | **locked** — `Tuning.br_read` 0.30 added to `_bullrush_chance` under the read threshold; a Grade dial ("Bullrush on a wobbling man"), in TABLE/CUSTOM/DIALS/`wheel_for`; test_wheel holds it. |
| 30.44 | **The action wheel** (Pete picked #11 of eleven mockups): the guard triangle, labels on plates outside the ring, a Cancel chip, the side under the thumb lit. | **locked** — `melee_scene` `_draw_wheel`/`_wheel_option_at`; odds coloured by value (a long shot in red). |
| 30.45 | **Blind screen reviews, rounds 3–11** (30 Sep overnight): 6.0 → 7.1 → 7.2 → 7.3 → 7.3 → 7.1 → 7.3 → 7.4 → 7.3. Plateau at ~7.3: each fresh reviewer puts 4–9 screens at 8 and re-ranks the rest, often reversing an earlier round. | **open** — see project doc `overnight-30-sep.md` for what the last round still asks. |
| 30.46 | The body face had no descenders (g read as 9: "Settinas") and no `& < > = " * [ ] _ \| ~ ^`, so those fell back to LanaPixel at half size mid-sentence. | **locked** — `tools/fix_descenders.py`, `tools/add_glyphs.py` (idempotent) on BuhurtRail; brackets kept 2 px wide so pseudo-loc headroom holds (test_untranslated caught the 3 px version). |
| 30.47 | A disabled button was a dark flat box with no drop: it read as a text field. | **locked** — `UiKit.skin` disabled = the button shape and drop, colour drained. |
| 30.48 | **The screen checklist** (`tests/test_checklist.gd`, in the shape sweep): blind reviews had plateaued at 7.3 and contradicted each other, so the rules they agreed on for 3+ rounds are pass/fail. C1 no text under 12 px · C2 text ≥ 4.5:1 · C3 one gold primary, never a disabled one · C4 a price over the purse is grey (full and empty purse both swept; pickers ending ">" exempt) · C5 no empty band over 20% of a phone frame. First run found: the NORMAL palette's red at 4.43:1, four gold +1s on the fighter page, a gold-and-dead Save, a live Reroll/Take at 0 CC. Judged by eye still: bars and ticks labelled — armorer tick ("min" on the heading), roster card bars ("kit N%"), level bar ("Earned…"). | **locked** — NORMAL `down` e05a3c → e8664a (5.0:1); +1s carry the up mark; Save gold only when dirty; Reroll/Take grey when short; `UiKit.ledger_art` so a logo counts as content. |
| 30.49 | Before/after review of item 2 (10 screens: 4 better, 4 unchanged by design — the fixture's purse covers every price — 2 worse). Worse: the fighter's +1s lost their gold; the report's "THE CLUB" caption sat over nothing and three men's identical "1 assist" read as three cards. | **locked** — the +1s are gold as one `primary_group` (C3 counts a group once); a news caption draws only with a whole card under it; identical notes merge into one card naming every man. |
| 30.50 | **Pete's playtest, 30 Sep** (17 findings, project doc `playtest-30-sep.md`). Decided: training weekly by the trainer + a winter camp, both by coach skill; knocks scale by difficulty; tap = hold ground; wage dictates contracts, CC moves mood. | **locked** — resize relayout (AppLife); ACTION_INSET 74; armorer "Fix …'s kit" / "New harness: …"; dilemma results "A · B." in a bar; first-bout-only hint; SECOND 10 → 28 words; `Grade` "knocks" 0.4/0.6/1.0/1.0 (dial 0.2-1.0); `can_extend` ≥ 1 year; extend priced × `mood_rate`; meeting shows the wage, not CC (it printed $34/wk as 34 CC); `OfficeStaff.camp_points` = Σ coaching over the eight / 4, added to the Training ground's; `MeleeSim.plant` (−0.10 bullrush against a planted man, lifted by a route or a second tap, not on a called play); clinch pair settles 2.5/tick instead of snapping; founding screen (`Session.founding`); Settings "Name & badge"; `Session.level_run`; UPGRADES tab; squad sheet 9 → 6 columns. #12 teleport not reproduced (8 AI bouts, worst step 4.2) — the snap was the one path that can jump a man. |
| 30.51 | **Pete's second playthrough, 30 Sep** (17 findings, ended on a soft lock; project doc `playtest-30-sep.md`). The soft lock was the squad sheet's display order, not the model (`tools/probe_softlock.gd`: no swap shrinks the five). | **locked** — the five in slot order with slot names (L rail … R rail), bench and reserve as framed groups, tap picks / Swap is its own button; Prospect says "+N max"; "Hurt · N" for out; 14 kit and 9 mark colors (f39c4a → f8b878 for contrast); two-tap confirm buying a mark; Another town no longer overlaps; dilemma effects say "team morale" / "renown" and wrap; the hospice card rewritten; STATISTICS out of 100 with a red potential box marked "max N"; the man's full name heads his page; Staff "Find a captain" list (8) replaces New names; plain names (YOUR PATH, VENUE, EVENTS, Cup bracket, Fix kit, Extra training, MEETING, WHAT THEY SAID). |
| 30.52 | **The calendar** (Pete, 30 Sep: "pretty fucked up if there's 3 different events during one week"). Cup ties and the hosted show rode on league matchdays, so one week could hold a league fixture, a cup tie and your tournament. Decided: one thing a week; single round robin; a top-four playoff (semis, final) after the league, the two finalists go up; a month-grid calendar. Then: "All Cups outside of world cups should be Friday-Sunday events … one weekend each. You can fight multiple times a day just fine", and "World Cup should be like a full week long itself". | **locked** — `Calendar` (weeks: LEAGUE / CUP / OWN / PLAYOFF / WORLDS); the Kings Cup (40% of the league) and Path of Honor (80%) one weekend each, your show one weekend after the league day bid for, the Worlds one full week ending a National year — every round inside its week, several bouts a day (`is_tournament`); the playoff a round a week. `LeagueWorld.play_week`; the other divisions paced to the player's so every table finishes together (they used to stop when his did); playoffs as `Cup` with `no_third`, `finalists`, `playoff_order` for promotion, titles and Worlds berths; table band = playoff places; Club tab COMING UP lists every week in its colour; `scenes/Calendar.tscn` (real months from the first Saturday of March; Fri–Sun and Mon–Sun spans drawn); weekly practice scaled by `practice_share` (league days / weeks) with a seeded die, so a season's XP is unchanged; saves carry the calendar, an older save gets one built. Backyard 9 weeks (10 with a show), State 11–12, Regional 15–16, National 21–22. The weekly shopping that came with it: nine calendar weeks of sessions, armorer and extra reps against five league weeks of gate took five power off a twenty-season club (`test_scouting`, 12 bases: 81.7 → 76.7). Pete: **between fixtures only** — `ClubOffice.fixture_week`, set by `Season.sync_week`; power back to 80.7. A title is now the playoff champion (`LeagueWorld.player_champion`, in test_scouting and five probes): reading the range 0.85 seasons / +6.9 power on the gate's 5 bases, 0.42 / +5.3 on 12 — the knockout makes title timing noisier. |
| 30.53 | **Bye weeks and the send-off** (Pete, 1 Oct: the playoff one weekend; "a bye week before championship playoffs and the Worlds"; "If you win nationals … a congratulations, a special training, and a 'bestowing' of the Team USA title and Tabard for Worlds. Art will follow"). | **locked** — `Calendar.Kind.BYE` before the playoff and before the Worlds; the playoff a Fri–Sun weekend (`is_tournament`); `SendOff`: the National champion's bye is three cards, Monday / Wednesday / Saturday — celebration (+10% of the room left in the following, +0.15 morale on the eight), the national camp (two full weeks' practice, unscaled), the tabard (`LeagueWorld.team_title` "Team USA" / "Team Europe", +1 honor on the eight, the name on the Worlds bracket); `WORLDS_HOME` 2 → 1, the champion is the country's only club; the calendar draws the three days in gold. Backyard 9 weeks, National 21. test_cupplay holds the year's shape and the send-off. |
| 30.54 | **An American calendar, days you can tap, and invitationals by level** (Pete, 1 Oct: "Sunday is on the left most day"; "those days clickable with a popup … opponent, location, records … tournament, rewards, opponents"; "which decision made these invitationals open to anyone below Regionals?" — register 09.10, my recommendation, never put to him: one pair for the whole pyramid, filled by rating, so an invited Backyard club drew the National Division's best). | **locked** — `Calendar.first_weekday` Sunday = 0, Saturday the last column; every day with something on it is a button and opens a popup (`_info`: a fixture's opponent, ground, town, both records, the gate or the result; a tournament's town, who is invited, what it pays, how you stand, the field, and its bracket); `INVITATIONAL_SETS`: local (Backyard + State, held in one of the three towns nearest you, "<Town> Open" / "<Town> Classic"), continental (Regional + five clubs from Canada and Mexico, held in Toronto, Montreal, Vancouver, Mexico City, Monterrey, Chicago or Denver: "North American Open", "Continental Cup"), elite (National + five European clubs, held in Paris, London, Rome, Barcelona, Prague, Krakow, Budapest or Vienna: Kings Cup, Path of Honor); every set's slot fought the same weekend, the guests sent home after it; honours keep the champion's name; `Cities.ABROAD`. tests/test_calendar.gd (6). |
| 30.55 | **Pete's playthrough, 1 Oct** (4): the captain list had the room's gold "Find a captain" buttons on top of it and the Session button ran off the screen; the Finances page's foot ran off the bottom and the message bar sat over its headings; simmed weeks banked levels nobody could see (a level is the player's to place, on his page — 13 men had one waiting after 6 weeks); a hosted show priced as one afternoon's gate against a date and a budget showed −13 CC expected, −7 if you won it. | **locked** — the list owns the staff screen (nothing else built while it is open), Session 380 wide inside the gutter; Finances rows share the room (`_row_h` 15–22), the note under the ground, its two buttons on the action row; the message bar clears itself after 4.5 s; a gold "+N" beside each man with levels banked (`Career.levels_banked`), a key for it, and "Levels to spend: …" after a simmed week; the squad sheet's DEAL says "0y", not "OUT"; your show is a weekend — three days of gate (`ClubEvent.show_gate`) plus the seven visiting clubs' entries (`ENTRY_BY_TIER` 1/1/2/4 a club, always less than the date): Pete's case (343 fans, 400 seats, 9 + 8 CC) comes out about +4, a back field with 14 fans −3. |
| 30.56 | **Scouting removed; every club in four stars** (Pete, 1 Oct, answering the scouting test going red: the title half swung 0.85 → 1.60 → 0.15 seasons across unrelated changes once a title was a top-four knockout: *"Remove scouting and just give each team a 4 category 5star system. Then if you click them or prior to fights, fight cards, you'll see info like the star ratings, overalls and W/L."*). | **locked** — a stranger's ceiling is shown exact (`Season.potential_range`; `ClubOffice.scout_width`, `SCOUT_BLIND`, `ceiling_range`, `tools/probe_scouting.gd` and the balance check that reading the range pays all gone; the Scout captain still finds more names); `TeamCard`: Strength / Base / Skill / Gas, each the average of the club's five on the 1-99 scale, ten points a half star; shown on a card when a league-table row is tapped (division, town, rating, place and record), at the foot of the calendar's fixture popup, and under both clubs at the walk-out (which also now reads a cup opponent's record and name, not the league's empty fixture). test_calendar holds the stars. |
| 30.57 | **Team-first restructure, screens** (Pete, 1 Oct: "Let's make it more centric about building the team"; mockups approved at v6, canvas "Team-First Restructure Mockups"). Tabs Club/Squad/Armorer/Upgrades/Finances read as five unrelated rooms and the career sat behind a header button. | **locked** — tabs FIGHT · TEAM · MAINTENANCE · UPGRADES · MANAGEMENT. Header: one Menu (Resume, Settings, Save / Load, Quit); the coach's name and level on the header line. Fight: fixture card is Home/Away, rating, odds and the gate; Coming up is Home/Away and who; table key gone. Team: Starters / Bench / Reserve (4 places, an empty one is "+ Hire free agent"), columns FIGHTER · KIT · DEAL · OVR · POT, the tapped man in a panel bottom right; Club record, Free agents, Training (popup: Light/Normal/Hard per captain + the paid session; both left the Staff room). Upgrades: title, cap as a gauge with the bill in the fill, a "?" per row, "N CC/Year" per row and a Maintenance total; Insurance row; Arena panel with the Arena button (the old "The ground"). Management: Finances (In/Out/Total → the full books), Staff (captains, armorer → Staff), You (level, XP, five skills, Spend points, Playbook, Team edit). New career: You → Your team (kit, mark, home town as popups; 24 kits, 16 marks) → Difficulty. `tools/shot_restructure.gd`. |
| 30.58 | **Team-first restructure, rules** (Pete, 1 Oct). | **locked** — **Coach**: named, background (Ex-fighter/Promoter/Marshal = a free point in Training/Business/Tactics), levels from wins (10), draws (4), finishes (60/40/25/15), cups (40…4), promotion (30); a level is a point; five skills of five stars: Training +5% XP, Motivation −10% of a loss's morale hit, Tactics +1 call at 3★ and 5★, Business +5% gate/bar/prizes, Recruiting −5% fees. Reputation, job offers, posts and the boyhood club deleted (`jobs.gd`, take_job); the dilemma deck reads the coach's level. Old saves: asked for the coach once; wins and draws count as XP. **Armorer**: hired, 1–5★ = the best metal he makes and keeps (Rust, Mild, Hardened, Stainless, Titanium — the old four renamed, Titanium new: wear ×0.50, 24 CC); repairs only up to his metal; fixes 1 CC cheaper; wage 0/2/4/7/12 CC a summer (unpaid → the free one-star hand); 4★ State and up, 5★ National only; old saves get one star above their best kit (max 4). **Federation** is insurance only (Regional asks 2); Federation screen deleted; kit and marshal certificates refunded. **Bus** is eight, always; old saves' bought places refunded. **A new club starts with eight**; reserve capped at 4 (books 12); CPU clubs carry 4 reserves on the original 14 kits / 9 marks. |
| 30.59 | **Blind review after the restructure** (1 Oct, two fresh reviewers, 40 shots: 6.5 and 6.4 against 7.3 on 30 Sep; project doc `screen-review-1-oct.md`). Ten real findings. | **locked** — fighter page says the banked count ("3 POINTS TO SPEND"); Upgrades' training row reads the ground's own camp ("camp +0", the number its button moves) and the total says "arena included"; the armorer list shows yours first and five people with no shared first or last name; Training rows say CAPTAIN and the session "+N XP each fighter"; standings names clip at the size they are drawn; the town popup opens on your own state; Trade says "+N CC"; three near-duplicate new kits replaced (magenta, sky, olive); coach +/− 46×44; Sign is grey until the man has a name. |
| 30.60 | **Blind review round 2 after the restructure** (1 Oct, two fresh reviewers: 6.5 and 6.5; fixed screens up a point each). Four bugs and five asks both rounds agreed on. | **locked** — the bracket's next round fills as its feeder ties finish; the armorer list offers only better men; the corner reads "YOURS STANDING 5 of 5" (it was your count; "5 - 0" read as a score); the fighter's wages named (now / at renewal / extend early); unlit stars drawn in the frame colour; club names lose whole words, never cut mid-word (`UiKit.fit_name`); Create's purse where the others are. Asks: the wage bill under CC in the header (purse box 170 wide); plainer words (pass, all kit, winter camp, POT); Maintenance lists everyone across both columns; the Team panel shows your five's four ratings when nobody is picked; the Staff room shows the armorer and opens the Armorers; the Coach page lists what each skill does now; "Hire for Flanker" on the red warning (opens the captain list); Trade and Release stand apart; Quit is "Save & quit". |
| 30.61 | **Blind review round 3** (1 Oct, two fresh reviewers: 6.7 and 6.4, mean 6.55). Four regressions from 30.60 and two colour misuses. | **locked** — the fighter's contract value no longer prints over its label; the header's wage line sits inside its box; the new-career purse keeps its margin; the coach's ± stay inside the skills panel; "Hire for …" and "Save & quit" are not red (red is for what cannot be undone); "STILL STANDING"; "spend them" when more than one; Maintenance shows a column heading only when it changes and NEXT only when a row has one; a zero total is not green. |
| 30.62 | **The Guide, and the review loop closed** (1 Oct, Pete: "Make a Guide in the Settings/Menu area"; grading stopped at 6.55 after three rounds, novice testing next). | **locked** — `Guide.tscn`: nine topics (season, table, fight, team, training, kit, money, upgrades, coach), every line checked against code; reached from Menu (under Resume) and a GUIDE panel in Settings; pages step their size down to fit in every language. Explanations go in "?" popups and the Guide, not on screens (Pete). Same pass: Settings' right panels the left column's width, the language arrow inside its panel; badge packs show which is open; the bracket uses one name per club across rounds and the path panel; the report says "+N ready" and the button "Spend points (N)"; the contact wheel's hub is a plate with your man and his target side by side, and Bullrush/Clinch/Hold marks read as their words; before the charge each row shows kit (and the weapon only when it is a pole), with a Back that leaves the fixture to be fought from the walk-out; the fixtures' "Strong Right" is drawn strong on the right. |
| 30.63 | **Pete's five rulings on the Guide research** (1 Oct). | **locked** — (1) the Infirmary is wired as it says: every level takes one event off a knock (floor one) and turns away a tenth of knocks (`knock_guard`); (3) kit wears in fights, not training: `REGIME_WEAR` is gone, every bout (fought, simmed or cup; not a forfeit) takes `BOUT_WEAR` 0.06 off the starting five, scaled by trait and metal; (4) wages read "/yr" — they always were season figures against a season cap; (5) the National blurb and notes say the playoff champion alone goes to the Worlds. (2) CPU levels pay 1–5 points by gap to ceiling while a player's hand-placed level pays +1 — asked Pete whether to give the player the same. |
| 30.64 | **First-timer test fixes** (1 Oct, three LLM first-timers through `tools/novice/drive.gd`, 57–103 moves each). Clear bugs only; design and wording findings go to the novice report for Pete. | **locked** — "STAYS ON" replaces the clipped "WILL NOT COME O…"; the fight hint is short enough to stay whole; the call counter reads "N of M choices picked"; pre-fight swaps no longer spend the first corner's two; a fresh sub does not wear his predecessor's DOWNED or downs; the report's rows close up when eight fought instead of running into the heading; a card's tally stays clear of the position word; a wheel drag starts from the hub wherever it is drawn; the crest redraws as the names are typed; a grey "Take the date" says what it costs against the purse. Tools: driver and bots skip buttons under a full-screen veil. |
| 30.65 | **Pete's two rulings, 1 Oct** — the armorer maintains; a level is a point. | **locked** — each winter, after the summer bill settles who the armorer is, every harness returns to the top of its own metal as far as he can work (`repair_top`); no grade is ever raised without buying it. `Career.gain_for` is 1 for everybody: CPU clubs and old-save drains took 1–5 points a level by gap to ceiling while the player's placed level took one; age still sets the bar's speed. (Fight wear without any reset had left a no-repair club unable to field five — `test_career`, `test_save`.) |
| 30.66 | **The climb, retuned on one level rule** (1 Oct, Pete: "make the test managers get new free agents… make the ceiling raises more expensive and play with the stat points per upgraded level"). Bases, 5 × 20 seasons, first National title: 1–5 accelerator (CPU path only, the old baseline) 11.2; +1 everywhere 21 (never); bar 3 or 2, or draining every level, changed nothing (~65 power) — the size of a level was the limit, not the count. The probe manager had also stopped signing: it held the squad limit at 13 after the restructure made it 12, so a full squad never made room. | **locked** — `Career.POINTS_PER_LEVEL` = 3 for every man of every club (the button reads "+3 Strength"); `RAISE_COST_PER` 2 → 4. Sweep: points 1/2/3 at raise 2 → 20.7 / 13.2 / 10.3; points 2/3 at raise 4 → 13.8 / **10.7**; 3 at raise 6 → 10.4. Manager uses `MeleeClub.SQUAD_MAX`. |
| 30.67 | **The ground, asked for in time** (1 Oct, Pete: "a prompt about mid-season about needing the next arena. Then a 'Build Now' prompt at the promotion gate"). Every novice persona and the learning player won the Backyard and stayed there; the ground was only named when promotion was refused. | **locked** — `SeasonDesk.ground_gap` (what the division above needs, every step and the total) and `ground_ask`: once a season, from halfway through the league, to a club in the top four on a ground the division above would refuse, the hub opens a card — what is still to build, the total, the purse — with "Build <next> · N CC" (gold when it can be built this week) and Later (`ground_warned`, saved). At the gate, a gold "Build now · N CC" builds every missing level at full price in one go and takes the place; a short purse is told the figure. |
| 30.68 | **GitHub and CI** (1 Oct, Pete: "let's set up GitHub for this project … make the most out of concurrent sessions"). | **locked** — `.github/workflows/suite.yml` replaces `tests.yml`: a branch push runs the fast tier, a pull request into main runs everything, split six ways by `RB_SHARD` plus the shape and language sweeps as their own jobs (`RB_SECTIONS` in `tools/run_tests.sh`; unset, the suite is unchanged). `sweep.yml` (one job per balance variant, sed edits on a fresh checkout, a side-by-side summary), `novice.yml` (every persona × seed at once, summary + jargon table), `learner.yml` (saves in chunks under the 6-hour limit, beliefs carried by artifact). `.github/actions/setup-godot` caches Godot and the import. `Claude outputs/` and `logs/` are ignored. No nightly: free minutes go to the PR gate. |
| 30.69 | **CI: pinned runners and a shader cache per engine** (2 Oct, coordinator). GitHub moves `ubuntu-latest` to Ubuntu 26 on 19 Oct; and main's Suite failed screens (langs) on `test_ink@it` with `Condition "header != String(shader_file_header)" is true` — the sixteen engines of the language sweep shared one user:// and one shader cache, and one read a file another was half-way through writing. | **locked** — every workflow job `runs-on: ubuntu-24.04`. `tools/run_tests.sh` gives each language-sweep engine its own fresh `XDG_DATA_HOME` / `XDG_CACHE_HOME` under `/tmp/rb_userdata/<test>-<locale>`, so user:// (and its `shader_cache`) and Mesa's cache are never shared. Not on `allowed_errors.txt`: the error is a race, not noise. `RB_SECTIONS=langs bash tools/run_tests.sh --fast` twice: 16/16 green both times. |
| 30.70 | **Blind review, lane D round 1** (2 Oct, two fresh reviewers over the 54-frame set — `shot_review.sh`, `shot_restructure`, `shot_guide` — briefed that the art is placeholder, explainers live in "?" and the Guide, Hardened stays, frames are separate worlds, navy is cup night: **6.81 and 7.22, mean 7.02**, against 6.55 on 1 Oct). In-frame bugs only; the design asks went to Pete in the PR. | **locked** — the fighter page's level line reads "Earned. Spend them below." (it said "+1s" over "+3" buttons and was cut at the panel edge); the prefight CHOSEN strip is 36 tall (its 7 px layout was drawn at the 12 px floor and sat on the top edge); the contact wheel's label plates are measured at the 14 px they are drawn at (the Hit line ran out of its plate); the staff armorer card is 74 tall ("Makes up to Rust" sat on its bottom edge); the header purse box is 42 tall so the wages line clears it; the cup-night ribbon is 12 px, centred on its own measure, four up (the "g" ran off the screen); Create's Kit/Mark colour swatches are the button's icon, not a square under space-padded words ("Mark color" ran into its square); the grade panel prints both multipliers to two places (x1.00 beside x1.0). Same PR, CI: the language sweep runs its first drawn pass alone, so a fresh runner's shader cache is filled before seven more engines read it (eight at once failed each other: "Can't create shader cache folder", a half-written cache header). |
| 30.71 | **The gold button is the next real step** (novice report, 1 Oct, item 2; Pete approved all of it). Every first-timer pressed the gold button and only the gold button, so a starter the marshals would turn away and a ground the division above would refuse went unseen until they cost a bout or a promotion. | **locked** — `Season.gold_step()` (`SeasonDesk`): with nothing blocking the week and the first bout fought, a man in the first five under the pass mark makes the hub's gold button "Fix kit" (opens Maintenance); else a ground short for the division above whose next level can be built this week makes it "Build <next> · N CC" (builds it, as the ground card does). Otherwise the fight stays gold. With a step showing, the fight sits beside it, plain, and Sim it moves left. `test_queue` reads all three off the real hub and presses Build. |
| 30.72 | **The bid card's way in is a button** (novice report, 1 Oct, item 3; Pete approved). "Choose at the Arena >" was gold words in the card's corner; first-timers read it as a caption and went looking for the bid elsewhere. | **locked** — a framed "Choose at the Arena" button (gate mark) sits in the FIGHT tab bid card's bottom-right corner and goes to the Arena (`SeasonClubTab.bid_button`); the card's two lines move up to make room, and the flat hit box that lay over the whole card goes (it sat on the button). `test_queue` finds it framed, inside the card, below its words, wired. |
| 30.73 | **A buy button that creates upkeep says so** (novice report, 1 Oct, item 4; Pete approved). First-timers built and upgraded on the price alone and met the keep in the summer bill. | **locked** — every button whose purchase leaves a yearly keep appends it: "Build Club gym · 6 CC · 4/yr" (`UiKit.with_upkeep`; the hub's gold step, the ground card, Build now at the gate, the Arena's build), the Upgrades rooms and insurance ("Level 0 → 1 · 3 CC · 1/yr"), and an armorer's hire (his wage, charged every summer). The figure is the thing's keep after the step, taken on the real numbers (`ClubOffice.arena_upkeep_next / arena_upkeep_at / facility_upkeep_next / rule_upkeep_next`); the salary cap creates none and says none. The hub's gold step is 280 wide to carry it. `test_office` predicts each, buys it and compares. |
| 30.74 | **A "?" by the CC** (novice report, 1 Oct, item 5; Pete approved). First-timers did not know what CC were, where they came from or what they were for, and the Guide's Money page was two menus away. | **locked** — a "?" right of the header's purse box, on every hub tab, opens the Guide on Money (`Session.guide_topic`, read and cleared by `GuideScene`, whose pages are now named by `GuideScene.Topic`). The mood moves 32 right for it and the Menu button narrows 140 → 108; the club's name and its rating line keep their room. `test_queue` finds it in the header clear of the purse, presses it and lands on Money. |
| 30.75 | **A wheel call says what it came to** (novice report, 1 Oct, item 6; Pete approved). First-timers picked a side of the contact wheel and could not tell whether it had worked; the only word in the air was the DOWN over a fallen man. | **locked** — when a call the player picked resolves (`acting_for_player`, read off `MeleeSim.action_resolved`), a word floats over the man who made it for 1 s (`MeleeScene.CALL_WORD_S`): **DOWN!** (a bullrush or takedown that landed), **held** (clinch, hold), **free** (escape, break), **hit**, or **missed**. Gold for a down, green for free, red for a miss. Nothing over the men nobody sent; the chosen act's word replaces its free swing's in the same moment; gone off the fight screen. `test_wheel` resolves a sent man's Hold and an AI man's and reads the words. |
| 30.76 | **The contact wheel explains itself, once** (novice report, 1 Oct, item 7; Pete approved). First-timers did not know the wheel's sides were choices, that he chooses if you leave it, what HOLD was for, or what "N of M choices picked" was counting. | **locked** — a third coach mark, `wheel`, on the existing tip system (`Settings.tip_due` / `tip_done`, career bouts only, off in the sweeps): the first time the contact wheel opens, "A choice" — tap a side to choose, each side shows its chance, leave it and he chooses, HOLD stops the fight for an order, "N of M choices picked" counts yours. The card is 76 taller than the other two for its six lines; the fight is held while it is up, as for the others. `test_audit_ui` opens a wheel twice (shown, then never) and wraps the words in all nine languages inside the card. |
| 30.77 | **The rating says what the kit took** (novice report, 1 Oct, item 8; Pete approved). First-timers won and watched the club rating fall, and nothing said why: kit wears in every bout (30.63) and a worn harness takes a man's base down. | **locked** — `Season.kit_dip()` (`SeasonDesk`): the rating with every travelling man's harness at the top of his own metal, less the rating now, in whole points. When it is 1 or more the header reads "rating 48 (-2 kit)"; where that will not fit beside the season number, the season number goes. Repairs give the points back and the note goes with them. ASCII "-": the pixel fonts have no minus sign. `test_kit` wears a club, checks the figure against what the repairs give back, and that whole kit says nothing. |
| 30.78 | **Every playbook card says what it is** (novice report, 1 Oct, item 9; Pete approved). First-timers could not tell a 2-1-2 from a Depth, or what a Rush or a Turtle would do, from the arrows; the blurbs were tooltips, which a phone never shows. | **locked** — one short line under each card's name in the full playbook (`Playbook.formation_caption` / `strategy_caption`, 11 px, dim): 2-1-2 "The even line", Depth "Center hangs back", Strong left "Left pair steps up", Rush left/right "Left/Right side drives first", Turtle left/right "Shell up on your left/right rail"; a drawn shape "A shape you drew", a drawn play "A play you drew.". Shape cards 96 → 111 tall, play cards 128 → 143; the corner's four favorites keep their old shape and carry none. The long blurbs stay in the tooltips. `test_book` finds a caption on every card and fits every caption in its card in nine languages. |
| 30.79 | **The dials are Custom's** (novice report, 1 Oct, item 10; Pete approved). Every grade printed ten read-out rows, the contact wheel's three among them ("Free swing on arrival", "Missed bullrush, he falls", "Grabbed or tripped passing"), and first-timers read them as things to fear before they had seen a fight. | **locked** — on Create's GRADE tab every grade but Custom is its name and one sentence in a window sized for it (`CreateScene.GRADE_ONE_H`); Custom keeps every row and its − and +. Matched, Friendly and Full Steel's blurbs are rewritten as one sentence each, saying the same things (the Settings panel shows the same sentence). `test_create` reads every grade's screen through the ink ledger — rows and dials on Custom only — and fits each sentence in its window in nine languages. |
| 30.80 | **A picked man with nothing to buy says why** (2 Oct, novice report 2: the Retro Bowl first-timer tapped Calder on the Maintenance tab after his first fight — "the row highlights but no repair panel opens, and the hint text and the Fight button disappear"). A new club's one-star armorer works rust only, so a rust harness at its top had no fix and no better metal: the action row went empty and said nothing. | **locked** — with nothing on offer, the hint line is the office's own refusal ("Hal Brenner works up to Rust. A better armorer makes better metal." / "…as good as it gets.") and the gold way-forward button stays; a pick only takes the row when it has a Fix or a New harness button (`SeasonArmorerTab.pick_has_action`). `test_kit` checks it on the real tab. |
| 30.81 | **The ground card says why a build cannot go ahead** (2 Oct, novice report 2: two of three first-timers built the Club gym from the mid-season ground card, then tapped "Build Fenced ground" and nothing seemed to happen — the refusal went to the flash bar, which is under the card's veil). | **locked** — the card prints the reason under "You hold N CC." in red, in the office's own words (one build a week; the price against the purse), and the build button is gold only when it would go ahead (`SeasonClubTab.ground_block`). The throttle line's "ground" is now translated ("%s wurde…" read "ground wurde…"). `test_arena` checks the card and the office agree. |
| 30.82 | **A dead SUB box says why** (2 Oct, novice report 2: the casual-fan first-timer subbed two men at the end of round one and all five SUB boxes went grey with Pike still on the bench, no word anywhere). The two swaps a break were the reason; the corner never said it. | **locked** — with the swaps spent the corner prints "No swaps left this break." under the rows; with nobody on the bench, "Nobody left on the bench." (`corner_sub_word`). The boxes stay where they are, disabled. `test_layout` drives the corner into the spent state and checks every box is dead and the word is there. |
| 30.83 | **The fighter page's answer is not under its own buttons** (2 Oct, novice report 2: the casual-fan first-timer spent two levels and never saw "Calder put a level into strength" or "Every level is spent" — the flash line sat at the foot of the page, behind the +3 row a man with a level waiting grows across it; the "N more xp before he levels" refusal was hidden the same way). | **locked** — while the level row is up the flash goes in the band under the title (the one `bus_note` uses; the two never show at once); otherwise it stays above the button row (`flash_y`). `test_layout` checks, at 960×540 in the language sweep, that the flash band is clear of every control with a level waiting. |
| 30.84 | **Lane B: the first year up, and a signing who plays** (2 Oct, research in `docs/lane-b-research.md`). The gold-button bot banked ~18k CC and yo-yoed (9 up, 9 down): nothing on the gold path ever led to the free agents, and `MeleeClub.sign()` put a new man in the reserve where only the probe manager's `best_line()` ever moved him. The market's Sign was gold whenever the fee was payable even when the cap or a full book would refuse it — one bot pressed a refused Sign 79,154 times. | **locked** — `SeasonDesk.market_ask` (MARKET_ASK on): once a season before the first bout, a just-promoted club that can afford a free agent who outrates a man on its eight gets a hub card (after the ground card, never with it); "Free agents" opens the list with him picked (`Session.market_pick`). SIGNING_STARTS on: a signing who outrates a man on the eight takes his place. `sign_wall` ("fee"/"cap"/"full"/""): Sign is gold only when it goes through and its label names the wall otherwise. Switches left off for sweeping: MARKET_ASK_ALWAYS, MARKET_ASK_HOARD, PROMOTED_FEE_MULT 1.0. |
| 30.85 | **The lanes, integrated** (2 Oct, overnight). Five cloud sessions left 14 open PRs that conflicted with each other on every merge (each appended the register). Integrated by hand in one branch — D (review fixes), A (novice fixes 2–10), C (four refusals that now say why, a bot fix), B (above) — conflicts resolved (Menu 108 with Lane D's 42-tall purse; both shader-cache fixes reduced to one, a user dir per engine; register rows renumbered 30.69–30.83 in merge order), suite run once. | **locked** — one integration, one push. |
| 30.86 | **Round-2 blind review fixes** (2 Oct, 7.28/10 from both reviewers, up from 7.02). Upkeep labelled under each Upgrades button in one unit (CC/yr), "3 LEVELS TO SPEND" with "Each level: +3 to one stat", Staff Extend readable, both kit columns headed TRAVELING, the fight's plan line clear of HOLD/SKIP, the Guide says Playbook, the walkout says VS. | **locked** — test_office reads the CC/yr label; test_ink holds the shorter level hint in all languages |
| 30.87 | **The corner: every fight choice in one place** (Pete, 2 Oct: "start with E for both ... a gameplay setting with left/right handed as well"). The contact wheel (fight stopped) and the three boxes over a man (fight running, and the clinch) are one quarter-wheel in the bottom corner under the thumb: three sides, one per act, the same place every time. The bar's own pick is outlined and its clock is a gold band draining on the outer edge; a clinch is rust with CLINCHED over the pair and a grey band filling until he can act. Two men asking at once queue; the hub moves between them (in the stopped wheel the hub is Cancel). Settings → FIGHT CONTROLS: Corner / On the man (the guard triangle and boxes, kept), and Right / Left hand; the Guide button moved beside Credits. Mockups: the "Contact wheel options" artifact (option E; A–D and 1–4 kept for a later setting). | **locked** — test_corner (16 checks: each side its act in both hands, hub Cancel, the mirror, newest-first queue and the hub cycling, a waiting clinch refuses, a ready one acts, both settings survive a restart); test_wheel holds the classic triangle |
| 30.88 | **Playtest on the phone, 2 Oct** (Pete, first APK). The mark is the whole knight everywhere — app icon, adaptive icon, boot splash, slot header (the crests were cut at the shoulders). The front door has a drifting wallpaper of the grayed crest and a Quit on every platform. Menu screens laid out for 960 are centred on a wide phone (`UiKit.frame`: the scene and its controls move to the middle, `screen()` answers 960 while it is up, ground and dimmers reach the real edges). New Career step 1: names up, a bigger portrait, Face/Kit/Beard with < and >. Step 3: grades, what the grade is, WHAT IT CHANGES — three columns. 189 more home towns, every state at least two (rival clubs still drawn from the big-city list, so a seed builds the same pyramid). Eight bright mark colours, and the contrast rule also passes a far-apart colour 20+ apart in lightness (red on navy). Free agents show rating and ceiling stars. The ground is a once-a-season card (the first week a build is affordable, or from halfway), never the gold slot; the fight keeps the gold. The season tabs are taller and span the width. | **locked** — test_queue (the fight keeps the gold, the card opens and builds), test_create (every grade shows what it changes; the fight's dials stay Custom's), test_ink/test_layout at 960, 1170, 1260 and 960x720 |
| 30.89 | **Weekdays every week, and cups that pay** (Pete, 2 Oct: stuck before a tournament — "I can't maintain because it's a training week"; "tune Cup win rewards in with this as well, they seemed small"). Repairs, sessions, signings and ceiling raises were gated to league weeks (`office.fixture_week`), so a cup or tournament weekend left the club unable to fix the kit it was about to fight in. Lifting the gate alone cost the bench's spender 13.6 points of end power (83.6 → 70.0; first title unchanged at 10.7) — every weekday spend draws on the same purse, and invitational cups paid nothing back. | **locked** — `Season.WEEKDAYS_EVERY_WEEK`: weekdays every week, no extra tap; the hub's COMING UP says "weekdays now: repair, train, sign" and the calendar marks "now: weekdays". Cups pay: `SeasonCups.cup_purse` = max(2, 6% of the division's season slack) a tie won (×2 at the Worlds) — Backyard/State 2, Regional 3, National 5 — and a podium of 4/2/1 purses (`_pay_podium`, once per cup). Bench (5 bases): first title 10.6, end power 85.0, CC 97.7 (was 83.6 / 82). The gold-button bot still banks ~290 CC a season (12.3k after 42 seasons, 22 signings; was 10–11k): it never opens Upgrades, and the unbounded cap raise and the hoard market card are the Retro Bowl answer — hoarding allowed, sinks on offer. |
| 30.90 | **Buildings renewed like insurance; the top rungs cost more** (Pete, 2 Oct: "having to re-purchase insurance is normal and maybe raise some other prices at the higher end of stars"). Facilities, the arena and the federation certificates already billed each summer and fell a level (or lapsed) unpaid, but a facility's bill was 28% of its price — 1–4 CC — so a rich club never felt it. | **locked** — `FACILITY_KEEP` [1, 2, 4, 8, 14] a winter by level (was 1/2/2/3/4), near the full price at the top the way insurance renews at about what it cost; `FACILITY_COST` [3, 5, 8, 12, 18] (was 3/5/7/9/11); captains by stars [5, 8, 12, 17, 24] (was 5/8/11/14/17); armorer wage 4★ 9, 5★ 18 (was 7, 12). Bottom rungs unchanged. Bench (5 bases): first title 11.5 (was 10.6), end power 82.7 (85.0), CC 93.8 (97.7) — inside the 10–12 window. The gold-button bot is untouched by design: it never buys a building or a captain, so it pays none of this. |
| 30.91 | **Beta feedback, 3 Oct** (Pete, TestFlight + Play closed test). (1) iOS audio session is **Playback** with mix-with-others (`project.godot [audio]`): Godot's default Ambient goes quiet when the device is muted, ACTM's plays. (2) **The beat**: a round ends on the field for 2.4 s (`MeleeScene.BEAT`) with "END OF ROUND n" and the short-name score on its own CanvasLayer (101, above Juice's pops); the bout posts and saves at once, only the corner/report waits; call/skip hidden during it. (3) Dilemma panel runs to the button row; the rule sits 98 above its bottom and the answers 34 under the rule — the first line had been drawn on the rule, and on 4:3 the answers fell out of a fixed 300 panel. (4) Local invitationals never take the player's own town ("Detroit Open" for a Detroit club read as the show he had passed on). (5) **Injuries have names** (`FighterCard.injury_kind`, 11 kinds in three bands by events out; saved, defaulted "knock"); fighter page "Hurt · 3  torn knee ligament", news "carried off — %s, out for %d events". (6) Tall info box (≥230, iPad) gets a large layout and a 104×124 portrait well; phones unchanged. Audit fixes: purchases claimed into the open career once a second (`SeasonScene._process`); title shows "BonkWorks · 1.0.0 (3)" (`config/version`, written by `aab_store.ps1` and Codemagic into the scratch copy); `version/name` 1.0.0 tracked, code 2 committed, the AAB name read from the preset; dilemma crowd figure was rounded to 0 (`fans` is a fraction) — now shown. Strings: 16 new, all 9 languages; ja concussion 脳しんとう (盪 not in the pixel font). New `tests/test_feedback.gd`; `test_flows` waits out the beat. |
| 30.92 | **StoreKit on iOS** (Pete, 3 Oct: "let's get the Apple store kit set up"). `scripts/game/apple_store.gd` wraps StoreKit 2 — Miguel de Icaza's GodotApplePlugins StoreKit addon (MIT), pinned to build a6d667d and fetched by the `ios-testflight` workflow, never committed (`/addons/GodotApplePlugins*/` ignored) — in the Play client's own signal and dictionary shapes, so `Store` gains one line in `_backend()` and keeps one code path: transaction id = purchase token, `finish()` = consume, `fetch_unfinished_transactions()` = query purchases / Restore, deferred connections because StoreKit answers off the main thread. Property names checked against the addon's own class list (`product_id`, `display_price`, `transaction_id`). iOS minimum 15.0 → **17.0** (the addon's floor). Export dry run on Linux: both xcframeworks embedded under `dylibs/addons`, deployment target 17.0. The iOS shop says "earned, not bought" only when the addon is missing. `test_store` drives the adapter through `tests/fake_storekit.gd`: buy, credit once, finish, re-delivery not paid twice, cancel, Ask to Buy pending then approved, Restore, unpriced pack refused (8 checks). App Store Connect: cc_small/medium/large consumables at $1.99/$3.99/$7.99, 175 countries. |
| 30.93 | **The dilemma deck, rewritten** (Pete, 3 Oct: "they're all missing half the idea and assuming people know what … they're talking about"). All 18 cards reworded in a shared Claude Doc ("Dilemma Deck — Rewrite") so each body says who, what and why, and each answer's line says what it costs in plain words; Pete edited card 16 himself ("Only after the last bout": morale +3, kit -5). Three new **Beast** energy-drink cards: `beast_shipment` (Shady), `beast_sponsor` (Clean; "Logo only, no music" given morale -2 so every answer still costs something), `beast_flavor` (Any; "White. Obviously." morale +9). Layout: the rule now sits as high as the tallest answer block needs (`_cost_rows` measures the same wrap the drawing uses) — the charity card's three-line answer plus a wrapped row of figures printed on the panel edge under the old fixed 98. Checked at 960x540 and 1024x768 (van, charity, beast_sponsor). New strings are English in the eight other languages until translated. | **locked** — test_dilemma, test_untranslated, test_audit_ui |
| 30.94 | **No Quit on iOS** (Pete, 3 Oct: "Quit button does not work on iPads"). iOS gives an app no way to close itself — Godot's `quit()` is a no-op there and App Review treats self-termination as a crash — so the front door draws Quit on Android and desktop only. New `tools/shot_beat.gd` photographs the end-of-round beat (skips the round, shoots 30 frames in). | **locked** — test_flows |
| 30.95 | **Routes join where the man is** (Pete, 3 Oct: a route drawn while he moved sent him back to where the stroke began). `MeleeSim.join_route` drops the waypoints he has already passed and joins the line at its nearest point; `clamp_route` keeps every waypoint inside the rail. | **locked** — test_feedback (3 route checks), test_melee |
| 30.96 | **Fresh-eyes code audit, 3 Oct** (5 auditors, ~75 findings; all real ones fixed). Fight: a sent man grabbed before he arrives no longer stands idle in the clinch (24 of 126 sends); clinched men refuse routes; a pre-fight swap is not a bout fought; wear/td counters reset each round; HOLD/SKIP hidden while paused; the beat hides the coach mark and marshal line; prompt bars honor READER. Season: one practice per cup weekend (was up to 3–6); cup results and dilemma mood move each man so `sync_morale` keeps them; the raise card raises; simmed ties use the grade; dilemma kit stops at the harness ceiling; no extending in the signing season; cap checks use the billed wage; drawn pool bouts are draws; injured men give up bus seats to fit reserves; emergency releases cut only the injured; knock/cup seeds carry week and match. Store/saves: purchases re-checked on resume and the billing link reconnects; a finished .tmp save is recovered before .bak; settings written atomically; pending payments tracked per purchase; unverified Apple transactions reported, never credited; newer-build saves refused, not silently rolled back; CPU marks pinned; iOS `ITSAppUsesNonExemptEncryption=false`. Screens: league table in right-aligned columns sized by figure and head; message bar in the bottom gutter; bye-week line on two lines; Fix/Upgrade/Session/Extend buttons disabled when the tap would be refused, with the reason; red only for danger (upkeep, max boxes, affordable dilemma costs, Toxic buff off red); shop Back left / Restore right, "20 CC · $1.99"; Trade out of the primary slot; Create/Coach buttons on the real bottom edge; injured man reads "Where: out 3 events · Hurt: torn knee ligament". Text: ~40 unwrapped strings and plurals through the table; bracket rounds, city picker, playbook translated; American spellings; French ordinals; all 1816 strings in all 9 languages (dilemma deck included). Beast sponsor: "fang logo" (Pete). | **locked** — full suite |
| 30.97 | **Injured section, bigger targets, tall iPad layouts** (Pete, 3 Oct, after screen review round 2; "leave the wheel"). A hurt man is off the eight and the bus — a fit reserve takes his seat, he stays on the books and the wage bill, back to the reserve when healed — and the Team tab lists him under INJURED (name, injury, "out N events"); Roster, fighter paging and the Create cut list include him. "+ Hire free agent" rows 36px (or one "(N open)" button). Home-town states ~60x44 on one page. Staff Release/Extend 44px, 24px apart, Release on the outer edge; teaching columns 190 apart. `UiKit.tall_k/tk/tz`: 1.0 on 16:9-and-wider, up to 1.25 at 960x720 — Team, Fight hub, Maintenance, Upgrades, Management, Roster, Market, Records, Bracket, Coach, Create and the Fighter page grow rows and type into the height; phones pixel-identical. Fight hint fits ("Tap to hold ground."); weapon button "Weapon: Sword"; New Career Next bottom-right on every step; injured man reads "Injured — out N events. He stays home." | **locked** — full suite (test_roster injured checks; test_office rule updated: a knock leaves the eight) |
| 30.98 | **Steam groundwork** (Pete, 3 Oct: "we're releasing this also on Steam"; earn-only on Steam; aim for Deck Verified). Desktop saves in a fixed folder (`use_custom_user_dir.pc`, BonkWorks/CombatClub) for Steam Cloud; exported desktop builds start fullscreen, Alt+Enter / F11 and a Settings "Fullscreen: on/off" button flip it (saved); "Buy credits" hidden where nothing is sold; Windows preset 1.0.0.0 with a multi-size crest.ico. Home-screen name "8-Bit Buhurt" on Android (`package/name`) and iOS (Codemagic patches CFBundleDisplayName). Plan and remaining work in project doc steam-plan-3-oct. | **locked** — test_export, test_flows, test_nav, test_save, test_store, test_untranslated |
| 30.99 | **The corner wheel's words, bigger and inside their sides** (Pete, 3 Oct: "slightly bigger, enough for the legibility, however they DO have to fit within their portion of the wheel without clipping through or wrapping"). The longest line takes the longest arc: effect at r 274 (123px of arc), chance 250, name 226 (the names are the short words). Asked sizes 18/15/14 (were 16/13/12), stepped down per line to fit; floors 16/13/12 held in all 9 languages by `test_corner` ("the wheel's words fit their sides"). Shortened to fit: en "he holds firm" (was "he is too steady"); es "libera al tuyo"; de "holt ihn raus"; it "libera il tuo", "proiezione %d%%", "%d%% riuscita"; fr/pt "%d%% chance". | **locked** — test_corner |
