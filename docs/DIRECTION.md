# Retro Buhurt — Direction Document

**Working title.** BonkWorks. Drafted 10 Sep 2026 from a brainstorming session.
**Status:** concept direction only. Nothing locked, no code, no register yet.

This document is the founding doc for a new project. It carries everything decided
or proposed in the 10 Sep session so a fresh chat can pick it up cold.

---

## 1. The pitch

A single-player, 8-bit buhurt game in the Retro Bowl mould. You run an armored
combat club — recruit fighters, commission harness, manage availability, chase
the national title and Worlds — and during bouts you drop into a fighter's hands
for a few seconds at a time. Cyclical seasons, no timers, no live service.

**Not** a reskin of Armored Combat Team Manager. ACTM is the live F2P manager;
this is the premium single-player one.

---

## 2. Reference and lineage

**Retro Bowl** is the structural reference. Facts worth holding onto:

| | |
|---|---|
| Engine | GameMaker |
| Team | Simon Read solo; pixel artist John Savage added later for character design and animation |
| Timeline | ~July 2019 → January 2020, roughly six months of active development |
| Hands-on time | ~90–120 sec per game, 15–20 snaps of 4–6 sec each |
| Player control | Offense only, and only the throw. Defense and special teams fully simmed |

**RB College** adds recruiting, prestige, a job you can lose, and players who leave.

The critical insight, and the thing most Retro Bowl clones miss: **you don't
control the important player, you control the important moment.** And the reason
it still reads as a GM game is that your roster decisions are legible in your
thumb — a bad arm has a visibly worse throw window, a bad line means you get hit
before the receiver breaks. The action layer exists to make the management layer
*felt*, not to be the game.

---

## 3. Core design

### 3.1 The structural problem: buhurt has no snap

Football is discrete — every play resets. Buhurt is continuous: no reset, clock
runs, 90 seconds of mass. The Retro Bowl structure cannot be ported until an
atomic unit is manufactured.

### 3.2 The atomic units — nested

| Unit | Football analogue | Notes |
|---|---|---|
| **The charge** | Kickoff | Round start; the one true snap buhurt already has. Frequently decisive in 12v12 |
| **The engagement** | The snap | Find target → close → base breaks or you disengage. ~15–20 per round across a 5v5 team, **4–6 for any one fighter** |
| **The round** | The drive | Profight rounds are already possessions. 3 rounds = 3 drives |

Target: **4–5 engagements per round at ~8 sec each ≈ 2 minutes hands-on per bout.**
That's Retro Bowl's budget, arrived at from buhurt's own structure rather than
copied.

### 3.3 The one verb

Retro Bowl's verb is *throw*. Buhurt's honest equivalent is not striking — nobody
wins buhurt by hitting. It's **leverage**: breaking someone's base and putting
three points on the ground.

**Hold to brace. Drag to drive. Release to commit.**

Direction and timing decide whether you break their base, trip them into a
teammate, or overcommit and lose your own. One thumb, portrait, 3–8 seconds.

Stamina drains on drive — **and stamina is a stat you bought.** That's the seam
where the management layer reaches into the player's hands. A gassed fighter
drags slower and recovers later, and you feel it in second 60 of round 3.

### 3.4 Hero vs. owner — three models

The central design question: how do you have a controllable hero and still feel
like an owner rather than a player?

**A. Fixed hero (the QB model).** You always play your captain. Maximum
attachment — he ages, gets injured, retires. Risk: when he's out you're playing a
different game, and buhurt injuries are real and heavy, so this breaks more often
than football's version does.

**B. The captain's eye.** You can inhabit any fighter on the field, but switching
costs a limited resource — 4–6 switches per round, or a beat of AI control. *Who
you're inhabiting becomes the tactical decision.* Rescue the man getting flanked,
or press the opening on the rail? Most owner-flavored option by a distance; also
solves injuries and roster churn for free. Cost: less attachment to any one
fighter.

