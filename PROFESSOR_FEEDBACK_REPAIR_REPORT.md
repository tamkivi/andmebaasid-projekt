# Final Professor-Style Conceptual Balance Audit

## A. Executive summary

The previous repair narrowed the project correctly, but it overcorrected in three places: `Treeninguliik` was too classifier-like, `Osalemine` was too weak for an attendance register, and `Treener` was visible mostly as an actor instead of also being a maintained specialization of `Töötaja`.

The model is now rebalanced without expanding the scope. The subsystem remains a focused rühmatreeningute registreeringute allsüsteem. `Registreering` remains the central lifecycle object, but the model also recognizes `Treeningukord`, `Treeninguliik`, `Isik`, `Töötaja`, `Klient` and `Treener` as strong conceptual objects in this scope. `Osalemine` and `Treeneri pädevus` are dependent, lifecycle-bearing concepts.

Remaining risks are mainly presentation risks: some generated diagrams are intentionally compact, and the EAP should still be opened manually before submission for visual layout review.

## B. Instruction-guide / tüüpvead audit

Inspected guidance:

- `instruction_guides/Projekti_tyypvead_ITI0206_2026.pdf`
- `instruction_guides/Koond.txt`
- `instruction_guides/Registri_eskiismudel.txt`

Relevant warnings:

- Do not create a conceptual model with too few entity types.
- Do not choose a classifier/admin subsystem as the main domain.
- Do not split the model mechanically by actor role.
- Do not make use cases generic CRUD-row examples.
- Do not model conceptual ERD as physical tables, keys, foreign keys, triggers or indexes.
- Show generalization/specialization when person roles require it.
- Keep registers tied to meaningful maintained objects and lifecycles.

Applied repair:

- `Treeninguliik` is no longer hidden in classifiers.
- `Treener` is a `Töötaja` specialization and a conceptual object in this subsystem.
- `Osalemine` is a dependent event/result object, not an incidental helper.
- Classifiers are limited to true value lists: `Seisund`, `Roll`, `Riik`.
- Conceptual text avoids PostgreSQL-specific wording; physical implementation details remain in physical sections.

## C. Final concept classification table

| Concept | Final classification | Lifecycle strength | Why this classification is correct | Where it appears |
| --- | --- | --- | --- | --- |
| Isik | põhiobjekt | full | General person object; clients and employees specialize it. | report generator, people diagram, conceptual overview |
| Töötaja | põhiobjekt, Isik specialization | full | Employee relationship has role/status validity and business responsibilities. | report generator, people diagram, EAP |
| Klient | põhiobjekt, Isik specialization | full | Client can register, cancel, view registrations and has membership status. | report generator, people diagram, EAP |
| Treener | põhiobjekt, Töötaja specialization, actor | full | Trainer has sessions, competences, schedule responsibilities and attendance workflow. | report generator, use-case diagram, people/session/attendance diagrams, EAP |
| Registreering | central põhiobjekt | full | Main lifecycle object: created, confirmed/waitlisted, cancelled, promoted, concluded through attendance. | report generator, state/activity diagrams, CRUD matrix |
| Treeningukord | põhiobjekt | full | Scheduled session has planning/open/closed/completed/cancelled lifecycle. | report generator, session diagrams, EAP |
| Treeninguliik | catalog/master-data põhiobjekt | full/limited | Managed reusable training concept with description, duration, usability state, competence and equipment rules. | report generator, conceptual overview, session register, EAP |
| Osalemine | dependent lifecycle-bearing result object | dependent | Attendance result depends on a confirmed registration but has marking/update/reporting events. | report generator, attendance diagram, EAP |
| Ootejärjekorra koht | dependent relationship object | dependent | Exists as queue position for a waiting registration; lifecycle follows registration. | report generator, registration diagrams |
| Treeneri pädevus | dependent lifecycle-bearing relationship object | dependent | Validity-based relationship between trainer and training type; affects planning. | report generator, session diagram, EAP |
| Pädevusala | supporting concept | limited | Describes competence/responsibility area; not the system and not the central object. | report generator/EAP as trainer competence support |
| Ruum | supporting resource object | limited | Relevant to scheduled sessions and capacity, but not a facility-management lifecycle here. | report generator, session register |
| Varustus | supporting resource/master-data object | limited | Used for session requirements and room suitability; not inventory lifecycle. | report generator, session register |
| Seisund | klassifikaator | none | Value list for lifecycle states. | classifier diagram, report generator |
| Roll | klassifikaator | none | Value list for employee permissions/specializations. | people/classifier diagrams |
| Konto | administrative support object | limited | Access/authentication support, not a business core object. | report generator, people diagram |

## D. Promotions and demotions

Promoted:

- `Treener` to conceptual `põhiobjekt` as `Töötaja` specialization.
- `Treeninguliik` to catalog/master-data `põhiobjekt`.
- `Osalemine` to dependent lifecycle-bearing result object.
- `Treeneri pädevus` to dependent lifecycle-bearing relationship object.

