# NOT FOR SUBMISSION — Project Explainer

This file is for study/reference only and must not be uploaded unless explicitly requested.

## One-Sentence Summary

The project models and prototypes a gym group-training schedule, registration, waitlist and attendance subsystem.

## What Changed

The old project treated `treening` mostly as a training description card with categories and lifecycle status. That looked too close to the workbook-style training example.

The reworked project centers on concrete `treeningukord` rows:

- a manager plans a session;
- the session has a room, capacity, trainer and deadlines;
- the trainer must have competence for the selected `treeninguliik`;
- clients register;
- a full session creates an `OOTEJRK` waitlist row;
- a confirmed cancellation promotes the first waitlisted client;
- trainers mark attendance through `osalemine`.

## Core Tables

- `klient`
- `treeninguliik`
- `ruum`
- `treeneri_padevus`
- `treeningukord`
- `registreering`
- `osalemine`
- status classifiers for training type, session and registration lifecycle

The useful person/account/employee foundation remains: `isik`, `kasutajakonto`, `tootaja`, `tootaja_roll` and `tootaja_rolli_omamine`.

## Database-Enforced Rules

The database, not just Flask, checks:

- room capacity is not exceeded;
- trainer has an active `TREENER` role;
- trainer has `treeneri_padevus` for the training type;
- trainer and room do not have overlapping non-cancelled sessions;
- client cannot have duplicate active registration for the same session;
- registration and cancellation deadlines are respected;
- only valid session and registration status transitions are allowed;
- waitlist promotion happens in a database function;
- attendance can be marked only for confirmed registrations by the assigned trainer or a manager.

## Main Routines

- `fn_planeeri_treeningukord`
- `fn_ava_treeningukord`
- `fn_sulge_treeningukord`
- `fn_lopeta_treeningukord`
- `fn_registreeri_klient_treeningukorrale`
- `fn_tyhista_registreering`
- `fn_edenda_ootejarjekorrast`
- `fn_marki_osalemine`
- `fn_tyhista_treeningukord`

## Flask Workflows

- Manager: `/manager/sessions`, `/manager/sessions/new`, `/manager/report`
- Trainer: `/trainer/sessions`, `/trainer/sessions/<treeningukorra_id>/roster`
- Client: `/schedule`, `/client/registrations`

Normal write routes call database functions. Reads use views such as `avalikud_treeningukorrad`, `kliendi_registreeringud`, `treeneri_tunniplaan` and `juhataja_treeningukordade_ulevaade`.

## Diagrams

Diagram sources are Mermaid files in `diagrams/`. Generated PNGs are in `work/generated_diagrams/` and are embedded into the DOCX.

The diagrams explain context, use cases, core ER model, registration activity, session state, registration state, waitlist promotion, permissions and app/database architecture.

## Final Submission Files

Use only the four files in `submission_files/`:

- `dokument.docx`
- `skript.sql`
- `mudelid.eap`
- `rakendus.zip`
