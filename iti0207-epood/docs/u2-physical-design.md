# Ü2 — PostgreSQL baastabelite füüsiline disain (DBeaver / no-EA)

**Kursus:** ITI0207 Andmebaasid II (2026 sügis)  
**Teema:** Nutitelefonide e-poe infosüsteemi kaupade funktsionaalne allsüsteem  
**Töökoht:** kaupade halduri töökoht  
**Uuendatud:** 2026-09-20 (Europe/Tallinn)

## Valitud tee

**Ü2 tee 3 (Erki §1.1):** luua baastabelid otse (SQL + disainimärkmed), arvestades ülesannete 2–4 põhimõtteid; diagrammid hiljem DBeaveri abil registrite kaupa (pöördprojekteerimine / visualiseerimine ilma EA-ta).  
`Diagrammid.eap` jääb ainult referentsiks — seda ei avata ega muudeta.

**Selles lõigus (Ü2):** tabelid, veerud, andmetüübid/pikkused, nullability, PK, UK, FK, sobivad vaikimisi väärtused, puhtad `snake_case` nimed, veergude järjekord Erki §3.7 järgi.  
**Välja jäetud (→ Ü3):** CHECK kitsendused, indeksid.  
**Ei tehta:** DDL `apex2` peal, pgApex, trigerid, vaated, rutiinid, jõusaali domeen.

Allikad: `docs/lahteprojekt/Dokument.docx` (tekstiekstrakt), `docs/ulesanded/Ylesanne_ITI0207_2_2025.txt`, `PROGRESS.md` elutsükli/rollide märkmed. Access `Prototüüp.mdb` / EA — ainult kontekst.

---

## Registrid (kaetud)

| Register | Tabelid | Miks vaja kaupade haldurile |
|---|---|---|
| **Kaupade register** | `kaup`, `nutitelefon`, `kauba_variant`, `kauba_kategooria_omamine` | UC2–UC10 peamine objekt |
| **Klassifikaatorite register** | `brand`, `diagonaal`, `ekraani_resolutsioon`, `kaamera`, `protsessor`, `sisemalu`, `varv`, `kauba_kategooria`, `kauba_kategooria_tyyp`, `kauba_seisundi_liik`, `riik`, `isiku_seisundi_liik`, `tootaja_seisundi_liik`, `kliendi_seisundi_liik`, `tootaja_roll` | OP1/OP6 klassifikaatorid; seisundid; kategooriad; riik isikukoodi UK jaoks |
| **Isikute register** | `isik`, `kasutajakonto` | UC1 autentimine; e_meil kasutajanimena |
| **Töötajate register** | `tootaja`, `tootaja_rolli_omamine` | registreerija / viimane muutja; rollid (haldur, juhataja, …) |
| **Klientide register** | `klient` | UC1 (klient / kliendihaldur kontekst); **mitte** tellimused/arved |

**Teadlikult välja jäetud** (pole kaupade allsüsteemi tuum): tellimused, arved, tarne, garantii, hinnareeglid, soodustused jne.

**Tabelite arv:** **24**.

---

## Tabelite nimekiri (eesmärk)

