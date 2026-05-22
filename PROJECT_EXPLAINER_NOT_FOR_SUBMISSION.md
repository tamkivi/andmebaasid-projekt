# NOT FOR SUBMISSION — Project Explainer

This file is for study/reference only and must not be uploaded unless explicitly requested. It is not a required submission artifact, and it must not be copied into `submission_files/` or included in `rakendus.zip`.

## 1. One-Sentence Summary

This project models and prototypes the training-management functional subsystem of a gym information system, centered on the register object `Treening`.

## 2. What This Project Is

The project is an ITI0206 database project for a gym's training subsystem. It includes a written report, an Enterprise Architect model, a PostgreSQL implementation script, and a small Flask prototype that demonstrates selected workflows.

The subsystem manages gym trainings as business objects: trainings can be registered, categorized, activated, deactivated, forgotten while pending, finished, viewed by different users, and reported on by a manager.

## 3. What This Project Is Not

This is not a full production gym platform. It is not a booking system, payment system, attendance system, membership billing system, or real-time class-capacity system.

The Flask app is a course prototype. It demonstrates the database rules and main workflows, but it does not claim production completeness for topics such as CSRF protection, audit logging depth, email verification, deployment hardening, or full user administration.

## 4. Business Context

The business context is a gym that needs a consistent way to publish and manage trainings. The gym wants trainings to be visible to clients only when they are ready, to keep inactive and finished trainings separate, and to allow employees with the right role to change training states.

The organization goals are business goals: provide structured training services, make active trainings visible to customers, and support management oversight. The information-system goals support those goals by storing training data, enforcing lifecycle rules, and presenting different views for public visitors, clients, trainers, and managers.

## 5. Main Users and Roles

The main actors are:

- `Uudistaja`: a public visitor who can see active trainings.
- `Klient`: an authenticated client who can see active trainings and training details.
- `Treener`: a trainer who registers and maintains trainings.
- `Juhataja`: a manager who finishes trainings and views reports.
- `Klassifikaatorite haldur`: a classifier administrator for classifier values.
- `Töötajate haldur`: an employee administrator for employee and role data.

The prototype implements the main public/client/trainer/manager behavior. The classifier and employee administrator roles are represented in the project model and database design but are not the main focus of the prototype UI.

## 6. Main Object: Treening

`Treening` is the central object of this subsystem. It represents a gym training offering with a name, description, duration, status, registration/change metadata, and category links.

It is central because the subsystem exists to maintain the lifecycle and visibility of trainings. Other objects support `Treening`: people, accounts, employees, roles, status classifiers, category classifiers, and the category ownership relationship.

## 7. Training Lifecycle

The documented lifecycle states are:

- `OOTEL`: the training is pending and not publicly active.
- `AKTIIVNE`: the training is active and visible in public/client active-training views.
- `MITTEAKT`: the training is inactive but can be reactivated.
- `LOPPENUD`: the training has ended and is terminal.
- `UNUSTATUD`: the pending training was forgotten/cancelled before becoming active and is terminal.

Allowed transitions:

- New training starts as `OOTEL`.
- `OOTEL -> AKTIIVNE` when a trainer activates a categorized training.
- `OOTEL -> UNUSTATUD` when a trainer forgets a pending training.
- `OOTEL -> OOTEL` when pending training data is edited.
- `AKTIIVNE -> MITTEAKT` when a trainer deactivates an active training.
- `AKTIIVNE -> LOPPENUD` when a manager finishes an active training.
- `MITTEAKT -> AKTIIVNE` when a trainer reactivates an inactive training.
- `MITTEAKT -> LOPPENUD` when a manager finishes an inactive training.
- `MITTEAKT -> MITTEAKT` when inactive training data is edited.

Invalid shortcuts are intentionally blocked. For example, a finished or forgotten training is not reactivated.

## 8. Main Use Cases

The main use cases include:

- View active trainings.
- View training details.
- Register a training.
- Edit a pending or inactive training.
- Add or change training categories.
- Activate a pending or inactive training.
- Deactivate an active training.
- Forget a pending training.
- Finish an active or inactive training.
- View manager training reports.

High-level use cases describe business interaction, not database operations. Extended use cases connect the actor steps and system responses to database-operation contracts where relevant.

## 9. Database Design Overview

The database design separates the main business object from classifier values and supporting actors:

- `treening` stores training records.
- `treeningu_seisundi_liik` stores status classifier values.
- `treeningu_kategooria_tyyp` and `treeningu_kategooria` store category classifier values.
- `treeningu_kategooria_omamine` stores the many-to-many relationship between trainings and categories.
- `isik`, `kasutajakonto`, `tootaja`, `tootaja_roll`, and `tootaja_rolli_omamine` support people, login, employees, and role history.

