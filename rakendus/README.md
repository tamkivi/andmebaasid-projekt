# Jõusaali Infosüsteemi - Treeningu Funktsionaalne Allsüsteem

Flaskiga loodud veebirakendus, mis toetab jõusaali treeningute registreerimist, muutmist, vaatamist ja seisundite juhtimist.

## 📋 Projekt info

- **Kursus:** ITI0206 - Andmebaaside projektid
- **Semester:** 2026 kevad
- **Autorid:** Tristan Aik Sild, Gustav Tamkivi
- **Tehnoloogia:** Python Flask + PostgreSQL

## Keskkonna piirid

- Rakendus on lokaalne õppeprojekti prototüüp, mitte tootmiskeskkonna rakendus.
- PostgreSQL on nõutud; rakendus ei tööta ainult failipõhise või mälus oleva andmebaasiga.
- Enne käivitamist tuleb `.env.example` kopeerida failiks `.env` ja kohandada PostgreSQL ühenduse väärtused.
- Rakendus kasutab räsitud paroole, sessiooni, parameeterdatud SQL päringuid ja rollipõhiseid õiguseid. README ei väida tootmiskeskkonna turvameetmeid, näiteks CSRF-kaitset, sest neid ei ole prototüübis eraldi realiseeritud.
- Kui kursuse töötajad nõuavad TalTech PostgreSQL serverisse laadimist või demoandmebaasi seadistamist, tuleb see teha eraldi kohaliku prototüübi käivitamisest.

## ✨ Omadused

### Kasutajate rollid
- **Treener** - Registreerib, muudab, aktiveerib, muudab mitteaktiivseks ja unustab ootel treeninguid
- **Juhataja** - Vaatab kõiki treeninguid, lõpetab treeninguid ja vaatab koondaruannet
- **Klient** - Vaatab aktiivseid treeninguid
- **Uudistaja** - Vaatab avalikult nähtavaid aktiivseid treeninguid

### Funktsionaalsus
- ✅ Kasutaja autentimine ja sessioon
- ✅ Treeningu registreerimine
- ✅ Treeningu muutmine
- ✅ Treeningu aktiveerimine, mitteaktiivseks muutmine, unustamine ja lõpetamine
- ✅ Treeningu kategooriatega sidumine
- ✅ Treeningu vaatamine detailidega
- ✅ Rollipõhised õigused
- ✅ Dashboard statistikaga ja juhataja koondaruanne

## 🔧 Paigaldus

### 1. Eeltingimused

- Python 3.8+
- PostgreSQL 12+
- pip (Python package manager)

### 2. Andmebaasi seadistamine

Esmalt looge andmebaas ja tabelid:

```bash
# Ühenduge PostgreSQL-iga
psql -U postgres

# Looge andmebaas
CREATE DATABASE jousaali;

# Ühenduge andmebaasiga
\c jousaali

# Käivitage SQL-skript
\i ../jousaali_skript.sql
```

Või käsul:
```bash
psql -U postgres -d jousaali -f ../jousaali_skript.sql
```

### 3. Rakenduse paigaldus

```bash
# Kloonige / navigeerige projektkausta
cd rakendus

# Looge virtuaalsel keskkond
python -m venv venv

# Aktiveerige virtuaalset keskkonda
# macOS/Linux
source venv/bin/activate

# Windows
venv\Scripts\activate

# Paigaldage nõutavad paketid
pip install -r requirements.txt
```

### 4. Keskkonna muutujate seadistamine

```bash
# Kopeerige näidisfail
cp .env.example .env

# Redigeerige .env ja sisestage andmebaasi andmed
nano .env  # või teie lemmikeditor
```

### 5. Testiandmete lisamine

Andmebaasi testimiseks saab käivitada kaasas oleva faili:

```bash
psql -U postgres -d jousaali -f test_data.sql
```

### 6. Rakenduse käivitamine

```bash
# Aktiveerige virtuaalset keskkonda (kui pole juba)
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate      # Windows

# Käivitage Flask
python app.py
```

Rakendus peaks käivituma: `http://localhost:5000`

## Andmebaasi suitsutest submission_files põhjal

Järgmised käsud eeldavad, et PostgreSQL töötab lokaalselt ja käsud käivitatakse kaustast `rakendus/` pärast virtuaalkeskkonna aktiveerimist. Vajaduse korral asendage kasutaja `postgres` oma kohaliku PostgreSQL kasutajaga.

```bash
# Looge või lähtestage puhas testandmebaas
dropdb -U postgres --if-exists jousaali_smoke
createdb -U postgres jousaali_smoke

# Käivitage lõplik esitatav SQL skript
psql -U postgres -v ON_ERROR_STOP=1 -d jousaali_smoke -f ../submission_files/skript.sql

# Lisage valikulised testiandmed
psql -U postgres -v ON_ERROR_STOP=1 -d jousaali_smoke -f test_data.sql

# Kontrollige, et tabelid ja näidisandmed on olemas
psql -U postgres -d jousaali_smoke -c '\dt'
psql -U postgres -d jousaali_smoke -c 'SELECT COUNT(*) AS treeninguid FROM treening;'

# Seadistage rakendus sama andmebaasi kasutama
cp .env.example .env
```