| # | Tabel | Eesmärk |
|---|---|---|
| 1 | `riik` | ISO 3166 riik/territoorium; isikukoodi unikaalsuse kontekst |
| 2 | `isiku_seisundi_liik` | isiku elutsükkel (nt elus / surnud) |
| 3 | `tootaja_seisundi_liik` | töötaja elutsükkel |
| 4 | `kliendi_seisundi_liik` | kliendi elutsükkel |
| 5 | `tootaja_roll` | haldur, juhataja, kliendihaldur, … |
| 6 | `kauba_seisundi_liik` | ootel / aktiivne / mitteaktiivne / lõpetatud (`kood` 1–4) |
| 7 | `brand` | bränd (ASCII nimi `brand` ← Bränd) |
| 8 | `diagonaal` | ekraani diagonaal tollides |
| 9 | `ekraani_resolutsioon` | resolutsioon + horisontaalne/vertikaalne |
| 10 | `kaamera` | kaamera megapikslid |
| 11 | `protsessor` | protsessori tüüp |
| 12 | `sisemalu` | sisemälu GB (ASCII `sisemalu`) |
| 13 | `varv` | värv (ASCII `varv`) |
| 14 | `kauba_kategooria_tyyp` | kategooriate rühmitus (välimus, sihtgrupp, …) |
| 15 | `kauba_kategooria` | kategooria väärtus tüübi all |
| 16 | `isik` | füüsiline isik |
| 17 | `kasutajakonto` | sisselogimise räsi + aktiivsus (1:1 isikuga) |
| 18 | `tootaja` | töötaja (1:1 isikuga) |
| 19 | `tootaja_rolli_omamine` | roll ajaperioodil |
| 20 | `klient` | klient (1:1 isikuga) |
| 21 | `kaup` | kaubaartikkel |
| 22 | `nutitelefon` | kauba alamtüüp (1:1 `kaup`) |
| 23 | `kauba_variant` | värvivariant |
| 24 | `kauba_kategooria_omamine` | M:N kaup ↔ kategooria |

SQL-mustand: `sql/01_tables_draft.sql`.

---

## Veergude järjekord (Erki §3.7)

Igas tabelis: **PK → UK/alternatiivvõtmete veerud → ülejäänud FK-d → muud kohustuslikud → mittekohustuslikud**. Loogiliselt seotud paarid kõrvuti (`eesnimi`/`perenimi`; `horisontaalne`/`vertikaalne`; `parool`/`on_aktiivne`; `alguse_aeg`/`lopu_aeg`).

---

## Tabelite detailid

Märkus: CHECK-reeglid (nt `@Pole_tühi`, positiivne hind, kauba_koodi muster, eesnimi∨perenimi, ajaintervallid) on **kirjeldatud allikates**, aga **ei kuulu Ü2 DDL-i** — need lähevad Ü3-sse. Siin ainult veerud/tüübid/null/PK/UK/FK/DEFAULT.

### Klassifikaatorid (ühine muster)

Enamikul: surrogaat `*_id` (SMALLINT IDENTITY) + **UK(`kood`)** + **UK(`nimetus`)** + `on_aktiivne boolean NOT NULL DEFAULT TRUE`.

| Tabel | Erisused |
|---|---|
| `riik` | `kood char(3)` (ISO 3166 alpha-3) |
| `diagonaal` | `kood numeric(4,1)` |
| `kaamera` | `kood numeric(6,1)` |
| `sisemalu` | `kood integer` (GB) |
| `ekraani_resolutsioon` | lisaks `horisontaalne`, `vertikaalne` (NOT NULL); **UK(horisontaalne, vertikaalne)** |
| `kauba_seisundi_liik` | `kood smallint` — oodatavad väärtused 1…4 |
| `kauba_kategooria` | FK → `kauba_kategooria_tyyp`; **UK(tyyp_id, nimetus)** (mitte globaalne nimetus); UK(kood) |
| `tootaja_roll` | `on_aktiivne` kohustuslik; valikuline `kirjeldus text` (järjestatud viimaseks) |

### `isik`

| Veerg | Tüüp | Null | Märkus |
|---|---|---|---|
| `isik_id` | integer IDENTITY | NOT NULL | PK |
| `isikukood` | varchar(50) | NOT NULL | osa UK-st koos riigiga |
| `e_meil` | varchar(254) | NOT NULL | UK; kasutajanimi UC1-s |
| `riik_id` | smallint | NOT NULL | FK → `riik` |
| `isiku_seisundi_liik_id` | smallint | NOT NULL | FK |
| `synni_kp` | date | NOT NULL | |
| `reg_aeg` | timestamptz(0) | NOT NULL | DEFAULT `CURRENT_TIMESTAMP` |
| `viimase_muutm_aeg` | timestamptz(0) | NOT NULL | DEFAULT `CURRENT_TIMESTAMP` |
| `eesnimi` | varchar(50) | NULL | Erki: vähemalt üks nimi → CHECK Ü3 |
| `perenimi` | varchar(50) | NULL | |
| `elukoht` | varchar(500) | NULL | |

