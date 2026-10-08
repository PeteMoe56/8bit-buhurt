"""Build the locked-rubric deliverable from Codex's independently inspected rows."""
import csv
import json
from pathlib import Path
from collections import defaultdict
from PIL import Image

root = Path(__file__).resolve().parent
data = json.loads((root / 'codex-review-data.json').read_text(encoding='utf-8'))
manifest = list(csv.DictReader((root / 'renders/MANIFEST.tsv').open(encoding='utf-8-sig'), delimiter='\t'))
reviews = {r['file']: r for r in data['renders']}
findings = {f['id']: f for f in data['findings']}
assert len(manifest) == len(reviews) == len(data['renders']) == 132
assert set(reviews) == {m['file'] for m in manifest}
for m in manifest:
    r = reviews[m['file']]
    assert len(r['scores']) == 6 and all(isinstance(s, int) and 1 <= s <= 5 for s in r['scores'])
    assert all(fid in findings and m['file'] in findings[fid]['evidence'] for fid in r['findings'])
    for i, s in enumerate(r['scores'], 1):
        assert s == 5 or any(f'C{i}' in findings[fid]['criteria'] for fid in r['findings']), (m['file'], i)
    with Image.open(root / 'renders' / m['file']) as im:
        assert im.size == tuple(map(int, m['canvas'].split('x')))

def mean(rows):
    return sum(sum(reviews[m['file']]['scores']) / 6 for m in rows) / len(rows)

def counts(rows):
    ids = {fid for m in rows for fid in reviews[m['file']]['findings']}
    return {s: sum(findings[fid]['severity'] == s for fid in ids) for s in ('S1', 'S2', 'S3')}

def cell(s):
    return str(s).replace('|', '\\|').replace('\n', ' ')

groups = defaultdict(list)
for m in manifest:
    groups[Path(m['file']).stem].append(m)
game_mean = sum(mean(rows) for rows in groups.values()) / len(groups)
game_counts = counts(manifest)
lines = ['# Screen Score #1: Codex',
         f"Game score: {game_mean:.1f} / 5   (S1: {game_counts['S1']}, S2: {game_counts['S2']}, S3: {game_counts['S3']})", '',
         'Per viewport:']
for viewport in ('v16x9', 'v19x9n', 'v19x9', 'v16x10'):
    rows = [m for m in manifest if m['viewport'] == viewport]
    c = counts(rows)
    lines.append(f"- {viewport}: {mean(rows):.1f} / 5 (S1: {c['S1']}, S2: {c['S2']}; {len(rows)} renders)")
lines += ['', 'Reviewed all 132 supplied renders individually at their native canvas dimensions, against the locked rubric. '
          'The images are the supplied `d5ce8a9` snapshot; the local checkout began at `d8cf2d5`. '
          'No Claude score, sealed output or earlier screen review was read. No game code changed.', '',
          f'Aggregation: {len(groups)} logical screen/state groups; unrounded criterion means feed viewport and logical means. '
          'Only displayed values are rounded. Finding counts are distinct defects, not multiplied by the number of affected images. '
          'A 5 means the criterion is met in the supplied still, not that animation, behavior or every unseen state is proven.', '',
          'The broad menu work is strong: club identity, prices, upkeep, lineups and primary actions are usually clear. '
          'The main weaknesses are overlay layering, angled wheel text and a few state-specific layout errors. '
          'I found no still-proven S1 blocked essential action or unreadable essential result. The S2 findings remain worth fixing despite the high mean.', '',
          '## Priority fixes', '']
priority = ['S38-1', 'S40-1', 'S37b-1', 'S29-1', 'S05-1', 'S12-1', 'S41-1', 'S26b-2', 'S25-1', 'S25-2', 'S42-1',
            'S33-1', 'S41-2', 'S01-1', 'S26b-1', 'S16-1']
short = {
 'S38-1': 'Put the pre-bout full playbook on an opaque modal panel.',
 'S40-1': 'Apply the wide colour-popup offset once; cover the entire viewport with its scrim.',
 'S37b-1': 'Keep the champion name fully inside Your Path.',
 'S29-1': 'Remove stale walk-out controls from the live-fight coach mark; check the shot fixture.',
 'S05-1': 'Restore the BENCH heading in the taller TEAM layout.',
 'S12-1': 'Keep Extend and Release in the same order on every captain card.',
 'S41-1': 'Preserve Open/Classic distinctions in dated tournament cells.',
 'S26b-2': 'Give Done and Back separate meanings and use the correct opener name.',
 'S25-1': 'Keep wheel action/chance/effect text horizontal.',
 'S25-2': 'Keep standing counts and fighter status visible while the wheel is open.',
 'S42-1': 'Replace the coach appearance placeholder with a working preview.',
 'S33-1': 'Separate the total differential from the current grade in the records footer.',
 'S41-2': 'Separate the calendar heading from its phase label.',
 'S01-1': 'Put the music credit inside the declared safe inset.',
 'S26b-1': 'Use the same pixel typography in the full-playbook header.',
 'S16-1': 'Let the venue panel show the ground, not just repeat its name and capacity.'}
