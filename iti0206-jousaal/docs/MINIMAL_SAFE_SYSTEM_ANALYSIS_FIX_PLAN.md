# Minimal Safe System-Analysis Fix Plan

> Historical note: this plan records the safe repair sequence used before the
> final submission audit. The current readiness result is maintained in
> `docs/FINAL_SUBMISSION_VERIFICATION_AUDIT.md`.

## 1. Executive summary

The highest-priority safe repairs are structural: the document must add `Klassifikaator` as a põhiobjekt, align `Klassifikaatorite haldur`, split combined subsystem/register names, and make the põhiobjekt -> funktsionaalne allsüsteem -> register mapping one-to-one. These fixes are low-to-medium risk because `docs/RULE_SOURCE_TRACE_AUDIT.md` classifies the supporting rules as `Explicit` and cites `instruction_guides/Yldvaade.txt` and the official pattern guide.

The next safe repairs are consistency and format repairs that do not require changing the domain scope: make high-level use-case table labels match the required use-case structure, add OP references to system steps that read or change data, specify list/report fields, replace the attribute definition table with the required definition format, formalize data-changing operation contracts, and transpose the CRUD matrix so olemitüübid are rows and kasutusjuhud are columns.

Postpone disputed or high-blast-radius changes until professor/TA clarification: prohibiting read-only OP contracts, enforcing exactly two steps for report use cases, adding `Pank`/`Maksekeskus` when payments are out of scope, treating exact high-level <-> extended use-case 1:1 matching as a blocker, and treating every diagram-to-text mismatch as a blocker rather than a warning.

## 2. Fix priority order

### Priority 1 - Structural naming and mapping fixes

#### 1.1 Add `Klassifikaator` to põhiobjektid

- Current problem: `submission_files/dokument.docx`, section `1.1.4 Põhiobjektid`, `Tabel 2` lists `Registreering`, `Treeningukord`, `Treeninguliik`, `Isik`, `Töötaja`, `Klient`, `Treener`, but not `Klassifikaator`.
- Proposed change: add a row:
  - `Klassifikaator` - `Süsteemis kasutatav väärtuste kogum, mille liikmetega kirjeldatakse olemi seisundeid, rolle, riike ja muid kontrollitud väärtusi.`
- Source-trace classification: `Explicit`.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, special check `4.1 Klassifikaator as required põhiobjekt`, and rule entry `Reegel: Põhiobjekt "Klassifikaator"`, citing `instruction_guides/Yldvaade.txt`.
- Risk level: low.

#### 1.2 Add required haldur actors for supported põhiobjektid

- Current problem: `submission_files/dokument.docx`, section `1.1.6 Tegutsejad`, `Tabel 6` lists `Juhataja`, `Treener`, `Klient`, `Süsteem`, `Aeg`. It does not list `Klassifikaatorite haldur`. Because `Töötaja` is also a põhiobjekt, it also does not list one of `Töötajate haldur`, `Personalihaldur`, or `Personalitöötaja`.
- Proposed change:
  - Add `Klassifikaatorite haldur` with responsibility `klassifikaatorite väärtuste lisamine, muutmine ja kasutuselt eemaldamine`.
  - Add `Töötajate haldur` with responsibility `töötajate andmete ja töötajaga seotud rolli omamiste haldamine`.
- Source-trace classification: `Explicit`.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, entries `Põhiobjekt Klassifikaator => Klassifikaatorite haldur` and `Põhiobjekt Töötaja => Töötajate haldur`, plus special check `4.1`.
- Risk level: medium, because adding actors affects pädevusalad, use-case diagrams, and CRUD labels.

#### 1.3 Split combined subsystem/register names in `Tabel 9`

- Current problem: `submission_files/dokument.docx`, section `1.1.8 Terviksüsteemi tükeldus`, `Tabel 9` contains combined or nonconforming names:
  - `Isikute ja rollide administratiivne allsüsteem`
  - `Isikute, töötajate ja klientide register`
  - `Klassifikaatorite administratiivne allsüsteem`
  - `Seisundite, rollide ja riikide väärtusloendid`
- Proposed corrected rows:
  - `Isikute funktsionaalne allsüsteem` / `Isikute register`
  - `Töötajate funktsionaalne allsüsteem` / `Töötajate register`
  - `Klientide funktsionaalne allsüsteem` / `Klientide register`
  - `Treenerite funktsionaalne allsüsteem` / `Treenerite register` (keep current row if already present)
  - `Klassifikaatorite funktsionaalne allsüsteem` / `Klassifikaatorite register`
- Source-trace classification: `Explicit`.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, entries `Nimetuste kontseptsioonid`, `Allsüsteem <=> Register 1:1 nimega`, `Põhiobjekt <=> Allsüsteem/Register seos`, `Allsüsteemi nime vorming`, `Registri nime vorming`, and special check `4.2`.
- Risk level: medium, because the same names recur in sketches, diagrams, CRUD, and text.

#### 1.4 Align all register references with the corrected register list

- Current problem: `submission_files/dokument.docx`, section `1.2.2 Seosed pädevusalade ja registritega`, `Tabel 10` uses combined register names:
  - `Treeningukordade ja registreeringute register`
  - `Treenerite, treeningukordade ja osalemiste register`
  - `Isikute ja kasutajakontode register`
  - `Töötajate rollide register`