**C. Earn the lens.** You start as one fighter in someone else's club — fixed
hero, no org layer, a nobody. Earn captaincy and the orders layer unlocks. Found
a club and switching unlocks. Player → captain → owner is literally how buhurt
careers go.

**Recommendation: C as the shape of the game, B as the moment-to-moment mechanic.**
C is also the natural merge point with Hedge Knight — see §9.

### 3.5 The six constraints that keep it a manager

Write these down before anything is built. Every one is a hard rule.

1. **Hands-on ≤ 2 min per bout.** More than that and it's an action game with menus.
2. **Cap hero swing at ~30% of point differential.** He's 20% of a 5v5 roster;
   give him slightly more than his share for agency and no more. A great thumb on
   a bad club still loses — that's the pressure that sends the player back to the
   org screen.
3. **Auto-sim always available, never punished.** A bout you'd win anyway should
   not require your hands.
4. **Post-fight report attributes losses to management, not reflexes.** *"Your #3
   gassed at 0:55 and the rail collapsed."* Failure must point at the roster.
5. **Broadcast camera, never a player camera.** Whole melee, teammate state, score
   ticking. The moment it goes over-the-shoulder it's a fighting game.
6. **Orders outrank hands.** Between engagements: hold the rail / flank left /
   focus their big man / break and breathe. These should move outcomes *more*
   than the drags do.

Constraint 6 is already prototyped — ACTM's Corner is exactly this layer with no
hands attached to it.

---

## 4. What replaces Retro Bowl's pillars

Four pillars don't map. Each substitute is more interesting than the original,
and collectively they're where the game stops being a reskin.

**Draft → trials day.** ~~Buhurt has no draft. You recruit from open trials,
poaching from rival clubs, and crossovers — rugby, HEMA, military, strongman.
Each source has a different stat shape and a different attitude problem. One
trials event per off-season plus year-round poaching that costs goodwill.~~

> **CUT, 12 Sep 2026.** Built and then removed at Pete's word: *"Remove the
> Trials day, Poaching, and Goodwill. Those are not good ideas."* The whole
> system came out — the five sources, the year-round poaching, and the goodwill
> number that priced it — rather than being left in and disabled.
>
> The first half of this paragraph still stands and is still solved: **buhurt has
> no draft**, and `Market` is the answer. Free agency is how the sport actually
> works — people become available and clubs talk to them — and it has been in the
> game since the market went in. What is cut is the second half: the idea that
> raw crossovers arriving with lopsided stat lines were a second inflow worth
> having beside it.

**Salary cap → kit and availability.** Nobody is paid. The cap isn't
money-per-player, it's *how many bodies you can put on a plane and how many
harnesses you own that pass inspection.* Bench depth is limited by armor, not
payroll. A fighter can be your best and unavailable because he can't get the
weekend off. This constraint has never been in a sports management game and it is
completely true to the sport.

**Owner/fan pressure → members and the federation.** Members pay dues and walk if
you're unserious. The federation gates nationals and Worlds on results *and*
compliance — kit standards, marshal certs, insurance. Two masters pulling
opposite directions.

**Getting fired → the club splits.** The signature system. Buhurt clubs fracture
constantly. A bad season, a bad captain call, favoritism over who goes to Worlds,
and half your roster walks out and founds a rival club across town that you now
have to fight. Better than a pink slip: recoverable, generates a rival with a
grudge, and populates that rival with your own former fighters.

If the game has one system people talk about, make it this one.

---

## 5. Season structure

- **10–14 events per season** — local melees (5v5), profight cards (1v1 points),
  a regional, nationals, Worlds if you qualify, plus a couple of
  festival/exhibition dates purely for money and kit.
- **~4–6 bouts per event you actually touch**, rest simmed.
- **Off-season:** trials, kit commissions with real lead times, national-team
  callups stealing your best fighter, injury rehab, gym and facility upgrades.

Estimated 45–90 minutes per season. Retro Bowl's is ~30. Buhurt seasons should
feel heavier.