The schema uses domains, primary keys, foreign keys, uniqueness constraints, checks, indexes, views, routines, triggers, test data, statistics, execution-plan examples, and role/grant logic.

## 10. Important Tables

- `riik`: country classifier.
- `isiku_seisundi_liik`: person status classifier.
- `tootaja_seisundi_liik`: employee status classifier.
- `tootaja_roll`: employee role classifier.
- `treeningu_seisundi_liik`: training lifecycle status classifier.
- `treeningu_kategooria_tyyp`: category type classifier.
- `treeningu_kategooria`: concrete category classifier.
- `isik`: person data.
- `kasutajakonto`: login data.
- `tootaja`: employee data.
- `tootaja_rolli_omamine`: employee role history.
- `treening`: training data.
- `treeningu_kategooria_omamine`: training-category relationship.

## 11. Important Classifiers

A classifier is a controlled list of valid values. Instead of free text like "active" or "finished", the database stores a code from a classifier table.

Important classifiers:

- Training statuses: `OOTEL`, `AKTIIVNE`, `MITTEAKT`, `LOPPENUD`, `UNUSTATUD`.
- Training category types such as group, strength, endurance, and wellness-related types.
- Concrete training categories such as yoga, strength, cardio, mobility, stretching, and circuit training.
- Employee roles such as trainer and manager.

Classifiers help keep data consistent, make reporting easier, and avoid spelling variants in important business states.

## 12. Important Relationships

The most important relationship is between `Treening` and `Treeningu kategooria`. A training can have multiple categories, and a category can apply to multiple trainings, so the physical schema uses `treeningu_kategooria_omamine`.

Employee role ownership is also important. It models that an employee can have one or more roles over time, and those roles control what the prototype lets the user do.

## 13. Important Constraints

Important constraints include:

- Training code is generated by a sequence, not by `MAX(id)+1`.
- A new training starts in status `OOTEL`.
- Only documented lifecycle transitions are allowed.
- Active trainings must have at least one category.
- Required text fields cannot be empty.
- Duration must be in a valid range.
- Category links must reference valid categories.
- Login emails and classifier codes are unique where required.

The app also validates forms before sending changes to the database, but database constraints are the final guardrail.

## 14. Why Certain Rules Are Enforced in the Database

Database enforcement matters because the database can be changed by more than one client. If lifecycle rules only existed in the Flask app, a direct SQL update or another future app could bypass them.

Triggers enforce lifecycle transitions and active-category requirements close to the data. This makes the data safer and makes the project easier to defend as a database project.

## 15. PostgreSQL Implementation

The generated PostgreSQL script creates domains, tables, constraints, indexes, classifier inserts, views, routines, triggers, tests, statistics commands, an execution-plan example, and role/grant sections.

The script is generated from `tools/sql_ddl.py` into `jousaali_skript.sql`, and the submission copy is `submission_files/skript.sql`.

## 16. Views, Routines, Triggers, and Indexes

Important views:

- `v_treeningud_kategooriatega`: trainings with category information.
- `v_aktiivsed_treeningud`: active trainings visible to public/client views.
- `v_treeningute_arv_seisundi_kaupa`: manager report counts by status.
- `v_treeningute_arv_kategooria_kaupa`: manager report counts by category.

Important routines:

- `fn_kasutaja_tuvastamise_andmed`: login/role lookup.
- `fn_registreeri_treening`: sequence-backed training registration.
- `fn_aktiveeri_treening`: activation with lifecycle logic.
- `fn_lopeta_treening`: finishing active/inactive trainings.

Important triggers:

- Initial status trigger: new trainings must start as `OOTEL`.
- Status transition trigger: only documented status changes are allowed.
- Active-category trigger: active trainings cannot be left without a category.

Important indexes include foreign-key indexes, status indexes, employee/category indexes, and secondary indexes used by app/report queries.

## 17. JSON Loading / Test Data / Statistics / Execution Plan

The SQL script includes JSON-based loading for some classifier source data. This demonstrates that the project can load structured source values into classifier tables.

The script includes test data and rollbackable trigger/routine test blocks. It also runs `ANALYZE` and includes an `EXPLAIN` example to show how a relevant query can be inspected.

`rakendus/test_data.sql` provides additional prototype login and demonstration data.

## 18. Flask Prototype Overview

The Flask prototype demonstrates how the database model can be used by a small web app. It supports login, sessions, role checks, public active-training views, trainer workflows, manager workflows, and a JSON stats API.

The prototype uses parameterized SQL and password hashing. It is intentionally small and local, not a hardened production deployment.

## 19. Important Flask Routes

Important routes include:

