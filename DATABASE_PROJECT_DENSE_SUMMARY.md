# Databases Project Dense Summary

Source-backed unless marked `[inferred]`; inspected from `/Users/gustav/andmebaasid-projekt` on 2026-05-21.

## 1. Project Identity
- Project name: `Jõusaali infosüsteemi treeningute funktsionaalne allsüsteem`.
- Course/context: `Andmebaasid I, ITI0206`, 2026 spring; TalTech / `TALLINNA TEHNIKAÜLIKOOL`, `Infotehnoloogia teaduskond`, `Tarkvarateaduse instituut`; supervisor `Erki Eessaar`.
- Authors/report identity: `Tristan Aik Sild, Gustav Tamkivi`; group `IAIB23`; matriculation `253782IAIB`, `253787IAIB`; emails `gustav@taltech.ee`, `trists@taltech.ee`.
- Domain/goal: gym training-management subsystem centered on register object `Treening`; manage training lifecycle, categories, public/client visibility, trainer operations, manager reporting.
- Expected deliverables: `submission_files/dokument.docx`, `submission_files/mudelid.eap`, `submission_files/skript.sql`, `submission_files/rakendus.zip`; root mirrors: `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx`, `.eap`, `jousaali_skript.sql`, `rakendus/`.
- Languages/tech: Estonian documentation/UI/object names; PostgreSQL SQL/PLpgSQL; Python Flask/Jinja/JS/Bootstrap app; Java Jackcess EAP tooling; Python `python-docx`/Pillow report generation.
- DBMS: PostgreSQL; DDL includes domains, sequence, tables, views, functions, triggers, indexes, roles/grants, `ANALYZE`, `EXPLAIN`.
- Current status: static/project validation passed via `.venv/bin/python tools/validate_project.py`; git worktree is dirty on `main` with many modified generated/source files and untracked instruction/explainer files.

## 2. Repository/File Map
- `README.md` -> root build/submission guide -> final artifact names, build steps, validation commands, manual EA checks -> first project overview.
- `FINAL_SUBMISSION_CHECKLIST.md` -> manual pre-upload checklist -> ZIP hygiene, DB/app smoke tests, TalTech server/manual EA notes -> operational delivery guardrail.
- `PROJECT_EXPLAINER_NOT_FOR_SUBMISSION.md` -> non-submittable defense/context notes -> FAQ, scope, lifecycle, validation checklist -> keep out of `submission_files/` and app ZIP.
- `jousaali_skript.sql` -> generated PostgreSQL DDL from `tools/sql_ddl.py` -> canonical executable schema and DB checks -> submission copy source.
- `tools/sql_ddl.py` -> source of SQL string `SQL_DDL` -> regenerate `jousaali_skript.sql`/DOCX embedded SQL -> edit schema here first.
- `tools/fill_report_docx.py` -> canonical report generator -> authors, report text, entities, use cases, operation contracts, diagrams, embedded SQL -> DOCX source of truth.
- `tools/validate_project.py` -> automated validator -> checks DOCX, SQL, EAP via `mdb-export`, app source/ZIP/submission copies/placeholders -> run before commit/submission.
- `tools/EapConvert.java`, `EapRename.java`, `EapFixes.java`, `EapDedupe.java`, `EapInspect.java` -> Java/Jackcess EAP mutation/inspection tools -> regenerate/fix Sparx EA `.eap`.
- `build_all.sh`, `build_all.bat` -> reproducible pipeline -> compile Java, copy `preset_files/EA_converted_source.eap`, patch/dedupe EAP, generate DOCX/SQL, refresh `submission_files/`.
- `requirements.txt` -> root generator deps -> `python-docx==1.1.2`, `Pillow==10.4.0`.
- `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx` -> generated final report -> 1001 paragraphs, 65 tables, 7 images, 45 headings; derived from `tools/fill_report_docx.py`.
- `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap` -> generated Sparx EA model -> patched from `preset_files/EA_converted_source.eap`; validated against SQL actors/table classes.
- `submission_files/` -> generated deliverables -> `dokument.docx`, `mudelid.eap`, `skript.sql`, `rakendus.zip`; derived, but tracked despite `.gitignore`.
- `rakendus/app.py` -> Flask prototype -> auth/session, role checks, training CRUD/status routes, report/stats queries -> app behavior source.
- `rakendus/templates/*.html` -> Bootstrap/Jinja UI -> login/dashboard/trainings/register/report/error -> user-visible workflows.
- `rakendus/test_data.sql` -> app demo data -> test users, roles, 3 sample trainings, category links -> prototype smoke-test seed.
- `rakendus/README.md`, `.env.example`, `requirements.txt`, `SETUP.sh` -> app setup/run docs/config -> PostgreSQL connection/env/deps.
- `instruction_guides/` -> course PDFs/text rule prompts/templates -> requirements/checking material, not generated deliverables.
- `preset_files/` -> original/converted course templates -> `AB_projekt_Eeltaidetud_2026.doc`, EA template/source -> build input/reference.
- `work/` -> generated/intermediate/reference artifacts -> extracted guide text, generated diagrams PNGs, filled docx, EAP edit working files -> mostly derived/supporting.