**Format ladder as difficulty curve:** 1v1 duel (pure timing) → 5v5 (engagement
cycle) → 12v12+ (you barely touch it; you're giving orders). The biggest, most
spectacular fights are the ones you play least. Good rhythm, thematically correct,
and it gives the hands a rest.

---

## 6. Art direction

**8-bit pixel, and it's load-bearing rather than decorative.**

1. **Heraldry is already low-res.** Charges were designed to be readable at 200
   yards through dust by illiterate people — flat color, high contrast, hard
   silhouette. Pixel art is heraldry's native format. The existing ACTM charge set
   translates nearly directly.
2. **It solves the blob problem.** Five armored figures in any realistic style are
   five gray lumps. In 8-bit you get silhouette + two-color surcoat + shield
   charge, and you can read the field instantly at 5v5 and survive at 12v12.
3. **It makes the art scope survivable solo.** One skeleton, ~8 animations × 4–6
   frames, palette-swapped harness types, decal-swapped heraldry.

Art is still the long pole — Read brought in a dedicated pixel artist and so
should we. MLC Studio was already researched for Relic Clash.

---

## 7. Tech

### Engine: Godot 4.6

Current stable as of Jan 2026 (4.7 in beta). Reasons, in honest order:

1. **Hedge Knight is already locked to Godot 4** and shares a world bible. If
   these merge or share tooling, matching engines outweighs any engine-quality
   difference.
2. **Relic Clash already proves the mobile export path works** on this machine
   with this signing setup — that retires the biggest unknown in any engine
   choice.
3. Godot 2D is genuinely top tier and pixel art is its strongest domain.
4. Solo velocity beats engine ceiling; GDScript iteration is fast.

**ACRTW is not a reason** — that's Steam pixel-art, a different target, and it
shouldn't drive a mobile decision.

Considered and rejected: **GameMaker** (strong if starting cold — it's what Retro
Bowl was built in — but GML doesn't transfer and it's a new engine to learn);
**Unity** (its advantage is mobile monetization/live-service infrastructure, the
exact thing this project is walking away from; heavier 2D, bigger builds);
**Defold** (excellent, community too small to be alone in).

### Two concrete tech notes

**Use the Compatibility renderer**, not Forward+ or Mobile. For 2D pixel art the
advanced renderers give nothing and cost device coverage on older Android,
battery life, and build size. This is the most common Godot mobile mistake.

**IAP is the real friction point.** Godot has no first-party cross-platform IAP.
Android has official Google Play Billing support in the docs; iOS StoreKit is
community plugins — godot-iap (OpenIAP-conformant), hrk4649's iOS plugin, or
Thunder Plugins' paid one, which tracks Play Billing versions actively. For one
non-consumable unlock plus restore this is manageable, **but prototype it in week
one, not month five.** Wire the unlock on both platforms before building the
season layer.

Everything else — notifications, save files, audio, l10n — Godot handles natively.

---

## 8. Business model

> **PETE, 12 Sep 2026 — and this supersedes the model below, which has not yet
> been rewritten around it.** *"It can be priced the same. $4.99. In app purchase
> for CC and whatever else is for sale."* Mobile **and** Steam.
>
> That is **premium at $4.99 with IAP for coaching credits** — not free-to-play
> with ads and an unlock. Three consequences follow and none of them is written
> down yet:
>
> 1. **The ads section below is moot**, and with it open question #4 (banners in
>    or out) and the rewarded-video slot list. A paid game does not run ads.
> 2. **The "Unlimited unlock" no longer exists** — there is nothing to unlock,
>    because nothing is locked. What was the unlock is now the price of entry.
> 3. **Steam does not do IAP the way the stores do.** A $4.99 Steam build selling
>    coaching credits is a different conversation from the same build on iOS, and
>    the honest options are DLC, a credits-are-earned-only Steam build, or no
>    credits purchase on desktop at all. **This one needs a decision.**
>
> The four properties immediately below still hold and are the reason the model
> works at all — they were written for the F2P version and they matter more, not
> less, when the player has already paid.