- Proposed change: replace combined names with semicolon-separated corrected register names from `Tabel 9`, for example:
  - `Registreeringute register; Treeningukordade register; Treeninguliikide register`
  - `Treenerite register; Treeningukordade register; Osalemiste register`
  - `Isikute register; Töötajate register; Klientide register`
  - `Klassifikaatorite register`
- Source-trace classification: `Explicit`.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, entries for register name existence/form consistency and `Nimetuste kontseptsioonid`.
- Risk level: medium.

#### 1.5 Rename `1.3 Treeningukordade ja registreeringute registri eskiismudelid`

- Current problem: section `1.3` combines two register concepts in one register-style heading.
- Proposed change: either:
  - split into `1.3 Treeningukordade registri eskiismudelid` and `1.4 Registreeringute registri eskiismudelid`, or
  - if only one central sketch remains, rename to `1.3 Registreeringute registri eskiismudelid`.
- Source-trace classification: `Explicit`.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, entries `Nimetuste kontseptsioonid`, `Registri nime vorming`, and `Allsüsteemi ja registri nimede vastavus`.
- Risk level: medium.

### Priority 2 - Use case consistency fixes

#### 2.1 High-level use-case table structure

- Current problem: `submission_files/dokument.docx`, `Tabel 11 Peamised kasutusjuhud` uses columns `Kasutusjuht`, `Tegutseja`, `Sisu`; the source-supported structure uses `Kasutusjuht`, `Tegutsejad`, `Kirjeldus`.
- Before:
  - `Tegutseja`
  - `Sisu`
- After:
  - `Tegutsejad`
  - `Kirjeldus`
- Source-trace classification: `Explicit`.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, summary table entry `High-level UC structure/naming/specificity`, citing the short use-case guide.
- Risk level: low.

#### 2.2 Normalize actor spelling in high-level use cases

- Current problem: `Tabel 11`, row `Edenda ootel registreering`, uses `Süsteem`; rows for automatic/time-triggered activity should use `Aeg` only when the process is time-triggered. If this use case remains event-triggered by cancellation, it should not be modeled as a separate primary actor use case with `Süsteem`.
- Proposed minimal change:
  - Treat `Edenda ootel registreering` as a system step inside `Tühista enda registreering` unless a separate event-triggered use case is intentionally kept.
  - If kept as a separate use case, define its trigger and actor consistently; do not use `Süsteem` as a human actor substitute.
- Source-trace classification: `Explicit` for actor consistency and primary actor rules; exact separate use-case requirement is not mandatory here.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, entries for high-level actor existence/consistency and extended primary actor matching.
- Risk level: medium.

#### 2.3 Add OP references to data-reading system steps without forcing read contracts

- Current problem: extended use-case system steps read data but lack OP references. Do not create full read-only operation contracts until professor/TA confirms whether read-only contracts are required or prohibited.
- Proposed change: add read OP references in scenario text and maintain a small "lugemisoperatsioonide viited" list outside the data-changing operation-contract section.
- Source-trace classification: `Explicit` for OP references in system data steps; `Contradicted / questionable` for banning read-only contracts.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, section `4.4 OP references in extended use cases`.
- Risk level: medium.

Recommended read OP labels:

| OP | Purpose |
| --- | --- |
| `OP10` | Loe planeerimiseks aktiivsed treeninguliigid, ruumid ja treenerid. |
| `OP11` | Loe juhatajale treeningukordade haldamise ülevaade. |
| `OP12` | Loe kliendile avalikud ja vabade kohtadega treeningukorrad. |
| `OP13` | Loe kliendi enda registreeringud. |
| `OP14` | Loe treeneri juhendatavad treeningukorrad. |
| `OP15` | Loe treeningukorra registreeringud ja osalejad. |
| `OP16` | Loe täituvuse statistika. |

Use-case before/after plan:

| Use case | Current issue | Minimal after-plan |
| --- | --- | --- |
| `Planeeri treeningukord` | Step 2 reads active treeninguliigid, ruumid, treenerid without OP; step 6 displays overview without OP. | Add `(OP10)` to step 2 and `(OP11)` to the overview step; specify displayed fields. |
| `Ava registreerimine` | Step 2 displays treeningukorrad without OP or displayed fields. | Add `(OP11)` and list fields: treeningukorra identifikaator, treeninguliik, algus/lõpp, ruum, treener, seisund. |
| `Esita registreering` | Step 2 displays public treeningukorrad without OP and without full unique identifying data. | Add `(OP12)` and fields: treeningukorra identifikaator, treeninguliik, algus/lõpp, ruum, treener, vabad kohad, ootejärjekorra pikkus. |
| `Vaata enda registreeringuid` | Steps 2-3 read/display data without OP and lack clear unique identifiers. | Add `(OP13)` and include registreeringu number plus treeningukorra identifying data. |
| `Tühista enda registreering` | Step 2 reads active registreeringud without OP and lacks clear unique identifiers. | Add `(OP13)` and include registreeringu number, treeningukord, seisund, tähtaeg. |
| `Märgi osalemine` | Steps 2 and 4 read treeningukorrad/osalejad without OP; participant list needs identifier beyond name. | Add `(OP14)` and `(OP15)`; display kliendi nimi plus e-post or isikukood, registreeringu number, seisund. |
| `Vaata statistikat` | Steps 2-3 read/report statistics without OP and report fields are too vague. | Add `(OP16)`; specify treeninguliik, periood, kohtade arv, kinnitatud arv, ootel arv, osales/puudus arv, täituvusprotsent. |