## 3. Domain Model
- `Treening` -> central offering/service; attrs `treeningu_kood`, status, registrar/changer, timestamps, `nimetus`, `kirjeldus`, `kestus_minutites`, `maksimaalne_osalejate_arv`, `vajalik_varustus`, `hind`; lifecycle `OOTEL -> AKTIIVNE|UNUSTATUD`, `AKTIIVNE -> MITTEAKT|LOPPENUD`, `MITTEAKT -> AKTIIVNE|LOPPENUD`; terminal `LOPPENUD`, `UNUSTATUD`.
- `Treeningu_seisundi_liik` -> training lifecycle classifier; values `OOTEL`, `AKTIIVNE`, `MITTEAKT`, `LOPPENUD`, `UNUSTATUD`; drives visibility/allowed transitions.
- `Treeningu_kategooria_tüüp` / SQL `treeningu_kategooria_tyyp` -> category type classifier; values `GRUPP`, `PERS`, `KARDIO`, `JÕUD`.
- `Treeningu_kategooria` -> concrete category classifier; values seeded `GRUPP`, `PERS`, `KARDIO`, `JÕUD`, JSON-loaded `VENITUS`, `RING`; active categories can be selected.
- `Treeningu_kategooria_omamine` -> M:N link; required before activation; active training cannot lose last category.
- `Isik` -> physical person/user; composite identity `isikukood + riigi_kood`; email unique; at least one name required.
- `Kasutajakonto` -> login account tied to `isik.e_meil`; password hash, active flag.
- `Töötaja` -> employee account; tied 1:1 to `kasutajakonto`; has employee status.
- `Töötaja_roll` / `Töötaja_rolli_omamine` -> role classifier and time-bounded role ownership; active role has `lopu_aeg IS NULL`; roles control app permissions.
- Actors/roles: `Treener` registers/edits/activates/deactivates/forgets; `Juhataja` finishes/reports; `Klient` and `Uudistaja` view active trainings; `Klassifikaatorite haldur` and `Töötajate haldur` modeled/documented, not fully implemented as UI workflows.