for i, fid in enumerate(priority, 1):
    f = findings[fid]
    lines.append(f"{i}. **{fid} {f['severity']}** — {short[fid]} Effort: {f['effort']}.")
lines += ['', 'Severity comes first; within severity, small concrete repairs precede broader control/art work. '
          'Effort is an estimate. Behavioral impact and fixture-versus-production questions need validation.', '', '## Scores', '',
          '| render | viewport | screen / state | C1 | C2 | C3 | C4 | C5 | C6 | score | S1/S2 | note |',
          '|---|---|---|---:|---:|---:|---:|---:|---:|---:|---|---|']
for m in manifest:
    r = reviews[m['file']]
    c = counts([m])
    refs = ', '.join(r['findings']) or '—'
    values = [m['file'], m['viewport'], m['screen'] + ' / ' + m['state'], *r['scores'],
              f"{sum(r['scores']) / 6:.1f}", f"{c['S1']}/{c['S2']}", r['note'] + ' ' + refs]
    lines.append('| ' + ' | '.join(map(cell, values)) + ' |')
lines += ['', '## Logical-screen means', '', '| screen / state | viewports | mean | S1/S2 | worst finding |',
          '|---|---|---:|---|---|']
rank = {fid: i for i, fid in enumerate(priority)}
for key in sorted(groups):
    rows = groups[key]
    c = counts(rows)
    ids = {fid for m in rows for fid in reviews[m['file']]['findings']}
    worst = min(ids, key=lambda fid: rank[fid]) if ids else '—'
    title = rows[0]['screen'] + ' / ' + rows[0]['state']
    values = [key + ': ' + title, ', '.join(m['viewport'] for m in rows), f'{mean(rows):.1f}', f"{c['S1']}/{c['S2']}", worst]
    lines.append('| ' + ' | '.join(map(cell, values)) + ' |')
lines += ['', '## Findings', '']
for fid in priority:
    f = findings[fid]
    lines += [f"### {fid} — {short[fid]}", '',
              f"- **{f['tags']} {f['severity']}**: {f['text']}",
              '- Evidence: ' + ', '.join(f'`{p}`' for p in f['evidence']) + '; ' + f['region'] + '.',
              '- Suggestion: ' + f['suggestion'],
              f"- Effort: {f['effort']}. Criteria: {', '.join(f['criteria'])}.", '']
lines += ['## Cross-cutting suggestions', '',
 '- Use one modal coordinate/layering path for the scrim, panel and controls. Exercise it from both walk-out and corner, at the wide and standard canvases.',
 '- Keep action text horizontal even where the hit area is radial; retain the existing buhurt action choices and mechanical effects.',
 '- Add render checks for labels tied to changing panel height: BENCH, CHAMPION and multi-field footers. These are useful art/layout checks either assistant can write.',
 '- Keep safe-area treatment consistent down to footer credits. Most centred menus use their margins purposefully; there is no blanket penalty for a 960-wide content frame.',
 '- Preserve readable full event identities in the calendar. The market fee labels and dense modal headers are also good candidates for the existing nine-language fit checks, without assuming an unseen translation failure.',
 '- Treat the coach and venue previews as opportunities to make it visibly your club while retaining the fixed palette, binary-alpha assets and locked list ratio.', '',
 '## What I could not judge from stills', '',
 '- Motion, sound, touch feel, actual physical-device readability, controller focus/navigation and the timing of tutorial/modal transitions.',
 '- Non-English strings, scrolling states not supplied, and fight/notch or fight/Steam-Deck combinations omitted by the brief. No missing-viewport deductions.',
 '- The coach mark shows a corner timer at 0:00, but a still cannot establish whether gameplay/timers continue under it; that needs a transition test.',
 '- The input manifest calls `26c_corner_favourites` four favourites; both supplied images show two. Scores describe the visible two-card strip. The before/after `38`/`38b` images both show four stars but differ in their order. File `42_founding_step_4` is a CUSTOM state of Step 3 of 3, not a fourth required step.',
 '- Whether the stale walk-out controls and missing playbook backing reproduce in the live build or originate in the shot setup. They are scored as visible weaknesses of the supplied renders, with that uncertainty explicit.',
 '- The fake/test money is not scored as an economy defect; the stills do not validate probability estimates, level counts, league mathematics or purchasing behavior.', '',
 'Audit files: `codex-review-data.json` contains the individual criterion scores and evidence mappings. '
 '`build_codex_score.py` checks complete manifest coverage, native sizes, finding references and a finding for every deduction, then calculates the means.']
(root / 'codex-score.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(json.dumps({'renders': len(manifest), 'logical_states': len(groups), 'game_mean_unrounded': game_mean,
                  'findings': game_counts, 'coverage': '132/132', 'deductions_with_evidence': True}, indent=2))