#### 2.4 Make list and report data specific

- Current problem: several extended use cases say "kuvab nimekirja", "kuvab ülevaate", or "kuvab statistika" without identifying the fields shown.
- Proposed change: for each displayed list/report, state the exact data fields and include a user-understandable unique identifier.
- Source-trace classification: `Explicit`.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, entry `Laiendatud nimekirja andmete spetsifikatsioon` and `Laiendatud aruande andmete spetsifikatsioon`.
- Risk level: low.

#### 2.5 Align `Märgi osalemine` primary actor and scenario

- Current problem: extended use case `Märgi osalemine` has primary actor `Treener või juhataja`, but the scenario steps describe `Treener` as the acting user.
- Proposed change: either:
  - set primary actor to `Treener` and keep `Juhataja` as stakeholder/extension, or
  - add explicit scenario/extension steps for `Juhataja`.
- Source-trace classification: `Explicit`.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, entry `Laiendatud primaarse tegutseja vastavus stsenaariumile`.
- Risk level: medium.

### Priority 3 - Attribute definition fixes

Current problem: `submission_files/dokument.docx`, section `2.2.1.3 Atribuudid`, `Tabel 20` is a grouped prose table. It does not use the required pattern `inimloetav selgitus {piirangud}` and it does not provide `Näiteväärtus:` per attribute. The table should be replaced with per-attribute rows.

Source-trace classification: `Explicit`.

Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, entries `Attribute definition format/annotations/examples`, `Attribute semantic constraints`, and special check `4.5 Attribute definition format`.

Money attributes were not found in the current document, so no money-specific fixes are needed unless money attributes are added later.

