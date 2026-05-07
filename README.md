# Jõusaali infosüsteemi treeningute funktsionaalne allsüsteem

See hoidla sisaldab ITI0206 andmebaaside projekti lõppartefakte ja nende taastootmiseks vajalikke lähtefaile.

## Lõppartefaktid

- `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx`
- `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap`
- PostgreSQL DDL skript `jousaali_skript.sql`, mis genereeritakse lähtefailist `tools/sql_ddl.py`
- rakenduse/prototüübi failid kataloogis `rakendus/`

## Juhendmaterjalid

Kursuse juhendid ja näidisdokumendid asuvad kataloogis `instruction_guides/`. Need on hoidlasse lisatud tahtlikult, sest lõppdokumendi struktuuri ja kontrollreegleid võrreldakse nende materjalidega.

## Taastootmine puhtast kloonist

Eeldused:

- Java JDK koos käsuga `javac`
- Python 3 koos mooduliga `venv`
- internetiühendus esimesel käivitusel Java ja Python sõltuvuste allalaadimiseks

macOS/Linux:

```bash
./build_all.sh
```

Windows:

```bat
build_all.bat
```

Build teeb järgmised sammud:

1. Loob vajaduse korral `.venv` virtuaalkeskkonna ja paigaldab `requirements.txt` sõltuvused.
2. Laadib vajaduse korral `tools/` alla Jackcessi Java teegid.
3. Kopeerib jälgitava Jackcessiga kirjutatava EAP lähtefaili `preset_files/EA_converted_source.eap` tööfailiks. Algne kursuse EA mall `preset_files/EA_mall_AB_projekt_Eeltaidetud_2026.eap` on jäetud võrdlusmaterjaliks.
4. Rakendab EAP mudelile nime-, sisu- ja kvaliteediparandused.
5. Genereerib DOCX dokumendi päris Wordi pealkirjade, tabelite, piltide ja pealdistega.
6. Genereerib PostgreSQL DDL skripti `jousaali_skript.sql`.

## Esitamiseks vajalikud failid

Maurus/e-õppe keskkonna esitusvormi jaoks vasta failinimedele järgmiselt:

- dokument: `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx`
- mudelid: `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap`
- rakendus: paki kataloog `rakendus/` ZIP-failiks, jättes välja lokaalsed failid nagu `rakendus/.env`, `rakendus/venv/`, `__pycache__/` ja `*.pyc`
- skript: `jousaali_skript.sql`

## Kontroll

Pärast buildi:

```bash
.venv/bin/python tools/validate_project.py
```

Kui kasutad eraldi Pythonit, peab selles olema paigaldatud `python-docx` ja `Pillow`.

SQL DDL on PostgreSQL süntaksiga. Kui kohalik PostgreSQL on olemas, saab DDL-i eraldi kontrollida näiteks nii:

```bash
.venv/bin/python - <<'PY' > /tmp/jousaali_schema.sql
from tools.sql_ddl import SQL_DDL
print(SQL_DDL)
PY
createdb jousaali_ddl_check
psql -v ON_ERROR_STOP=1 -d jousaali_ddl_check -f /tmp/jousaali_schema.sql
dropdb jousaali_ddl_check
```

## Sparx Enterprise Architecti visuaalne lõppkontroll

Enne esitamist ava `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap` Sparx Enterprise Architectis ja kontrolli käsitsi:

- Package tree avaneb korrektselt ning peamised paketid on nähtavad.
- Kõik oodatud diagrammid on olemas ja avanevad ilma veateadeteta.
- Kasutusjuhtude diagrammil on õiged tegutsejad: Treener, Juhataja, Klient, Uudistaja, Klassifikaatorite haldur, Töötajate haldur ja Maksekeskus.
- Kasutusjuhtude seosed on visuaalselt loogilised ning ei ole alles põhjendamata `extend` seoseid.
- Klasside ja olemite diagrammid on loetavad.
- Seisundi- ja tegevusdiagrammid ei ole tühjad.
- Füüsilise disaini klassid vastavad SQL tabelitele.
- Diagrammidel ja märkustes ei ole nähtavaid kohahoidjaid nagu `<Siia sündmus>`, `<täienda>`, `OP..`, `X` või `Y`.
- Ei ole visuaalselt dubleerivaid tegutsejaid, klasse ega ühendusi.
- Kasutusjuhtude notes/descriptions väljad on sisukad.
- Diagrammide elemendid ei kattu ega ole lõuendi servast ära lõigatud.
