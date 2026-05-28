# Final Submission Verification Audit

## 1. Executive verdict

**Not ready: blockers remain.**

The regenerated DOCX, SQL, diagram PNGs, and submission copies build successfully, render successfully, and pass the project validators. The main remaining submission blockers are model parity issues:

- the submitted EAP still does not reflect the canonical DOCX/Mermaid conceptual model;
- the DOCX/Mermaid use-case diagram still contains use cases and `<<include>>` relations that do not match the textual use-case list.

The project is close, but it should not be submitted until these two parity blockers are fixed or explicitly accepted by the professor/TA.

## 2. Validation commands run

| Command | Status | Important output |
|---|---:|---|
| `git status --short` | Pass | Working tree has expected modified generated/source files plus untracked `docs/`. |
| `./build_all.sh` | Pass | Rendered Mermaid diagrams, rebuilt DOCX/EAP/SQL, refreshed `submission_files/`. |
| `git diff --check` | Pass | No whitespace errors reported. |
| `.venv/bin/python tools/validate_project.py` | Pass | All validation checks passed. Root/submission DOCX/EAP/SQL match. Mermaid images are fresh and nonblank. |
| `cmp -s root DOCX/EAP/SQL submission_files copies` | Pass | `docx_cmp=0`, `eap_cmp=0`, `sql_cmp=0`. |
| `textutil -convert txt -stdout submission_files/dokument.docx` | Pass | Text extraction completed; no old combined subsystem/register names found in extracted DOCX text. |
| `render_docx.py submission_files/dokument.docx --output_dir work/final_verification_render --emit_pdf` | Pass | Rendered 72 pages; no blank/broken pages seen in contact-sheet and targeted page inspection. |
| `mdb-export ... t_object/t_diagram/t_package` | Pass with findings | EAP could be inspected; parity blockers found. |
| `.venv/bin/python tests/database/run_database_validation.py` | Pass with warnings | 292 passed, 0 failed, 33 warnings, 12 skipped. Warnings are SQL/DB design risks, not direct DOCX blockers. |

## 3. Artifact/source parity

| Source/artifact pair | Status | Evidence | Issues |
|---|---:|---|---|
| `tools/fill_report_docx.py` -> root DOCX | Pass | `./build_all.sh` regenerated `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx`. | None found in generation. |
| Root DOCX -> `submission_files/dokument.docx` | Pass | `cmp` returned `docx_cmp=0`; validator confirms exact match. | None. |
| `tools/sql_ddl.py` -> root SQL -> `submission_files/skript.sql` | Pass | Validator confirms generated SQL matches source and submission SQL. | Database validation reports warnings about active destructive setup SQL and FK action review. |
| `diagrams/*.mmd` -> `work/generated_diagrams/*.png` | Pass | Validator confirms all 15 rendered images are fresh, nonblank, and readable-sized. | Use-case source content still has semantic mismatches; see Blocker 2. |
| Mermaid PNGs -> DOCX embedded diagrams | Mostly pass | DOCX contains 15 inline images and rendered pages show the diagrams. | Joonis 2 embeds the current but semantically mismatched use-case diagram. |
| Root EAP -> `submission_files/mudelid.eap` | Pass for byte copy | `cmp` returned `eap_cmp=0`; validator confirms exact match. | Both copies share the same EAP parity problems; see Blocker 1. |
| DOCX/Mermaid conceptual model -> EAP model | Fail | `mdb-export` shows missing/stale conceptual EAP content compared with DOCX/Mermaid. | Blocker 1. |

## 4. Remaining blockers

### Blocker 1: Submitted EAP is not in parity with the regenerated DOCX/Mermaid model