- `/`: redirects users toward the dashboard or trainings view.
- `/login` and `/logout`: authentication and session handling.
- `/dashboard`: role-aware dashboard.
- `/trainings`: public/client active-training list, or broader role-based list for staff.
- `/training/<id>`: detail view with role-aware visibility.
- `/trainer/register-training`: trainer registration workflow.
- `/trainer/edit-training/<id>`: trainer edit workflow for pending/inactive trainings.
- `/trainer/activate-training/<id>`: activation.
- `/trainer/deactivate-training/<id>`: deactivation.
- `/trainer/forget-training/<id>`: forget pending training.
- `/manager/finish-training/<id>`: finish active/inactive training.
- `/manager/report`: manager report.
- `/api/stats`: status counts as JSON.

## 20. Authentication and Authorization

Users log in with email and password. Passwords are stored as hashes in the database/test data. The app stores authenticated user information in the Flask session.

Role checks decide which routes are available. Trainer-only routes require the trainer role. Manager-only routes require the manager role. Public visitors are not allowed to mutate data.

## 21. How Public/Client/Trainer/Manager Behavior Differs

Public visitors (`Uudistaja`) can see active trainings. Clients can also see active training details.

Trainers can register, edit, activate, deactivate, and forget trainings within the documented lifecycle rules. Managers can finish trainings and view reports.

The key distinction is that visibility and mutation permissions are role-dependent. A public visitor must not see inactive/pending/internal training management data.

## 22. Reproducible Build Pipeline

The build pipeline is `./build_all.sh` on macOS/Linux and `build_all.bat` on Windows. It compiles EAP tools, regenerates the EAP, regenerates the DOCX, regenerates SQL, and refreshes `submission_files/`.

Generated artifacts should not be hand-edited as the source of truth. Source/tooling fixes should be made first, then the artifacts regenerated.

## 23. Submission Files

The current submission strategy is direct files plus one application ZIP:

- `submission_files/dokument.docx`
- `submission_files/mudelid.eap`
- `submission_files/skript.sql`
- `submission_files/rakendus.zip`

Obsolete `dokument.zip` and `mudelid.zip` are intentionally not used. `PROJECT_EXPLAINER_NOT_FOR_SUBMISSION.md` must not be uploaded.

## 24. What Was Deliberately Left Out of Scope

Out of scope:

- Booking clients into trainings.
- Payments, invoices, memberships, and refunds.
- Attendance tracking.
- Room/equipment capacity planning.
- Trainer payroll.
- Full admin UI for every classifier.
- Production security hardening.
- Public deployment automation.

These topics would belong to other subsystems or a production implementation, not this training-management database project.

## 25. Common Design Tradeoffs

Statuses are classifier values rather than arbitrary text because lifecycle values must be controlled and reportable.

Categories use a many-to-many table because one training may belong to several categories, and one category may describe many trainings.

Triggers are used for lifecycle rules because they protect data even when changes do not come from the Flask app.

The app repeats some validation because users need clear feedback before the database rejects a change.

## 26. Known Limitations

The prototype is local and educational. It does not implement complete production security, production logging, full error monitoring, full UI coverage for all administrative actors, or real deployment.

Enterprise Architect visual inspection still benefits from opening the EAP in Sparx EA because automated MDB checks cannot fully prove diagram aesthetics inside the EA GUI.

## 27. How To Explain This Project To A Professor

Start with the central object: `Treening`. Explain that the subsystem maintains gym trainings and controls their lifecycle. Then explain that the database protects the most important rules: valid status transitions, required category before activation, and sequence-backed identifiers.

Then connect the artifacts: the DOCX explains the analysis and design, the EAP visualizes it, the SQL implements it in PostgreSQL, and the Flask prototype demonstrates how different users interact with it.

## 28. Professor FAQ

### 1. What is the central register/object of this subsystem?

The central object is `Treening`. The subsystem exists to manage gym trainings, their categories, visibility, and lifecycle states.

### 2. Why is this not a booking or payment system?

Booking and payment are different business processes. This subsystem only manages training offerings and their lifecycle; client enrolment, billing, and attendance are intentionally out of scope.

### 3. Why does Treening have these lifecycle states?

The states separate pending, active, inactive, completed, and forgotten trainings. This lets the gym distinguish trainings being prepared, trainings visible to customers, temporarily inactive trainings, completed trainings, and pending trainings that were cancelled before publication.

### 4. Why is UNUSTATUD different from LOPPENUD?

`UNUSTATUD` means a pending training was abandoned before it became active. `LOPPENUD` means a real active or inactive training has ended. They have different business meaning and different history.

### 5. Why must a training have a category before activation?

An active training should be understandable and searchable for clients. A category gives the public/client view meaningful context and prevents publishing incomplete training data.

### 6. Why are statuses and categories classifiers?

They are controlled value sets. Classifiers prevent spelling variants, support referential integrity, and make reporting consistent.

### 7. Why is there a many-to-many relationship between trainings and categories?

One training can belong to more than one category, for example strength and group training. One category can also apply to many trainings. A link table models this correctly.

### 8. What does the Flask prototype demonstrate?

