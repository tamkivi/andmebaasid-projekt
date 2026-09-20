# Ü2 physical-design diagrams

Generated 2026-09-21 from local database `iti0207_epood_u2` (Homebrew PostgreSQL 17) after loading `sql/01_tables_draft.sql`.

| File | Register | Detailed tables |
|---|---|---|
| `u2-01-klassifikaatorid` | Klassifikaatorid | all classifier tables |
| `u2-02-isikud` | Isikud | `isik`, `kasutajakonto` |
| `u2-03-tootajad` | Töötajad | `tootaja`, `tootaja_rolli_omamine` |
| `u2-04-kliendid` | Kliendid | `klient` |
| `u2-05-kaubad` | Kaubad | `kaup`, `nutitelefon`, `kauba_variant`, `kauba_kategooria_omamine` |

Formats: `.png` (screen), `.pdf` (document paste), `.dot` (Graphviz source).

Regenerate: `python3 iti0207-epood/scripts/render_u2_er_diagrams.py`

DBeaver can connect to the same DB for interactive layout; these exports are the chapter-3 starting set.