- **Location:** `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap`; `submission_files/mudelid.eap`; EAP generation code in `tools/EapFixes.java`.
- **Evidence:**
  - `tools/EapFixes.java`, `removeNonSubmittedTemplateObjects`, explicitly deletes `Class` object named `Klassifikaator` when `Package_ID == 11`.
  - `tools/validate_project.py` still treats absence of generic `Klassifikaator` in EAP as a pass: `EAP contains no generic Klassifikaator class in the classifier register`.
  - `mdb-export ... t_object` shows EAP has classifier classes `Riik`, `Treeningukorra_seisundi_liik`, `Töötaja_seisundi_liik`, `Isiku_seisundi_liik`, `Töötaja_roll`, etc., but no `Klassifikaator` class, while the DOCX/Mermaid model contains `Klassifikaator`.
  - EAP still contains `Class` object `Juhataja` with attributes `juhataja_roll` and `rolli_kehtivus`, while DOCX/Mermaid removed `Juhataja` as a conceptual entity.
  - EAP actors are only `Treener`, `Juhataja`, `Klient`, `Süsteem`, `Aeg`; EAP is missing `Töötajate haldur` and `Klassifikaatorite haldur`.
  - EAP has use case `Vaata täituvuse statistikat`, while the canonical text/Mermaid name is `Vaata treeningukordade täituvuse statistikat`.
  - EAP packages include `Isikute register`, `Klassifikaatorite register`, `Töötajate register`, `Registreeringute register`, but not the full canonical register set: `Treeningukordade register`, `Treeninguliikide register`, `Osalemiste register`, `Treenerite register`, `Klientide register`.
- **Why it violates instructions:** The submission itself states that models are represented in EAP and Mermaid/DOCX. `docs/RULE_SOURCE_TRACE_AUDIT.md` classifies `Klassifikaator`, subsystem/register naming, and diagram/model consistency as source-supported or checklist-supported. A submitted EAP that lacks the new canonical entities/actors/registers can contradict the DOCX and be graded as stale.
- **Exact required fix:**
  - Update `preset_files/EA_converted_source.eap` or the Java EAP patching tools so EAP contains the same canonical actors, use cases, conceptual entities, classifier supertype, and register packages as the DOCX/Mermaid model.
  - Remove stale conceptual `Juhataja` class unless it is also defined in the document.
  - Add `Klassifikaator` as a generic conceptual class where classifier subtypes are modeled.
  - Add/update `Töötajate haldur`, `Klassifikaatorite haldur`, canonical register packages, and `Vaata treeningukordade täituvuse statistikat`.
  - Update `tools/validate_project.py` so it no longer passes the absence of generic `Klassifikaator` after the DOCX model requires it.
- **Files likely affected:** `preset_files/EA_converted_source.eap`, `tools/EapFixes.java`, possibly `tools/EapRename.java`, `tools/validate_project.py`, root `.eap`, `submission_files/mudelid.eap`.

### Blocker 2: Use-case diagram labels do not match the textual use-case list

- **Location:** `diagrams/02_use_cases.mmd`; rendered `work/generated_diagrams/02_use_cases.png`; embedded DOCX `Joonis 2`; textual use-case table in `tools/fill_report_docx.py` / DOCX `Tabel 11`.
- **Evidence:**
  - `diagrams/02_use_cases.mmd` contains use cases not present in the high-level use-case table:
    - `Vaata tunniplaani`
    - `Sulge enda treeningukorra registreerimine`
    - `Rakenda registreerimise tähtaja tingimus`
  - The canonical high-level list contains `Vaata treeningukorra registreeringuid`, `Sulge registreerimine`, `Lõpeta treeningukord`, etc., but not the three names above.
  - The diagram contains `Ava registreerimine -. <<include>> .-> Planeeri treeningukord`, but the extended scenario for `Ava registreerimine` does not call `Planeeri treeningukord`.
  - The diagram contains `Sulge registreerimine` / `Sulge enda treeningukorra registreerimine` includes to `Rakenda registreerimise tähtaja tingimus`, but `Rakenda registreerimise tähtaja tingimus` is not a textual use case.
- **Why it violates instructions:** `docs/RULE_SOURCE_TRACE_AUDIT.md` traces UC diagram exact name/actor/include consistency to `instruction_guides/Koond.txt`, lines 889-901. Here the mismatch is visible in source and rendered DOCX, not a diagram-extraction uncertainty.
- **Exact required fix:**
  - Rename or remove diagram-only use cases so the diagram uses exactly the canonical textual use-case names, or add matching textual use cases if they are intentionally separate.
  - Remove `Ava registreerimine -> Planeeri treeningukord` include unless the scenario explicitly invokes `Planeeri treeningukord`.
  - Either replace `Rakenda registreerimise tähtaja tingimus` with a textual use case and extended description or remove it as a separate UC node and show it as a condition/note.
  - Re-render diagrams and regenerate DOCX/submission files.