| Olemitüüp | Atribuut | Problem | Required fix | Example corrected definition |
| --- | --- | --- | --- | --- |
| Isik | e_meil | No `{}` constraints, no example, email rule missing. | Define email as required identifier; require `@`; add `@Pole_tühi`. | `Isiku e-posti aadress, mida kasutatakse süsteemis isiku tuvastamiseks. {Isiku tõstutundetu unikaalne identifikaator. @Kohustuslik. Peab sisaldama märki "@". @Pole_tühi.} Näiteväärtus: klient@jousaal.ee` |
| Isik | isikukood | Format not specified. | Specify 11 numeric characters; add example. | `Isiku Eesti isikukood. {Koosneb täpselt 11 numbrimärgist. @Kohustuslik. @Pole_tühi.} Näiteväärtus: 39504040004` |
| Isik | eesnimi | Current table uses generic `nimi`; ERD uses split names. | Align table and ERD; define text non-empty. | `Isiku eesnimi. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Mari` |
| Isik | perenimi | Current table uses generic `nimi`; ERD uses split names. | Align table and ERD; define text non-empty. | `Isiku perekonnanimi. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Tamm` |
| Isik | elukoht | Text emptiness and target meaning missing. | Define optional address text; if stored, disallow blank. | `Isiku elukoha aadress kliendihalduse jaoks. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 255 märki pikk.} Näiteväärtus: Tartu, Riia 2` |
| Isik | seisund | Constraint to classifier missing. | State allowed classifier relation/value. | `Isiku kasutusseisund süsteemis. {@Kohustuslik. Väärtus peab olema registreeritud seisundi klassifikaatori väärtus.} Näiteväärtus: Aktiivne` |
| Töötaja | tootaja_tunnus | No required format/example. | Define business identifier and non-empty constraint. | `Töötajat organisatsioonis eristav tunnus. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: T-104` |
| Töötaja | seisund | Constraint to classifier missing. | Define allowed state values. | `Töötaja töösuhte või kasutusõiguse seisund. {@Kohustuslik. Väärtus peab olema registreeritud seisundi klassifikaatori väärtus.} Näiteväärtus: Aktiivne` |
| Klient | kliendi_tunnus | No required format/example. | Define customer identifier. | `Klienti organisatsioonis eristav tunnus. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: K-2048` |
| Klient | aktiivsus | Constraint missing. | Define boolean/domain. | `Tunnus, mis näitab, kas klient saab registreeringuid esitada. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE` |
| Klient | kliendiks_saamise_aeg | Date/time range missing. | Specify allowed date/time range. | `Kuupäev ja kellaaeg, millal isik registreeriti kliendiks. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59.} Näiteväärtus: 2026-03-10 09:15` |
| Treener | treeneri_tunnus | No required format/example. | Define trainer identifier. | `Treenerit organisatsioonis eristav tunnus. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: TR-12` |
| Treener | padevuste_ulatus | Free-text target audience missing. | Define audience and non-empty if present. | `Treeneri pädevuste kirjeldus juhatajale treeningukordade planeerimiseks. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Jõutreeningud algajatele ja edasijõudnutele` |
| Töötaja rolli omamine | rolli_algus | Date range missing. | Specify date/time range. | `Kuupäev, millest alates töötaja roll kehtib. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 kuni 2100-12-31.} Näiteväärtus: 2026-01-01` |
| Töötaja rolli omamine | rolli_lopp | Date range and optionality missing. | Specify optional end date and range. | `Kuupäev, millest alates töötaja roll enam ei kehti. {Kui väärtus registreeritakse, peab see olema vahemikus 2000-01-01 kuni 2100-12-31 ja mitte varasem kui rolli_algus.} Näiteväärtus: 2026-12-31` |
| Treeningukord | algus | Date/time range missing. | Specify allowed date/time range. | `Treeningukorra alguse kuupäev ja kellaaeg. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59.} Näiteväärtus: 2026-05-12 18:00` |
| Treeningukord | lopp | Date/time range and relation to start missing. | Specify range and `lopp > algus`. | `Treeningukorra lõpu kuupäev ja kellaaeg. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59 ja hilisem kui algus.} Näiteväärtus: 2026-05-12 19:00` |
| Treeningukord | registreerimise_tahtaeg | Date/time range missing. | Specify range and relation to start. | `Viimane kuupäev ja kellaaeg, milleni klient saab treeningukorrale registreeruda. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59 ja mitte hilisem kui algus.} Näiteväärtus: 2026-05-12 17:00` |
| Treeningukord | tyhistamise_tahtaeg | Date/time range missing. | Specify range and relation to start. | `Viimane kuupäev ja kellaaeg, milleni klient saab registreeringu ise tühistada. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59 ja mitte hilisem kui algus.} Näiteväärtus: 2026-05-12 16:00` |
| Treeningukord | kohtade_piir | Quantity unit and zero/negative constraint missing. | Define unit as people/spots; require positive integer. | `Treeningukorrale lubatud klientide maksimaalne arv inimestes. {@Kohustuslik. Täisarv. Väärtus peab olema suurem kui 0.} Näiteväärtus: 12` |
| Treeningukord | seisund | Constraint to classifier missing. | Define allowed state values. | `Treeningukorra elutsükli seisund. {@Kohustuslik. Väärtus peab olema registreeritud seisundi klassifikaatori väärtus.} Näiteväärtus: Registreerimiseks avatud` |
| Registreering | esitamise_aeg | Date/time range missing. | Specify allowed date/time range. | `Kuupäev ja kellaaeg, millal klient esitas registreeringu. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59.} Näiteväärtus: 2026-05-10 13:25` |
| Registreering | seisund | Constraint to classifier missing. | Define allowed registration states. | `Registreeringu elutsükli seisund. {@Kohustuslik. Väärtus peab olema registreeritud seisundi klassifikaatori väärtus.} Näiteväärtus: Kinnitatud` |
| Registreering | tyhistamise_aeg | Date/time range missing. | Specify optional date/time range. | `Kuupäev ja kellaaeg, millal registreering tühistati. {Kui väärtus registreeritakse, peab see olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59.} Näiteväärtus: 2026-05-11 10:00` |
| Registreering | edendamise_aeg | Date/time range missing. | Specify optional date/time range. | `Kuupäev ja kellaaeg, millal ootel registreering kinnitatud registreeringuks edendati. {Kui väärtus registreeritakse, peab see olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59.} Näiteväärtus: 2026-05-11 10:01` |
| Registreering | tyhistamise_pohjus | Comment audience missing. | State audience and text constraints. | `Registreeringu tühistamise põhjendus kliendile, treenerile ja juhatajale. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Klient tühistas registreeringu enne tähtaega.` |
| Ootejärjekorra koht | jarjekorranumber | Quantity/zero constraint missing. | Define positive integer. | `Registreeringu koht treeningukorra ootejärjekorras. {@Kohustuslik. Täisarv. Väärtus peab olema suurem kui 0.} Näiteväärtus: 3` |
| Osalemine | tulemus | Constraint missing. | Define allowed values. | `Treeningukorrale registreeritud kliendi osalemise tulemus. {@Kohustuslik. Lubatud väärtused on "osales" ja "ei osalenud".} Näiteväärtus: osales` |
| Osalemine | markimise_aeg | Date/time range missing. | Specify allowed date/time range. | `Kuupäev ja kellaaeg, millal treener või juhataja märkis osalemise tulemuse. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59.} Näiteväärtus: 2026-05-12 19:05` |
| Osalemine | markus | Comment audience missing. | State audience and text constraints. | `Treeneri või juhataja sisemine märkus osalemise kohta. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Klient saabus 10 minutit hiljem.` |
| Treeninguliik | nimetus | Text non-empty missing. | Require non-empty. | `Treeninguliigi nimetus, mida kasutatakse treeningukorra kirjeldamisel. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Jõutreening algajatele` |
| Treeninguliik | sisu | Description audience missing. | State audience and text constraints. | `Treeninguliigi sisukirjeldus klientidele ja juhatajatele. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 1000 märki pikk.} Näiteväärtus: Üldkehaline jõutreening algajatele.` |
| Treeninguliik | tyypiline_kestus | Quantity unit and zero/negative constraint missing. | Define unit minutes and positive integer. | `Treeninguliigi tavapärane kestus minutites. {@Kohustuslik. Täisarv. Väärtus peab olema suurem kui 0.} Näiteväärtus: 60` |
| Treeninguliik | kasutatavus | Constraint missing. | Define boolean/domain. | `Tunnus, mis näitab, kas treeninguliiki saab uutel treeningukordadel kasutada. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE` |
| Ruum | ruumi_tunnus | Text non-empty missing. | Define unique business identifier. | `Ruumi organisatsioonis eristav tunnus. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: SAAL-1` |
| Ruum | nimetus | Text non-empty missing. | Require non-empty. | `Ruumi nimetus, mida kasutatakse treeningukorra planeerimisel. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Peasaal` |
| Ruum | asukoht | Text non-empty missing. | Require non-empty if stored. | `Ruumi asukoha kirjeldus klientidele, treeneritele ja juhatajatele. {@Kohustuslik. @Pole_tühi. Võib olla kuni 255 märki pikk.} Näiteväärtus: 1. korrus` |
| Ruum | mahutavus | Quantity unit and zero/negative constraint missing. | Define unit people and positive integer. | `Ruumi maksimaalne mahutavus inimestes. {@Kohustuslik. Täisarv. Väärtus peab olema suurem kui 0.} Näiteväärtus: 20` |
| Varustus | varustuse_tunnus | Text non-empty missing. | Define unique business identifier. | `Varustust organisatsioonis eristav tunnus. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: MAT-01` |
| Varustus | nimetus | Text non-empty missing. | Require non-empty. | `Varustuse nimetus treeningukordade planeerimiseks. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Joogamatt` |
| Varustus | aktiivsus | Constraint missing. | Define boolean/domain. | `Tunnus, mis näitab, kas varustust saab treeningukordade planeerimisel kasutada. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE` |
| Treeneri pädevus | kehtiv_alates | Date range missing. | Specify date range. | `Kuupäev, millest alates treeneri pädevus kehtib. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 kuni 2100-12-31.} Näiteväärtus: 2026-01-01` |
| Treeneri pädevus | kehtiv_kuni | Date range missing. | Specify optional date range. | `Kuupäev, milleni treeneri pädevus kehtib. {Kui väärtus registreeritakse, peab see olema vahemikus 2000-01-01 kuni 2100-12-31 ja mitte varasem kui kehtiv_alates.} Näiteväärtus: 2026-12-31` |
| Ruumi varustatus | kogus | Quantity unit and zero/negative constraint missing. | Define unit pieces and non-negative integer. | `Ruumis olemasoleva varustuse kogus tükkides. {@Kohustuslik. Täisarv. Väärtus ei tohi olla negatiivne.} Näiteväärtus: 15` |
| Ruumi varustatus | markus | Comment audience missing. | State audience and text constraints. | `Juhatajale mõeldud märkus ruumi varustatuse kohta. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Osa matte asub kõrvalruumis.` |
| Varustuse nõue | minimaalne_kogus | Quantity unit and zero/negative constraint missing. | Define unit pieces and non-negative integer. | `Treeninguliigi läbiviimiseks vajalik minimaalne varustuse kogus tükkides. {@Kohustuslik. Täisarv. Väärtus ei tohi olla negatiivne.} Näiteväärtus: 10` |
| Varustuse nõue | kohustuslikkus | Constraint missing. | Define boolean/domain. | `Tunnus, mis näitab, kas varustus on treeninguliigi jaoks kohustuslik. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE` |
| Varustuse nõue | markus | Comment audience missing. | State audience and text constraints. | `Juhatajale ja treenerile mõeldud märkus varustuse nõude kohta. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Algajate rühmas võib kasutada poole vähem raskusi.` |
| Klassifikaator | kood | Missing because `Klassifikaator` entity is missing. | Add classifier entity and code definition. | `Klassifikaatori väärtust eristav kood. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: AKTIIVNE` |
| Klassifikaator | nimetus | Missing because `Klassifikaator` entity is missing. | Add classifier display name. | `Klassifikaatori väärtuse nimetus kasutajale kuvamiseks. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Aktiivne` |
| Klassifikaator | tahendus | Missing because `Klassifikaator` entity is missing. | Add target audience and text constraints. | `Klassifikaatori väärtuse selgitus süsteemi haldajale. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Väärtus näitab, et objekt on kasutatav.` |
| Klassifikaator | aktiivsus | Missing because `Klassifikaator` entity is missing. | Define boolean/domain. | `Tunnus, mis näitab, kas klassifikaatori väärtust saab uutes kirjetes kasutada. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE` |

