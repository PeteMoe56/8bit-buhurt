import json,subprocess,time
jobs=json.load(open('/home/claude/b3/stage3.json'))
# wait for reruns
while subprocess.run("ps -eo args | grep run_variant | grep -v grep | wc -l",shell=True,capture_output=True,text=True).stdout.strip()!='0': time.sleep(15)
running=[]
for name,spec,bases in jobs:
    while len(running)>=2:
        running=[p for p in running if p.poll() is None]; time.sleep(5)
    running.append(subprocess.Popen(['bash','/home/claude/b3/run_variant.sh',name,json.dumps(spec),'5']+bases)); time.sleep(2)
for p in running: p.wait()
print('ALL DONE',time.strftime('%H:%M'))