Muutke `.env` failis vähemalt järgmised väärtused:

```env
DB_NAME=jousaali_smoke
DB_USER=postgres
DB_PASSWORD=postgres
```

Seejärel käivitage rakendus ja kontrollige ühendust eraldi terminalis:

```bash
python app.py
curl -fsS http://127.0.0.1:5000/trainings >/dev/null && echo "App connects"
```

## 📊 Andmebaasi skeem

### Tabelid

#### Klassifikaatorid
- `riik` - Riikide klassifikaator
- `isiku_seisundi_liik` - Isiku seisund (klient, töötaja jne)
- `tootaja_seisundi_liik` - Töötaja seisund
- `tootaja_roll` - Töötaja rollid (treener, juhendaja jne)
- `treeningu_seisundi_liik` - Treeningu seisund (ootel, aktiivne, lõppenud)
- `treeningu_kategooria_tyyp` - Treeningu kategooria tüüp
- `treeningu_kategooria` - Konkreetsed kategooriad

#### Peamised tabelid
- `isik` - Kasutajate üldandmed
- `kasutajakonto` - Sisselogimisandmed
- `tootaja` - Töötaja andmed
- `tootaja_rolli_omamine` - Töötaja rollide ajalugu
- `treening` - Treeningute andmed
- `treeningu_kategooria_omamine` - Treeningu ja kategooria seos

## 🔐 Turvalisus

- Paroolid on räsitud (werkzeug.security)
- Sessioon-põhine autentimine
- SQL injection kaitse (parameeterdatud päringud)
- Rollipõhised õigused

## 📱 Kasutajaliides

### Lehekülgede vaade

- **Login** (`/login`) - Sisselogimine
- **Dashboard** (`/dashboard`) - Statistika ja kiired tegevused
- **Trainings** (`/trainings`) - Treeningu nimekirja vaatamine
- **Register Training** (`/trainer/register-training`) - Uue treeningu registreerimine
- **Edit Training** (`/trainer/edit-training/<id>`) - Ootel või mitteaktiivse treeningu muutmine
- **Manager Report** (`/manager/report`) - Treeningute koondaruanne seisundite ja kategooriate kaupa

### API lõpp-punktid

- `GET /api/stats` - Statistika JSON-ina

## 🚀 Kasutamine

### Treenerina

1. Logige sisse e-mail ja parooliga
2. Minge "Treener" → "Registreeri treening"
3. Sisestage treeningu detailid
4. Valige kategooriad
5. Salvestatud treening ilmub ootel seisundis treeningute töölauda
6. Vajaduse korral muutke, aktiveerige, muutke mitteaktiivseks või unustage treening

### Juhatajana

1. Logige sisse
2. Vaadake kõiki treeninguid
3. Lõpetage aktiivne või mitteaktiivne treening, mida enam ei pakuta
4. Avage koondaruanne seisundite ja kategooriate kaupa

### Kliendi või uudistajana

1. Avage `/trainings` või logige sisse kliendina
2. Vaatage aktiivseid treeninguid
3. Vaadake treeningu detaile
4. Kontrollige treeningu kirjelduse, hinna, kestuse ja osalejate arvu andmeid

## 🐛 Tõrkeotsing

### Andmebaasi ühenduse viga

```
Error: could not connect to server: Connection refused
```

**Lahendus:** Kontrollige, kas PostgreSQL käivitatakse:
```bash
# macOS
brew services start postgresql

# Linux
sudo systemctl start postgresql

# Windows - kontrollida Services-is
```

### Paroolide probleemid

Testamiseks saate luua uue parooliga:

```python
from werkzeug.security import generate_password_hash
hash = generate_password_hash('password123', method='pbkdf2:sha256')
print(hash)
# Sisestage see andmebaasi
```

### Pordi kasutamine

Kui port 5000 on juba kasutusel:

```bash
PORT=5001 python app.py
```

## 📚 Failide struktuur

```
rakendus/
├── app.py                 # Peamine Flask rakendus
├── requirements.txt       # Pythoni paketid
├── .env.example          # Keskkonna muutujate näidis
├── README.md             # See fail
├── templates/            # HTML šabloonid
│   ├── base.html         # Põhimall
│   ├── login.html        # Sisselogimisleht
│   ├── dashboard.html    # Dashboard
│   ├── trainings.html    # Treeningu nimekiri
│   ├── register_training.html  # Uue treeningu vorm
│   ├── report.html       # Juhataja koondaruanne
│   └── error.html        # Vealeht
```

## 📝 Märkused

- Rakendus on loodud õppeprojekti lokaalse prototüübina.
- Andmebaasi ühendus seadistatakse `.env` failis.

## 📞 Kontakt

- **E-mail:** tristansild@icloud.com
- **Projekt:** ITI0206 Andmebaaside projektid
- **Instituut:** Tallinna Tehnikaülikool

## 📄 Litsents

Projekt on loodud õppimise eesmärgil ja kuulub TTÜ Tarkvarateaduse instituudile.

---

**Viimane värskendus:** 7. mai 2026  
**Versioon:** 1.0
