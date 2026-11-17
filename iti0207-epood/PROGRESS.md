# ITI0207 e-poe — progress

## Seis 17.11.2026: Ü10 tuvastamine kohalikult kontrollitud

Kaupade halduri töökoha jaoks lisandus kommenteeritud PL/pgSQL-funktsioon
`f_on_kaubahaldur`. See kontrollib tõstutundetut meiliaadressi, tõstutundlikku
parooli, konto aktiivsust, elus isikut, töötaja lubatud seisundit ning aktiivse
kaubahalduri rolli kehtivust. Sobimatu konto korral arvutatakse räsi sama
kuluteguriga näidisräsi abil. Ü8 rutiinide ja Ü9 trigerite käitumine säilis.
Varasema avatekstilise parooli uuendus jätab olemasolevad bcrypt-räsid puutumata.

Täielik SQL-komplekt läbis kontrolli kohalikes PostgreSQL 17.12 ja 18.6
andmebaasides värske paigalduse, Ü9 uuenduse ja uuesti ehitamise järel.
Kontrolliti õigusi, avateksti uuendust ja korduskäivitust, eemaldamist ning
null projektiobjekti. PostgreSQL 17-s läbisid kontrolli üheksa kahe seansi
katset ning kaks koormustesti; tõrkeid ja ummikseise oli null. Eraldi
konteinerid koos nende andmefailidega on eemaldatud.

[Ü10 tehniline lisa](docs/u10-tuvastamine.md) kirjeldab pääsureeglit, kontrolle
ja paigaldamist. Kooliserver, tegelikud kontod ning pgApexi autentimine ja
seansi kasutaja sidumine toimingutega jäävad üle kontrollida. Wordi dokumenti
ei muudetud; Ü10 tekst tuleb sinna hiljem lisada ja sisukord uuendada.
Töö on esitamata.

## Seis 16.11.2026: Ü9 trigerid kohalikult kontrollitud

Ü9 juhendi versiooni 3 järgi lisandusid 20 trigerit ja 10 kommenteeritud
PL/pgSQL-trigerifunktsiooni. Need kontrollivad kauba loomist, seisundiüleminekuid,
aktiveerimise kategoorianõuet, kustutamist, põhi- ja lisaandmete muudetavust,
registreerimisandmete säilimist ning uue seisundiliigi aktiivsust. Lisaks määravad
trigerid viimase muutmise aja ja keelavad TRUNCATE-i. Sama seisundi ja muutmata
andmete tagasikirjutamine on lubatud. OP3–OP5 korduskutsed juba sihtseisundis
kaubale annavad NULL-i ega muuda auditandmeid. Aktiveerimistriger lukustab leitud
kategooriaseose `FOR SHARE` abil. Isiku ajatriger käivitub ainult rea tegelikul
muutumisel; muudetavuse viga nimetab tegelikult muudetud veeru. Rutiinidest
eemaldati korduvad kontrollid.

Täielik SQL-komplekt, Ü8 paigalduse uuendus, domeenimigratsioon, eemaldamine,
null projektiobjekti kontroll ja uuesti ehitamine läbisid kontrolli eraldi kohalikes
PostgreSQL 17.12 ja 18.6 andmebaasides. Mõlemas versioonis läbisid kontrolli
üheksa kahe seansi katset ning kaks 30-sekundilist koormustesti; tõrkeid ja
ummikseise oli null. Otsese SQL-i katses leitud vana seisundi lugemine parandati:
lisaandmete triger lukustab kaubarea enne klassifikaatorikoodi lugemist.
Testikonteinerid koos oma andmefailidega on eemaldatud.

[Ü9 tehniline lisa](docs/u9-trigerid.md) kirjeldab reegleid, vigu, paigaldust ja
piire. Wordi dokumenti ei muudetud; Ü9 sisu ja muudetud SQL-loendid tuleb sinna
hiljem üle kanda ning sisukord värskendada. Kooliserver, tegelik JSON-allikas,
pgApexi veakuvamine ja kasutajatuvastus on kontrollimata. Töö on esitamata.

## Varasem seis 16.11.2026: Ü8 rutiinid ja dokument üle kontrollitud

Ühine töötajakontroll kaitseb nüüd ka rolli omamise ning kontrollitavate seisundi-
ja rolliklassifikaatorite ridu `FOR SHARE` lukuga. Kahe seansi katsed kinnitasid
lukuootuse mõlemas järjekorras. Kui rolli lõpetamine kinnitati esimesena,
tagastas abifunktsioon pärast lukuootust tühja hulga.
Täielik paigaldus, testid, S1–S5, kaks koormustesti, eemaldamine ja uuesti
ehitamine läbisid kontrolli eraldi PostgreSQL 17.10 klastris. Tõrkeid ei tekkinud.