### Priority 4 - Operation contract fixes

Current problem: `submission_files/dokument.docx`, section `2.2.2 Andmebaasioperatsioonid`, `Tabel 21` is a compact narrative table. It does not provide operation signatures with parameters, separate `Eeltingimused`, `Järeltingimused`, and `Kasutus kasutusjuhtude poolt` blocks in the expected contract style.

Source-trace classification: `Explicit`.

Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, entries `Operation contract structure` and `Operation OP/use-case/entity/attribute consistency`.

Do this only for data-changing operations. Keep read-only OP handling in the professor/TA clarification section.

| Operation | Current problem | Required fix | Minimal target |
| --- | --- | --- | --- |
| `OP1 Planeeri treeningukord` | No signature/parameters; narrative postcondition. | Write a full contract with input parameters and postconditions assigning attributes and relationships. | Parameters should include treeninguliik, treener, ruum, algus, lõpp, tähtajad, kohtade piir, juhataja. Postconditions should register a `Treeningukord` and its relationships. |
| `OP2 Ava registreerimine` | No formal state-change contract. | Formalize state transition. | Preconditions: treeningukord exists and is planned. Postconditions: `tk.seisund := registreerimiseks avatud`; use case `Ava registreerimine`. |
| `OP3 Sulge registreerimine` | Referenced in operation table but not in extended use cases. | Keep contract only if corresponding use case remains; align use-case references. | Preconditions: treeningukord open. Postconditions: state becomes closed. |
| `OP4 Lõpeta treeningukord` | Referenced in operation table but not in extended use cases. | Keep contract only if corresponding use case remains; align use-case references. | Preconditions: treeningukord closed or held. Postconditions: state becomes completed. |
| `OP5 Esita registreering` | No formal registration contract. | Define creation of `Registreering` and optional `Ootejärjekorra koht`. | Postconditions should create confirmed registration if places exist, otherwise waiting registration with queue position. |
| `OP6 Tühista registreering` | Contract mixes client and system cancellation. | Formalize cancellation and separate automatic promotion if kept. | Postconditions: registration state becomes cancelled; cancellation time/reason set; relationships preserved or removed according to model. |
| `OP7 Edenda ootel registreering` | Automatic/event-triggered behavior unclear. | Formalize if kept as separate data-changing operation. | Preconditions: confirmed place became available and waiting registration exists. Postconditions: earliest waiting registration becomes confirmed; queue positions updated. |
| `OP8 Märgi osalemine` | Current table says create/update but lacks contract detail. | Formalize create/update of `Osalemine`. | Postconditions should register or update `Osalemine`, assign result, marking time, note, and marker relationship. |
| `OP9 Tühista treeningukord` | Current table says dependent rows cancelled but lacks precise postconditions. | Formalize state change and affected registrations. | Postconditions: treeningukord state cancelled; active related registrations cancelled; cancellation reason/time set. |

