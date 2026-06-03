# Manual DBeaver Physical Diagram Exports

This folder contains the six DBeaver/PostgreSQL physical diagram exports used by the build:

- `registreeringute_register.png`
- `treeningukordade_register.png`
- `osalemiste_register.png`
- `isikute_rollide_register.png`
- `treenerite_padevuste_register.png`
- `klassifikaatorite_register.png`

If any diagram is re-exported, keep the same filename and run `./build_all.sh`. The DOCX generator embeds these PNGs in the physical design section, and `tools/validate_project.py` checks that all six non-placeholder files are available.
