# Ü2 — PostgreSQL baastabelite füüsiline disain (DBeaver / no-EA)

**Kursus:** ITI0207 Andmebaasid II (2026 sügis)
**Teema:** Nutitelefonide e-poe infosüsteemi kaupade funktsionaalne allsüsteem
**Töökoht:** kaupade halduri töökoht
**Uuendatud:** 2026-10-19 (Europe/Tallinn)

## Valitud tee

**Ü2 tee 4 (2026 ver2 §2.1):** luua baastabelid otse (SQL + disainimärkmed), arvestades ülesannete 2–4 põhimõtteid; registridiagrammid on pöördprojekteeritud kohalikust PostgreSQLi baasist Graphviziga ning sama baas on DBeaveris avatav.
`Diagrammid.eap` jääb ainult referentsiks — seda ei avata ega muudeta.

**Füüsiline mudel:** tabelid, veerud, andmetüübid/pikkused, kohustuslikkus, PK, UK, FK, CHECK, sobivad vaikeväärtused, `snake_case` nimed ja veergude järjekord Erki §3.7 järgi.
**Indeksid:** 16 välisvõtmeindeksit ja e-posti tõstutundetu unikaalne avaldisindeks.
**Ei tehta:** DDL `apex2` peal, pgApex, trigerid, rutiinid, jõusaali domeen.

Allikad: `docs/lahteprojekt/Dokument.docx` (tekstiekstrakt), `docs/sources/Ylesanne_ITI0207_2_2026_ver2.txt`, `PROGRESS.md` elutsükli/rollide märkmed. Access `Prototüüp.mdb` / EA — ainult kontekst.

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

23.09 auditi käigus jagati viis registrit 11 loetavaks jooniseks. Klassifikaatorite register võtab viis ja kaupade register kolm lehte; iga tabeli veerud/piirangud on ainult ühel lehel. Täpne lehtede loend ja kontekstitabelid on docs/diagrams/README.md.

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

## Tabelite salvestus ja loomine

Tabelite loomise fail on ühes transaktsioonis (`START TRANSACTION` ja `COMMIT`). Muudetavate tabelite `FILLFACTOR=90` jätab lehtedele ruumi uuenduste jaoks. Variandi ja kategooria omamise seoseridade puhul tehakse lepingute järgi lisamine või kustutamine, mistõttu neile eraldi madalamat täitetegurit ei määrata. Kõik 20 surrogaatvõtit kasutavad IDENTITY-generaatoreid; välisvõtmetele generaatorit ei looda. Seisundite vaikeväärtused jäävad lahtiseks, kuni nende koodid ja algseisundid on kinnitatud.

## Tabelite detailid

DDL sisaldab 45 tabeli CHECK-kitsendust ja ühte jagatud domeeni CHECK-kitsendust, mis lähtuvad kontseptuaalse mudeli atribuutide definitsioonidest. Teksti sisukontroll välistab tühja ja ainult tühimärkidest koosneva väärtuse. Valikulised veerud võivad jääda NULL-iks. Positiivse arvu reegel välistab ka PostgreSQLi eriväärtuse NaN. Ajapiirid on fikseeritud ISO-vormingus ega sõltu jooksva päeva väärtusest.

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
| `eesnimi` | varchar(50) | NULL | CHECK nõuab vähemalt ühte nimeosa |
| `perenimi` | varchar(50) | NULL | |
| `elukoht` | varchar(500) | NULL | |

**UK:** `(riik_id, isikukood)`. E-posti tõstutundetu unikaalsuse tagab `ux_isik_e_meil` avaldisel `lower(e_meil)`. Tavalist e-posti UNIQUE-indeksit ei dubleerita.

### `kasutajakonto`

| Veerg | Tüüp | Null | Märkus |
|---|---|---|---|
| `isik_id` | integer | NOT NULL | PK + FK → `isik` |
| `parool` | varchar(60) | NOT NULL | bcrypt/crypt räsi (PostgreSQL tee, Erki §3.6); **sool eraldi veerus pole** |
| `on_aktiivne` | boolean | NOT NULL | DEFAULT TRUE |

### `tootaja` / `tootaja_rolli_omamine`

- `tootaja`: `tootaja_id` PK, **UK(`isik_id`)**, FK seisundiliigile.
- `tootaja_rolli_omamine`: surrogaat PK; FK-d `tootaja`, `tootaja_roll`; `alguse_aeg timestamptz(0) NOT NULL`; `lopu_aeg timestamptz(0) NOT NULL DEFAULT 'infinity'` — lõputa perioodi vaikimisi lõpp on `'infinity'`; **UK(tootaja_id, tootaja_roll_id, alguse_aeg)**.