**UK:** `(riik_id, isikukood)`, `(e_meil)`. Tõstutundetu e_meil-unikaalsus → Ü3 funktsiooniline indeks.

### `kasutajakonto`

| Veerg | Tüüp | Null | Märkus |
|---|---|---|---|
| `isik_id` | integer | NOT NULL | PK + FK → `isik` |
| `parool` | varchar(60) | NOT NULL | bcrypt/crypt räsi (PostgreSQL tee, Erki §3.6); **sool eraldi veerus pole** |
| `on_aktiivne` | boolean | NOT NULL | DEFAULT TRUE |

### `tootaja` / `tootaja_rolli_omamine`

- `tootaja`: `tootaja_id` PK, **UK(`isik_id`)**, FK seisundiliigile.  
- `tootaja_rolli_omamine`: surrogaat PK; FK-d `tootaja`, `tootaja_roll`; `alguse_aeg timestamptz(0) NOT NULL`; `lopu_aeg timestamptz(0) NOT NULL` — use `'infinity'` for open-ended periods; **UK(tootaja_id, tootaja_roll_id, alguse_aeg)**.

### `klient`

- PK/FK `isik_id`; FK `kliendi_seisundi_liik`; `on_nous_tylitamisega boolean NOT NULL DEFAULT FALSE`.

### `kaup`

| Veerg | Tüüp | Null | Märkus |
|---|---|---|---|
| `kaup_id` | integer IDENTITY | NOT NULL | PK |
| `kauba_kood` | varchar(50) | NOT NULL | UK; inimsisestatud (OP1) |
| `nimetus` | varchar(255) | NOT NULL | osaline UK mitte-lõpetatutele → Ü3 |
| `kauba_seisundi_liik_id` | smallint | NOT NULL | FK |
| `brand_id` | smallint | NOT NULL | FK |
| `registreerija_id` | integer | NOT NULL | FK → `tootaja` |
| `viimase_muutja_id` | integer | NOT NULL | FK → `tootaja` |
| `hind` | numeric(12,2) | NOT NULL | |
| `kirjeldus` | text | NOT NULL | Access Memo → TEXT |
| `reg_aeg` | timestamptz(0) | NOT NULL | DEFAULT now |
| `viimase_muutm_aeg` | timestamptz(0) | NOT NULL | DEFAULT now |
| `pildi_aadress` | varchar(500) | NULL | tee/URL; pildi baitide asemel |

### `nutitelefon` (1:1 alamtüüp)

PK/FK `kaup_id` → `kaup` (**ON DELETE CASCADE** unustamise OP2 jaoks).  
FK-d: `eesmine_kaamera_id`, `tagumine_kaamera_id`, `sisemalu_id`, `diagonaal_id`, `protsessor_id`, `ekraani_resolutsioon_id` — kõik NOT NULL.  
`on_sormejalelugeja`, `on_veekindel` — boolean NOT NULL DEFAULT FALSE.

### `kauba_variant`

Surrogaat PK; **UK(`kaup_id`, `varv_id`)**; FK `kaup` CASCADE; FK `varv`.

### `kauba_kategooria_omamine`

Komposiit-PK (`kaup_id`, `kauba_kategooria_id`); CASCADE kaubalt.

---

## Kauba elutsükkel (veerud; reeglid hiljem)

| `kauba_seisundi_liik.kood` | Nimetus | Üleminekud (rakendus/rutiinid/trigerid hiljem) |
|---|---|---|
| 1 | Ootel | registreerimine; Unusta=DELETE; Muuda; Aktiveeri→2 |
| 2 | Aktiivne | Mitteaktiivseks→3; Lõpeta→4 (juhataja); **ei** Muuda (UC4) |
| 3 | Mitteaktiivne | Muuda; Aktiveeri→2; Lõpeta→4 |
| 4 | Lõpetatud | peamiselt vaatamine; füüsilist kustutamist ei ole |

Seisund on FK-veerg `kaup.kauba_seisundi_liik_id` — **mitte** CHECK ega enum Ü2-s.  
`registreerija_id` / `reg_aeg` jäävad muutumatuks peale loomist (jõustamine rutiinides/trigerites).