Wordi lepingud, eestikeelsed selgitused ning rutiinide, indeksite ja andmete
laadimise SQL-loendid on ajakohastatud. Dokumendi renderdamine ja parandatud
lehekülgede visuaalne kontroll on tehtud. Sisukorra leheküljenumbrid vajavad
värskendamist. Kooliserver ja pgApex on endiselt kontrollimata; töö on esitamata.

## Historical status — 14.11.2026: Ü8 rutiinid ja samaaegsus kohalikult kontrollitud

Ü8 kümme lepingulist funktsiooni ja ühine töötajakontroll olid juba olemas.
OP6 telefoni olemasolu kontroll kasutab nüüd `FOR NO KEY UPDATE` lukku, mis
kõrvaldas eraldatud koormuskatses varasema jagatud luku tugevdamise ummikseisu.
Lisandusid kõigi funktsioonide loetavad nimeliste argumentidega näited, vana `xmin`-i
katse, kahe seansi SQL-failid ja samaaegsuse kontrolli käivitaja.
[Ü8 tehniline lisa](docs/u8-rutiinid.md) kirjeldab lepinguid, eeltingimusi ja lukke.

Täielik paigaldus, integreeritud testid koos näidetega, S1–S5 mõlema vajaliku
järjekorraga, kaks koormustesti, eemaldamine, null projektiobjekti kontroll ja
uuesti ehitamine läbisid kontrolli eraldi PostgreSQL 17.10 klastris kohaliku
JSON-näidisallikaga. Parandatud OP6 ja segakoormuse eraldi katsetes oli tõrkeid null.
See ei välista kõiki võimalikke ummikseise; tehingu kordamise vajadus on lisas kirjas.

Wordi dokument sisaldab Ü6, Ü7 ja Ü8 sisu ning ajakohaseid lepinguid ja SQL-loendeid.
Dokumendi struktuur, puutumata osade säilimine ja SQL-i vastavus on kontrollitud;
lehekülgede paigutust ei renderdatud. Varukoopiad on säilitatud.
Kooliserveri paigaldus, tegelik JSON-allikas, olemasoleva paigalduse vanade allkirjade
uuendus, pgApex, kasutajatuvastus, seisundimuudatuste trigerid ja esitamine jäävad
kontrollimata. Kohalik kontroll ei tähenda kooliserveri paigaldust ega esitamist.

## Historical status — 10.11.2026: Ü7 lugemisliides kohalikult kontrollitud

Ü5 laadimine, Ü6 domeen ja ühendatud rutiinide/õiguste muudatused on säilinud.
Ü7 jaoks on 12 kommenteeritud turvabarjääriga lugemisvaadet ning 36 vaadete kaudu
muutmist blokeerivat reeglit. Lisandusid kaupade detailid, seisundite koondaruanne,
aktiivsete kaupade kataloog, kaks vajalikku valikut ning kategooriate loendi,
pingerea ja JSON-esituse vaated. Kõik vaated on pgApexi jaoks järjestatud;
ajatempleid näidatakse Eesti ajas nõutud vormingus. `xmin` on endiselt tüüpi `xid`.
Lugemisoperatsioonide vastavus ja täielik SQL on [Ü7 tehnilises lisas](docs/u7-vaated.md).

Eraldatud PostgreSQL 17.10 klastris läbisid kõik 11 integreeritud SQL-testikomplekti,
Ü5 korduvlaadimine ja eraldi Ü6 migratsioonikomplekt kohaliku JSON-näidisallikaga.
Vaateid kontrolliti ka pärast korduvlaadimist ning muutmiskatsed säilitasid kõigi
24 baastabeli sisu. Eemaldamine, null projektiobjekti kontroll, uuesti ehitamine ja
samad integreeritud testid läbisid kontrolli. Kõik 12 vaadet tagastasid ridu.

