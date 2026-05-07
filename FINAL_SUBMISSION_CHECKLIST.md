# Final Submission Checklist

Use this checklist after the final files are built and before uploading.

## ZIP and File Hygiene

- [ ] Unzip `submission_files/dokument.zip` into an empty folder and confirm it contains only `dokument.docx`.
- [ ] Unzip `submission_files/mudelid.zip` into an empty folder and confirm it contains only `mudelid.eap`.
- [ ] Unzip `submission_files/rakendus.zip` into an empty folder and confirm the Flask app starts from the extracted files.
- [ ] Confirm ZIPs do not contain `.env`, `.DS_Store`, `__MACOSX`, `__pycache__`, `*.pyc`, `venv`, `flask_session`, `.class`, or other generated/local junk.
- [ ] Confirm `submission_files/skript.sql` exists, is non-empty, and matches the final SQL script.

## Database Smoke Test

- [ ] Create or reset a clean local PostgreSQL test database.
- [ ] Run `submission_files/skript.sql` on the clean database.
- [ ] Optionally run `rakendus/test_data.sql` to add demonstration data.
- [ ] Verify tables exist with `\dt`.
- [ ] Verify seed data exists, for example `SELECT COUNT(*) FROM treening;`.

## Application Smoke Test

- [ ] Copy `rakendus/.env.example` to `rakendus/.env`.
- [ ] Edit `.env` so `DB_NAME`, `DB_USER`, `DB_PASSWORD`, host, and port match the local PostgreSQL database.
- [ ] Install application dependencies from `rakendus/requirements.txt`.
- [ ] Start the app using the steps in `rakendus/README.md`.
- [ ] Test public `/trainings` active-training view.
- [ ] Test login with `treener@jousaal.ee` / `treener123`.
- [ ] Test register, edit, activate, deactivate, and forget flows.
- [ ] Test login with `juhataja@jousaal.ee` / `juhataja123`.
- [ ] Test finish-training and report flows.

## Manual-Only Checks

- [ ] Confirm with course staff whether TalTech PostgreSQL server upload is required for the final demonstration.
- [ ] If TalTech server upload is required, upload/deploy the PostgreSQL database separately.
- [ ] Open `mudelid.eap` in Sparx Enterprise Architect and visually inspect diagram readability/layout.
- [ ] Confirm the Sparx EA visual inspection is manual and has not been performed by the automated validator.
