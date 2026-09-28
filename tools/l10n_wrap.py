#!/usr/bin/env python3
"""One-off codemod (27 Sep 2026): wrap display-text literals in UiKit.t().

Scans the argument span of UiKit.text/right/mid/raw/pair/button calls and the
right-hand side of `flash =`, `notice =`, `.text =` assignments, `_say(` and
`Line.new(` calls, and wraps every string literal that reads as words (has a
capital letter or a space, is not a res:// path) in UiKit.t(). Idempotent.
Kept in tools/ so the rule that decided what was wrapped is on record.
"""
import re, sys, glob

START = re.compile(r'UiKit\.(text|right|mid|raw|pair|button)\(|\bflash\s*=(?!=)|\bnotice\s*=(?!=)|\.text\s*=(?!=)|\b_say\(|\bLine\.new\(')

def is_words(t):
    return ('res://' not in t and re.search(r'[A-Za-z]', t)
            and (re.search(r'[A-Z]', t) or ' ' in t) and not t.startswith('user://'))

def span_end(src, i):
    """From i, return end index of the statement/call span (balanced parens, stops at newline when depth 0)."""
    depth = 0
    j = i
    in_str = False
    while j < len(src):
        c = src[j]
        if in_str:
            if c == '\\': j += 2; continue
            if c == '"': in_str = False
        else:
            if c == '"': in_str = True
            elif c == '#': # comment to end of line
                while j < len(src) and src[j] != '\n': j += 1
                continue
            elif c in '([{': depth += 1
            elif c in ')]}':
                depth -= 1
                if depth < 0: return j
            elif c == '\n' and depth <= 0: return j
        j += 1
    return j

def process(src):
    out = []
    pos = 0
    count = 0
    for m in START.finditer(src):
        if m.start() < pos: continue
        # skip matches inside comments
        ls = src.rfind('\n', 0, m.start()) + 1
        if '#' in src[ls:m.start()].split('"')[0]: continue
        # for calls, start after the '('; for assignments after '='
        body_start = m.end()
        end = span_end(src, body_start)
        seg = src[body_start:end]
        new, n = wrap(seg)
        count += n
        out.append(src[pos:body_start]); out.append(new); pos = end
    out.append(src[pos:])
    return ''.join(out), count

LIT = re.compile(r'"((?:[^"\\\n]|\\.)*)"')

def wrap(seg):
    res = []; last = 0; n = 0
    for m in LIT.finditer(seg):
        before = seg[max(0, m.start()-9):m.start()]
        if before.endswith('UiKit.t(') or not is_words(m.group(1)):
            continue
        # skip dictionary keys / get() keys: next non-space char is ':' or it's an arg of get(/has(
        after = seg[m.end():m.end()+2].lstrip()
        pre = seg[max(0, m.start()-6):m.start()]
        if after.startswith(':') or pre.endswith('get(') or pre.endswith('has(') or pre.endswith('meta('):
            continue
        # skip comment lines inside the segment
        ls = seg.rfind('\n', 0, m.start()) + 1
        if seg[ls:m.start()].lstrip().startswith('#'):
            continue
        res.append(seg[last:m.start()]); res.append('UiKit.t(%s)' % m.group(0)); last = m.end(); n += 1
    res.append(seg[last:])
    return ''.join(res), n

if __name__ == '__main__':
    total = 0
    for f in sys.argv[1:]:
        src = open(f, encoding='utf-8').read()
        new, n = process(src)
        if n:
            open(f, 'w', encoding='utf-8').write(new)
        total += n
        print(f"{f}: {n}")
    print("total", total)
