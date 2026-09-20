# ITI0207 e-poe — progress

**Updated:** 2026-09-20 · **Tool choice:** DBeaver path (no Windows EA on Mac)

## Current decision
- Modeling / diagram tool: **DBeaver Community** (`/Applications/DBeaver.app`)
- Course route: Ü2 option **3** — design base tables carefully (SQL / notes from Dokument.docx), later visualize per-register diagrams in DBeaver (Erki explicitly allows this without CASE). Do **not** depend on opening `Diagrammid.eap`.
- Stack still: PostgreSQL on school server + pgApex app later.
- EA / Rational Rose: not required for our Mac workflow unless we later choose to use an ICT lab PC.

## Repo layout (live)
- `iti0206-jousaal/` — last year (archive)
- `iti0207-epood/docs/lahteprojekt/` — Dokument.docx, Diagrammid.eap (reference only), Prototüüp.mdb
- `iti0207-epood/docs/ulesanded/` — Ü2, tegevuskava, näidis
- `iti0207-epood/models/`, `sql/`, `app/` — for upcoming slices

## Next slice when we start building
Week 5 / Ü2 (DBeaver variant):
1. From Dokument.docx, draft PostgreSQL base-table design notes (names, PK/FK/UK, types) — **no CHECK/indexes yet**.
2. Optional: local SQL draft under `sql/` (not executed on school server until Ü4 unless we choose a throwaway local DB for DBeaver diagrams).
3. Produce readable portrait-A4-style register diagrams in DBeaver for the document.
4. Stop before Ü3 (CHECK/indexes) and before school-server DDL unless explicitly asked.

---

## Historical prep log (Codex, earlier same day)

# ITI0207 e-poe — Prep and grounding

Verified locally: 2026-09-20. Scope: Prep and prerequisites verification only. Updated from newly supplied local sources on 2026-09-20. No implementation assignment is marked complete.

## Authority and scope

Authority order: current Maurus 391 assignment PDFs and tegevuskava; smartphone e-poe lähteprojekt (Dokument, Diagrammid.eap, Access prototype); AB II sample for document structure only; user handoff for process. The week mapping is now verified against the supplied local 2026 tegevuskava; Ü2 scope is verified against the supplied 2025-labelled assignment. This is local-source verification, not a fresh Maurus website check.

Intended topic: Nutitelefonide e-poe infosüsteemi kaupade funktsionaalne allsüsteem. Intended workplace: kaupade haldur. Intended stack: PostgreSQL + pgApex. These are user-supplied requirements, not independently verified Maurus registration facts.

## Directly verified repository evidence

- Repository: `/Users/gustav/Developer/andmebaasid-projekt`.
- Initial `git status -sb`: `## main...origin/main`, with no changes.
- Current branch: `main`; HEAD: `98220f5e7d509becb0b95757859c8ca6f0409a9c`.
- Neither `iti0206-jousaal/` nor `iti0207-epood/` exists on this checkout. Existing project files use the old flat jõusaal layout.
- Local remote-tracking ref `origin/cursor/restructure-iti0206-iti0207-separation-5059` exists at `275414134f352b0cc90fb18a89c5f16ce0808a0c`.
- Relative to local main, the restructure ref has one additional commit and main has no exclusive commits (`git rev-list --left-right --count`: `0 1`). No fetch was performed; this is local ref evidence, not current GitHub status.
- That ref contains the archived jõusaal tree and only `iti0207-epood/README.md` plus `.gitkeep` for e-poe. Its README describes the intended project and future folders. No e-poe model, SQL, app implementation, or PROGRESS file exists in that tree.
- No AB II e-poe implementation was found in the inspected checkout or restructure ref. Server state was not inspected, so no claim is made about objects that might exist there.
- PR #2 is identified by the user as the restructure PR; its live status was not checked.

## Source material now available

The earlier missing-source blocker is resolved. Exact paths:

- `/Users/gustav/Developer/andmebaasid-projekt/_iti0207_sources/ulesanded/tegevuskava.txt` — identifies Maurus 391, autumn 2026.
- `/Users/gustav/Developer/andmebaasid-projekt/_iti0207_sources/ulesanded/Ylesanne_ITI0207_2_2025.txt` — Ü2, labelled 2025. Used as supplied; whether a newer revision exists was not checked online.
- `/Users/gustav/Developer/andmebaasid-projekt/_iti0207_sources/lahteprojekt/Dokument.docx` — readable OOXML text; use cases and operation contracts extracted without editing the document.
- `/Users/gustav/Developer/andmebaasid-projekt/_iti0207_sources/lahteprojekt/Diagrammid.eap` — present; not opened or modified.
- `/Users/gustav/Developer/andmebaasid-projekt/_iti0207_sources/lahteprojekt/Prototüüp.mdb` — present; not opened or modified.

The source folder is untracked. Source/reference files are not completed implementation. Neither project folder exists on the current main checkout; HEAD remains `98220f5e7d509becb0b95757859c8ca6f0409a9c`.

## Verified Week / ülesanne mapping

Source: `tegevuskava.txt`, named week sections and line ranges below. “Verified” describes the mapping only; no assignment has been completed in this session.

| Week | Official ülesanne / scope in local schedule | Status | Evidence lines |
| --- | --- | --- | --- |
| 1 | Technical setup, access request, sample chapters 3–4 | Readiness unverified | 23–57 |
| 2 | Server/client readiness and topic registration | Completion unverified | 59–91 |
| 3 | Oracle familiarization; state-registration pattern | Completion unverified | 93–113 |
| 4 | PostgreSQL familiarization; state-change UI pattern | Completion unverified | 115–135 |
| 5 | Ü2 — adapt physical model; base tables; defer CHECKs/indexes | Mapping verified; not started | 137–157 |
| 6 | Ü3 — CHECK constraints and indexes | Mapping verified; not started | 175–187 |
| 7 | Finish Ü2 and Ü3 — base-table design model | Mapping verified; not started | 203–213 |
| 8 | Ü4 — generate, correct, execute CREATE TABLE statements | Mapping verified; not started | 229–239 |
| 9 | Ü5 — test data; Riik, Isik, Kasutajakonto from external source | Mapping verified; not started | 255–269 |
| 10 | Ü6 — PostgreSQL refactoring using at least one domain | Mapping verified; not started | 283–293 |
| 11 | Ü7 — public interface: views | Mapping verified; not started | 309–319 |
| 12 | Ü8 — public interface: stored routines | Mapping verified; not started | 335–345 |
| 13 | Ü9 — triggers or PostgreSQL rewrite rules | Mapping verified; not started | 361–371 |
| 14 | Ü10 — begin app with user identification | Mapping verified; not started | 387–401 |
| 15 | Ü11 — study app-building tools and PostgreSQL/Oracle DML | Mapping verified; not started | 415–427 |
| 16 | Ü12 — statistics, execution plan, document, references, app, privileges; finish project | Mapping verified; not started | 443–455 |

The handoff's Week 5–16 numbering matches. Its Week 15 completion requirement (“all use cases operable”) is a project planning target, not what this schedule explicitly says. Detailed Ü3–Ü12 acceptance criteria have not been audited. Do not treat the snapshot's “Käimasolev nädal” marker as today's calendar week.

## Verified Ü2 scope and source quotes

Source: `Ylesanne_ITI0207_2_2025.txt`, section 1, printed page 1:

> Ülesande eesmärgiks on saada korda oma iseseisva töö projekti andmebaasi füüsilist disaini kirjeldavad diagrammid e skeemid (välja arvatud CHECK kitsendused ja indeksid, mida pole vaja selle ülesande lahendamise käigus kirjeldada).