Contract-writing controls:

- Use parameter names with `p_` unless the parameter name contains `identifikaator`.
- Do not use `_id` attribute names in conceptual contracts; use `identifikaator` wording if needed.
- Use `hetke kuupäev ja kellaaeg` for current timestamp values.
- Make every precondition variable used in at least one postcondition.
- Make every postcondition source traceable to a parameter, precondition variable, constant, current timestamp, or newly created instance.
- Ensure `Kasutus kasutusjuhtude poolt` exactly matches use cases that reference the OP in the final scenario text.

### Priority 5 - CRUD matrix fixes

Current problem: `submission_files/dokument.docx`, section `2.3 CRUD maatriks`, `Tabel 24` and `Tabel 25` use use cases as rows and olemitüübid as columns. Empty cells use `-`, one cell uses `C/U`, and no clear summary column is visible in the extracted text.

Source-trace classification: `Explicit` / `Strongly implied`.

Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, entries `CRUD matrix orientation/symbols/summary` and special check `4.6 CRUD matrix orientation and symbols`.

Proposed corrected matrix structure:

```text
Olemitüüp | Vaata vabu treeningukordi | Esita registreering | Vaata enda registreeringuid | Tühista enda registreering | Edenda ootel registreering | Vaata treeningukorra registreeringuid | Märgi osalemine | Sulge registreerimine | Lõpeta treeningukord | Tühista treeningukord | Planeeri treeningukord | Ava registreerimine | Vaata täituvuse statistikat | Kokku
```

Rows must match the final entity-definition list after structural fixes. Use this row set unless the conceptual model is changed:

- `Isik`
- `Kasutajakonto`
- `Töötaja`
- `Klient`
- `Treener`
- `Töötaja rolli omamine`
- `Treeningukord`
- `Registreering`
- `Ootejärjekorra koht`
- `Osalemine`
- `Treeninguliik`
- `Ruum`
- `Varustus`
- `Treeneri pädevus`
- `Ruumi varustatus`
- `Varustuse nõue`
- `Klassifikaator`
- `Seisund`
- `Roll`
- `Riik`

Cell rules for the rewrite:

- Use only `C`, `R`, `U`, `D`, or direct combinations such as `CR`, `CU`, `RU`, `CRUD`.
- Replace `-` with an empty cell.
- Replace `C/U` with `CU`.
- Add a final `Kokku` column containing the unique operation letters used in that row.
- Ensure no entity row and no use-case column is completely empty.
- Do not fill uncertain cells speculatively; mark them for manual model review before editing the DOCX.

### Priority 6 - Diagram/text consistency fixes

These are source-supported, but diagram extraction should be visually checked before editing because `.mmd` source and rendered EAP/DOCX figures can diverge.

#### 6.1 Use-case diagram names and actors

