#!/usr/bin/env bash
## run_variant.sh NAME SPEC_JSON NCAREERS [BASES...]
## SPEC_JSON: [[file, regex, replacement], ...] applied to a fresh worktree of rb HEAD + rb working-tree diff.
set -u
name=$1; spec=$2; n=$3; shift 3
wt=/home/claude/b3/wt-$name
rm -rf "$wt"; git -C /home/claude/rb worktree prune
git -C /home/claude/rb worktree add -q --detach "$wt" HEAD
(cd /home/claude/rb && git diff HEAD -- scripts) | (cd "$wt" && git apply)
cp -r /home/claude/rb/.godot "$wt/"
python3 - "$wt" "$spec" <<'PY'
import sys,json,re
wt,spec=sys.argv[1],json.loads(sys.argv[2])
for f,rx,rep in spec:
    p=wt+'/'+f; s=open(p).read()
    s2,k=re.subn(rx,rep,s,count=1,flags=re.M)
    assert k==1,(f,rx)
    open(p,'w').write(s2)
PY
cd "$wt" && bash tools/bb.sh probe harness_budget $n 20 "$@" --out=res://docs/bakeoff-2/harness/b3-$name > /home/claude/b3/$name.log 2>&1
find "$wt/docs/bakeoff-2/harness/b3-$name" -name "*.jsonl" -delete; rm -rf "$wt/.godot"
grep -h HARNESS_BUDGET /home/claude/b3/$name.log