> Vajadusel tuleb kooskõla säilitamiseks täiendada kontseptuaalset andmemudelit.

The 2026 schedule's Week 5 agrees:

> Käesoleval nädalal keskenduge baastabelitele, kuid esialgu jätke vaatluse alt välja CHECK kitsendused ja indeksid.

For our selected EA/PostgreSQL workflow: work on a copy of the source physical-design package, set PostgreSQL for every copied table, and correct the converted design using the source requirements and clean-code guidance. Section 2.1 explicitly describes that path; section 2.2 recommends dated backups before working on the model. Section 2.3 warns that automatic type conversion needs manual correction.

Ü2 covers base-table structure, classifiers, names, person names/password representation, column ordering, PostgreSQL types and lengths, image representation, nullability, PK/UK/FK constraints, hierarchical data, and defaults (section 3.1–3.14). Keep the conceptual model consistent; change it only where needed. Preserve source rules that Access could not enforce while scheduling their actual CHECK/index or procedural implementation in the appropriate later slice.

Diagram requirements (sections 1 and 3.2): readable on portrait A4 at 100%, at least one diagram per used/served register, direct referenced tables for context, and each table's details shown on exactly one diagram. Final physical diagrams belong in chapter 3 (sample section 3.1). Section 1 also asks for document-format cleanup: new pages for top-level headings, text after headings, figure/table captions and references, and source citations. No whole-document rewrite is authorized now.

Ü2 does not require DDL execution in this modeling slice: generation/execution is Week 8 / Ü4. CHECKs and indexes are Week 6 / Ü3. No model work, DDL, or DB access has been performed during this prerequisites pass.

## Source-based role boundaries

Source: Dokument section 2.1.1, expanded use cases 2.1.1.1–2.1.1.11; cross-checked against the short use-case descriptions.

| Actor | Use cases |
| --- | --- |
| Kauba haldur | UC2 register smartphone; UC3 forget goods; UC4 edit goods; UC5 activate; UC6 deactivate; UC7 list waiting/inactive goods; UC8 list/detail all goods |
| Juhataja | UC8 list/detail all goods; UC9 retire goods; UC10 summary by state |
| Shared authentication | UC1: Kauba haldur, Juhataja, Klient, Kliendihaldur |
| Public/customer read | UC11: Uudistaja and Klient in expanded use case; short description additionally lists Kliendihaldur |

UC1 requires authentication and authorization, suitable person/relationship states, person not deceased, and an active employee role. Its short description explicitly includes entering a role along with username/password. The expanded scenario checks role/status but does not explicitly repeat role entry. It permits up to three login attempts and uses a generic failure message. Exact app role-selection design remains for the authorized later slice.

UC10 returns every registered state, including zero-count states; names uppercase; count descending, then uppercase name ascending. With no state definitions, return zero rows.

Do not infer that juhataja inherits all haldur actions. The source lists actors explicitly. A single app with role-gated pages remains the working plan, but the registered workplace/submission scope must still be confirmed before expanding the deliverable to every actor. UC11 is not listed as a haldur use case. Preserve the short/expanded UC11 actor discrepancy for resolution instead of silently assigning permissions.

## Extracted lifecycle transition table

Source: Dokument section 2.1.1 use-case pre/postconditions and section 2.2.2 operation contracts OP1–OP10. The table is extracted from readable text, not an invented design. The embedded state diagram (section 2.2.3, Figure 10) is EMF and has not been visually cross-checked; the `.eap` remains unopened.

All write rows require the stated actor to be authenticated and authorized under UC1. OP1 and OP3–OP10 also require the acting employee record to exist. “Active target state” means the state classifier row has `on_aktiivne=TRUE`; it is distinct from the goods being in state Aktiivne.

