# Dense Technical Summary

This is an internal reference summary, not a submission file.

## Scope

`Jõusaali rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalne allsüsteem`

Core process:

1. Juhataja planeerib konkreetse `treeningukord` rea.
2. Juhataja avab registreerimise.
3. Klient registreerub ja saab `KINNIT` või `OOTEJRK` seisundi.
4. Kliendi tühistamine võib käivitada `fn_edenda_ootejarjekorrast`.
5. Treener näeb enda treeningukordi ja märgib `osalemine`.
6. Juhataja näeb täituvuse ja ootejärjekorra statistikat.

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

- `fn_kasutajal_on_roll`
- `fn_on_juhataja`
- `fn_on_treener`
- `fn_kasutaja_tuvastamise_andmed`
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

- `v_avalikud_treeningukorrad`
- `v_kliendi_registreeringud`
- `v_treeneri_tunniplaan`
- `v_treeningukorra_osalejad`
- `v_juhataja_treeningukordade_ulevaade`
- `v_treeningute_taituvuse_statistika`
- `v_treeninguliigid_kategooriatega`

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
- registration activity;
- session lifecycle;
- registration lifecycle;
- waitlist promotion sequence;
- permission flow;
- app/database architecture.

## App Routes

- `/schedule`
- `/client/sessions/<treeningukorra_kood>/register`
- `/client/registrations`
- `/client/registrations/<registreeringu_kood>/cancel`
- `/manager/sessions`
- `/manager/sessions/new`
- `/manager/sessions/<treeningukorra_kood>/open`
- `/manager/sessions/<treeningukorra_kood>/close`
- `/manager/sessions/<treeningukorra_kood>/complete`
- `/manager/sessions/<treeningukorra_kood>/cancel`
- `/manager/report`
- `/trainer/sessions`
- `/trainer/sessions/<treeningukorra_kood>/roster`
- `/trainer/sessions/<treeningukorra_kood>/attendance`

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
