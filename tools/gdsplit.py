import re,sys,collections
def chunks(src):
    """Split a GDScript file into top-level items; each item = (kind,name,text,start_line). Comments/blank lines
    immediately preceding an item attach to it."""
    lines=src.split('\n')
    items=[]; buf=[]; i=0
    header=[]
    # header: lines until first top-level item that is func/var/const/static/signal/enum/class
    top=re.compile(r'^(static func|func|var|const|signal|enum|@export|@onready|class )')
    cur=None
    for ln_no,l in enumerate(lines):
        if top.match(l):
            if cur is not None:
                items.append(cur)
            m=re.match(r'^(?:static func|func)\s+(\w+)|^(?:var|const|@export var|@onready var)\s+(\w+)|^signal\s+(\w+)|^enum\s+(\w+)|^class\s+(\w+)',l)
            name=next((g for g in m.groups() if g),None) if m else None
            kind='func' if 'func' in l.split('(')[0] else 'other'
            cur={'kind':kind,'name':name,'lines':buf+[l],'start':ln_no-len(buf)}
            buf=[]
        elif l.startswith('\t') or l.startswith(' ') :
            if cur is not None:
                cur['lines'].extend(buf); buf=[]
                cur['lines'].append(l)
            else:
                buf.append(l)
        else:
            # blank or comment or other top-level (extends/class_name)
            if l.strip()=='' or l.startswith('#'):
                buf.append(l)
            elif cur is not None:
                cur['lines'].extend(buf); buf=[]
                cur['lines'].append(l)
            else:
                header.extend(buf+[l]); buf=[]
    if cur is not None: items.append(cur)
    trailing=buf
    return header,items,trailing
if __name__=='__main__':
    src=open(sys.argv[1]).read()
    h,items,t=chunks(src)
    print(len(items), sum(1 for x in items if x['kind']=='func'))