| From | Action | Actor | To | Guards | Delete? |
| --- | --- | --- | --- | --- | --- |
| Not yet registered | Registreeri nutitelefon (UC2 / OP1) | Kauba haldur | Ootel (1) | Employee exists; Ootel state classifier is active; selected brand, both cameras, memory, diagonal, processor and resolution exist and are active; system assigns state, registration/change timestamps and registrar/latest modifier | No; create Kaup and Nutitelefon |
| Ootel (1) | Unusta kaup (UC3 / OP2) | Kauba haldur | Removed | Goods exist in Ootel; delete associated subtype instances, category memberships, variants and their relationships per OP2 | Yes, physical deletion |
| Ootel (1) | Muuda kaupa (UC4 / OP6) | Kauba haldur | Ootel (1), unchanged | Goods and smartphone links exist; selected classifiers active; preserve registrar, registration time and state; system updates latest modifier/time | No goods deletion |
| Mitteaktiivne (3) | Muuda kaupa (UC4 / OP6) | Kauba haldur | Mitteaktiivne (3), unchanged | Same OP6 guards and protected fields | No goods deletion |
| Ootel (1) | Aktiveeri kaup (UC5 / OP3) | Kauba haldur | Aktiivne (2) | At least one category membership exists; active target state classifier exists | No |
| Mitteaktiivne (3) | Aktiveeri kaup (UC5 / OP3) | Kauba haldur | Aktiivne (2) | At least one category membership exists; active target state classifier exists | No |
| Aktiivne (2) | Muuda kaup mitteaktiivseks (UC6 / OP4) | Kauba haldur | Mitteaktiivne (3) | Active target state classifier exists | No |
| Aktiivne (2) | Lõpeta kaup (UC9 / OP5) | Juhataja | Lõpetatud (4) | Active target state classifier exists; retain goods and related transaction history | No; explicitly forbidden |
| Mitteaktiivne (3) | Lõpeta kaup (UC9 / OP5) | Juhataja | Lõpetatud (4) | Active target state classifier exists; retain goods and related transaction history | No; explicitly forbidden |
| Ootel (1) or Mitteaktiivne (3) | Add/remove category membership (OP7/OP8), add/remove variant (OP9/OP10), under UC2/UC4 | Kauba haldur | Same starting state | Added category/color must be active; relevant records exist; system updates latest modifier/time | Removal deletes membership/variant only, not Kaup |
| Lõpetatud (4) | View via UC8 / include in UC10 report | Haldur or Juhataja for UC8; Juhataja for UC10 | Lõpetatud (4), unchanged | Read authorization; no outgoing write transition defined by the extracted contracts | No |

OP3–OP5 change the state relationship and latest modifier/time; they do not change registrar or registration time. Activation does not state a minimum variant count or require the category itself to be active in OP3; do not add either guard without further source evidence. No Ootel → Lõpetatud transition is specified. Aktiivne cannot be edited with UC4; first deactivate. No write transition out of Lõpetatud is specified. These are source findings, not implemented enforcement.

## Privilege design early, GRANTs late

Keep application end-user roles (such as haldur and juhataja) separate from the application's PostgreSQL login. Plan view-based reads and routine-based writes, with role checks enforced at the appropriate trusted boundary rather than relying only on hidden UI controls. The intended least-privilege app login receives SELECT on the necessary views and EXECUTE on necessary routines, without broad base-table rights. Final GRANT/REVOKE implementation and verification belong to the later official privilege assignment; no privileges or DB objects were changed during Prep.

## Recommended restructure path — commands for Gustav only

Recommend checking out the existing restructure branch for the next modeling session if PR #2 is still pending. This obtains the intended layout without merging main. Alternatively, review and merge PR #2 for the durable main layout. Live PR status has not been checked. No commands below were executed.

First preserve the untracked bootstrap and source materials outside the repo, then inspect status:

```sh
cd ~/Developer/andmebaasid-projekt
backup_dir=$(mktemp -d /tmp/iti0207-before-restructure.XXXXXX)
cp -R ITI0207_EPood_BOOTSTRAP.md _iti0207_sources "$backup_dir/"
git status -sb
git fetch origin
```