## 4. Database Schema
- Domains: `kood_10`=`VARCHAR(10)` CHECK nonblank; `e_meil_aadress`=`VARCHAR(254)` CHECK nonblank, `@` after first char, no spaces; `raha_mitte_negatiivne`=`NUMERIC(8,2)` CHECK `VALUE >= 0`.
- Sequence: `seq_treeningu_kood START 1000 INCREMENT 1 OWNED BY treening.treeningu_kood`.
- `riik(riigi_kood kood_10 PK NOT NULL, nimetus VARCHAR(200) NOT NULL, on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE; chk nonblank kood/nimetus)`.
- `isiku_seisundi_liik(kood kood_10 PK, nimetus VARCHAR(200) NOT NULL, on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE; chk nonblank)`.
- `tootaja_seisundi_liik(kood kood_10 PK, nimetus VARCHAR(200) NOT NULL, on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE; chk nonblank)`.
- `tootaja_roll(kood kood_10 PK, nimetus VARCHAR(200) NOT NULL, on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE, kirjeldus TEXT NULL; chk nonblank kood/nimetus/kirjeldus-if-present)`.
- `treeningu_seisundi_liik(kood kood_10 PK, nimetus VARCHAR(200) NOT NULL, on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE; chk nonblank)`.
- `treeningu_kategooria_tyyp(kood kood_10 PK, nimetus VARCHAR(200) NOT NULL, on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE; chk nonblank)`.
- `treeningu_kategooria(kood kood_10 PK, treeningu_kategooria_tyyp_kood kood_10 FK->treeningu_kategooria_tyyp.kood NOT NULL, nimetus VARCHAR(200) NOT NULL, on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE; UNIQUE(treeningu_kategooria_tyyp_kood,nimetus); chk nonblank kood/nimetus)`.
- `isik(isikukood VARCHAR(20) NOT NULL, riigi_kood kood_10 NOT NULL FK->riik.riigi_kood, isiku_seisundi_liik_kood kood_10 NOT NULL FK->isiku_seisundi_liik.kood, synni_kp DATE NOT NULL, reg_aeg TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, viimase_muutm_aeg TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, eesnimi VARCHAR(200), perenimi VARCHAR(200), elukoht VARCHAR(500), e_meil e_meil_aadress NOT NULL UNIQUE; PK(isikukood,riigi_kood); checks: nonblank isikukood, eesnimi OR perenimi present, elukoht-if-present nonblank, email format, synni_kp 1900-01-01..2100-12-31, viimase_muutm_aeg>=reg_aeg)`.
- `kasutajakonto(e_meil e_meil_aadress PK FK->isik.e_meil, parool VARCHAR(255) NOT NULL, on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE; chk email format, parool nonblank)`.
- `tootaja(e_meil e_meil_aadress PK FK->kasutajakonto.e_meil, tootaja_seisundi_liik_kood kood_10 NOT NULL FK->tootaja_seisundi_liik.kood)`.
- `tootaja_rolli_omamine(tootaja_e_meil e_meil_aadress FK->tootaja.e_meil, tootaja_roll_kood kood_10 FK->tootaja_roll.kood, alguse_aeg TIMESTAMPTZ NOT NULL, lopu_aeg TIMESTAMPTZ NULL; PK(tootaja_e_meil,tootaja_roll_kood,alguse_aeg); chk lopu_aeg IS NULL OR lopu_aeg>alguse_aeg)`.
- `treening(treeningu_kood INTEGER PK DEFAULT nextval('seq_treeningu_kood'), treeningu_seisundi_liik_kood kood_10 NOT NULL DEFAULT 'OOTEL' FK->treeningu_seisundi_liik.kood, registreerija_e_meil e_meil_aadress NOT NULL FK->kasutajakonto.e_meil, viimase_muutja_e_meil e_meil_aadress NOT NULL FK->kasutajakonto.e_meil, reg_aeg TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, viimase_muutm_aeg TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, nimetus VARCHAR(200) NOT NULL UNIQUE, kirjeldus TEXT NOT NULL, kestus_minutites INTEGER NOT NULL, maksimaalne_osalejate_arv INTEGER NOT NULL, vajalik_varustus TEXT NOT NULL, hind raha_mitte_negatiivne NOT NULL; checks: kood>0, nonblank text fields, kestus 15..240, osalejad>0, hind>=0, viimase_muutm_aeg>=reg_aeg)`.
- `treeningu_kategooria_omamine(treeningu_kood INTEGER FK->treening.treeningu_kood, treeningu_kategooria_kood kood_10 FK->treeningu_kategooria.kood; PK(treeningu_kood,treeningu_kategooria_kood))`.
- All FKs omit explicit `ON DELETE/ON UPDATE`; PostgreSQL default `NO ACTION` applies.
- Indexes: `ix_isik_riik`, `ix_isik_seisund`, `ix_tootaja_seisund`, `ix_rolli_omamine_roll`, `ix_treening_seisund`, `ix_treening_registreerija`, `ix_treening_muutja`, `ix_treeningu_kategooria_tyyp`, `ix_kategooria_omamine_kategooria`.
- Views: `v_treeningud_kategooriatega` aggregates category names per training via `string_agg`; `v_aktiivsed_treeningud` filters active; `v_treeningute_arv_seisundi_kaupa` counts trainings by status including zeroes; `v_treeningute_arv_kategooria_kaupa` counts category links by category/type.
- Functions: `fn_kasutaja_tuvastamise_andmed(p_e_meil)` returns account/person/current roles; `fn_registreeri_treening(...)` validates nonempty active categories + active account, inserts `OOTEL`, inserts links, returns code; `fn_aktiveeri_treening(id,email)` updates `OOTEL|MITTEAKT -> AKTIIVNE` else raises; `fn_lopeta_treening(id,email)` updates `AKTIIVNE|MITTEAKT -> LOPPENUD` else raises; trigger functions `fn_treening_initial_status`, `fn_treening_status_transition`, `fn_treening_prevent_active_categoryless`.
- Triggers: `trg_treening_initial_status BEFORE INSERT ON treening`; `trg_treening_status_transition BEFORE UPDATE OF treeningu_seisundi_liik_kood ON treening`; `trg_treening_no_active_without_category AFTER DELETE ON treeningu_kategooria_omamine DEFERRABLE INITIALLY IMMEDIATE`.
- Admin/test SQL: classifier seed inserts; JSON `jsonb_to_recordset` loads `VENITUS`/`RING`; rollbackable `BEGIN`/`ROLLBACK` tests trigger/routine behavior; `ANALYZE`; `EXPLAIN SELECT * FROM v_aktiivsed_treeningud WHERE hind <= 20`; roles `jousaali_rakendus`, `jousaali_vaatleja`; `REVOKE ALL ... FROM PUBLIC`; conditional grants.

