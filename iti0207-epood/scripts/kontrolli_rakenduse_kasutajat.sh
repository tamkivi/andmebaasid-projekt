#!/bin/sh
# Ainult eraldi kohalikus katseandmebaasis; parool on testiks mõeldud püsiväärtus.
set -eu
if [ "$#" -ne 3 ]; then
    echo "Kasutus: $0 ANDMEBAAS KOHALIK_HOST PORT" >&2
    exit 2
fi
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec python3 - "$root" "$@" <<'PYTHON'
from pathlib import Path
import os,re,subprocess,sys
root=Path(sys.argv[1]);database,host,port=sys.argv[2:]
assert host=='127.0.0.1' or (Path(host).is_absolute() and Path(host).is_dir()), 'Vajalik on kohalik sokkel või 127.0.0.1'
assert re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*',database) and port.isdigit() and 1<=int(port)<=65535, 'Kontrolli andmebaasi nime ja porti'
env={**os.environ,'PGHOST':host,'PGPORT':port,'PGDATABASE':database,
     'PGSERVICEFILE':'/nonexistent','PGPASSFILE':'/nonexistent','PGCONNECT_TIMEOUT':'5','PGSSLMODE':'disable','PGOPTIONS':''}
for key in ['PGHOSTADDR','PGSERVICE']:
    env.pop(key,None)
base=['psql','-X','-w','-v','ON_ERROR_STOP=1','-d',database]
def owner(statement):
    return subprocess.run([*base,'-qAt'],input=statement,env=env,text=True,capture_output=True,check=True).stdout.strip()
user='t253787_epood_kaubahaldur'
owner("ALTER ROLE "+user+" PASSWORD 'disposable-local-login-fixture';")
try:
    actor=owner("SELECT i.e_meil FROM isik i JOIN tootaja t USING(isik_id) JOIN tootaja_rolli_omamine o USING(tootaja_id) JOIN tootaja_roll r USING(tootaja_roll_id) WHERE r.kood='KAUBAHALDUR' AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id LIMIT 1;")
    assert actor, 'Kaubahalduri testkonto puudub'
    login={**env,'PGUSER':user,'PGPASSWORD':'disposable-local-login-fixture'}
    subprocess.run([*base,'-v','test_e_meil='+actor,'-f',str(root/'sql/tests/16_1_rakenduse_kasutaja.sql')],env=login,check=True)
    wrong=subprocess.run([*base,'-v','VERBOSITY=verbose','-c','SELECT current_user'],env={**login,'PGPASSWORD':'wrong-local-fixture'},text=True,capture_output=True)
    assert wrong.returncode!=0 and 'password authentication failed' in wrong.stderr, 'Vale parool peab paroolikontrollis tagasi lükatama; trust ei sobi'
    print('Õige ühendus ja vale parooli keeld kontrollitud.')
finally:
    owner('ALTER ROLE '+user+' PASSWORD NULL;')
PYTHON