Copy Retro Bowl's structure: ~~**free to play with ads, one-time unlock, plus an
earned-but-purchasable soft currency.**~~

### The four properties that keep it clean

It isn't the number of monetization surfaces — Retro Bowl has three. It's these:

1. **One currency.** Not gems + coins + tickets + energy. One.
2. **No timers anywhere.** Ten seasons back to back at 3am. The only limit is
   your thumb.
3. **The currency is earned at a rate that makes buying it optional.** Buying is a
   shortcut for impatient players, never a gate.
4. **No wall exists.**

**The rule to write on the wall: a player who never pays and never watches an ad
must be able to reach Worlds and win it.** Slower, never blocked.

Hold all four and you can monetize fairly aggressively without being Monopoly Go.
Break #2 or #4 and no restraint elsewhere saves you.

### Ads

Rough market rates, US-weighted: **banner eCPM ~$0.30–1.50, interstitial ~$5–15,
rewarded video ~$10–30.** A player seeing ~80 banner impressions a day nets
roughly 4–8¢/day; at 5,000 DAU that's $200–400/month. Banners are the smallest
lever and permanently eat 50dp of a UI that has no spare vertical space.

**ACTM is live with AdMob — price this off real eCPM by format and geo from that
console, not off the ranges above.**

**Recommendation: rewarded video as the primary format.** Opt-in, 10–30× the
banner rate, and this game shape has natural slots:

- Re-roll a trials candidate
- Scout the opposing club before a bout
- One extra tactical call this round
- Double the purse on a festival date
- Second opinion on an injury prognosis

Nothing on that list is a timer skip, energy refill, or continue. Every one is a
bonus on top of a complete experience.

**The Unlimited unlock kills ads entirely** — that's what makes it worth $3–5. An
inescapable banner reads as a hostage situation; an optional rewarded video reads
as a choice. If a banner ships anyway, restrict it to low-density screens
(results, standings, calendar) and never Front Office or a live bout.

### Currency: Marks

Buhurt has no salaries, so unlike Retro Bowl (which needs in-fiction dollars for
the cap *and* Coaching Credits for everything else) **one currency covers it all.**
Nobody has to be told what a Mark is.

Sinks, all competing for one pool:

- Commission a harness or upgrade a component
- Repairs after a hard event
- Travel and lodging for an away tournament
- Trials day
- Coach / armorer / physio hires
- Gym upgrades — strength, conditioning, technique
- Federation fees, insurance, marshal certification

Seven sinks against one pool is more tension than Retro Bowl's four bars.

Retro Bowl's commissioner dialog translates directly: *"Petition the federation
for a wildcard entry to the World Championships? It will cost you 400 marks."*

### Retro Bowl's actual price points, for reference

| SKU | Price | Unit |
|---|---|---|
| Unlimited Version (team editor, 10-man roster, weather, rule options, no ads) | one-time | — |
| Coaching Credits × 50 | $1.99 | 3.98¢ |
| Coaching Credits × 100 | $3.49 | 3.49¢ |
| Coaching Credits × 250 | $4.99 | 2.00¢ |
| Coaching Credits × 500 | $9.99 | 2.00¢ |
| Coaching Credits × 2000 | $29.99 | 1.50¢ |

Note the 250 and 500 tiers are the same unit price — a slightly weak ladder worth
improving on.

### Operational flag

A second app means a second AdMob app review, and ACTM has been through three
rejections. Budget for slow and annoying rather than a formality, and register the
app early — well before ad units are needed live.

---

## 9. What carries over

**From ACTM — the design work, not the code.** Flutter doesn't come along, but
the expensive part does: match resolution math in the arena package, the Corner's
call seam, the fatigue/readiness model, the fighter stat model, the heraldry
system, 640 generated club names, and the whole release/l10n/store discipline. The
arena math has already been tuned against 32 simulation runs.