## 5. Relationships and Cardinalities
- `riik 1..N isik via fk_isik_riik`; `isik.riigi_kood` mandatory; no cascade.
- `isiku_seisundi_liik 1..N isik via fk_isik_seisund`; mandatory; no cascade.
- `isik 1..0..1 kasutajakonto via fk_kasutajakonto_isik` using unique `isik.e_meil`; account mandatory to person; person may lack account `[inferred from optional account table]`; no cascade.
- `kasutajakonto 1..0..1 tootaja via fk_tootaja_konto`; employee requires account; account may be client/nonemployee; no cascade.
- `tootaja_seisundi_liik 1..N tootaja via fk_tootaja_seisund`; mandatory; no cascade.
- `tootaja 1..N tootaja_rolli_omamine via fk_rolli_omamine_tootaja`; role history; no cascade.
- `tootaja_roll 1..N tootaja_rolli_omamine via fk_rolli_omamine_roll`; role classifier; active role when `lopu_aeg IS NULL`; no cascade.
- `treeningu_seisundi_liik 1..N treening via fk_treeningu_seisund`; mandatory lifecycle state; no cascade.
- `kasutajakonto 1..N treening via fk_treeningu_registreerija`; registrar mandatory; no cascade.
- `kasutajakonto 1..N treening via fk_treeningu_muutja`; last changer mandatory; no cascade.
- `treeningu_kategooria_tyyp 1..N treeningu_kategooria via fk_treeningu_kategooria_tyyp`; mandatory; no cascade.
- `treening M..N treeningu_kategooria via treeningu_kategooria_omamine`; link mandatory columns; no cascade; DB trigger prevents active training losing last link.
- `[inferred/model] Treener/Juhataja permissions derive from current `tootaja_rolli_omamine`; app checks roles in session, DB broad grants do not encode per-business-role permissions.

## 6. Business Rules and Constraints
- Enforced in DB: controlled classifiers via FKs; nonblank domains/text checks; `isik` needs eesnimi or perenimi; email unique/format; status/category/type/role codes unique by PK; `treening.nimetus` unique; duration 15..240; participants >0; price >=0; timestamps not decreasing; new training status exactly `OOTEL`; lifecycle transitions only documented paths; activation requires at least one category; active training cannot lose last category by deleting link; `fn_registreeri_treening` requires nonempty active categories and active registrar account.
- Enforced in app/code: password hash check and active account; role gates for trainer/manager routes; public/client visibility only active trainings; staff sees full training list; form required fields, numeric ranges, price max `999999.99`, category dedupe; active category selection validation; edit only `OOTEL|MITTEAKT`; deactivate only `AKTIIVNE`; forget only `OOTEL`; finish only `AKTIIVNE|MITTEAKT`; parameterized SQL; create/edit category links in one transaction with rollback.
- Documented only: daily backup requirement; active-training list response <=2s; full production security/logging/monitoring; complete classifier/employee admin UI; TalTech PostgreSQL upload possibility; manual Sparx EA visual review; date/time allowed ranges 2020-2100 for several non-birth timestamp attributes.
- Missing/should be enforced if hardening: DB does not enforce per-role authorization (`TREENER` vs `JUHATAJA`) for writes; app does not call DB routines, so business logic is duplicated; no CSRF protection; no migration framework; no automated browser/app integration tests found; DB does not CHECK documented 2020-2100 ranges for `reg_aeg`, `alguse_aeg`, `lopu_aeg`; broad `jousaali_rakendus` grants allow table-wide CRUD.

## 7. Data Flow / Main Operations
- Build flow: `./build_all.sh`/`build_all.bat` downloads jars if missing -> compiles Java -> copies `preset_files/EA_converted_source.eap` -> runs EAP rename/fixes/dedupe -> generates DOCX -> prints `SQL_DDL` to `jousaali_skript.sql` -> refreshes `submission_files/` and app ZIP.
- Login: `/login` reads `kasutajakonto` + `isik`, checks `on_aktiivne`, `check_password_hash`, loads current roles from `tootaja_rolli_omamine.lopu_aeg IS NULL`, stores session `user_id/name/role/roles`.
- Public/client list: `/trainings` uses `v_aktiivsed_treeningud`; staff list uses `v_treeningud_kategooriatega`; detail route hides non-active unless `session.role == 'tootaja'`.
- Register: `GET /trainer/register-training` loads active categories; `POST` validates form/category, inserts `treening` with `OOTEL` and default sequence, inserts links, commits; uses direct SQL, not `fn_registreeri_treening`.
- Edit: `GET/POST /trainer/edit-training/<id>` only `OOTEL|MITTEAKT`; updates main fields, deletes/reinserts category links, commits.
- Status operations: trainer activate/deactivate/forget and manager finish call helper `update_training_status`; DB trigger backs transition validity; each route commits/rolls back one transaction.
- Reports/API: `/manager/report` reads `v_treeningute_arv_seisundi_kaupa` and `v_treeningute_arv_kategooria_kaupa`; `/api/stats` counts active/pending/inactive/finished/forgotten.
- Operation contracts in report: `OP3 Registreeri treening`, `OP6 Unusta ootel treening`, `OP8 Muuda treeningu andmeid`, `OP9 Lisa treeningu kategooria seos`, `OP10 Eemalda treeningu kategooria seos`, `OP11 Aktiveeri treening`, `OP13 Muuda treening mitteaktiivseks`, `OP15 Lõpeta treening`.

## 8. Sample Data and Test Coverage
- DDL seed data: countries `EE/LV/LT`; person statuses `KLIENT/TOOTAJA`; employee statuses `AKTIIVNE/PUHKUSEL/LAHKUNUD`; roles `TREENER/JUHATAJA/KL_HALDUR/TOO_HALD`; training statuses `OOTEL/AKTIIVNE/MITTEAKT/LOPPENUD/UNUSTATUD`; category types and categories `GRUPP/PERS/KARDIO/JÕUD`; JSON categories `VENITUS`, `RING`.
- DDL rollback tests: creates temporary `ddl.test.treener@example.com`; verifies invalid initial active insert fails; inserts/checks category + activation; verifies `AKTIIVNE -> UNUSTATUD` fails; verifies deleting last category of active training fails; uses `fn_registreeri_treening` + activate + finish reaching `LOPPENUD`; rolls back all.
- `rakendus/test_data.sql`: inserts users `treener@jousaal.ee`/`treener123`, `juhataja@jousaal.ee`/`juhataja123`, `klient@jousaal.ee`/`klient123`, `uudistaja@jousaal.ee`/`uudistaja123` with portable `pbkdf2:sha256` hashes; employees `treener`, `juhataja`; roles `TREENER`, `JUHATAJA`, `KL_HALDUR`; trainings IDs 1 `Jõutreening algajatele` active, 2 `Jooga ja painduvus` active, 3 `HIIT treening` ootel; category links `(1,JÕUD),(2,GRUPP),(3,KARDIO)`.
- Validator coverage: DOCX structure/format/headings/captions/placeholders/wording/op refs; SQL required constraints/objects/FK target keys; EAP duplicate IDs/placeholders/actors/use-case notes/op refs/table classes; app Python compile/source markers/hash portability/placeholder checks; submission ZIP integrity/stale/forbidden contents/root-copy equality.
- Verified this inspection: `.venv/bin/python tools/validate_project.py` passed.
- Not verified this inspection: full `./build_all.sh`; live PostgreSQL `psql -f` smoke test; Flask browser walkthrough; manual Sparx EA visual inspection.

## 9. Documentation / Report Content
- DOCX metadata/content: title page with institution/course/authors/supervisor; A4; generated from `tools/fill_report_docx.py`; 65 Word tables, 7 embedded diagrams, SQL DDL embedded in section 7.4.
- DOCX headings: `Sisukord`; `1 Sissejuhatus`; `1.1 Organisatsiooni kirjeldus`; `1.2 Organisatsiooni eesmärgid`; `2 Süsteemi üldvaade`; `2.1 Infosüsteemi eesmärgid`; `2.2 Põhiobjektid`; `2.3 Tegutsejad ja pädevusalad`; `2.4 Funktsionaalsed allsüsteemid ja registrid`; `2.5 Põhiprotsessid ja käivitavad sündmused`; `2.6 Lausendid`; `3 Mittefunktsionaalsed nõuded`; `4 Kasutusjuhud`; `4.1 Kõrgtaseme kasutusjuhud`; `4.2 Laiendatud kasutusjuhud`; 11 use-case subsections; `5 Treeningute registri eskiismudel`; `5.1 Registri seosed`; `5.2 Ärireeglid`; `5.3 Kontseptuaalne eskiismudel`; `6 Operatsioonilepingud`; 8 OP subsections; `7 Andmemudel ja füüsiline disain`; `7.1 Olemid ja atribuudid`; `7.2 Seisundimudel`; `7.3 Füüsiline mudel`; `7.4 SQL DDL`; `8 Reprodutseerimine ja kontroll`.
- Generated diagram PNGs: `01_architecture.png`, `02_use_cases.png`, `03_activity_register.png`, `04_activity_activate.png`, `05_conceptual.png`, `06_state.png`, `07_physical.png`.
- EAP diagrams exact names: `Treeningute funktsionaalne allsüsteem`; `Treeningu lõpetamise tegevusdiagramm`; `Treeningute register`; `Klassifikaatorite register`; `Treeningu seisundidiagramm`; `Kontseptuaalne eskiismudel`; `Treeningute FASiga seotud pädevusalad ja registrid`; `Treeningu aktiveerimise tegevusdiagramm`; `Pädevusalad`; `Isikute register`; `Töötajate register`; `Treeningute registrite füüsiline disain`.
- Course/template constraints captured in `instruction_guides/`: complete structure, no placeholders `X/Y/<täienda>`, Estonian consistency, high-level/extended use-case rules, DB operation contracts, attribute definition rules, CRUD matrix rules, diagram checks, typical-project-error checks.
- Intentional omissions: Andmebaasid II/Oracle continuation headings omitted from generated DOCX; booking/payment/attendance/membership/deployment/full admin UI out of scope; `PROJECT_EXPLAINER_NOT_FOR_SUBMISSION.md` explicitly non-submittable.

## 10. Current Known Issues / Risks / TODOs
- P0: none discovered by static validator.
- P1: Manual Sparx Enterprise Architect visual inspection is still required by README/checklist; validator checks MDB tables but cannot prove EA GUI layout/readability.
- P1: PostgreSQL live smoke test and Flask browser walkthrough were not run in this inspection; validator is static/packaging oriented.
- P1: `FINAL_SUBMISSION_CHECKLIST.md` says confirm whether TalTech PostgreSQL server upload is required; current repo does not prove that has happened.
- P2: App duplicates DB routines instead of calling `fn_registreeri_treening`, `fn_aktiveeri_treening`, `fn_lopeta_treening`, `fn_kasutaja_tuvastamise_andmed`; future schema/rule edits must keep direct SQL and routines synchronized.
- P2: DB role/grant model is broad (`jousaali_rakendus` CRUD on all tables); business authorization is mainly app-level.
- P2: Documented timestamp range rules for `reg_aeg`, `alguse_aeg`, `lopu_aeg` are not fully represented by SQL CHECKs; only birth date and ordering are enforced.
- P2: Prototype lacks production security hardening (notably CSRF, deployment hardening, audit/logging depth), explicitly acknowledged as out of scope.
- P2: `Klassifikaatorite haldur` and `Töötajate haldur` are modeled/documented and seeded as possible roles, but prototype UI mainly implements trainer/manager/client/public flows.
- P2: Git worktree is dirty and contains untracked project-support files; future agents must not assume repository state is committed or clean.
- P3: `.gitignore` lists `submission_files/`, but existing submission files are tracked/modified; do not rely on ignore behavior for these tracked deliverables.
- P3: EAP diagram name `Treeningute registrite füüsiline disain` differs grammatically from common singular `Treeningute register`/DOCX physical-model wording; validator accepts it.

## 11. Important Exact Names
- Tables: `riik`, `isiku_seisundi_liik`, `tootaja_seisundi_liik`, `tootaja_roll`, `treeningu_seisundi_liik`, `treeningu_kategooria_tyyp`, `treeningu_kategooria`, `isik`, `kasutajakonto`, `tootaja`, `tootaja_rolli_omamine`, `treening`, `treeningu_kategooria_omamine`.
- Columns: `riigi_kood`, `kood`, `nimetus`, `on_aktiivne`, `kirjeldus`, `treeningu_kategooria_tyyp_kood`, `isikukood`, `isiku_seisundi_liik_kood`, `synni_kp`, `reg_aeg`, `viimase_muutm_aeg`, `eesnimi`, `perenimi`, `elukoht`, `e_meil`, `parool`, `tootaja_seisundi_liik_kood`, `tootaja_e_meil`, `tootaja_roll_kood`, `alguse_aeg`, `lopu_aeg`, `treeningu_kood`, `treeningu_seisundi_liik_kood`, `registreerija_e_meil`, `viimase_muutja_e_meil`, `kestus_minutites`, `maksimaalne_osalejate_arv`, `vajalik_varustus`, `hind`, `treeningu_kategooria_kood`.
- Domains/sequence/views/functions/triggers/roles: `kood_10`, `e_meil_aadress`, `raha_mitte_negatiivne`, `seq_treeningu_kood`, `v_treeningud_kategooriatega`, `v_aktiivsed_treeningud`, `v_treeningute_arv_seisundi_kaupa`, `v_treeningute_arv_kategooria_kaupa`, `fn_kasutaja_tuvastamise_andmed`, `fn_registreeri_treening`, `fn_aktiveeri_treening`, `fn_lopeta_treening`, `fn_treening_initial_status`, `fn_treening_status_transition`, `fn_treening_prevent_active_categoryless`, `trg_treening_initial_status`, `trg_treening_status_transition`, `trg_treening_no_active_without_category`, `jousaali_rakendus`, `jousaali_vaatleja`.
- Classifier/status codes: `EE`, `LV`, `LT`, `KLIENT`, `TOOTAJA`, `AKTIIVNE`, `PUHKUSEL`, `LAHKUNUD`, `TREENER`, `JUHATAJA`, `KL_HALDUR`, `TOO_HALD`, `OOTEL`, `MITTEAKT`, `LOPPENUD`, `UNUSTATUD`, `GRUPP`, `PERS`, `KARDIO`, `JÕUD`, `VENITUS`, `RING`.
- Actors/entities/course terms: `Treener`, `Juhataja`, `Klient`, `Uudistaja`, `Klassifikaatorite haldur`, `Töötajate haldur`, `Klassifikaator`, `Riik`, `Isik`, `Kasutajakonto`, `Töötaja`, `Treening`, `Treeningute register`, `Treeningute funktsionaalne allsüsteem`, `Andmebaasid I`, `ITI0206`, `Sparx Enterprise Architect`, `Maurus`.
- Artifacts/files: `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx`, `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap`, `jousaali_skript.sql`, `submission_files/dokument.docx`, `submission_files/mudelid.eap`, `submission_files/skript.sql`, `submission_files/rakendus.zip`, `rakendus/app.py`, `rakendus/test_data.sql`.

## 12. AI Continuation Notes
- Inspect first: `tools/sql_ddl.py`, `jousaali_skript.sql`, `tools/fill_report_docx.py`, `rakendus/app.py`, `tools/validate_project.py`, then `README.md`/`FINAL_SUBMISSION_CHECKLIST.md`.
- Do not hand-edit derived outputs as source of truth: regenerate root DOCX/EAP/SQL and `submission_files/` via `./build_all.sh` after source/tool changes.
- Do not accidentally include `PROJECT_EXPLAINER_NOT_FOR_SUBMISSION.md` in `submission_files/` or `rakendus.zip`.
- Preserve Estonian exact names/codes; note SQL physical `treeningu_kategooria_tyyp` uses ASCII `tyyp`, while conceptual/docs may use `tüüp`.
- Fragile assumptions: app depends on PostgreSQL schema existing; `.env` defaults to `DB_NAME=jousaali`, user/password `postgres`; no migrations; current demo passwords rely on Werkzeug PBKDF2 compatibility.
- Validation commands: `./build_all.sh`; `.venv/bin/python tools/validate_project.py`; optional PostgreSQL: `createdb jousaali_ddl_check && psql -v ON_ERROR_STOP=1 -d jousaali_ddl_check -f jousaali_skript.sql && dropdb jousaali_ddl_check`; app smoke from `rakendus/`: `psql -U postgres -v ON_ERROR_STOP=1 -d jousaali_smoke -f ../submission_files/skript.sql`, `psql ... -f test_data.sql`, `python app.py`, `curl -fsS http://127.0.0.1:5000/trainings`.
- Likely next tasks: run full build after any edits; live DB/app smoke test; manual EA open/layout review; decide/confirm TalTech PostgreSQL upload; optionally reduce app/DB routine duplication or add CSRF only if project scope allows.