- **Files likely affected:** `diagrams/02_use_cases.mmd`, `tools/fill_report_docx.py` if textual use cases are added/renamed, root DOCX, `submission_files/dokument.docx`, EAP use-case model.

## 5. Warnings / manual review items

### DOCX visual warnings

1. `Tabel 11. Olulisemad kasutusjuhud` splits a row across rendered pages 8-9 without a repeated table header. The content is still readable, but the split is visually awkward.
2. `Tabel 24` and `Tabel 25` CRUD matrices render without clipping, but the column headers are very narrow and break words into short vertical fragments. This is readable with effort, but visually dense.
3. The SQL appendix pages 50-72 are dense code pages. They render, but they are not visually pleasant; this is acceptable if full SQL inclusion is expected.

### EAP manual review warnings

1. Full EAP visual diagram layout was not verified inside Enterprise Architect. Database-table exports were inspected via `mdb-export`, which is enough to find content parity problems but not visual layout issues.
2. After EAP content fixes, manually open `submission_files/mudelid.eap` in Enterprise Architect and verify diagrams, packages, actors, entities, relationships, state transitions, and physical model views visually.

### Professor/TA clarification items

1. Read-only OP contracts: OP10-OP16 are referenced/listed but not formalized as operation contracts. The source trace treats OP references as supported but the hard requirement/prohibition for read-only contracts as questionable.
2. Exact two-step report use case: `Vaata treeningukordade täituvuse statistikat` is specific and has OP references, but the exact two-step report-use-case rule remains a clarification item.
3. Payment actors: `Pank`/`Maksekeskus` were not added because payment processing is out of scope.
4. Exact high-level ↔ extended use-case 1:1 coverage: five high-level use cases still lack extended descriptions. The exact 1:1 rule is checklist-derived; clarify before large rewrites.

### Language/style warnings

1. Mixed terminology remains between conceptual prose and SQL/code identifiers: `e-post`, `e-meil`, and physical `e_meil`.
2. Some use-case prose leaks code-like values, e.g. `on_osalenud/ei osalenud` in `Märgi osalemine`; prefer human wording such as `osales / ei osalenud`.
3. Some OP parameter names use ASCII approximations (`p_tyh_pohjus`, `p_lopp`) while surrounding contract prose uses Estonian diacritics. This is acceptable in parameter names, but should stay consistent.
4. `Süsteem` is listed as a tegutseja but not as a pädevusala. This may be acceptable as an automatic actor, but it is worth confirming if strict actor/pädevusala 1:1 is enforced.

### Validation warnings

1. Database validation passed but reported 33 warnings: active destructive setup SQL, FK referential-action review items, and one query-plan smoke warning for roster lookup not visibly using the intended index.
2. These are implementation-quality warnings rather than direct system-analysis document blockers.

## 6. Language and terminology findings

| Severity | Location | Finding | Recommendation |
|---|---|---|---|
| Warning | DOCX / `tools/fill_report_docx.py`, `Märgi osalemine` scenario | `on_osalenud/ei osalenud` mixes a code identifier with human prose. | Use `osales / ei osalenud` in prose, leave `on_osalenud` only in SQL/physical model contexts. |
| Warning | Conceptual text vs physical SQL | `e-post`, `e-meil`, `e_meil` are all present in different layers. | Keep `e-post` or `e-meil` in prose consistently; reserve `e_meil` for physical identifiers. |
| Warning | OP contracts | Parameters such as `p_tyh_pohjus` are ASCII-only while attributes/prose use `tühistamise_põhjus`. | Acceptable if the course allows ASCII parameters; otherwise normalize parameter naming style. |
| Style improvement | DOCX page 8-9 | Table row split is visually awkward. | Configure table rows not to split or repeat header rows. |

