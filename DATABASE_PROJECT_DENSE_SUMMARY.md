# Dense Technical Summary

This is an internal reference summary, not a submission file.

## Scope

`Jõusaali rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalne allsüsteem`

Core process:

1. Juhataja planeerib konkreetse `treeningukord` rea.
2. Juhataja avab registreerimise.
3. Klient vaatab vabu treeningukordi.
4. Klient esitab `registreering` objekti ja saab `KINNIT` või `OOTEJRK` seisundi.
5. Klient vaatab enda registreeringuid.
6. Kliendi tühistamine võib käivitada `fn_edenda_ootejarjekorrast`.
7. Treeneri rollis töötaja näeb enda treeningukordi ja märgib `osalemine`.
8. Juhataja näeb täituvuse ja ootejärjekorra statistikat.

Conceptual classification:

- Central lifecycle object: `registreering`.
- Strong core objects: `isik`, `tootaja`, `klient`, `treener`, `treeninguliik`, `treeningukord`, `registreering`.
- Dependent lifecycle-bearing objects: `osalemine`, `treeneri_padevus`.
- Supporting/relationship objects: `ootejarjekorra_koht`, `ruum`, `varustus`, `ruumi_varustuse_omamine`, `treeninguliigi_varustuse_noue`.
- Classifiers/value lists: statuses, roles and countries.
- `treener` is a `tootaja` specialization and actor; it is not an unrelated person object.

## Core Tables

- `klient`
- `treeninguliigi_seisundi_liik`
- `treeninguliik`
- `ruum`
- `treeneri_padevus`
- `treeningukorra_seisundi_liik`
- `treeningukord`
- `registreeringu_seisundi_liik`
- `registreering`
- `osalemine`

Kept foundation:

- `riik`
- `isik`
- `kasutajakonto`
- `tootaja`
- `tootaja_roll`
- `tootaja_rolli_omamine`
- `isiku_seisundi_liik`
- `tootaja_seisundi_liik`

## Required Routines

- `on_kasutajal_roll`
- `on_juhataja`
- `on_treener`
- `fn_tuvasta_kasutaja_e_meili_jargi`
- `fn_planeeri_treeningukord`
- `fn_ava_treeningukord`
- `fn_sulge_treeningukord`
- `fn_lopeta_treeningukord`
- `fn_registreeri_klient_treeningukorrale`
- `fn_tyhista_registreering`
- `fn_edenda_ootejarjekorrast`
- `fn_marki_osalemine`
- `fn_tyhista_treeningukord`

## Required Views

- `avalikud_treeningukorrad`
- `kliendi_registreeringud`
- `treeneri_tunniplaan`
- `treeningukorra_osalejad`
- `juhataja_treeningukordade_ulevaade`
- `treeningute_taituvuse_statistika`
- `treeninguliigid_kategooriatega`

## Database Rules

- room capacity cannot be exceeded;
- trainer and room cannot overlap with non-cancelled sessions;
- trainer must have active `TREENER` role;
- trainer must have `treeneri_padevus`;
- client cannot have duplicate active registration for the same session;
- registration and cancellation deadlines are enforced in DB routines;
- session and registration status transitions are guarded by triggers;
- waitlist promotion happens inside a DB function;
- attendance is separate from registration status and is trigger-checked.

## Diagrams

Mermaid sources are in `diagrams/`; PNG outputs are in `work/generated_diagrams/`.

The DOCX embeds:

- system context;
- use cases;
- core ER model;
- separate conceptual register diagrams for people, training sessions, registrations, attendance and classifiers;
- registration activity;
- session lifecycle;
- registration lifecycle;
- waitlist promotion sequence;
- permission flow;
- app/database architecture.

## App Routes

- `/schedule`
- `/client/sessions/<treeningukorra_id>/register`
- `/client/registrations`
- `/client/registrations/<registreeringu_id>/cancel`
- `/manager/sessions`
- `/manager/sessions/new`
- `/manager/sessions/<treeningukorra_id>/open`
- `/manager/sessions/<treeningukorra_id>/close`
- `/manager/sessions/<treeningukorra_id>/complete`
- `/manager/sessions/<treeningukorra_id>/cancel`
- `/manager/report`
- `/trainer/sessions`
- `/trainer/sessions/<treeningukorra_id>/roster`
- `/trainer/sessions/<treeningukorra_id>/attendance`

## Validation

Run:

```bash
./build_all.sh
.venv/bin/python tools/validate_project.py
```

Optional disposable live SQL check:

```bash
createdb jousaali_live_check
RUN_LIVE_SQL_TESTS=1 LIVE_SQL_DSN="dbname=jousaali_live_check" .venv/bin/python tools/validate_project.py
dropdb jousaali_live_check
```