Demoted or kept constrained:

- `Pädevusala` remains controlled support, not subsystem identity.
- `Seisund`, `Roll`, `Riik` remain classifiers.
- `Konto` remains administrative support.
- `Ruum` and `Varustus` remain supporting resources, not full facility/inventory domains.

Intentionally not promoted:

- `Juhataja` remains a `Töötaja` role/specialization and actor, not an additional strong core object.
- Equipment inventory, payroll, pricing, campaigns, entry control and maintenance remain outside scope.

## E. Treeninguliik decision

`Treeninguliik` is a catalog/master-data business object, not a classifier. Repository evidence supports this: it has descriptive content, typical duration, usability state, trainer competence relationships, equipment requirements and independent management operations. It exists before and outside any single `Treeningukord`.

## F. Osalemine decision

`Osalemine` is not an independent top-level object, but it is stronger than a passive support row. It is a dependent lifecycle-bearing attendance/result object. It depends on `Registreering`, yet the marking event, later correction, marker, timestamp and reporting value give it distinct business meaning.

## G. People/role model

The model now uses specialization explicitly:

- `Isik` is the general person concept.
- `Klient` specializes `Isik`.
- `Töötaja` specializes `Isik`.
- `Treener` specializes `Töötaja` and is both actor and conceptual object.
- `Juhataja` specializes `Töötaja` as an actor/management role, but is not promoted to a separate strong core object.

This avoids confusing actor names with entity types while still allowing a concept to be both an actor and a maintained business object.

## H. Diagram audit

Changed and regenerated diagrams:

- system context
- use-case diagram
- conceptual overview ER diagram
- registration activity
- session state
- registration state
- waitlist sequence
- attendance activity
- people register
- training sessions register
- registrations register
- attendance register
- classifiers register

The split register diagrams remain, but the conceptual overview now keeps the model coherent. `Treener`, `Treeninguliik`, `Osalemine` and person specializations have visible weight. The classifier diagram is now only value-list concepts.

EAP cleanup removes stale template artifacts and injects the corrected concept names/classes. Manual EAP visual layout review is still recommended.

## I. CRUD/use-case alignment

The CRUD matrix now includes meaningful conceptual entities, including `Treener`, `Treeninguliik`, `Treeningukord`, `Registreering`, `Ootejärjekorra koht`, `Osalemine` and `Treeneri pädevus`. Use cases are lifecycle/business operations rather than generic row CRUD examples. The client use case for viewing own registrations remains explicit.

## J. Scope control

The system stayed focused on rühmatreeningute registration and attendance. The repair did not add pricing, campaigns, access control, incidents, payroll, full HR, maintenance or inventory lifecycle. The model is no longer artificially thin, but it is still not a whole gym ERP.

## K. Validation

Commands run:

- `./build_all.sh`
- `.venv/bin/python tools/validate_project.py`
- `.venv/bin/python tests/database/run_database_validation.py`

Results:

- Build completed.
- Project validator passed.
- Database validation: 292 passed, 0 failed, 33 warnings, 12 skipped/not applicable.
- DOCX render check completed; representative pages were visually inspected after diagram scaling fixes.

Remaining warnings are not caused by this conceptual repair and do not break SQL validation.

## L. Files changed

Changed source/generator files:

- `tools/fill_report_docx.py`
- `tools/EapFixes.java`
- `tools/EapRename.java`
- `tools/render_diagrams.py`
- `tools/validate_project.py`

Changed diagram sources:

- `diagrams/01_system_context.mmd`
- `diagrams/02_use_cases.mmd`
- `diagrams/03_core_er.mmd`
- `diagrams/04_registration_activity.mmd`
- `diagrams/05_session_state.mmd`
- `diagrams/06_registration_state.mmd`
- `diagrams/07_waitlist_sequence.mmd`
- `diagrams/10_attendance_activity.mmd`
- `diagrams/11_people_register.mmd`
- `diagrams/12_training_sessions_register.mmd`
- `diagrams/13_registrations_register.mmd`
- `diagrams/14_attendance_register.mmd`
- `diagrams/15_classifiers_register.mmd`

Changed documentation/artifacts:

- `README.md`
- `DATABASE_PROJECT_DENSE_SUMMARY.md`
- `PROJECT_EXPLAINER_NOT_FOR_SUBMISSION.md`
- `PROFESSOR_FEEDBACK_REPAIR_REPORT.md`
- `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx`
- `Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap`
- `submission_files/dokument.docx`
- `submission_files/mudelid.eap`
- `submission_files/rakendus.zip`

## M. Remaining risks

- Some activity diagrams are compact in DOCX after scaling; they are no longer clipped, but should be manually checked for professor-facing readability.
- EAP content is regenerated and cleaned, but Enterprise Architect layout should be opened manually before final submission.
- The generic guide warning that classifiers can appear in some registry contexts conflicts with the professor's concrete warning not to confuse classifiers with core objects; this repair follows the latest professor feedback.
- SQL validation warnings remain, but there are no SQL validation failures.
