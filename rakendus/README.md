# Jõusaali rühmatreeningute Flask prototüüp

Rakendus demonstreerib andmebaasiprojekti kolme nähtavat töövoogu:

- juhataja planeerib, avab, sulgeb, lõpetab või tühistab konkreetseid treeningukordi;
- treener näeb enda treeningukordi, osalejate nimekirja ja märgib osalemist;
- klient vaatab avatud ajakava, registreerub, satub täitumisel ootejärjekorda ja tühistab enda registreeringu.

Tavapärased kirjutavad toimingud kutsuvad PostgreSQL funktsioone. Rakendus ei ole eraldiseisev ärireeglite allikas. Treeningukorra planeerimisel kuvab juhataja vorm ruumide varustust ja treeninguliikide varustuse nõudeid; sobimatuse lõplik kontroll tehakse andmebaasis.

## Eeltingimused

- Python 3.8+
- PostgreSQL 12+
- imporditud `../submission_files/skript.sql` või `../jousaali_skript.sql`

## Paigaldus

```bash
cd rakendus
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Muuda `.env` failis vähemalt. Allolevad väärtused on kohaliku prototüübi näited, mitte kooli serveri kasutajanimi ega parool:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=jousaali
DB_USER=postgres
DB_PASSWORD=postgres
```

## Andmebaasi loomine

Repo juurkaustast:

```bash
createdb jousaali
psql -v ON_ERROR_STOP=1 -d jousaali -f submission_files/skript.sql
```

`skript.sql` sisaldab juba demoandmeid. Vajadusel saab pärast skeemi importimist käivitada ka:

```bash
cd rakendus
psql -v ON_ERROR_STOP=1 -d jousaali -f test_data.sql
```

## Käivitamine

```bash
python app.py
```

Vaikimisi aadress: `http://127.0.0.1:5001`

## Demo kasutajad

Järgmised kasutajad ja paroolid on ainult lokaalse demoandmebaasi testimiseks. Need ei ole TalTechi ega kooli PostgreSQL serveri kasutajad.

- juhataja: `juhataja@jousaal.ee` / `juhataja123`
- treener: `treener@jousaal.ee` / `treener123`
- teine treener: `treener2@jousaal.ee` / `treener123`
- klient: `klient@jousaal.ee` / `klient123`
- lisakliendid: `klient2@jousaal.ee`, `klient3@jousaal.ee`, `klient4@jousaal.ee` / `klient123`

## Olulisemad marsruudid

- `/dashboard` - rollipõhine avaleht
- `/schedule` - avatud treeningukordade ajakava
- `/client/registrations` - kliendi enda registreeringud
- `/manager/sessions` - juhataja treeningukordade töölaud
- `/manager/sessions/new` - uue treeningukorra planeerimine koos ruumi varustuse infoga
- `/manager/report` - täituvuse statistika
- `/trainer/sessions` - treeneri tunniplaan
- `/trainer/sessions/<treeningukorra_id>/roster` - osalejate nimekiri ja osalemise märkimine

## Andmebaasi funktsioonid, mida rakendus kasutab

- `fn_tuvasta_kasutaja_e_meili_jargi`
- `fn_planeeri_treeningukord`
- `fn_ava_treeningukord`
- `fn_sulge_treeningukord`
- `fn_lopeta_treeningukord`
- `fn_tyhista_treeningukord`
- `fn_registreeri_klient_treeningukorrale`
- `fn_tyhista_registreering`
- `fn_marki_osalemine`

## Prototüübi piirid

Rakendus on õppeprojekti prototüüp. See kasutab parameeterdatud SQL päringuid, parooliräse ja sessioone, kuid ei väida tootmiskeskkonna täielikku turvataset. Varustus on ainult ruumi sobivuse põhiandmete kontroll, mitte täiemahuline inventari elutsükli haldus. Makseid, tellimusi, inventari, toitumiskavasid ja palgaarvestust ei käsitleta.
