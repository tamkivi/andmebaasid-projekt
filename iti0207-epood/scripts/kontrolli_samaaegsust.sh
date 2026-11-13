#!/bin/sh
# Käivita ainult eraldi kohaliku testandmebaasi vastu.
set -eu
if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    echo "Kasutus: $0 ANDMEBAAS SOKKEL [PORT [LOGIKATALOOG]]" >&2
    exit 2
fi
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec python3 - "$root/sql/tests/samaaegsus" "$@" <<'PY'
from pathlib import Path
import json, os, re, shutil, subprocess, sys, tempfile, time
folder=Path(sys.argv[1]);database=sys.argv[2];socket=sys.argv[3]
port=sys.argv[4] if len(sys.argv)>4 else '56328'
assert Path(socket).is_absolute() and Path(socket).is_dir(), 'Vajalik on kohalik soklikataloog'
assert database and port.isdigit(), 'Kontrolli andmebaasi nime ja porti'
out=Path(sys.argv[5]) if len(sys.argv)>5 else Path(tempfile.mkdtemp(prefix='iti0207-samaaegsus-'))
out.mkdir(parents=True,exist_ok=True)
psql=shutil.which('psql');pgbench=shutil.which('pgbench')
assert psql and pgbench, 'psql ja pgbench peavad olema käsuteel'
env={**os.environ,'PGHOST':socket,'PGPORT':port,'PGDATABASE':database,
     'PGCONNECT_TIMEOUT':'5','PGPASSFILE':'/nonexistent','PGSERVICEFILE':'/nonexistent',
     'PGSSLMODE':'disable','PGOPTIONS':'-c statement_timeout=15000'}
base=[psql,'-X','-w','-qAt','-v','ON_ERROR_STOP=1','-d',database]
results=[]
def sql(statement,label):
    p=subprocess.run([*base,'-c',statement],env=env,text=True,capture_output=True,timeout=25)
    (out/(label+'.log')).write_text(p.stdout+p.stderr)
    if p.returncode: raise RuntimeError(label+': '+p.stderr)
    return p.stdout.strip()
def read(name): return (folder/(name+'.sql')).read_text()
def fixture(label): sql(read('seadista'),label+'-andmed')
def invariants(label): sql(read('kontrolli'),label+'-terviklus')
class Session:
    def __init__(self,name,version):
        self.name=name;self.log=[]
        self.p=subprocess.Popen([*base,'-v','ver='+version],env={**env,'PGAPPNAME':name},
            stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,bufsize=1)
    def send(self,statement):
        self.log.append(statement+'\n')
        self.p.stdin.write(statement+'\n\\echo __VALMIS__\n');self.p.stdin.flush()
    def result(self):
        lines=[]
        while True:
            line=self.p.stdout.readline()
            if not line: raise RuntimeError(self.name+': '+''.join(lines))
            self.log.append(line)
            if line.strip()=='__VALMIS__': return ''.join(lines).strip()
            lines.append(line)
    def close(self):
        if self.p.poll() is None:
            self.p.stdin.write('ROLLBACK;\n\\q\n');self.p.stdin.flush()
        tail=self.p.communicate(timeout=20)[0];self.log.append(tail)
        (out/(self.name+'.log')).write_text(''.join(self.log))
def pair(case,expected_b='NULL'):
    fixture(case)
    version=sql("SELECT xmin::text FROM v_kaubad_muutmiseks WHERE kauba_kood='CON008'",case+'-versioon')
    prefix='u8-'+str(os.getpid())+'-'+case
    a=Session(prefix+'-a',version);b=Session(prefix+'-b',version)
    try:
        a.send(read(case+'_a'));ra=a.result();assert ra=='CON008',(case,'A',ra)
        if case=='s2':
            a.send('COMMIT;');a.result()
            b.send(read(case+'_b'));rb=b.result();locked=False
        else:
            b.send(read(case+'_b'));locked=False;deadline=time.monotonic()+5
            while time.monotonic()<deadline:
                locked=sql("SELECT EXISTS(SELECT 1 FROM pg_stat_activity WHERE application_name='"+b.name+"' AND wait_event_type='Lock')",case+'-lukk')=='t'
                if locked: break
                time.sleep(.02)
            assert locked,case+': B ei jõudnud lukku ootama'
            sql("SELECT application_name,state,wait_event_type,wait_event FROM pg_stat_activity WHERE application_name IN ('"+a.name+"','"+b.name+"')",case+'-seansid')
            a.send('COMMIT;');a.result();rb=b.result()
        assert rb==expected_b,(case,'B',rb)
        b.send('COMMIT;');b.result();invariants(case)
        if case=='s1':
            assert sql("SELECT hind=901 AND nimetus='Samaaegsuse näidiskaup' FROM kaup WHERE kauba_kood='CON008'",case+'-tulemus')=='t'
        if case.startswith('s5'):
            assert sql("SELECT count(*) FROM kaup WHERE kauba_kood='CON008'",case+'-tulemus')=='0'
        results.append({'katse':case,'a':ra,'b':rb,'lukuootus':locked})
        print(case+': korras',flush=True)
    finally:
        a.close();b.close()
assert sql("SELECT count(*) FROM kaup WHERE kauba_kood='CON008'",'algseis')=='0', 'Näidiskauba kood CON008 on juba kasutusel'
try:
    for case in ['s1','s2','s3_aktiveeri','s3_eemalda','s4','s5_kustuta','s5_variant']:
        pair(case,'CON008' if case=='s5_variant' else 'NULL')
    for name in ['muuda','seosed']:
        fixture('koormus-'+name)
        p=subprocess.run([pgbench,'-n','-c','8','-j','4','-T','30','--failures-detailed',
            '-f',str(folder/('pgbench_'+name+'.sql')),database],env=env,text=True,capture_output=True,timeout=55)
        output=p.stdout+p.stderr;(out/('pgbench-'+name+'.log')).write_text(output)
        assert p.returncode==0,output[-3000:]
        failures=re.search(r'number of failed transactions:\s*(\d+)',output)
        deadlocks=re.search(r'number of deadlock failures:\s*(\d+)',output)
        assert failures and deadlocks, 'Koormustesti kokkuvõte puudub'
        count=int(failures[1]);deadlock_count=int(deadlocks[1])
        if name=='muuda': assert count==0, 'Kauba muutmisel tekkis tõrge'
        else: assert count==deadlock_count, 'Seoste katses tekkis muu tõrge kui ummikseis'
        invariants('koormus-'+name)
        results.append({'koormus':name,'torkeid':count,'ummikseise':deadlock_count})
        print(name+': tõrkeid '+str(count)+', ummikseise '+str(deadlock_count),flush=True)
finally:
    sql("DELETE FROM kaup WHERE kauba_kood='CON008'",'puhastus')
(out/'tulemused.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
print('Kontroll läbitud. Logid: '+str(out),flush=True)
PY