**From Hedge Knight — more than expected.** The world bible transfers close to
whole: real countries with fictional federations, Russia excluded, the three
starting archetypes, the weight-sets-role ruling, the tone decision, and all three
research dossiers (buhurt rules/formats/gear/costs/glossary, roguelite
fundamentals, career/legacy/failure design). Rough estimate: **60–70 of the 97
locked items.**

### The fork that needs deciding first

There are now two single-player premium buhurt career games planned in Godot 4 for
Steam+mobile, from one solo dev, sharing a research base and an audience. Hedge
Knight has 7 sessions and 97 locked items in it.

The honest portfolio is probably **ACTM (live F2P manager) + one premium
single-player game**, with ACTM funneling into it. So the question is whether that
premium game is Hedge Knight, is Retro Buhurt, or is one game containing both.

**The merge is cleaner than it sounds:** the player → captain → owner arc (§3.4,
model C) is Hedge Knight's first act followed by Retro Buhurt's whole game. Swap
the card layer for the drag verb and the roguelite run for the season cycle, keep
the title — which is already trademark-cleared.

**This is open question #1 and it should be settled before a second world bible
gets built.**

---

## 10. Scope

Godot 4, solo, 20+ hrs/week, to a shippable 1.0: **estimated 6–9 months.**

| Phase | Estimate |
|---|---|
| Core loop prototype (one bout, one verb) | 1–2 weeks |
| Sim engine + roster model | 3–4 weeks |
| Season / calendar / org layer | 4–6 weeks |
| Art — fighters, arenas, UI | 8–10 weeks (long pole; outsource) |
| Audio | short — the ACTM event-music pipeline already exists |
| Polish, balance, l10n, store | 6–8 weeks |

Retro Bowl itself was ~6 months solo with an artist added mid-project, which is
the closest real datapoint available.

---

## 11. Risks

**Two half-games.** The primary failure mode. Retro Bowl works because the action
layer is tiny and perfect. An ambitious melee sim eats the project and ships a
mediocre fighter bolted to a mediocre manager. The six constraints in §3.5 exist
to prevent this.

**Readability.** Ten armored figures on a phone are ten gray blobs. The 8-bit
choice plus heraldry doing real work is the mitigation, and ACTM's charge set is
already a head start.

**Portfolio dilution.** Three buhurt titles from one studio split a small
audience. See §9.

**Store-shelf overlap with ACTM.** ~~Same search terms, same players. Possibly a
portfolio play (F2P funnels into premium), possibly cannibalization.
Undecided.~~

> **DECIDED, Pete, 12 Sep 2026:** *"ACTM claim stays, this is the second."*
>
> ACTM keeps **"the first buhurt management game"**, which is true, is already
> live on bonkworks.com, and is the kind of claim you only get to make once.
> `8-Bit Buhurt: Combat Club` is the second and says so.
>
> That settles it as a **portfolio play rather than a cannibalization risk**, and
> the shared search term stops being a collision: two games from one studio, both
> findable on "buhurt", one free and one premium, in an order the studio states
> itself rather than leaving the store to infer. A player who finds either one
> finds the other, which is the whole upside of the overlap and was only a
> liability while nobody had said which came first.
>
> Practical consequence for the store copy: **this game never claims to be
> first at anything ACTM is first at.** Its own claim is the shape of the
> game — the melee you play with your thumb, the club you run around it — not
> primacy in the sport.

---

## 12. Open questions

Tagged in the Hedge Knight convention: **ASK** (needs Pete), **REC**
(recommendation awaiting sign-off), **ASSUMED** (baked in unchecked).

**Four answered by Pete on 12 Sep 2026** — recorded here in his words rather than
paraphrased, because the paraphrase is where a decision quietly becomes something
else.

| # | Question | Tag |
|---|---|---|
| 1 | ~~Does this merge with Hedge Knight, replace it, or ship alongside it?~~ **ANSWERED: ships alongside.** *"This is separate, it just used a bunch of guts from Hedge Knight."* The merge in §9 is off; the code reuse is not. | **DONE** |
| 2 | ~~Final title.~~ **ANSWERED: `8-Bit Buhurt: Combat Club`.** Pete, 12 Sep 2026, after four rounds of candidates. See the note below for what it is and is not. | **DONE** |
| 3 | Hero model — C-shape with B-mechanic, or fixed hero throughout? | **REC** |

