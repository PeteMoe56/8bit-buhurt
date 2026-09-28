#!/usr/bin/env python3
"""Move a set of methods out of a GDScript class into a helper class of static
functions, leaving thin delegating wrappers behind.

  extract_group.py SRC.gd HostClass NewFile.gd NewClass "self_param" funcs... [--builtins a,b,c]

Every moved body is rewritten so that references to the host's members become
`<p>.member` (instance vars/funcs) or `HostClass.member` (consts, enums, static
funcs). A function whose locals shadow a host member is refused (left in place).
"""
import re, sys
sys.path.insert(0, __import__('os').path.dirname(__file__))
from gdsplit import chunks

ID = re.compile(r'[A-Za-z_]\w*')

def tokens(code):
    """Yield (kind, text) over code: 'str', 'comment', 'code'."""
    i = 0; out = []
    while i < len(code):
        c = code[i]
        if c == '#':
            j = code.find('\n', i); j = len(code) if j < 0 else j
            out.append(('comment', code[i:j])); i = j; continue
        if c in '"\'':
            q = c
            # triple quotes
            if code[i:i+3] in ('"""', "'''"):
                j = code.find(code[i:i+3], i+3); j = len(code) if j < 0 else j+3
                out.append(('str', code[i:j])); i = j; continue
            j = i + 1
            while j < len(code) and code[j] != q:
                if code[j] == '\\': j += 1
                if code[j] == '\n': break
                j += 1
            out.append(('str', code[i:j+1])); i = j + 1; continue
        # & or ^ string names / node paths
        if c in '&^' and i + 1 < len(code) and code[i+1] in '"\'':
            q = code[i+1]; j = i + 2
            while j < len(code) and code[j] != q:
                if code[j] == '\\': j += 1
                j += 1
            out.append(('str', code[i:j+1])); i = j + 1; continue
        j = i
        while j < len(code) and code[j] not in '#"\'' and not (code[j] in '&^' and j + 1 < len(code) and code[j+1] in '"\''):
            j += 1
        if j == i: j = i + 1
        out.append(('code', code[i:j])); i = j
    return out

def locals_of(func_text):
    names = set()
    head = func_text.split('\n', 1)[0]
    m = re.search(r'\((.*)\)', head)
    if m:
        for p in m.group(1).split(','):
            p = p.strip()
            if p: names.add(re.match(r'\w+', p).group(0))
    for m in re.finditer(r'\bvar\s+(\w+)', func_text): names.add(m.group(1))
    for m in re.finditer(r'\bfor\s+(\w+)\s+in\b', func_text): names.add(m.group(1))
    for m in re.finditer(r'\bfunc\s*\(([^)]*)\)', func_text):
        for p in m.group(1).split(','):
            p = p.strip()
            if p: names.add(re.match(r'\w+', p).group(0))
    # match bindings: `var x` inside match patterns handled by var regex
    return names

def rewrite_body(text, inst, stat, P, host):
    out = []
    for kind, s in tokens(text):
        if kind != 'code':
            out.append(s); continue
        res = []; last = 0
        for m in ID.finditer(s):
            name = m.group(0)
            prev = s[:m.start()].rstrip()
            prev_ch = prev[-1:] if prev else ''
            nxt = s[m.end():].lstrip()[:1]
            # skip after '.', skip keywords handled by membership
            if prev_ch == '.':
                continue
            if name == 'self':
                res.append(s[last:m.start()]); res.append(P); last = m.end(); continue
            if name in inst:
                # dictionary key in `{name: ...}` literal is a string only if quoted; bare names in GDScript dict keys are strings in Lua style `{a = 1}` only
                res.append(s[last:m.start()]); res.append(P + '.' + name); last = m.end()
            elif name in stat:
                res.append(s[last:m.start()]); res.append(host + '.' + name); last = m.end()
        res.append(s[last:])
        out.append(''.join(res))
    return ''.join(out)

