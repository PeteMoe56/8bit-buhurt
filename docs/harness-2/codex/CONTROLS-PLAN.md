# Single-family controls under Pete's updated instructions

8 October 2026, 15:56:05 US Central (clock: 20:56:05 UTC), before these runs.

Pete increased the limit to eight variants, explicitly allowed mild grade stat
bonuses, and defined worth buying as a sensible buyer reaching a first title
no slower than a nonbuyer, preferably sooner. No Claude results have been read.

The four original runs and adaptive value design remain recorded as they were.
Three additional controls isolate every remaining family used by value:

6. **prices**: only quartermaster.gd COST [6,14,28,48] → [1,2,4,7].
7. **wages**: only armorer.gd WAGE [0,0,2,4,9,18] → [0,0,1,1,2,3].
8. **bonus**: only fighter_card.gd HARNESS_BASE_BONUS and effective_base formula,
   exactly as in grade/gentle/value: [0,.02,.05,.09,.12], with a 99 cap.

These controls retain the baseline wear ladder to isolate their own family.
It already makes lower grades wear quicker than higher grades, with uneven
steps (.14,.14,.14,.08). They do not increase Rust's absolute wear; the stronger
experimental ladder is separately isolated by wear. No change to TOP, repairs,
income, XP or growth ceilings in any variant.

Use unchanged tools/probe_harness_budget.gd -- 5 20, five default bases, three
original arms, into codex-prices/codex-wages/codex-bonus respectively. Retain
all eight results even if the combined design fails Pete's success definition.

The bonus applies through effective_base to rating and club power, melee
defence, and overall displayed on the card. Raw base/stat bars, ability(),
potential and growth eligibility remain unchanged. It is multiplied by the
same condition factor as base: full at condition 1, .857 of its full amount at
the .35 inspection line; it does not fully disappear before inspection fails.
This is a material bonus plus durability, not a pure condition bonus.