- Historical problem: `diagrams/02_use_cases.mmd` contained legacy diagram-only use-case names that did not match `Tabel 11`.
- Current result: resolved in the generated Mermaid, EAP, and DOCX artifacts; the diagram now uses the finalized use-case names from the textual use-case list.
- Source-trace classification: source support exists, but blocker severity should be clarified.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, `Diagram-to-text exact matching` and special check `4.7`.
- Risk level: medium.
- Manual visual check required: yes.

#### 6.2 Use-case `include` relations

- Current problem: `diagrams/02_use_cases.mmd` includes relations such as `Ava registreerimine` including `Planeeri treeningukord`, but the corresponding extended scenario does not clearly state this included use case is launched.
- Proposed change: either remove unsupported `<<include>>` relations or add matching scenario steps where the base use case launches the included use case.
- Source-trace classification: `Explicit`.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, diagram rules for `UC <<include>> seose vastavus tekstile`.
- Risk level: medium.
- Manual visual check required: yes.

#### 6.3 ERD entity and attribute alignment

- Current problem: ER diagrams include or imply elements not aligned with `Tabel 19`/`Tabel 20`, including:
  - `JUHATAJA` entity appears in ERD sources, but `Juhataja` is not defined as an olemitüüp.
  - `Klassifikaator` is missing as a general entity while classifier-specific entities exist.
  - Attribute names differ, for example `nimi` vs `eesnimi`/`perenimi`, `pädevuste ulatus` vs diagram-style variants, and `märkus`/`markus`.
- Proposed change:
  - Remove `Juhataja` as a separate entity unless it is added as an olemitüüp; prefer modeling it through `Töötaja`, `Roll`, and `Töötaja rolli omamine`.
  - Add `Klassifikaator` to the classifier ERD or explicitly model `Seisund`, `Roll`, and `Riik` as classifier subtypes.
  - Align every ERD attribute name with the final attribute-definition table.
- Source-trace classification: `Explicit`.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, entries `ERD existence/entity/attribute matching` and special check `4.7`.
- Risk level: high.
- Manual visual check required: yes.

#### 6.4 State diagrams and OP references

- Current problem: state diagrams use function or use-case names in transitions, but not OP references. Examples are visible in `diagrams/05_session_state.mmd` and `diagrams/06_registration_state.mmd`.
- Proposed change:
  - Add OP references to transition labels, for example `planeerimine / OP1`, `registreerimise avamine / OP2`, `registreeringu esitamine / OP5`, `registreeringu tühistamine / OP6`, `ootel registreeringu edendamine / OP7`, `treeningukorra tühistamine / OP9`.
  - Align `Tabel 22` and `Tabel 23` transition rows with the same OP references.
- Source-trace classification: `Explicit`.
- Source evidence: `docs/RULE_SOURCE_TRACE_AUDIT.md`, entry `State diagrams OP references`.
- Risk level: medium.
- Manual visual check required: yes.

## 3. Items to ask professor/TA before changing

### Read-only OP contracts

- Why uncertain: `docs/RULE_SOURCE_TRACE_AUDIT.md` classifies the hard ban on read-only operation contracts as `Contradicted / questionable`, while OP references in read steps are classified as `Explicit`.
- Question to ask: "Kas lugemisoperatsioonidele tuleb lisada ainult OP-viited stsenaariumidesse või tuleb need ka operatsioonilepingutena lahti kirjutada?"
- Change if confirmed: either add read-only OP contracts for `OP10`-`OP16`, or keep them only as scenario read references.

### Report-display use cases: exactly 2 steps or at least 2 steps

- Why uncertain: `docs/RULE_SOURCE_TRACE_AUDIT.md` classifies the exact two-step report rule as `Contradicted / questionable`.
- Question to ask: "Kas aruande kuvamise kasutusjuhul peab olema täpselt kaks põhistsenaariumi sammu või piisab vähemalt kahest sammust?"
- Change if confirmed: reduce `Vaata statistikat` to the required step count or keep current step count while improving OP references and report fields.

### `Pank`/`Maksekeskus` when payment processing is out of scope

- Why uncertain: the source trace classifies this as weak/implied rather than clearly mandatory.
- Question to ask: "Kui süsteem ei käsitle makseid ega arveldamist, kas `Pank` või `Maksekeskus` peab siiski tegutsejate nimekirjas olema?"
- Change if confirmed: add `Pank` or `Maksekeskus` only if payment handling is in scope.

### Title-page email

- Why uncertain: source support is not as strong as for author name, but the current document already includes an e-mail address on the title page.
- Question to ask: "Kas tiitellehel peab kindlasti olema autori e-posti aadress või piisab nimest ja rühmainfost?"
- Change if confirmed: no current edit needed unless the title page is later rewritten.

### Exact high-level <-> extended use-case 1:1 matching

- Why uncertain: the user specifically requested this remain a clarification topic if not clearly required outside `Koond.txt`; source support may be checklist-based rather than a full guide rule.
- Question to ask: "Kas iga lühike kasutusjuht peab dokumendis omama täpselt samanimelist laiendatud kasutusjuhtu ja vastupidi?"
- Change if confirmed: add extended use cases for `Vaata vabu treeningukordi`, `Edenda ootel registreering`, `Vaata treeningukorra registreeringuid`, `Sulge registreerimine`, and `Lõpeta treeningukord`, or remove/merge high-level use cases not intended for extension.

