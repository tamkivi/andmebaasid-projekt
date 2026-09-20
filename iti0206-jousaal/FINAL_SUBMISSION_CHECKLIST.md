# Final Submission Checklist

## Build and Generated Files

- [ ] Run `./build_all.sh`.
- [ ] Run `.venv/bin/python tools/validate_project.py`.
- [ ] Confirm `submission_files/dokument.docx` exists and matches the regenerated DOCX.
- [ ] Confirm `submission_files/skript.sql` exists and matches `jousaali_skript.sql`.
- [ ] Confirm `submission_files/mudelid.eap` exists and matches the regenerated EAP.
- [ ] Confirm `submission_files/rakendus.zip` exists and passes ZIP hygiene checks.
- [ ] Confirm obsolete `submission_files/dokument.zip` and `submission_files/mudelid.zip` are absent.

## Database Smoke Test

- [ ] Create a clean PostgreSQL database.
- [ ] Run `psql -v ON_ERROR_STOP=1 -d <db> -f submission_files/skript.sql`.
- [ ] Verify the core tables exist: `treeninguliik`, `treeningukord`, `registreering`, `osalemine`, `ruum`, `klient`, `treeneri_padevus`.
- [ ] Verify the full small-session demo has two confirmed clients and one `OOTEJRK` client.
- [ ] Run optional live validation with `RUN_LIVE_SQL_TESTS=1 LIVE_SQL_DSN="dbname=<db>" .venv/bin/python tools/validate_project.py` only on a disposable database.

## Application Smoke Test

- [ ] Copy `rakendus/.env.example` to `rakendus/.env`.
- [ ] Set `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, and `DB_PORT`.
- [ ] Install dependencies from `rakendus/requirements.txt`.
- [ ] Start with `python app.py` and open `http://127.0.0.1:5001`.
- [ ] Log in as `juhataja@jousaal.ee` / `juhataja123`; test planning, opening, closing/cancelling and manager report pages.
- [ ] Log in as `treener@jousaal.ee` / `treener123`; test own sessions, roster and attendance marking.
- [ ] Log in as `klient@jousaal.ee` / `klient123`; test schedule, registration, own registrations and cancellation.
- [ ] Confirm DB error messages are surfaced clearly when a rule is violated.

## Diagram and DOCX Review

- [ ] Confirm DOCX title is `Jõusaali rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalne allsüsteem`.
- [ ] Confirm DOCX contains Mermaid-based diagrams, not old Pillow box diagrams.
- [ ] Confirm diagrams are readable and not cropped.
- [ ] Confirm the report explains `treeningukord`, `registreering`, `ootejärjekord`, `osalemine`, `ruum`, `klient`, and `treeneri_pädevus`.
- [ ] Confirm old statements saying booking, attendance, room planning or capacity planning are out of scope are absent.

## EAP Manual Check

- [ ] Open `submission_files/mudelid.eap` in Sparx Enterprise Architect.
- [ ] Confirm the model contains the new conceptual core: Treeninguliik, Treeningukord, Registreering, Osalemine, Ruum, Klient and Treeneri_padevus.
- [ ] Confirm physical model elements include the new table names from `skript.sql`.
- [ ] Confirm the model no longer presents the old `treening` card/status catalog as the main solution.

## Package Hygiene

- [ ] Unzip `submission_files/rakendus.zip` into an empty folder.
- [ ] Confirm it does not contain `.env`, `.DS_Store`, `__MACOSX`, `__pycache__`, `*.pyc`, `venv`, `flask_session`, `.class` or `.jar`.
- [ ] Confirm it contains only app files needed to run the Flask prototype.