`sql/01_tables_draft.sql` sisaldab 24 tabelit, 116 veergu ja 26 välisvõtit, sealhulgas
`mentor_id` eneseviidet. Domeen `d_klassifikaatori_nimetus` koondab 15 klassifikaatori
nimetuse ühised omadused; migratsiooni piirangud on [Ü6 lisas](docs/u6-domeenid.md).
Wordi dokumenti ei muudetud: Ü6 ja Ü7 lisade ülekanne ning sisukorra ajakohastamine
on veel tegemata. Töötajate skeemijoonis, peatüki 5 nõutud lisad ning varasemate
rutiiniallkirjade uuendus jäävad eraldi tööks. `reg_aeg` esitusmuutus vajaks olemasolevas
paigalduses eraldi vaateuuendust. Kooliserveri PostgreSQL 18, tegelik JSON-allikas,
üliõpilase õigused, ärireeglite trigerid, kasutajatuvastamine, pgApexi rakendus ja
esitamine on endiselt kontrollimata. Ü7 kohaliku kontrolli põhjal ei saa nende valmimist kinnitada.

**Tool choice:** PostgreSQL + DBeaver / Graphviz path

## Historical status — 23.09 preparation for Week 5 / Ü2

| Item | State |
|---|---|
| Route | **Ü2 2026 §2.1 path 4** — SQL draft + local Postgres reverse engineering / Graphviz register diagrams (DBeaver-compatible DB) |
| Design notes | `docs/u2-physical-design.md`, `docs/u2-audit-2026-09-23.md`, `docs/u2-brief-gap-2026-09-23.md` |
| SQL draft | `sql/01_tables_draft.sql` — **loads cleanly** into a separate local DB; **not** applied to `apex2` |
| Presentation DB | `iti0207_epood_u2_audit_20260923` on Homebrew PostgreSQL 17 (`localhost:5432`, user `gustav`; local TCP verified) |
| Previous DB | `iti0207_epood_u2` remains from 21 Sep and does not reflect the explicit FK-action update |
| Diagrams | 11 PNG/PDF/DOT sets under `docs/diagrams/`, covering 5 registers; each of 24 tables detailed exactly once |
| Chapter 3 | `docs/lahteprojekt/Dokument.docx` — assembled and rendered; Estonian prose plus figures 11–21, with backup `Dokument_backup_2026-09-23.docx` |
| Handoff | `docs/u2-chapter3-docx-qa-2026-09-23.md` and `docs/u2-practical-talk-2026-09-25.md` — document checks and Friday presentation |
| Excluded (Ü2) | CHECK, indexes → **Ü3**; school-server DDL → **Ü4** |
| Domain firewall | No jõusaal content in e-pood |

### Done this slice (23 Sep)
- Loaded the revised SQL atomically into a clean separate local PostgreSQL database: **24 tables, 115 columns, 24 PK, 37 UK, 25 FK, 0 CHECK**.
- Made all 25 FK delete/update actions explicit, including CASCADE for the three person subtype tables.
- Rebuilt 11 register diagrams with exact data types/lengths, nullability, defaults and named keys. All PDF content bounds fit portrait A4 at 100%; all pages were visually checked.
- Read the full 2026 Ü2 brief text and `Dokument.txt`; checked all 24 concrete source entity types and OP1–OP10 against SQL. No missing Ü2 base table or FK was found, so SQL and diagrams needed no further change.
- Extracted EA names from `.eap` with `strings`. `Kauba_mudel` and a recursive employee FK appear there but are not required by the textual entity/OP contracts; the EA GUI and full visual model remain unverified.
- Wrote the full brief/conceptual gap checklist and Estonian chapter-3 draft. Assembled it into `Dokument.docx`, replaced the old Access figures, rendered the 84-page file, checked chapter 3 on pages 63–74, and updated the affected contents entries and source entry. The original DOCX is backed up.

### DBeaver and chapter 3
Use the presentation DB above. The finished chapter and PNGs are in `docs/lahteprojekt/Dokument.docx`; diagram order and database details remain in `docs/u2-chapter3-handoff.md`. The final document check is in `docs/u2-chapter3-docx-qa-2026-09-23.md`.

### Next
1. **Human next:** bring the DOCX and DBeaver to the 25 Sep practical in ICT-403 (15:45–17:15); use `docs/u2-practical-talk-2026-09-25.md` and ask about the EA-only `Kauba_mudel`/employee self-FK and source CRUD `Amet`.
2. **Next steps only when requested:** Ü3 CHECK constraints and indexes. **Ü4** school-server DDL remains later. The whole-document source/heading sweep and unfilled later template chapters remain separate from this Ü2 chapter assembly.

The workload Excel has its own interim human upload deadline of 27 Sep; it was not edited or submitted here.

### Regenerate diagrams
```bash
ITI0207_U2_DB=iti0207_epood_u2_audit_20260923 python3 iti0207-epood/scripts/render_u2_er_diagrams.py
```