### Exact diagram-to-text matching as blocker or warning

- Why uncertain: source support exists, but the source trace recommends caution because diagram extraction and rendered figures can differ.
- Question to ask: "Kas diagrammi ja tekstikirjelduse nimede täpne kattumine on hindamisel blokeeriv viga või parandamist vajav hoiatus?"
- Change if confirmed: update all `.mmd`, EAP, and DOCX diagrams to exactly match final use-case, actor, entity, attribute, and OP names.

## 4. Minimal edit checklist

- [ ] `1.1.4 Põhiobjektid` - add `Klassifikaator`; do not remove `Treener` unless professor/TA confirms a different conceptual scope.
- [ ] `1.1.6 Tegutsejad` - add `Klassifikaatorite haldur`; add `Töötajate haldur` if `Töötaja` remains a põhiobjekt.
- [ ] `1.1.8 Terviksüsteemi tükeldus`, `Tabel 9` - split combined rows into one row per põhiobjekt/register; replace administratiivne/value-list names with `[mitmuse omastav] funktsionaalne allsüsteem` and `[mitmuse omastav] register`.
- [ ] `1.2.2`, `Tabel 10` - replace combined register references with exact corrected register names from `Tabel 9`.
- [ ] `1.3 eskiismudelid` - rename/split combined register-heading text; replace `Isikute ja kasutajakontode register` and `Töötajate rollide register` with corrected register names.
- [ ] `2.1`, `Tabel 11` - rename columns `Tegutseja` -> `Tegutsejad` and `Sisu` -> `Kirjeldus`.
- [ ] `2.1` extended use cases - add read OP references `OP10`-`OP16` to data-reading system steps.
- [ ] `2.1` extended use cases - specify fields for every displayed list/report and include user-understandable identifiers.
- [ ] `2.1 Märgi osalemine` - align primary actor with scenario or add explicit `Juhataja` path.
- [ ] `2.2.1`, `Tabel 19` - add `Klassifikaator` entity definition or clearly model classifier supertype; remove or define any entity shown in ERD but absent from definitions.
- [ ] `2.2.1.3`, `Tabel 20` - replace grouped attribute prose with per-attribute definitions in the required `{}` + `Näiteväärtus:` format.
- [ ] `2.2.2`, `Tabel 21` - rewrite data-changing operations as formal contracts with parameters, preconditions, postconditions, and use-case references.
- [ ] `2.3 CRUD` - transpose matrix so olemitüübid are rows and kasutusjuhud are columns; remove `-`; replace `C/U` with `CU`; add `Kokku` column.
- [ ] `diagrams/02_use_cases.mmd` and rendered UC diagrams - after textual names are final, align use-case names, actors, and include relations.
- [ ] ERD diagrams and `Tabel 19`/`Tabel 20` - align entity and attribute names; remove or define `Juhataja`; add/align `Klassifikaator`.
- [ ] State diagrams and `Tabel 22`/`Tabel 23` - add OP references to transitions.

## 5. Risk controls

- If `Klassifikaator` is added as a põhiobjekt, also add `Klassifikaatorite haldur`, `Klassifikaatorite funktsionaalne allsüsteem`, `Klassifikaatorite register`, a conceptual entity/definition, CRUD row, and diagram representation. Do not add only the põhiobjekt row.
- Do not remove `Treener` as a põhiobjekt in this plan. Removing it would require coordinated changes across actors, pädevusalad, registries, ERD, use cases, and CRUD.
- If `Tabel 9` names are changed, update all headings, eskiismudelid, `Tabel 10`, diagrams, CRUD labels, and operation/use-case references that use old combined names.
- If use-case names are changed, update high-level table rows, extended descriptions, UC diagram labels, CRUD columns, and `Kasutus kasutusjuhtude poolt` entries together.
- If attribute names are changed, update ERD attributes, attribute definitions, operation-contract postconditions, CRUD row labels if applicable, and state/operation text.
- Before editing the DOCX, make one canonical list each for põhiobjektid, tegutsejad, pädevusalad, funktsionaalsed allsüsteemid, registrid, use cases, olemitüübid, and attributes. Use those lists as the source of truth for all later edits.

## 6. Final recommendation for the next implementation run

Safe to implement immediately:

- Add `Klassifikaator` and its conditional structural consequences.
- Split combined subsystem/register names and align all textual register references.
- Fix high-level use-case table labels.
- Add OP references to read/write system steps and specify list/report fields.
- Replace attribute definitions with required per-attribute `{}` + `Näiteväärtus:` format.
- Formalize data-changing operation contracts.
- Rewrite CRUD orientation and symbols.
- Add OP references to state transitions after visual diagram check.

Likely but confirm before major rewrites:

- Whether to write read-only OP contracts or only read OP references.
- Whether every high-level use case must have a matching extended use case.
- Whether diagram/text exact matching is a blocker or warning.
- Whether report use cases must have exactly two steps.
- Whether payment actors are required when payments are out of scope.