No obvious Estonian grammar issue was severe enough to classify as a blocker in the inspected text. The biggest language risk is terminology/code leakage, not basic grammar.

## 7. Canonical list parity check

### Põhiobjektid

Status: internally consistent in DOCX/Mermaid, not in EAP.

- Registreering
- Treeningukord
- Treeninguliik
- Isik
- Töötaja
- Klient
- Treener
- Klassifikaator

### Tegutsejad

Status: internally consistent in DOCX text; EAP missing two actors.

- Juhataja
- Töötajate haldur
- Klassifikaatorite haldur
- Treener
- Klient
- Süsteem
- Aeg

### Pädevusalad

Status: DOCX list is consistent with human/internal roles; automatic actors are excluded.

- Juhataja
- Töötajate haldur
- Klassifikaatorite haldur
- Treener
- Klient

### Funktsionaalsed allsüsteemid

Status: DOCX text consistent; EAP package structure incomplete.

- Registreeringute funktsionaalne allsüsteem
- Treeningukordade funktsionaalne allsüsteem
- Treeninguliikide funktsionaalne allsüsteem
- Osalemiste funktsionaalne allsüsteem
- Treenerite funktsionaalne allsüsteem
- Isikute funktsionaalne allsüsteem
- Töötajate funktsionaalne allsüsteem
- Klientide funktsionaalne allsüsteem
- Klassifikaatorite funktsionaalne allsüsteem

### Registrid

Status: DOCX text consistent; EAP package structure incomplete.

- Registreeringute register
- Treeningukordade register
- Treeninguliikide register
- Osalemiste register
- Treenerite register
- Isikute register
- Töötajate register
- Klientide register
- Klassifikaatorite register

### Use cases

Status: textual use-case list is consistent; use-case diagram and EAP are not fully aligned.

- Vaata vabu treeningukordi
- Esita registreering
- Vaata enda registreeringuid
- Tühista enda registreering
- Edenda ootel registreering
- Vaata treeningukorra registreeringuid
- Märgi osalemine
- Sulge registreerimine
- Lõpeta treeningukord
- Tühista treeningukord
- Planeeri treeningukord
- Ava registreerimine
- Vaata treeningukordade täituvuse statistikat

### Olemitüübid

Status: DOCX/Mermaid mostly aligned; EAP has stale/missing conceptual classes.

- Isik
- Kasutajakonto
- Töötaja
- Klient
- Treener
- Töötaja rolli omamine
- Treeningukord
- Registreering
- Ootejärjekorra koht
- Osalemine
- Treeninguliik
- Ruum
- Varustus
- Treeneri pädevus
- Ruumi varustatus
- Varustuse nõue
- Klassifikaator
- Seisund
- Roll
- Riik

### OPs

Status: write OP contracts exist; read OPs are referenced/listed without contracts by design.

- OP1 `fn_planeeri_treeningukord`
- OP2 `fn_ava_treeningukord`
- OP3 `fn_sulge_treeningukord`
- OP4 `fn_lopeta_treeningukord`
- OP5 `fn_registreeri_klient_treeningukorrale`
- OP6 `fn_tyhista_registreering`
- OP7 `fn_edenda_ootejarjekorrast`
- OP8 `fn_marki_osalemine`
- OP9 `fn_tyhista_treeningukord`
- OP10 `Loe planeerimiseks aktiivsed treeninguliigid, ruumid ja treenerid`
- OP11 `Loe juhatajale treeningukordade haldamise ülevaade`
- OP12 `Loe kliendile avalikud ja vabade kohtadega treeningukorrad`
- OP13 `Loe kliendi enda registreeringud`
- OP14 `Loe treenerile või juhatajale lubatud treeningukorrad`
- OP15 `Loe treeningukorra registreeringud ja osalejad`
- OP16 `Loe treeningukordade täituvuse statistika`

## 8. Use-case and OP parity

