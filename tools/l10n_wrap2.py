#!/usr/bin/env python3
"""Codemod (28 Sep 2026): wrap sentence literals in the rules layer in UiKit.t().

    python3 tools/l10n_wrap2.py [--dry] files...

Wraps a string literal when it reads as a sentence or phrase (a 3+ letter word
and a space, or ends in . ! ?), and it is NOT: inside a `const` table (those go
through the extractor's TABLES registry and are translated where read), a
dictionary key, one side of a comparison, an argument to print / push_error /
push_warning / assert / hash / load / preload / has / get / set / emit /
connect / call, a path, already wrapped. Idempotent. Kept so the rule is on
record, like tools/l10n_wrap.py.
"""
import re, sys

SKIP_CALLS = re.compile(r'\b(print|prints|printerr|push_error|push_warning|assert|hash|load|preload|has|get|set|emit_signal|emit|connect|call|has_method|get_node|find_child|begins_with|ends_with|contains|replace|split|find|erase|remove_at|str_to_var|FileAccess\.open|DirAccess\.\w+|ProjectSettings\.\w+|Audio\.play|Juice\.\w+|RegEx\.create_from_string|compile)\(\s*$')
LIT = re.compile(r'"((?:[^"\\\n]|\\.)*)"')

def sentence(t):
    if 'res://' in t or 'user://' in t:
        return False
    return bool(re.search(r'[A-Za-z]{3,}', t)) and (' ' in t or re.search(r'[.!?]$', t))

def process(src):
    out = []
    depth_const = 0
    in_const = False
    changed = 0
    for line in src.split('\n'):
        st = line.strip()
        if not in_const and re.match(r'^(static\s+)?const\s+\w+.*:?=\s*[\[{]', st):
            in_const = True
            depth_const = 0
        if in_const:
            depth_const += line.count('[') + line.count('{') - line.count(']') - line.count('}')
            out.append(line)
            if depth_const <= 0:
                in_const = False
            continue
        if st.startswith('#') or st.startswith('const '):
            out.append(line); continue
        code = line
        # cut trailing comment (outside strings) roughly
        new = ''
        pos = 0
        for m in LIT.finditer(code):
            t = m.group(1)
            pre = code[:m.start()]
            post = code[m.end():]
            if '#' in re.sub(r'"(?:[^"\\\n]|\\.)*"', '""', pre):
                break
            skip = (not sentence(t)
                or pre.endswith('UiKit.t(')
                or post.lstrip().startswith(':')
                or re.search(r'(==|!=|\bin)\s*$', pre)
                or re.match(r'\s*(==|!=)', post)
                or SKIP_CALLS.search(pre)
                or re.search(r'\b(match)\b', st))
            new += code[pos:m.start()] + (m.group(0) if skip else 'UiKit.t(%s)' % m.group(0))
            pos = m.end()
            if not skip:
                changed += 1
        new += code[pos:]
        out.append(new)
    return '\n'.join(out), changed

if __name__ == '__main__':
    dry = '--dry' in sys.argv
    tot = 0
    for f in [a for a in sys.argv[1:] if not a.startswith('--')]:
        src = open(f, encoding='utf-8').read()
        new, n = process(src)
        tot += n
        if n and not dry:
            open(f, 'w', encoding='utf-8').write(new)
        if n:
            print(f"{n:4d} {f}")
    print("wrapped", tot)
