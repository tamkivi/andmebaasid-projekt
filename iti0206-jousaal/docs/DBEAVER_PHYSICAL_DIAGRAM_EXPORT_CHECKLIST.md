# DBeaver PostgreSQL Physical Diagram Export Checklist

Purpose: the repository can regenerate SQL, Mermaid PNGs, DOCX, and EAP, but it cannot reliably export DBeaver ER diagrams without a local DBeaver workspace connected to a rebuilt PostgreSQL database. If DBeaver diagrams are required by the course or professor, this is a real remaining submission blocker until actual exported images are present in the final DOCX or otherwise accepted submission material.

Export the PNGs into `manual_exports/dbeaver_physical/` using the exact filenames below, then run `./build_all.sh` so `submission_files/dokument.docx` embeds them. The checklist alone does not satisfy the diagram requirement.

## Required Manual Exports

- [ ] `registreeringute_register.png` — include `registreering`, `ootejarjekorra_koht`, `registreeringu_seisundi_liik`, `klient`, `treeningukord`.
- [ ] `treeningukordade_register.png` — include `treeningukord`, `treeninguliik`, `tootaja`, `ruum`, `ruumi_varustuse_omamine`, `treeninguliigi_varustuse_noue`, `varustus`.
- [ ] `osalemiste_register.png` — include `osalemine`, `registreering`, `tootaja`, `klient`, `treeningukord`; verify `osalemine.klient_e_meil`, `osalemine.treener_e_meil`, and `osalemine.markija_e_meil`.
- [ ] `isikute_rollide_register.png` — include `isik`, `kasutajakonto`, `klient`, `tootaja`, `tootaja_rolli_omamine`, `tootaja_roll`, `riik`.
- [ ] `treenerite_padevuste_register.png` — include `tootaja`, `tootaja_rolli_omamine`, `treeneri_padevus`, `treeninguliik`.
- [ ] `klassifikaatorite_register.png` — include `isiku_seisundi_liik`, `tootaja_seisundi_liik`, `tootaja_roll`, `treeninguliigi_seisundi_liik`, `treeningukorra_seisundi_liik`, `registreeringu_seisundi_liik`, `riik`.

## Export Checks

- [ ] Rebuild the database from `submission_files/skript.sql` in a disposable PostgreSQL database before opening DBeaver.
- [ ] Export each diagram from the same rebuilt database, not from an older local schema.
- [ ] Show physical tables, columns, primary keys, foreign keys, and important indexes where DBeaver supports them.
- [ ] Do not use these DBeaver diagrams as conceptual/register diagrams; conceptual diagrams must stay implementation-independent.
- [ ] Add the exported files to the submission package only after confirming they are not stale and match `submission_files/skript.sql`.