It demonstrates authentication, role-based views, active-training visibility, trainer mutation workflows, manager finishing/reporting workflows, and database-backed lifecycle behavior.

### 9. What business rules are enforced in PostgreSQL?

PostgreSQL enforces valid statuses, required relationships, uniqueness, non-empty fields, valid durations, allowed lifecycle transitions, initial pending status, and the rule that active trainings must have a category.

### 10. What business rules are enforced in the Flask app?

The app checks roles, validates form fields, validates category selections, blocks invalid route access, and only sends allowed lifecycle operations for the current user's role.

### 11. Why enforce rules in both the app and the database?

The app gives user-friendly feedback and avoids unnecessary failed writes. The database protects the data if another client, direct SQL, or future integration attempts an invalid change.

### 12. How do trainer and manager permissions differ?

Trainers maintain trainings: register, edit, activate, deactivate, and forget pending trainings. Managers finish trainings and view summary reports.

### 13. What can a public visitor see?

A public visitor can see active trainings. Pending, inactive, forgotten, and finished trainings are internal and are not part of the public active-training list.

### 14. What does the manager report show?

The manager report summarizes trainings by status and category so management can understand the current training portfolio.

### 15. How does the project satisfy the PostgreSQL implementation requirements?

It includes schemas/tables, domains, constraints, primary keys, foreign keys, indexes, classifier inserts, views, routines, triggers, test data, JSON loading, statistics, execution-plan examples, and role/grant sections.

### 16. What are the main triggers/routines/views/indexes?

Main triggers enforce initial status, lifecycle transitions, and active-category safety. Main routines support login data lookup, registration, activation, and finishing. Views support active lists and reports. Indexes support foreign keys, statuses, categories, and common query filters.

### 17. How is reproducibility handled?

`./build_all.sh` regenerates the EAP, DOCX, SQL, and submission files from tracked sources and tools. `tools/validate_project.py` checks that generated/submission files match.

### 18. What files should be submitted?

Submit `submission_files/dokument.docx`, `submission_files/mudelid.eap`, `submission_files/skript.sql`, and `submission_files/rakendus.zip`.

### 19. What is intentionally out of scope?

Bookings, payments, memberships, attendance, production deployment, complete admin UI, and production-grade security hardening are out of scope.

### 20. What are the known limitations?

The app is a prototype, not production software. The EAP should still be visually checked in Sparx EA if possible. Some administrative actors are modeled but not fully implemented as UI workflows.

### 21. How would this need to change for a real production gym?

It would need stronger security, CSRF protection, logging, monitoring, migrations, deployment automation, robust admin screens, booking/payment integration, backup/recovery planning, and broader test coverage.

### 22. What edge cases were considered?

Invalid status transitions, active categoryless trainings, route-level role bypasses, editing terminal states, sequence misuse, public visibility leaks, stale generated artifacts, and junk in submission packages were checked.

### 23. How do you know generated artifacts are fresh?

The build script regenerates them, and validation compares root outputs with `submission_files/` copies using byte/content checks.

### 24. How do you know the app ZIP does not contain junk?

The build script zips only selected app files, and validation checks the ZIP top-level contents, expected files, forbidden names/components, and stale file drift against `rakendus/`.

### 25. How would you explain the project in two minutes?

It is a gym training-management database subsystem. The main object is `Treening`, which moves through pending, active, inactive, finished, or forgotten states. PostgreSQL enforces the lifecycle and category rules, the EAP and DOCX document the design, and the Flask prototype shows how public users, clients, trainers, and managers use the subsystem.

## 29. Quick Defense Cheat Sheet

- Central object: `Treening`.
- Main rule: only documented lifecycle transitions are valid.
- Public visibility: active trainings only.
- Activation requirement: at least one category.
- Identifier rule: use sequences, not `MAX(id)+1`.
- Classifiers: statuses, roles, category types, categories.
- Many-to-many: trainings and categories.
- Database protection: constraints and triggers.
- App protection: role checks, form validation, parameterized SQL.
- Submission files: direct DOCX, direct EAP, direct SQL, app ZIP.

## 30. Final Sanity Checklist

- Run `./build_all.sh`.
- Run `.venv/bin/python tools/validate_project.py`.
- Compile Python files with `py_compile`.
- Load `jousaali_skript.sql` into a clean PostgreSQL database if PostgreSQL is available.
- Load `rakendus/test_data.sql` for prototype data if needed.
- Compare root DOCX/EAP/SQL with submission copies.
- Test `submission_files/rakendus.zip`.
- Confirm `PROJECT_EXPLAINER_NOT_FOR_SUBMISSION.md` is not in `submission_files/`.
- Confirm `PROJECT_EXPLAINER_NOT_FOR_SUBMISSION.md` is not in `rakendus.zip`.
- Open the EAP in Sparx EA manually before upload if possible.