---

## Access → PostgreSQL tüübimärkmed

| Access (tüüpiline) | PostgreSQL valik | Põhjendus |
|---|---|---|
| AutoNumber Long | `integer GENERATED … AS IDENTITY` | surrogaat; Erki lubab SERIAL/IDENTITY |
| Text(n) | `varchar(n)` | pikkused atribuutide definitsioonidest |
| Memo | `text` | kirjeldused |
| Yes/No | `boolean` | `on_*` lipud |
| Currency / Number(decimal) | `numeric(p,s)` | hind; diagonaal/kaamera koodid |
| Date/Time | `timestamptz(0)` / `date` | Erki: `*_aeg` vs `*_kp`; ajavöönd; whole seconds (0 fractional) |
| OLE / Attachment (pilt) | `varchar` aadress **või** hiljem `bytea` | lähteprojekt: `pildi_aadress`; baitide hoidmine valikuline |
| Short code | `char(3)` / `varchar` / `smallint` | riik / tekstkood / seisundi kood |

Identifikaatorid: ASCII `snake_case` (ä→a, ö→o, ü→u, õ→o; `Bränd`→`brand`, `Töötaja`→`tootaja`, `Värv`→`varv`, `Sisemälu`→`sisemalu`).

Parool: PostgreSQL tee **`varchar(60)` räsi, ilma eraldi `sool` veeruta** (Erki §3.6).

---

## Deferred to Ü3 (explicit)

- Kõik **CHECK** kitsendused (positiivne hind, kauba_koodi muster 6–50, `@Pole_tühi`, eesnimi∨perenimi, ajaintervallid `@Lubatud_ajavahemik`, `lopu_aeg > alguse_aeg`, pildi laiend, hind>1000 ⇒ pilt kohustuslik, jms).
- **Indeksid:** kõik FK-veerud; võimalik osaline unikaalne indeks `kaup.nimetus` mitte-lõpetatud ridadele; `lower(e_meil)` unikaalsus.
- Võimalik `citext` / domeenid (domeenid ametlikult Ü6).

---

## Ambiguities left open

1. **`kauba.nimetus` unikaalsus** — allikas: unikaalne ootel+aktiivne+mitteaktiivne ühendis (lõpetatud võib korduda). Ü2-s ainult tavaline veerg; osaline UK/indeks Ü3.  
2. **`ekraani_resolutsioon.kood` vs horisontaalne×vertikaalne** — mõlemad allikas; hoiame mõlemat (kood OP jaoks, mõõtmed UK jaoks).  
3. **Initial goods state assignment** — New goods must be inserted with `kauba_seisundi_liik_id` referencing the Ootel classifier (expected seed code 1). Application/routine queries the classifier by `kood=1`; no DEFAULT on the FK column (avoids brittle assumption that generated ID 1 always equals state code 1). Assignment implemented in Ü3+ application routines.  
4. **Klientide register** — kaasas UC1 jaoks; kui registreeritud töökoht on rangelt ainult haldur, võib `klient` hiljem dokumendis “konteksttabeliks” märkida, ilma et seda eemaldaksime auth-teelt.  
5. **Pärimine** — `nutitelefon`/`tootaja`/`klient`/`kasutajakonto` on **FK 1:1**, mitte PostgreSQL `INHERITS` (selgem DBeaveri diagrammidel; näidisprojekti INHERITS on valikuline muster).

---

## Järgmine samm (DBeaveri diagrammid)

1. Kohalik Postgres (Docker/Postgres.app) **või** tühjad tabelid — **mitte** `apex2` kuni Ü4.  
2. Käivita `sql/01_tables_draft.sql`.  
3. DBeaver: Database Diagram / ER — **üks diagramm registri kohta** (kaupade, klassifikaatorite, isikute, töötajate, klientide), portrait A4 loetavus Erki §3.2.  
4. Ekspordi PNG/PDF → dokumendi peatükk 3.1.  
5. Peatu enne Ü3 (CHECK + indeksid).