Option A — checkout the restructure branch (local branch was absent when checked):

```sh
git switch --track -c cursor/restructure-iti0206-iti0207-separation-5059 origin/cursor/restructure-iti0206-iti0207-separation-5059
git status -sb
ls -d iti0206-jousaal iti0207-epood
```

If that local branch already exists by then, use `git switch cursor/restructure-iti0206-iti0207-separation-5059` instead. If Git reports untracked-file collisions or unexpected changes, stop and inspect; do not force or discard files.

Option B — after reviewing and merging PR #2 on GitHub, update local main:

```sh
git switch main
git fetch origin
git merge --ff-only origin/main
git status -sb
ls -d iti0206-jousaal iti0207-epood
```

Option B's Git commands only obtain an already-merged PR; they do not merge PR #2 on GitHub. If the folders are absent afterwards, the expected restructure is not present in fetched main: stop and check the PR. Do not execute both options as a sequence.

Once the selected checkout exists, the next authorized session can carry this content into `iti0207-epood/PROGRESS.md`, retain source references under `_iti0207_sources/`, and put new models under `iti0207-epood/models/`. Do not move gym-domain files manually or reuse their model as the smartphone model.

## Remaining prerequisites and readiness

| Prerequisite | Verified state | Blocks Ü2 modeling? |
| --- | --- | --- |
| Local schedule and Ü2 instructions | Present and scope verified; instruction labelled 2025, schedule 2026 | Available; newer revision not checked |
| Smartphone source document/model/prototype | Present; DOCX use cases/contracts readable; EA/MDB not opened | Source availability resolved |
| Restructured active checkout | Missing on current main | Yes, under the agreed workflow; Gustav must select/confirm branch or merged layout |
| EA installed, licensed, usable in its actual host/VM environment | Not verified; no obvious EA/VM app name found in top-level `/Applications` or `~/Applications`; that does not prove absence elsewhere | Yes for chosen EA workflow; Gustav must confirm readiness |
| EA can open the source `.eap` | Not tested, as instructed | Confirm at start of authorized modeling session; preserve a dated source backup first |
| PostgreSQL account, VPN and connectivity | Not tested; account request is user-reported only | Not needed for offline Ü2 modeling; remains required for later server work (Ü4) |
| Model backup / editable working copy | Not created; source `.eap` untouched | Create at the start of authorized modeling, per Ü2 section 2.2 |
| Final workplace/role submission scope | Source actors extracted; formal registration not checked | Does not prevent base-model preparation; resolve before app scope decisions |

## Progress and next single step

- Done: initial Prep record and local prerequisites/source pass, 2026-09-20.
- Current: Week 5 / Ü2 requirements grounded; modeling not started.
- Implementation assignments completed: none verified.
- Next single step: Gustav obtains/confirms the restructured checkout and licensed EA readiness, then authorizes Ü2 modeling only.
- No CHECK/index implementation, DDL generation, EA launch/edit, database access, submission, checkout, merge, push, or history rewrite occurred.

Exact next prompt, to use after those confirmations:

> Restructure is available locally and EA is installed, licensed, and ready: start Week 5 / Ü2 modeling only using the verified local sources; preserve a dated source-model backup, adapt the PostgreSQL base-table model, defer CHECKs/indexes and DDL, then stop and report.

## Verification recipe

1. Run `git status -sb` and `git rev-parse HEAD`: remain on main at the recorded HEAD with the bootstrap and supplied source folder untracked.
2. Review the Week/Ülesanne table against `_iti0207_sources/ulesanded/tegevuskava.txt`, and Ü2 quotations against assignment section 1.
3. Review lifecycle rows against Dokument use cases 2.1.1.2–2.1.1.9 and contracts OP1–OP10. No claim is made that any rule has been implemented.
