# Claude's Harness #2 log (US Central)
- 15:11 A and B started (sealed plan).
- 15:35 A, B done, validation_passed=true. A: no_h 25/25 10.76, h_first 9/25 19.88, dev_first 3/25 20.04. B: no_h 25/25 10.04, h_first 6/25 19.52, dev_first 11/25 18.16.
- 15:36 C = A + club_office.gd kit_cost: ceil(gap*5)-1 clamp 0..4 -> ceil(gap*5) clamp 0..5 (repairs cost money). D = B + same kit_cost change. Started.
- 16:28 Codex report read. Started R (Codex value.patch repro), C (A + paid repairs, rerun), H (Codex grade.patch + paid repairs).
- 16:39 C done: no_h 17/25 15.68, h_first 0/25 20.00, dev_first 2/25 19.64 (cap 20). Paid repairs drain everyone; dead end.
- 16:46 R reproduces Codex value exactly (10.88/10.88/10.44). H (grade + paid repairs): 11.72/13.68/14.24. Started R on held-out bases 17011 29033 43049 67061 91081.
- 16:55 R held-out: no_h 10.40, h_first 10.76, dev_first 10.80 (per-base dev-no: +0.8 -0.4 +2.2 -0.4 -0.2). Started V2 = value with bonus [0,.03,.07,.12,.16] on both seed sets.
- 17:04 V2 done. Default: 10.88/10.36/11.16. Held-out: 10.40/10.44/11.04. Power trace: harness_first power vs no_harness at S1/3/5/8/10/12: +0/+0.5/+0.4/-0.4/-0.5/-0.9 (V2). Bonus buys ~0.5 power; development displacement eats it.
- 17:38 Melee sweep (tools/probe_harness_melee.gd, identical rosters, auto play, grade L vs Rust, n=64/cell, seeds 900000+): today's game: grade has NO effect (53.1/25.0/9.4/0.0 at deficit 0/4/8/12 for every grade). Value: grade 2/3/4 at d0 = 70.3/76.2/76.6; d4 = 20.3/14.1/17.2; d8 = 4.7/7.8/12.5. V2: d0 = 75.0/76.6/71.9; d8 = 10.9/12.5/20.3. Kit is a tiebreaker at parity; doesn't rescue a 4-point deficit (C-6 safe).
- 18:03 Codex R2 read (recommends sponsor on value prices). Started S1 = r2-sponsor.patch with COST/WAGE back to today's (6/14/28/48; 0/0/2/4/9/18), S2 = r2-sponsor.patch with pre-doubling COST 3/7/14/24 and value wages; both seed sets.
- 18:20 S1 (sponsor, today's prices+wages): default 10.88/16.76/16.16 (13,18/25 titles); held-out 10.40/16.72/16.24. FAIL.
  S2 (sponsor, 3/7/14/24, value wages): default 10.88/11.56/11.80; held-out 10.40/11.20/11.56. FAIL (+0.7..+1.2) despite higher income (350 vs 309).
  Started S3 = sponsor with 2/4/8/14, value wages, both sets.
- 18:30 S3 (sponsor, 2/4/8/14): default 10.88/10.48/10.96; held-out 10.40/10.52/10.56. Break-even; income 358-373 vs 309-313.
- 18:38 Pete chose Codex's sponsor (1/2/4/7). Applied r2-sponsor.patch to main with: pay_sponsors/sponsor_rate/SPONSOR_CC names, own books line "Sponsors", translated entry text, Maintenance-tab "sponsors X CC a bout", test_quartermaster no-nerf line at 1.10 (Pete's ruling) + 9 new checks. Balance tier + full gate running.
- Summaries (no .jsonl) of every Claude run are in docs/bakeoff-2/harness/claude-*. wearA/wearB were renamed claude-A/claude-B.