| OP | Type | Referenced where | Contract/listed where | Status | Issues |
|---|---|---|---|---|---|
| OP1 | Write | `Planeeri treeningukord` | Formal contract | Pass | None found. |
| OP2 | Write | `Ava registreerimine` | Formal contract | Pass | None found. |
| OP3 | Write | `Sulge registreerimine`; state diagram | Formal contract | Pass | No extended use case for `Sulge registreerimine`; coverage warning. |
| OP4 | Write | `Lõpeta treeningukord`; state diagram | Formal contract | Pass | No extended use case for `Lõpeta treeningukord`; coverage warning. |
| OP5 | Write | `Esita registreering` | Formal contract | Pass | None found. |
| OP6 | Write | `Tühista enda registreering` | Formal contract | Warning | Conditional assignment `TYH_KL või TYH_SYS` is understandable but less formal than separate operations/branches. |
| OP7 | Write/internal | `Edenda ootel registreering`; cancellation flow | Formal contract | Pass | No standalone extended use case; coverage warning. |
| OP8 | Write | `Märgi osalemine` | Formal contract | Pass | Prose uses code-like `on_osalenud`. |
| OP9 | Write | `Tühista treeningukord` | Formal contract | Pass | None found. |
| OP10 | Read | `Planeeri treeningukord` | Read OP list | Warning | No formal read contract by design. |
| OP11 | Read | `Planeeri`, `Ava`, `Tühista treeningukord` | Read OP list | Warning | No formal read contract by design. |
| OP12 | Read | `Esita registreering`; high-level `Vaata vabu treeningukordi` | Read OP list | Warning | No extended `Vaata vabu treeningukordi`; no formal read contract. |
| OP13 | Read | `Vaata enda registreeringuid`, `Tühista enda registreering` | Read OP list | Warning | No formal read contract by design. |
| OP14 | Read | `Märgi osalemine` | Read OP list | Warning | No formal read contract by design. |
| OP15 | Read | `Märgi osalemine`; high-level `Vaata treeningukorra registreeringuid` | Read OP list | Warning | No extended `Vaata treeningukorra registreeringuid`; no formal read contract. |
| OP16 | Read | `Vaata treeningukordade täituvuse statistikat` | Read OP list | Warning | No formal read contract by design. |

High-level use cases without extended descriptions:

- `Vaata vabu treeningukordi`
- `Edenda ootel registreering`
- `Vaata treeningukorra registreeringuid`
- `Sulge registreerimine`
- `Lõpeta treeningukord`

This is a warning/professor-clarification item unless the exact same-name 1:1 checklist rule is enforced as a blocker.

## 9. Attribute/ERD parity

Status: mostly pass in DOCX/Mermaid; EAP parity fails.

- Attribute definitions in `tools/fill_report_docx.py` all have explanation before `{}`, non-empty constraints inside `{}`, and `Näiteväärtus:`.
- No `_id` suffixes, `tabel`, `veerg`, `primaarvõti`, or `välisvõti` terms were found in the conceptual attribute definition strings.
- DOCX/Mermaid adds `Klassifikaator` with `kood`, `nimetus`, `tähendus`, `aktiivsus`; rendered page 25 shows `KLASSIFIKAATOR`.
- Mermaid ERDs no longer show `Juhataja` as a class.
- EAP still has conceptual `Juhataja` class and lacks generic `Klassifikaator` class, so EAP is not in parity with attribute/entity definitions.

## 10. Diagram audit

### UC diagrams

Status: fail due Blocker 2.

- Mermaid/DOCX Joonis 2 contains diagram-only use cases: `Vaata tunniplaani`, `Sulge enda treeningukorra registreerimine`, `Rakenda registreerimise tähtaja tingimus`.
- Mermaid/DOCX Joonis 2 contains include relations that do not cleanly map to scenario text.
- EAP use-case model has stale `Vaata täituvuse statistikat` instead of `Vaata treeningukordade täituvuse statistikat`.

### ERDs

Status: DOCX/Mermaid mostly pass; EAP fail.

- Mermaid register ERDs render and include `Klassifikaator`.
- Mermaid no longer has `Juhataja` entity.
- EAP still has `Juhataja` conceptual class and no generic `Klassifikaator` conceptual class.

### State diagrams

Status: DOCX/Mermaid pass.

