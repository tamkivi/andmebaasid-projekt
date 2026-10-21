# ITI0207 e-poe — progress

## Current status — 26.09.2026: Ü2 Not ready (one confirmed model gap)

The rendered source document, figure 8 on page 40, explicitly requires an optional employee mentor relationship. `sql/01_tables_draft.sql` and the physical employee diagram omit it. Earlier text-only conclusions that no required FK was missing are superseded. The detailed review includes an unapplied schema patch and a defense pack. Current counts remain 24 tables / 25 FK; the proposed repair would add one nullable column and one FK. No database was connected to, no schema patch applied, no school submission made, and no commit or push performed during this deep pass. Runtime statements below are historical checks.

**Updated:** 2026-09-23 (Europe/Tallinn) · **Tool choice:** PostgreSQL + DBeaver / Graphviz path

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
- Wrote the full brief/conceptual gap checklist and Estonian chapter-3 draft. Assembled it into `Dokument.docx`, replaced the old Access figures, rendered the 84-page file, checked chapter 3 on pages 63–74, and updated the affected contents entries, source entry and AI-use statement. The original DOCX is backed up.

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