def main():
    args = sys.argv[1:]
    builtins = []
    if '--builtins' in args:
        k = args.index('--builtins'); builtins = args[k+1].split(','); args = args[:k] + args[k+2:]
    src_path, host, new_path, new_class, P = args[:5]
    wanted = args[5:]
    src = open(src_path, encoding='utf-8').read()
    header, items, trailing = chunks(src)
    inst = set(builtins); stat = set()
    for it in items:
        first = next(l for l in it['lines'] if not l.startswith('#') and l.strip())
        if it['name'] is None: continue
        if first.startswith('static func') or first.startswith('const') or first.startswith('enum'):
            stat.add(it['name'])
        else:
            inst.add(it['name'])
    # enum values used bare? (enum Foo {A, B} values can be used bare) - collect
    for it in items:
        first = next(l for l in it['lines'] if not l.startswith('#') and l.strip())
        if first.startswith('enum'):
            body = '\n'.join(it['lines'])
            m = re.search(r'\{(.*)\}', body, re.S)
            if m:
                for v in m.group(1).split(','):
                    v = v.strip().split('=')[0].strip()
                    if re.match(r'^\w+$', v): stat.add(v)
    moved = []; kept = []; refused = []
    for it in items:
        if it['kind'] == 'func' and it['name'] in wanted:
            text = '\n'.join(it['lines'])
            code_only = ''.join(s for k, s in tokens(text) if k == 'code')
            loc = locals_of(code_only)
            clash = loc & (inst | stat)
            if clash:
                refused.append((it['name'], sorted(clash))); kept.append(it); continue
            moved.append(it)
        else:
            kept.append(it)
    new_items = []
    wrappers = {}
    base_P = P
    for it in moved:
        lines = it['lines']
        code_only = ''.join(x for k, x in tokens('\n'.join(lines)) if k == 'code')
        P = base_P
        while P in locals_of(code_only):
            P = P + '_'

        di = next(i for i, l in enumerate(lines) if re.match(r'^(static )?func ', l))
        comments = lines[:di]
        ## A signature may run over several lines; join until the parens close.
        end = di
        depth = lines[di].count('(') - lines[di].count(')')
        while depth > 0 and end + 1 < len(lines):
            end += 1
            depth += lines[end].count('(') - lines[end].count(')')
        sig = ' '.join(x.strip() if k else x for k, x in enumerate(lines[di:end+1]))
        lines = lines[:di] + [sig] + lines[end+1:]
        is_static = sig.startswith('static func')
        m = re.match(r'^(static )?func\s+(\w+)\((.*)\)(\s*->\s*[^:]+)?:\s*(.*)$', sig)
        name, params, ret, inline = m.group(2), m.group(3), m.group(4) or '', m.group(5)
        ## Default values and the return type may name the host's enums/consts.
        params_new = rewrite_body(params, set(), stat, P, host)
        ret = rewrite_body(ret, set(), stat, P, host) if ret else ret
        body = '\n'.join(lines[di+1:])
        body_new = rewrite_body(body, inst, stat, P, host) if not is_static else rewrite_body(body, set(), stat, P, host)
        inline_new = rewrite_body(inline, inst, stat, P, host) if inline else ''
        if is_static:
            new_sig = 'static func %s(%s)%s:%s' % (name, params_new, ret, (' ' + inline_new) if inline_new else '')
        else:
            new_sig = 'static func %s(%s%s)%s:%s' % (name, '%s: %s' % (P, host), (', ' + params_new) if params.strip() else '', ret, (' ' + inline_new) if inline_new else '')
        new_items.append('\n'.join(comments + [new_sig] + ([body_new] if body.strip() else [])))
        # wrapper in host
        call_args = ', '.join(re.match(r'\s*(\w+)', p).group(1) for p in params.split(',') if p.strip())
        ret_kw = '' if ret.strip() == '-> void' else 'return '
        if is_static:
            w = 'static func %s(%s)%s:\n\t%s%s.%s(%s)' % (name, params, ret, ret_kw, new_class, name, call_args)
        else:
            w = 'func %s(%s)%s:\n\t%s%s.%s(self%s)' % (name, params, ret, ret_kw, new_class, name, (', ' + call_args) if call_args else '')
        wrappers[name] = w
    # rebuild host: replace moved items by wrappers (with a one-line pointer comment)
    out_items = []
    for it in items:
        if it in moved:
            out_items.append('## -> %s (%s)\n%s' % (new_class, new_path.split('/')[-1], wrappers[it['name']]))
            out_items.append('')
            out_items.append('')
        else:
            out_items.append('\n'.join(it['lines']))
    new_src = '\n'.join(header + out_items + trailing)
    open(src_path, 'w', encoding='utf-8').write(new_src)
    head = 'class_name %s\nextends RefCounted\n## Methods of `%s`, moved out of %s so that file is not one\n## three-thousand-line object. Every function takes the %s as `%s`; `%s`\n## keeps a one-line wrapper for each, so callers did not change.\n\n\n' % (
        new_class, host, src_path.split('/')[-1], host, P, host)
    open(new_path, 'w', encoding='utf-8').write(head + '\n\n\n'.join(new_items) + '\n')
    print('moved %d, refused %d' % (len(moved), len(refused)))
    for r in refused: print('  refused', r)

main()