- `diagrams/05_session_state.mmd` transitions include OP1, OP2, OP3, OP4, OP9.
- `diagrams/06_registration_state.mmd` transitions include OP5, OP6, OP7, OP9.
- No placeholder events or decision diamonds were observed in these Mermaid state diagrams.

### Physical DB diagrams

Status: generated physical section and SQL pass validators; EAP physical classes pass existing validator.

- `tools/validate_project.py` confirms required physical EAP classes/tables, attributes, and connectors.
- Generated SQL passes static and live PostgreSQL validation with warnings.

### EAP parity

Status: fail due Blocker 1.

Verified with `mdb-export`:

- EAP can be read.
- Root and submission EAP are identical.
- Physical model checks pass the existing validator.
- Conceptual/model parity with DOCX/Mermaid fails.

Manual Enterprise Architect review still required after EAP content is fixed:

1. Open `submission_files/mudelid.eap`.
2. Confirm package list matches canonical registers and subsystems.
3. Confirm actor list includes `Töötajate haldur` and `Klassifikaatorite haldur`.
4. Confirm use-case diagram names match DOCX `Tabel 11`.
5. Confirm no `Juhataja` class remains unless defined.
6. Confirm `Klassifikaator` appears as the generic classifier type.
7. Confirm state transitions show OP references.
8. Confirm physical model matches `submission_files/skript.sql`.

## 11. CRUD audit

Status: structurally pass, visually dense.

- Rows are entity types, not actors/pädevusalad.
- Columns are use cases.
- Final `Kokku` column exists.
- Cells use only empty values and `C`, `R`, `U`, `D` combinations; no `-` or `C/U` found in the generated matrix.
- Row summaries appear consistent with row letters in inspected pages.
- Rendered pages 40-41 show no clipping, but table headers are very narrow and hard to read.

## 12. Items intentionally not treated as blockers

- Read-only OP contracts: OP10-OP16 are not formal contracts; this remains a professor/TA clarification item.
- Exact two-step report-use-case rule: not enforced as a blocker.
- Payment actor requirement: `Pank`/`Maksekeskus` not required here because payment processing is out of scope.
- High-level ↔ extended 1:1 coverage: documented as warning/clarification, not blocker, although it remains a real risk if `Koond.txt` is applied strictly.
- Database validation warnings: no failures; warnings should be reviewed but are not direct final-submission document blockers.
- EAP visual layout: not fully verified in Enterprise Architect; content parity issues are already blockers.

## 13. Final safe-to-submit checklist

- [x] DOCX generated and renders.
- [x] Submission DOCX copied from root DOCX.
- [x] SQL generated and copied.
- [x] EAP present and copied.
- [ ] EAP model parity verified.
- [ ] EAP manually reviewed in Enterprise Architect.
- [x] Mermaid diagrams present, fresh, and readable.
- [!] Use-case diagram matches text.
- [x] CRUD structurally valid.
- [!] CRUD visually dense but not clipped.
- [x] No stale combined subsystem/register names found in DOCX text extraction.
- [x] `Klassifikaator` consistent in DOCX/Mermaid.
- [ ] `Klassifikaator` consistent in EAP.
- [x] Attribute definitions formatted.
- [x] Data-changing OP contracts formatted.
- [x] State transitions include OP references in Mermaid/DOCX.
- [x] Project validation passed.
- [x] Database validation passed with warnings.
- [x] Git status understood.

## 14. Final recommendation

Do **not** submit yet.

Next steps:

1. Fix EAP conceptual parity and update the EAP validator so it expects the same `Klassifikaator`, actors, use cases, and register packages as the DOCX/Mermaid model.
2. Fix `diagrams/02_use_cases.mmd` so Joonis 2 exactly matches the canonical textual use-case list and supported include relations.
3. Re-run `./build_all.sh`, `git diff --check`, `.venv/bin/python tools/validate_project.py`, DOCX rendering, `mdb-export` EAP checks, and database validation.
4. Open `submission_files/mudelid.eap` manually in Enterprise Architect before final submission.

After those fixes, the remaining issues look like warnings/manual-review items rather than blockers.