### `klient`

- PK/FK `isik_id`; FK `kliendi_seisundi_liik`; `on_nous_tylitamisega boolean NOT NULL DEFAULT FALSE`.

### FK kompenseerivad tegevused

Kõik 25 FK-d määravad nüüd selgesõnaliselt ON DELETE ja ON UPDATE. Isikust sõltuvad 1:1 alamtabelid `kasutajakonto`, `tootaja` ja `klient` kasutavad kustutamisel CASCADE. Kaubast sõltuvad `nutitelefon`, `kauba_variant` ja `kauba_kategooria_omamine` kasutavad samuti CASCADE. Ülejäänud 19 FK puhul on ON DELETE NO ACTION; kõigi 25 puhul ON UPDATE NO ACTION, sest viidatud surrogaat-ID-sid ei ole vaja muuta. See ei asenda hilisemat seisundipõhist kustutusõiguse kontrolli.

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

## Väärtuste kitsendused

- Klassifikaatorite nimetused ja tekstilised koodid peavad sisaldama vähemalt üht mittetühimärki. Riigikood koosneb kolmest suurtähest A–Z. Diagonaali, kaamera, sisemälu ja resolutsiooni mõõtmed on positiivsed.
- Isikukood sisaldab ainult mudelis lubatud tähti, numbreid ja erimärke. Vähemalt üks nimeosa on olemas. E-post sisaldab @-märki; aadress ei koosne ainult numbritest. Sünnikuupäev jääb aastatesse 1900–2100 ega ole registreerimise Eesti kuupäevast hilisem.
- Isiku ja kauba ajatemplid ning rolli algus jäävad aastatesse 2010–2100. Muutmise aeg ei eelne registreerimise ajale. Rolli lõpp on algusest hilisem ning võib olla infinity.
- Kaubakoodi pikkus on 6–50 märki; see algab kolme suurtähega ja jätkub suurtähtede või numbritega. Kauba nimetus on vähemalt neli märki pikk, hind positiivne ja kirjeldus sisukas. Pildi aadress lõpeb .jpg või .png laiendiga; üle 1000-eurose hinna korral on pilt kohustuslik.
- Konto räsi ja valikuline rollikirjeldus ei või olla tühi tekst. See ei asenda autentimisel räsi kontrollimist.

Piirjuhud on failis `sql/tests/04_tables.sql`: 49 lubatud ja 64 keelatud väärtust. Keelatud väärtuste puhul kontrollitakse SQLSTATE-i ning nimetatud CHECK-kitsendust. Riigist sõltuvat Eesti isikukoodi pikkuse reeglit ei saa praeguse riik_id kaudu väljendada ühe rea CHECK-kitsendusena.

## Indeksid

`sql/10_indexes.sql` lisab 16 välisvõtmeindeksit veergudele, mida olemasolev PK või UNIQUE indeks algusveeruna ei kata. Kõik 25 välisvõtme veergu on kaetud kehtiva, osalise tingimuseta B-puu indeksi algusveeruga. Primaar- ja alternatiivvõtmete automaatseid indekseid ei korrata. E-posti aadressi unikaalsust kontrollib ainult `lower(e_meil)` unikaalne indeks; eri tõstuvariandid põhjustavad SQLSTATE-i 23505. Kontrollid on failis `sql/tests/10_indexes.sql`.

## Klassifikaatori nimetuse domeen

`sql/00_domains.sql` loob domeeni `klassifikaatori_nimetus` tüübiga `varchar(100)`. Domeen sisaldab NOT NULL-i ja sisuka teksti CHECK-kitsendust. Seda kasutavad kõigi 15 klassifikaatoritabeli `nimetus` veerud, mis ei ole välisvõtmed. Veergudel neid reegleid ei korrata. Kauba nimetus on eraldi `varchar(255)` ning sellel on lisaks miinimumpikkuse reegel, mistõttu see ei kasuta sama domeeni. Joonistel näidatakse domeeni nime, baastüüpi ja sellest tulenevat kohustuslikkust. Domeeni täielik deklaratsioon on dokumendi jaotises 4.3.

## Lisamata andmebaasiobjektid

- Võimalik osaline unikaalne indeks `kaup.nimetus` mitte-lõpetatud ridadele sõltub seisundite sidumisest; seda ei saa määrata juhusliku surrogaat-ID kaudu.
- Võimalik `citext` ei ole vajalik, sest e-posti tõstutundetust jõustab avaldisindeks.

