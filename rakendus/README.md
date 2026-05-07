# Jõusaali Infosüsteemi - Treeningu Funktsionaalne Allsüsteem

Veebirakendusel üleslaaditud Flask'iga, mis rakendab jõusaali treeningu haldamise süsteemi.

## 📋 Projekt info

- **Kursus:** ITI0206 - Andmebaaside projektid
- **Semester:** 2026 kevad
- **Autorid:** Tristan Aik Sild, Gustav Tamkivi
- **Technoloogia:** Python Flask + PostgreSQL

## ✨ Omadused

### Kasutajate rollid
- **Treener** - Registreerib, muudab ja aktiveerib treeninguid
- **Klient** - Vaatab aktiivseid treeninguid ja bronteerib
- **Uudistaja** - Vaatab avalikult nähtavat infot

### Funktsionaalsus
- ✅ Kasutaja autentimine ja sessioon
- ✅ Treeningu registreerimine
- ✅ Treeningu aktiveerimise ja seisundite muutmine
- ✅ Kategooriate haldus
- ✅ Treeningu vaatamine detailidega
- ✅ Rollipõhised õigused
- ✅ Dashboard statistikaga

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

### 5. Testimiskasutajate lisamine

Andmebaasi testimiseks saate lisada kasutajaid:

```sql
-- Lisage riik
INSERT INTO riik (riigi_kood, nimetus) VALUES ('EE', 'Eesti');

-- Lisage isikud ja kontod
INSERT INTO isik (isikukood, riigi_kood, isiku_seisundi_liik_kood, synni_kp, eesnimi, perenimi, e_meil)
VALUES 
('12345678901', 'EE', 'KLIENT', '1990-01-01', 'Tristan', 'Treener', 'treener@jousaal.ee'),
('12345678902', 'EE', 'KLIENT', '1995-05-15', 'Andres', 'Klient', 'klient@jousaal.ee');

-- Lisage kasutajakontod (paroolid on räsitud)
INSERT INTO kasutajakonto (e_meil, parool, on_aktiivne)
VALUES 
('treener@jousaal.ee', '<parool_räsid>', TRUE),
('klient@jousaal.ee', '<parool_räsid>', TRUE);
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
- CSRF kaitse (Flask)
- SQL injection kaitse (parameeterdatud päringud)
- Rollipõhised õigused

## 📱 Kasutajaliides

### Lehekülgede vaade

- **Login** (`/login`) - Sisselogimine
- **Dashboard** (`/dashboard`) - Statistika ja kiired tegevused
- **Trainings** (`/trainings`) - Treeningu nimekirja vaatamine
- **Register Training** (`/trainer/register-training`) - Uue treeningu registreerimine

### API lõpp-punktid

- `GET /api/stats` - Statistika JSON-ina

## 🚀 Kasutamine

### Treenerina

1. Logige sisse e-mail ja parooliga
2. Minge "Treener" → "Registreeri treening"
3. Sisestage treeningu detailid
4. Valige kategooriad
5. Saate aktiveerida treeningu listist

### Klientina

1. Logige sisse
2. Vaatage aktiivseid treeninguid
3. Vaadake treeningu detaile
4. Broneeri treening (funktsiooniks sammal)

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
│   └── error.html        # Vealeht
└── static/               # CSS, JavaScript, pildid (tulevikus)
```

## 🔄 Jääkute arendus

Võimalikud täiendused:

- [ ] Treeningu broneeri funktsioon
- [ ] Maksete haldus
- [ ] Aruannete genereerimine
- [ ] E-posti teatised
- [ ] Kalender vaade
- [ ] Piktogrammide lisamine
- [ ] Mobiilne rakendus (React Native)

## 📝 Märkused

- Rakendus on eesmärgiga õppematerjalina
- Tootmiseks vajaks täiendavat turvasete ja jõudluse seadistust
- HTTPS on soovitav tootmisserveril

## 📞 Kontakt

- **E-mail:** tristansild@icloud.com
- **Projekt:** ITI0206 Andmebaaside projektid
- **Instituut:** Tallinna Tehnikaülikool

## 📄 Litsents

Projekt on loodud õppimise eesmärgil ja kuulub TTÜ Tarkvarateaduse instituudile.

---

**Viimane värskendus:** 7. mai 2026  
**Versioon:** 1.0
