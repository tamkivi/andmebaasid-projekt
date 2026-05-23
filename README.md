# Jõusaali rühmatreeningute ajakava, registreerimise ja osalemise allsüsteem

See hoidla sisaldab ITI0206 andmebaaside projekti lähtefaile ja taastoodetavaid lõppartefakte. Projekt ei käsitle enam treeningut kui töövihiku laadset kirjelduskaarti. Põhiobjekt on konkreetne `treeningukord` koos ruumi, treeneri, registreeringute, ootejärjekorra ja osalemisega.

## Lõppartefaktid

Build toodab neli esitatavat faili kataloogi `submission_files/`:

- `submission_files/dokument.docx`
- `submission_files/skript.sql`
- `submission_files/mudelid.eap`
- `submission_files/rakendus.zip`

Samad juurartefaktid on:

- `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx`
- `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap`
- `jousaali_skript.sql`

## Taastootmine

Eeldused:

- Java JDK koos käsuga `javac`
- Python 3 koos mooduliga `venv`
- Mermaid CLI käsuna `mmdc` või kättesaadav `npx`
- internetiühendus esimesel käivitusel Java, Python ja vajadusel Mermaid sõltuvuste allalaadimiseks

macOS/Linux:

```bash
./build_all.sh
```

Windows:

```bat
build_all.bat
```

Buildi järjekord:

1. valmistab Python sõltuvused ette;
2. renderdab `diagrams/*.mmd` Mermaid diagrammid PNG-failideks;
3. uuendab EAP mudeli Jackcessi tööriistadega;
4. genereerib DOCX aruande;
5. genereerib PostgreSQL skripti lähtefailist `tools/sql_ddl.py`;
6. värskendab `submission_files/` kataloogi ja pakib Flaski rakenduse.

## Kontroll

Pärast buildi:

```bash
.venv/bin/python tools/validate_project.py
```

Valikuline live SQL kontroll disposable PostgreSQL andmebaasis:

```bash
createdb jousaali_live_check
RUN_LIVE_SQL_TESTS=1 LIVE_SQL_DSN="dbname=jousaali_live_check" .venv/bin/python tools/validate_project.py
dropdb jousaali_live_check
```

Validaator kontrollib uue mudeli tabeleid, funktsioone, triggereid, vaateid, Mermaid diagramme, DOCX sisu, EAP sisu, rakenduse funktsioonikutseid ja esituspaketi hügieeni.

## Rakenduse demo

Rakendus on kataloogis `rakendus/`. Pärast PostgreSQL andmebaasi loomist impordi:

```bash
psql -v ON_ERROR_STOP=1 -d jousaali -f submission_files/skript.sql
```

Seejärel seadista `rakendus/.env` ning käivita:

```bash
cd rakendus
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

Vaikimisi töötab prototüüp aadressil `http://127.0.0.1:5001`.

Demo kasutajad:

- juhataja: `juhataja@jousaal.ee` / `juhataja123`
- treener: `treener@jousaal.ee` / `treener123`
- teine treener: `treener2@jousaal.ee` / `treener123`
- klient: `klient@jousaal.ee` / `klient123`
- lisakliendid: `klient2@jousaal.ee`, `klient3@jousaal.ee`, `klient4@jousaal.ee` / `klient123`

## Kaitsmise põhisõnum

Projekt ei ole enam vana `treening` kaardi CRUD. Andmebaas kontrollib mahutavust, kattuvaid aegu, treeneri pädevust, registreerimise ja tühistamise tähtaegu, seisundimuutusi, topeltaktiivset registreeringut, osalemise märkimist ja ootejärjekorra edendamist. Flaski tavapärased kirjutavad töövood kutsuvad PostgreSQL funktsioone ning loevad rollipõhiseid vaateid.