### The title, and the two names this project now has

**Store name: `8-Bit Buhurt: Combat Club`.** 25 characters, which clears the
mobile name field with room. Short form **`8-Bit Buhurt`** anywhere the subtitle
does not fit — icon, window title, conversation.

Three things it gets right, recorded so a later rename has to argue with them:

1. **The subtitle translates the main title.** "Buhurt" is a word almost no buyer
   knows. A subtitle exists to make the name legible, and this one does the job
   without spending itself on a genre label nobody searches.
2. **It never says "Armored Combat".** Every candidate that did was one word from
   *Armored Combat Team Manager*, BonkWorks' own live F2P title, which is the
   portfolio-dilution risk §11 flags — two games from one studio in one sport
   fighting each other for the same search terms. "Combat Club" carries the same
   meaning and shares no phrase with it.
3. **"Club" is the genre signal.** It says the thing you manage is an
   organisation, which is the whole game, and it says it in one word.

**THE INTERNAL NAME DOES NOT CHANGE.** The repo stays `RetroBuhurt`, the paths
stay, the docs stay, the register's forty-six sections stay. Renaming a codebase
to match a storefront buys nothing and breaks every path in a document that has
been accurate for six days. `project.godot`'s `config/name` is the one place the
store name belongs, because that is the string the built game shows.
| 4 | Banners in or out? Recommendation is rewarded-video-only. | **REC** |
| 5 | ~~Price of the Unlimited unlock — $3.99? $4.99?~~ **ANSWERED: $4.99**, same as Hedge Knight — *"It can be priced the same. $4.99. In app purchase for CC and whatever else is for sale."* See the note under §8: this reads as **premium at $4.99 plus IAP for credits**, which is a different structure from the free-to-play-with-ads model §8 currently describes. | **DONE** |
| 6 | ~~Mobile-only, or Steam too?~~ **ANSWERED: both.** *"Mobile and Steam as well."* | **DONE** |
| 7 | ~~Team size for 5v5 vs. 12v12 — which ships in 1.0 and which is post-launch?~~ **ANSWERED: 5v5 throughout.** Which is what is built; 12v12 is off the roadmap rather than deferred. | **DONE** |
| 8 | Does the club-split system make 1.0, or is it a v1.1 headline feature? | **ASK** |
| 9 | Real countries with fictional federations, Russia excluded — inherit from Hedge Knight? | **ASSUMED** |
| 10 | Currency name "Marks" | **ASSUMED** |
| 11 | Godot 4.6, Compatibility renderer | **REC** |
| 12 | Season length 10–14 events | **ASSUMED** |
| 13 | Art outsourced (MLC Studio or similar) vs. in-house | **ASK** |

---

## 13. First milestone

**One bout. One week.**

Godot, one 5v5, three rounds, the brace-drag-commit verb, four AI teammates, a
sim running around you. No meta, no season, no org screen, no art beyond
placeholder sprites with two-color surcoats.

Two questions to answer:

1. **Can you read the fight?** Ten figures, phone screen, portrait.
2. **Is it still fun on the fifth run?**

If both are yes, everything above is worth designing properly. If not, you found
out in a week instead of six months.

Second milestone, immediately after: **the IAP unlock wired on both platforms**
(§7). Get the unpleasant part out of the way while the project is small.

---

## Working method

Per the Hedge Knight pattern, which is the established process:

- Pete gives the idea, Claude brings the mold, worked through section by section.
- Every item gets an industry-standard recommendation attached.
- Pete proofreads at the end of each session and signs off before anything is
  locked.
- Previous session gets audited for correctness before the next one starts.
- A README stays current so any chat can continue cold.
- Coding starts only after the register is worked through.