---

## Ambiguities left open

1. **`kauba.nimetus` unikaalsus** — allikas: unikaalne ootel+aktiivne+mitteaktiivne ühendis (lõpetatud võib korduda). Ü2-s ainult tavaline veerg; osaline UK/indeks Ü3.
2. **`ekraani_resolutsioon.kood` vs horisontaalne×vertikaalne** — mõlemad allikas; hoiame mõlemat (kood OP jaoks, mõõtmed UK jaoks).
3. **Initial goods state assignment** — New goods must be inserted with `kauba_seisundi_liik_id` referencing the Ootel classifier (expected seed code 1). Application/routine queries the classifier by `kood=1`; no DEFAULT on the FK column (avoids brittle assumption that generated ID 1 always equals state code 1). Assignment implemented in Ü3+ application routines.
4. **Klientide register** — kaasas UC1 jaoks; kui registreeritud töökoht on rangelt ainult haldur, võib `klient` hiljem dokumendis “konteksttabeliks” märkida, ilma et seda eemaldaksime auth-teelt.
5. **Pärimine** — `nutitelefon`/`tootaja`/`klient`/`kasutajakonto` on **FK 1:1**, mitte PostgreSQL `INHERITS` (selgem DBeaveri diagrammidel; näidisprojekti INHERITS on valikuline muster).

---

## Kohalik kontroll

Laadi SQL uude tühja kohalikku PostgreSQLi andmebaasi ning käivita `sql/tests/04_tables.sql` tagasirullitavas transaktsioonis. Jooniste taastamiseks kasuta sama andmebaasi ja `scripts/render_u2_er_diagrams.py` skripti. Testimiseks loodud andmebaas eemaldatakse pärast kontrolli. Olemasolevad varasemad andmebaasid ei ole selle kontrolli osa.

## Kaupade halduri lugemisvaated

`sql/05_views.sql` loob neli kommenteeritud ja security_barrier kaitsega vaadet: `v_kaup_muutmiseks` ootel või mitteaktiivsete kaupade nimekirja jaoks, `v_kaubad` kõigi kaupade nimekirja jaoks, `v_kauba_kategooriad` kauba kategooriate ja tüüpide kuvamiseks ning `v_kauba_variandid` värvivariantide kuvamiseks. Kõik ühendused kasutavad USING-süntaksit. Vaated on ainult lugemiseks: INSERT, UPDATE ja DELETE reeglid ei muuda baastabeleid. Need reeglid ei teosta äriloogikat ega asenda ärireeglite trigereid.

## Õigused ja objektide kustutamine

`sql/16_rights.sql` loob sisselogimisõiguseta rolli `epood_rakendus`, millel on ühendusõigus jooksvale andmebaasile, public-skeemi kasutusõigus ja nelja lugemisvaate SELECT. Baastabelite, arvujadade, muutmise, objektide loomise ega õiguste edasijagamise õigust rollil ei ole. PUBLIC-i liigsed õigused eemaldatakse. See on õiguste koondamise roll; tegelik rakenduse sisselogimiskasutaja ja autentimise teostus vajavad eraldi seadistust.

`sql/19_drop_objects.sql` eemaldab realiseeritud projektiobjektid. Õigused võetakse enne ära; domeeni kustutamise CASCADE eemaldab sellest sõltuvad veerud ja vaated; seejärel kustutatakse ülejäänud tabelid ning roll. Tabelitega kustuvad nende identiteedijadad ja indeksid, vaadetega nende reeglid. Avalik skeem on andmebaasi vaikimisi skeem ning seda ei kustutata. Tegeliku projektiandmebaasi kustutamislauset ei määrata enne selle nime kinnitamist.

## Statistika ja täitmisplaan

`sql/14_statistics.sql` kogub kõigi 24 baastabeli statistika ning tuleb käivitada pärast andmete laadimist. `sql/15_explain.sql` koostab vaate `v_kaubad` päringu JSON-vormingus täitmisplaani koos tegeliku täitmise ja puhvrite andmetega. Vaade ühendab kauba, brändi ja seisundiliigi. Tühja kohaliku andmebaasi plaan kontrollib lausete käivitatavust; see ei kirjelda andmetega kooliserveri jõudlust. Dokumendi lõplik plaanipilt ja konkreetse plaani selgitus tuleb koostada tegeliku serveri ja projektiandmete põhjal.