```text
MACHINE_CONTEXT
project_root=/Users/gustav/andmebaasid-projekt
project_name=Jõusaali infosüsteemi treeningute funktsionaalne allsüsteem
course=Andmebaasid I, ITI0206, 2026 kevad
authors=Tristan Aik Sild|Gustav Tamkivi
dbms=PostgreSQL
app=Python Flask + psycopg2 + Jinja + Bootstrap
central_table=treening
central_object=Treening
source_sql=tools/sql_ddl.py
generated_sql=jousaali_skript.sql
report_source=tools/fill_report_docx.py
validator=tools/validate_project.py
build=./build_all.sh|build_all.bat
final_docx=Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx
final_eap=Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap
submission=submission_files/dokument.docx|submission_files/mudelid.eap|submission_files/skript.sql|submission_files/rakendus.zip
tables=riik,isiku_seisundi_liik,tootaja_seisundi_liik,tootaja_roll,treeningu_seisundi_liik,treeningu_kategooria_tyyp,treeningu_kategooria,isik,kasutajakonto,tootaja,tootaja_rolli_omamine,treening,treeningu_kategooria_omamine
states=OOTEL,AKTIIVNE,MITTEAKT,LOPPENUD,UNUSTATUD
state_transitions=OOTEL->AKTIIVNE|UNUSTATUD;AKTIIVNE->MITTEAKT|LOPPENUD;MITTEAKT->AKTIIVNE|LOPPENUD
roles=TREENER,JUHATAJA,KL_HALDUR,TOO_HALD
actors=Treener,Juhataja,Klient,Uudistaja,Klassifikaatorite haldur,Töötajate haldur
key_rules=Treening starts OOTEL; active needs category; active cannot lose last category; clients/public see only AKTIIVNE; duration 15..240; participants>0; price>=0; unique treening.nimetus; sequence starts 1000
validation_last=.venv/bin/python tools/validate_project.py => passed
not_verified=full build this inspection; live PostgreSQL smoke; Flask browser flow; manual Sparx EA visual inspection
known_risks=dirty git tree; app direct SQL duplicates DB routines; broad DB grants; no CSRF; admin roles mostly modeled not UI; documented timestamp ranges partly not SQL-enforced
```
