# ITI0207 Andmebaasid II — nutitelefonide e-poe kaupade allsüsteem

**Ametlik teema (Maurus vorm 1123):** Nutitelefonide e-poe infosüsteemi kaupade funktsionaalne allsüsteem  
**Töökoht:** kaupade halduri töökoht (lugemine + muutmine: lisamine, uuendamine, kustutamine)  
**DBMS / rakendus (registreeritud):** PostgreSQL + pgApex  
**Postgres:** `apex2.taltech.ee:5432`, konto `t253787`  
**Lähteprojekt:** `epood-lahteprojekt/E_poe_kaupade_arvestus/` (`Dokument.docx`, `Diagrammid.eap`, `Prototüüp.mdb`)  
**Repo:** `tamkivi/andmebaasid-projekt` — AB I jõusaal ja AB II e-pood eraldi (PR #2)

See juhend ühendab (1) sinu teema, (2) Erki kataloogi lähteprojekti ja (3) Maurus 391 tegevuskava ülesanded 2–12.

---

## 1. Mida sa tegelikult ehitad

Kogu e-poodi sa **ei** ehita. Sa võtad **kaupade funktsionaalse allsüsteemi** (paks jagatud SQL + üks töökoht) ja teed sellest Andmebaasid II iseseisva töö:

1. **Andmebaas** õppeserveris — tabelid, kitsendused, vaated, rutiinid, trigerid/reeglid, õigused, testandmed.
2. **Dokument** — lähteprojekti laiendus AB II peatükkidega (füüsiline disain, PostgreSQL realisatsioon, rakendus, TI kasutus), vormistus lõputöö juhendi järgi.
3. **Rakendus** — **kaupade halduri** töökoht pgApexis, mis räägib andmebaasiga peamiselt **vaadete ja rutiinide** kaudu.

Põhiobjekt: **Kaup** (nutitelefoni artikkel), koos variantide, kategooriate ja klassifikaatoritega.

Oluline: Maurus ütleb, et sa **ei jätka** AB I jõusaali projekti. Teema on e-pood. Jõusaali repo on ainult koodihalduse konteiner / protsessi mall.

---

## 2. Domeen (lähteprojektist)

**Organisatsioon:** nutitelefonide e-pood (osta partneritelt → müü klientidele).

**Sinu allsüsteem:** kaupade haldus. Teised registrid (kliendid, tellimused, arved, …) on kontekst; realiseerid peamiselt **kaupade registri** + selleks vajalikud isiku/töötaja/klassifikaatori osad.

### Kauba elutsükkel

| Seisund | Tähendus | Tüüpilised tegevused |
|---|---|---|
| **Ootel** | just registreeritud, müügis pole | Unusta (kustuta), Muuda, Aktiveeri |
| **Aktiivne** | müügiks / kasutuses | Muuda mitteaktiivseks, Lõpeta (juhataja), Vaata |
| **Mitteaktiivne** | ajutiselt peidus | Muuda, Aktiveeri uuesti, Lõpeta |
| **Lõpetatud** | lõplikult kasutusest väljas | peamiselt vaatamine / aruanded |

- **Unusta** = DELETE, **ainult ootel** kaubale.  
- **Lõpeta** = seisundi muutus (juhataja), mitte kustutamine.  
- Seisundi muutmine **ei** käi “Muuda kaupa” kasutusjuhu all — selleks on eraldi juhud.

### Kasutusjuhud (halduri / juhataja töökoht)

| # | Kasutusjuht | Peamine tegutseja | Lühidalt |
|---|---|---|---|
| 1 | Tuvasta kasutaja | haldur / juhataja / klient / kliendihaldur | login + roll + seisund |
| 2 | Registreeri nutitelefon | Kauba haldur | uus kaup (+ variant/kategooriad) → **ootel** |
| 3 | Unusta kaup | Kauba haldur | kustuta **ootel** kaup |
| 4 | Muuda kaupa | Kauba haldur | ootel/mitteaktiivne; **mitte** registreerija/aeg; **mitte** seisund; kategooriad OK |
| 5 | Aktiveeri kaup | Kauba haldur | ootel või mitteaktiivne → aktiivne |
| 6 | Muuda kaup mitteaktiivseks | Kauba haldur | aktiivne → mitteaktiivne |
| 7 | Vaata ootel või mitteaktiivseid | Kauba haldur | nimekiri + sort/filter |
| 8 | Vaata kõiki kaupu | Haldur, Juhataja | nimekiri + detailid |
| 9 | Lõpeta kaup | **Juhataja** | aktiivne/mitteaktiivne → lõpetatud |
| 10 | Vaata kaupade koondaruannet | Juhataja | loendurid seisundi kaupa (0 kui tühi) |
| 11 | Vaata aktiivseid kaupu | kliendihaldur / klient / uudistaja | kategooria järgi; ilma registreerimis-metata |

### Olulisemad olemitüübid

**Kaupade register:** Kaup, Nutitelefon, Kauba_variant, Kauba_kategooria_omamine  
**Klassifikaatorid:** Bränd, Diagonaal, Ekraani_resolutsioon, Kaamera, Protsessor, Sisemälu, Värv, Kauba_kategooria (+ tüüp), Kauba_seisundi_liik, Riik, …  
**Isikud:** Isik, Kasutajakonto, Töötaja, Klient (+ seisundiliigid) — autentimine ja “kes registreeris”.

Lähteprojekti füüsiline disain on **MS Access** prototüübi peal; AB II-s teed selle **PostgreSQL**-iks ümber.

---

## 3. Nädalate kaupa (Maurus 391 → ülesanded 2–12)

| Nädal | Ülesanne | Mida teed e-poe teemaga |
|---|---|---|
| 1–4 | ettevalmistus | VPN, serverikonto, EA ~nädal 5; loe lähteprojekti + näidisprojekti ptk 3–4 struktuuri |
| **5** | **Ü2** | EA: füüsilise disaini mudel PostgreSQL-i jaoks; baastabelid; **ilma** CHECK/indeksiteta alguses; puhtad nimed |
| **6** | **Ü3** | Lisa **CHECK** + **indeksid** |
| **7** | Ü2+Ü3 lõpetus | Baastabelite mudel valmis |
| **8** | **Ü4** | Genereeri `CREATE TABLE` (+ DDL), silu, käivita `apex2` peal |
| **9** | **Ü5** | Testandmed; **Riik, Isik, Kasutajakonto** välisest allikast |
| **10** | **Ü6** | Vähemalt üks PostgreSQL **domeen**, refaktoreeri |
| **11** | **Ü7** | Avalik liides: **vaated** |
| **12** | **Ü8** | Avalik liides: **rutiinid** kasutusjuhtude jaoks |
| **13** | **Ü9** | Trigerid / PostgreSQL rules (seisundireeglid) |
| **14** | **Ü10** | Rakendus: alusta **kasutaja tuvastamisest** |
| **15** | **Ü11** | Jätka halduri ekraane; DML võimalused |
| **16** | **Ü12** | Statistika, EXPLAIN, dokumendi viimistlus, õigused, **esita** |

Paralleelselt: UML/SQL harjutused, vahetestid, tööaja logi.

---

## 4. Kuidas alustada praegu

1. **Hoia domeenid repos eraldi** (PR #2): AB I jõusaal oma kaustas, AB II e-pood oma kaustas. Ära sega jõusaali SQL-i e-poe esitusse.
2. **Ava lähteprojekt** — `Dokument.docx` (nõuded), `Diagrammid.eap` (EA), `Prototüüp.mdb` (referents).
3. **EA (~nädal 5)** — koopia, DBMS = PostgreSQL, puhtad nimed, A4 portrait diagrammid.
4. **Server** — `apex2.taltech.ee:5432` / `t253787`; VPN; paroole mitte markdowni.
5. **pgApex (hiljem)** — login, ootel nimekiri, registreeri/muuda, aktiveeri/mitteaktiivseks, juhataja lõpeta + koondaruanne; kirjutused → rutiinid, nimekirjad → vaated.
6. **Dokument** — lähteprojekti struktuur + AB II peatükid (nagu vastuvõtuaegade näidis); sissejuhatuse tabel (DBMS, server, db, töökoht, pgApex URL, testlogin, millised lehed → rutiinid/vaated).

---

## 5. Valmisoleku kontrollnimekiri

- [ ] Füüsilise disaini diagrammid EA-s (PostgreSQL), loetavad dokumendis  
- [ ] DDL õppeserveris; PK/UK/FK/CHECK + indeksid  
- [ ] ≥1 domeen; välislaadimine Riik/Isik/Kasutajakonto  
- [ ] Vaated + rutiinid katavad kasutusjuhud 1–11 (rollidega)  
- [ ] Trigerid/reeglid (nt unusta ainult ootel)  
- [ ] Minimaalsed õigused rakenduse DB-kasutajale  
- [ ] pgApex halduri (+ juhataja) ekraanid  
- [ ] Dokument + TI-kasutus + vormistus  
- [ ] Esitus Mauruses (nädal 16)

---

## 6. Lõksud

- Ära jätka jõusaali domeeni — teema on e-pood.  
- Ära ehita kogu e-poodi — ainult kaupade allsüsteem + halduri töökoht.  
- Seisundimuutused on eraldi kasutusjuhud.  
- Lõpetamine ja koondaruanne on juhataja omad.  
- Access MDB = lähte, mitte sihtmärk.  
- Moodle on kest; **Maurus 391** on tööjärjekord.

## 7. Failid

- Lähte: `school/courses/iti0207/epood-lahteprojekt/`  
- Ü2: `Ylesanne_ITI0207_2_2025.txt`  
- Näidis: `Naidisprojekt_ITI0207_vastuvotuajad_ver10_27.txt`  
- Tegevuskava: Maurus 391 / `tegevuskava.txt`  
- COURSE: `COURSE.md`
