#!/usr/bin/env python3
from __future__ import annotations

import os
import py_compile
import csv
import io
import re
import shutil
import subprocess
import sys
from pathlib import Path, PurePosixPath
from zipfile import BadZipFile, ZipFile

from docx import Document
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DOCX = ROOT / "Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx"
EAP = ROOT / "Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap"
SQL_OUTPUT = ROOT / "jousaali_skript.sql"
APP_DIR = ROOT / "rakendus"
SUBMISSION_DIR = ROOT / "submission_files"
DIAGRAM_SRC = ROOT / "diagrams"
DIAGRAM_DST = ROOT / "work" / "generated_diagrams"

sys.path.insert(0, str(ROOT / "tools"))
from sql_ddl import SQL_DDL  # noqa: E402


REQUIRED_TABLES = [
    "klient",
    "treeninguliik",
    "ruum",
    "treeneri_padevus",
    "treeningukord",
    "treeningukorra_seisundi_liik",
    "registreering",
    "registreeringu_seisundi_liik",
    "osalemine",
]

REQUIRED_FUNCTIONS = [
    "fn_planeeri_treeningukord",
    "fn_ava_treeningukord",
    "fn_sulge_treeningukord",
    "fn_lopeta_treeningukord",
    "fn_registreeri_klient_treeningukorrale",
    "fn_tyhista_registreering",
    "fn_edenda_ootejarjekorrast",
    "fn_marki_osalemine",
    "fn_tyhista_treeningukord",
]

REQUIRED_VIEWS = [
    "v_avalikud_treeningukorrad",
    "v_kliendi_registreeringud",
    "v_treeneri_tunniplaan",
    "v_treeningukorra_osalejad",
    "v_juhataja_treeningukordade_ulevaade",
    "v_treeningute_taituvuse_statistika",
]

REQUIRED_DIAGRAMS = [
    "01_system_context",
    "02_use_cases",
    "03_core_er",
    "04_registration_activity",
    "05_session_state",
    "06_registration_state",
    "07_waitlist_sequence",
    "08_permission_flow",
    "09_app_db_architecture",
]

REQUIRED_DOCX_TERMS = [
    "rühmatreeningute ajakava",
    "treeningukord",
    "registreering",
    "ootejärjekord",
    "osalemine",
    "treeneri pädevus",
    "ruum",
    "fn_registreeri_klient_treeningukorrale",
    "fn_edenda_ootejarjekorrast",
]

REQUIRED_DOCX_CAPTION_TERMS = [
    "Süsteemi kontekst",
    "Kasutusjuhtude kaart",
    "Põhiandmemudel",
    "Registreerimise tegevusvoog",
    "Treeningukorra seisundimudel",
    "Registreeringu seisundimudel",
    "Ootejärjekorra edendamise järjestus",
    "Õiguste ja andmebaasirutiinide seos",
    "Rakenduse ja andmebaasi arhitektuur",
]

FORBIDDEN_DOCX_PHRASES = [
    "broneerimine on skoobist väljas",
    "osalemine on skoobist väljas",
    "ruumide planeerimine on skoobist väljas",
    "mahutavus on skoobist väljas",
]

FORBIDDEN_ZIP_COMPONENTS = {"__MACOSX", "__pycache__", "venv", ".venv", "flask_session"}
FORBIDDEN_ZIP_FILENAMES = {".DS_Store", ".env", "PROJECT_EXPLAINER_NOT_FOR_SUBMISSION.md"}
FORBIDDEN_ZIP_SUFFIXES = {".pyc", ".pyo", ".class", ".jar"}


def fail(message: str, failures: list[str]) -> None:
    failures.append(message)
    print(f"FAIL: {message}")


def ok(message: str) -> None:
    print(f"PASS: {message}")


def warn(message: str) -> None:
    print(f"WARN: {message}")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def docx_text(doc: Document) -> str:
    parts = [p.text for p in doc.paragraphs]
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                parts.extend(p.text for p in cell.paragraphs)
    return "\n".join(parts)


def validate_generated_outputs(failures: list[str]) -> None:
    for path in [DOCX, EAP, SQL_OUTPUT]:
        if path.exists() and path.stat().st_size > 0:
            ok(f"{path.relative_to(ROOT)} exists")
        else:
            fail(f"{path.relative_to(ROOT)} is missing or empty", failures)

    if SQL_OUTPUT.exists():
        expected = SQL_DDL.strip() + "\n"
        actual = SQL_OUTPUT.read_text(encoding="utf-8")
        if actual == expected:
            ok("generated SQL matches tools/sql_ddl.py")
        else:
            fail("generated SQL does not match tools/sql_ddl.py", failures)


def validate_static_sql(failures: list[str]) -> None:
    sql = SQL_DDL.lower()
    for table in REQUIRED_TABLES:
        if re.search(rf"create\s+table\s+{table}\b", sql):
            ok(f"SQL defines table {table}")
        else:
            fail(f"SQL missing table {table}", failures)

    for function in REQUIRED_FUNCTIONS:
        if re.search(rf"create\s+or\s+replace\s+function\s+{function}\b", sql):
            ok(f"SQL defines function {function}")
        else:
            fail(f"SQL missing function {function}", failures)

    for view in REQUIRED_VIEWS:
        if re.search(rf"create\s+view\s+{view}\b", sql):
            ok(f"SQL defines view {view}")
        else:
            fail(f"SQL missing view {view}", failures)

    checks = {
        "partial unique active registration index": r"create\s+unique\s+index\s+uq_registreering_aktiivne_klient_kord[\s\S]+where\s+seisundi_kood\s+in\s+\('kinnit',\s*'ootejrk'\)",
        "trainer overlap trigger/function": r"treeneril on samal ajal juba teine|trg_treeningukord_invariandid",
        "room overlap trigger/function": r"ruumis on samal ajal juba teine|trg_treeningukord_invariandid",
        "capacity trigger/function": r"maksimaalne_osalejate_arv\s+>\s+v_ruumi_mahutavus",
        "trainer competence trigger/function": r"treeneri_padevus",
        "session status transition trigger": r"trg_treeningukord_status_transition",
        "registration status transition trigger": r"trg_registreering_status_transition",
        "waitlist promotion routine": r"fn_edenda_ootejarjekorrast",
    }
    for label, pattern in checks.items():
        if re.search(pattern, sql):
            ok(f"SQL includes {label}")
        else:
            fail(f"SQL missing {label}", failures)

    if "create table treening (" in sql:
        fail("old treening table is still present as a core table", failures)
    else:
        ok("old treening table is not present")


def validate_app(failures: list[str]) -> None:
    app_py = APP_DIR / "app.py"
    try:
        py_compile.compile(str(app_py), doraise=True)
        ok("Flask app compiles")
    except py_compile.PyCompileError as exc:
        fail(f"Flask app does not compile: {exc}", failures)
        return

    source = read_text(app_py)
    for function in [
        "fn_planeeri_treeningukord",
        "fn_registreeri_klient_treeningukorrale",
        "fn_tyhista_registreering",
        "fn_marki_osalemine",
    ]:
        if function in source:
            ok(f"app calls {function}")
        else:
            fail(f"app does not call {function}", failures)

    direct_mutations = re.findall(
        r"\b(INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+(treeningukord|registreering|osalemine)\b",
        source,
        flags=re.I,
    )
    if direct_mutations:
        fail(f"app directly mutates protected core tables: {direct_mutations}", failures)
    else:
        ok("app normal source has no direct INSERT/UPDATE/DELETE on protected core tables")

    required_routes = [
        "/schedule",
        "/client/sessions/<int:treeningukorra_kood>/register",
        "/client/registrations",
        "/manager/sessions",
        "/manager/sessions/new",
        "/trainer/sessions",
        "/trainer/sessions/<int:treeningukorra_kood>/roster",
    ]
    for route in required_routes:
        if route in source:
            ok(f"app defines route {route}")
        else:
            fail(f"app missing route {route}", failures)

    stale_templates = [APP_DIR / "templates" / name for name in ["register_training.html", "trainings.html"]]
    stale_existing = [str(path.relative_to(ROOT)) for path in stale_templates if path.exists()]
    if stale_existing:
        fail(f"stale old training-card templates still exist: {stale_existing}", failures)
    else:
        ok("stale old training-card templates are absent")


def validate_diagrams(failures: list[str]) -> None:
    for name in REQUIRED_DIAGRAMS:
        source = DIAGRAM_SRC / f"{name}.mmd"
        target = DIAGRAM_DST / f"{name}.png"
        if not source.exists():
            fail(f"missing Mermaid source {source.relative_to(ROOT)}", failures)
            continue
        ok(f"Mermaid source exists: {source.relative_to(ROOT)}")

        if not target.exists():
            fail(f"missing rendered diagram {target.relative_to(ROOT)}", failures)
            continue
        if target.stat().st_mtime + 0.5 < source.stat().st_mtime:
            fail(f"rendered diagram is older than source: {target.relative_to(ROOT)}", failures)
        else:
            ok(f"rendered diagram is fresh: {target.relative_to(ROOT)}")

        try:
            image = Image.open(target)
            extrema = image.convert("L").getextrema()
            if image.width < 600 or image.height < 250:
                fail(f"diagram is too small: {target.relative_to(ROOT)} {image.size}", failures)
            elif extrema == (255, 255):
                fail(f"diagram appears blank: {target.relative_to(ROOT)}", failures)
            else:
                ok(f"diagram image is nonblank and readable-sized: {target.relative_to(ROOT)} {image.size}")
        except Exception as exc:
            fail(f"cannot inspect diagram {target.relative_to(ROOT)}: {exc}", failures)


def validate_docx(failures: list[str]) -> None:
    if not DOCX.exists():
        fail("DOCX is missing", failures)
        return

    doc = Document(DOCX)
    text = docx_text(doc).lower()
    for term in REQUIRED_DOCX_TERMS:
        if term.lower() in text:
            ok(f"DOCX contains term: {term}")
        else:
            fail(f"DOCX missing required term: {term}", failures)

    full_text = docx_text(doc)
    for caption in REQUIRED_DOCX_CAPTION_TERMS:
        if caption in full_text:
            ok(f"DOCX contains figure caption fragment: {caption}")
        else:
            fail(f"DOCX missing figure caption fragment: {caption}", failures)

    for phrase in FORBIDDEN_DOCX_PHRASES:
        if phrase in text:
            fail(f"DOCX contains obsolete out-of-scope phrase: {phrase}", failures)
        else:
            ok(f"DOCX does not contain obsolete phrase: {phrase}")

    if len(doc.inline_shapes) >= len(REQUIRED_DIAGRAMS):
        ok(f"DOCX contains {len(doc.inline_shapes)} inline images")
    else:
        fail(f"DOCX contains too few images: {len(doc.inline_shapes)}", failures)

    if "treeningu hind" in text or "käibemaks" in text:
        fail("DOCX still discusses training price/payment", failures)
    else:
        ok("DOCX does not discuss payment/price as core scope")


def eap_export_text() -> str:
    if not shutil.which("mdb-export"):
        return ""
    pieces = []
    for table in ["t_package", "t_object", "t_attribute", "t_diagram"]:
        result = subprocess.run(
            ["mdb-export", str(EAP), table],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        pieces.append(result.stdout)
    return "\n".join(pieces)


def eap_export_rows(table: str) -> list[dict[str, str]]:
    if not shutil.which("mdb-export"):
        return []
    result = subprocess.run(
        ["mdb-export", str(EAP), table],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if result.returncode != 0 or not result.stdout.strip():
        return []
    return list(csv.DictReader(io.StringIO(result.stdout)))


def validate_eap(failures: list[str]) -> None:
    if not EAP.exists() or EAP.stat().st_size == 0:
        fail("EAP is missing or empty", failures)
        return
    ok("EAP exists")

    if not shutil.which("mdb-export"):
        warn("mdb-export is unavailable; skipping deep EAP content check")
        return

    text = eap_export_text()
    required = [
        "Rühmatreeningute ajakava",
        "Treeninguliik",
        "Treeningukord",
        "Registreering",
        "Osalemine",
        "Ruum",
        "Klient",
        "Treeneri_padevus",
        "treeningukord",
        "registreering",
        "osalemine",
    ]
    for item in required:
        if item in text:
            ok(f"EAP contains {item}")
        else:
            fail(f"EAP missing {item}", failures)

    object_rows = eap_export_rows("t_object")
    stale_treening = [
        row for row in object_rows
        if row.get("Object_Type") == "Class" and row.get("Name") == "treening"
    ]
    if stale_treening:
        ids = ", ".join(row.get("Object_ID", "?") for row in stale_treening)
        fail(f"EAP still contains stale physical class/table named exactly treening (Object_ID: {ids})", failures)
    else:
        ok("EAP contains no stale physical class/table named exactly treening")

    old_fragments = [
        "hind_ei_kuulu_skoopi",
        "Treeningu hind eurodes",
        "kestus_minutites, maksimaalne_osalejate_arv, vajalik_varustus",
        "Treeningute arvuline kood",
        "Treeningu registreerimise kuupäev",
        "Treeningu andmete viimase muutmise kuupäev",
    ]
    stale_fragments = [fragment for fragment in old_fragments if fragment in text]
    if stale_fragments:
        fail(f"EAP still contains stale old-model text: {stale_fragments}", failures)
    else:
        ok("EAP stale training-card/price wording absent")


def unsafe_zip_entries(names: list[str]) -> list[str]:
    unsafe = []
    for name in names:
        stripped = name.rstrip("/")
        parts = PurePosixPath(stripped).parts
        if name.startswith("/") or ".." in parts:
            unsafe.append(name)
    return unsafe


def forbidden_zip_entries(names: list[str]) -> list[str]:
    forbidden = []
    for name in names:
        stripped = name.rstrip("/")
        if not stripped:
            continue
        parts = PurePosixPath(stripped).parts
        base = parts[-1]
        if any(part in FORBIDDEN_ZIP_COMPONENTS for part in parts):
            forbidden.append(name)
        elif base in FORBIDDEN_ZIP_FILENAMES:
            forbidden.append(name)
        elif PurePosixPath(base).suffix.lower() in FORBIDDEN_ZIP_SUFFIXES:
            forbidden.append(name)
    return forbidden


def validate_submission(failures: list[str]) -> None:
    expected = {
        "dokument.docx": DOCX,
        "skript.sql": SQL_OUTPUT,
        "mudelid.eap": EAP,
        "rakendus.zip": None,
    }
    if SUBMISSION_DIR.exists():
        actual = {path.name for path in SUBMISSION_DIR.iterdir()}
        extra = sorted(actual - set(expected))
        missing = sorted(set(expected) - actual)
        if extra:
            fail(f"submission_files contains extra entries: {extra}", failures)
        elif missing:
            fail(f"submission_files is missing required entries: {missing}", failures)
        else:
            ok("submission_files contains exactly the four required deliverables")

    for name, source in expected.items():
        path = SUBMISSION_DIR / name
        if not path.exists() or path.stat().st_size == 0:
            fail(f"submission file missing or empty: {name}", failures)
            continue
        ok(f"submission file exists: {name}")
        if source is not None and path.read_bytes() == source.read_bytes():
            ok(f"submission file matches root artifact: {name}")
        elif source is not None:
            fail(f"submission file does not match root artifact: {name}", failures)

    zip_path = SUBMISSION_DIR / "rakendus.zip"
    if not zip_path.exists():
        return
    try:
        with ZipFile(zip_path) as archive:
            bad = archive.testzip()
            if bad:
                fail(f"rakendus.zip has corrupt entry: {bad}", failures)
            else:
                ok("rakendus.zip integrity check passed")
            names = archive.namelist()
            unsafe = unsafe_zip_entries(names)
            forbidden = forbidden_zip_entries(names)
            if unsafe:
                fail(f"rakendus.zip contains unsafe paths: {unsafe}", failures)
            else:
                ok("rakendus.zip contains no unsafe paths")
            if forbidden:
                fail(f"rakendus.zip contains forbidden local/generated files: {forbidden}", failures)
            else:
                ok("rakendus.zip contains no forbidden local/generated files")
            required = {
                ".env.example",
                "README.md",
                "SETUP.sh",
                "app.py",
                "requirements.txt",
                "test_data.sql",
                "templates/base.html",
                "templates/dashboard.html",
                "templates/schedule.html",
                "templates/client_registrations.html",
                "templates/manager_sessions.html",
                "templates/manager_session_form.html",
                "templates/trainer_sessions.html",
                "templates/trainer_roster.html",
                "templates/manager_report.html",
                "templates/login.html",
                "templates/error.html",
            }
            entries = {name.rstrip("/") for name in names}
            missing = sorted(required - entries)
            if missing:
                fail(f"rakendus.zip missing required app files: {missing}", failures)
            else:
                ok("rakendus.zip contains required app files")
    except BadZipFile as exc:
        fail(f"rakendus.zip is unreadable: {exc}", failures)


def validate_packaging_hygiene(failures: list[str]) -> None:
    local_only = []
    for rel in ["rakendus/venv", "rakendus/flask_session"]:
        if (ROOT / rel).exists():
            local_only.append(rel)
    local_only.extend(str(path.relative_to(ROOT)) for path in ROOT.rglob(".DS_Store"))
    if local_only:
        fail(f"local-only files should not be committed/submitted: {local_only}", failures)
    else:
        ok("no local-only app artifacts found")


def validate_live_sql_if_requested(failures: list[str]) -> None:
    if os.environ.get("RUN_LIVE_SQL_TESTS") != "1":
        ok("live SQL behavior tests skipped by default")
        return
    dsn = os.environ.get("LIVE_SQL_DSN")
    if not dsn:
        fail("RUN_LIVE_SQL_TESTS=1 requires LIVE_SQL_DSN pointing to a disposable PostgreSQL database", failures)
        return
    try:
        import psycopg2
    except Exception as exc:
        fail(f"psycopg2 unavailable for live SQL tests: {exc}", failures)
        return

    try:
        conn = psycopg2.connect(dsn)
        conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute(SQL_DDL)

            cur.execute("SELECT COUNT(*) FROM registreering WHERE seisundi_kood = 'OOTEJRK'")
            seeded_waitlisted = cur.fetchone()[0]
            cur.execute("SELECT fn_tyhista_registreering(3000, 'klient@jousaal.ee', 'Live test')")
            cur.execute("SELECT COUNT(*) FROM registreering WHERE registreeringu_kood = 3002 AND seisundi_kood = 'KINNIT'")
            seeded_promoted = cur.fetchone()[0]

            cur.execute(
                """
                SELECT fn_planeeri_treeningukord(
                    1002, 'treener2@jousaal.ee', 'SAAL_A',
                    CURRENT_TIMESTAMP + INTERVAL '60 days',
                    CURRENT_TIMESTAMP + INTERVAL '60 days 75 minutes',
                    CURRENT_TIMESTAMP + INTERVAL '59 days',
                    CURRENT_TIMESTAMP + INTERVAL '59 days',
                    2, 'juhataja@jousaal.ee'
                )
                """
            )
            open_seat_session = cur.fetchone()[0]
            cur.execute("SELECT fn_ava_treeningukord(%s, 'juhataja@jousaal.ee')", (open_seat_session,))
            cur.execute(
                "SELECT * FROM fn_registreeri_klient_treeningukorrale(%s, 'klient4@jousaal.ee')",
                (open_seat_session,),
            )
            confirmed_row = cur.fetchone()

            cur.execute(
                """
                SELECT fn_planeeri_treeningukord(
                    1002, 'treener2@jousaal.ee', 'SAAL_A',
                    CURRENT_TIMESTAMP + INTERVAL '61 days',
                    CURRENT_TIMESTAMP + INTERVAL '61 days 75 minutes',
                    CURRENT_TIMESTAMP + INTERVAL '60 days',
                    CURRENT_TIMESTAMP + INTERVAL '60 days',
                    1, 'juhataja@jousaal.ee'
                )
                """
            )
            full_session = cur.fetchone()[0]
            cur.execute("SELECT fn_ava_treeningukord(%s, 'juhataja@jousaal.ee')", (full_session,))
            cur.execute(
                "SELECT * FROM fn_registreeri_klient_treeningukorrale(%s, 'klient@jousaal.ee')",
                (full_session,),
            )
            full_confirmed = cur.fetchone()
            cur.execute(
                "SELECT * FROM fn_registreeri_klient_treeningukorrale(%s, 'klient2@jousaal.ee')",
                (full_session,),
            )
            waitlisted_row = cur.fetchone()

            duplicate_rejected = False
            duplicate_detail = ""
            try:
                cur.execute(
                    "SELECT * FROM fn_registreeri_klient_treeningukorrale(%s, 'klient@jousaal.ee')",
                    (full_session,),
                )
            except Exception as exc:
                duplicate_rejected = True
                duplicate_detail = str(exc)
                conn.rollback()

            cur.execute(
                "SELECT * FROM fn_tyhista_registreering(%s, 'klient@jousaal.ee', 'Live promotion test')",
                (full_confirmed[0],),
            )
            cancellation_row = cur.fetchone()
            cur.execute(
                "SELECT seisundi_kood FROM registreering WHERE registreeringu_kood = %s",
                (waitlisted_row[0],),
            )
            promoted_status = cur.fetchone()[0]
        conn.close()

        live_failures: list[str] = []
        if seeded_waitlisted < 1 or seeded_promoted != 1:
            live_failures.append("seeded waitlist promotion did not produce expected state")
        if confirmed_row is None or confirmed_row[1] != "KINNIT":
            live_failures.append(f"available-seat registration returned {confirmed_row}")
        if full_confirmed is None or full_confirmed[1] != "KINNIT":
            live_failures.append(f"first full-session registration returned {full_confirmed}")
        if waitlisted_row is None or waitlisted_row[1] != "OOTEJRK" or waitlisted_row[2] is None:
            live_failures.append(f"full-session waitlist registration returned {waitlisted_row}")
        if not duplicate_rejected:
            live_failures.append("duplicate active registration was accepted")
        elif "duplicate key value" not in duplicate_detail and "uq_registreering_aktiivne_klient_kord" not in duplicate_detail:
            live_failures.append(f"duplicate active registration failed for unexpected reason: {duplicate_detail}")
        if cancellation_row is None or cancellation_row[1] != waitlisted_row[0] or promoted_status != "KINNIT":
            live_failures.append(
                f"confirmed cancellation did not promote waitlist row; cancellation={cancellation_row}, promoted_status={promoted_status}"
            )

        if live_failures:
            fail("live SQL tests failed: " + "; ".join(live_failures), failures)
        else:
            ok("live SQL tests confirmed registration, waitlist, duplicate rejection, and promotion")
    except Exception as exc:
        fail(f"live SQL tests failed: {exc}", failures)


def main() -> int:
    failures: list[str] = []
    validate_generated_outputs(failures)
    validate_static_sql(failures)
    validate_app(failures)
    validate_diagrams(failures)
    validate_docx(failures)
    validate_eap(failures)
    validate_submission(failures)
    validate_packaging_hygiene(failures)
    validate_live_sql_if_requested(failures)

    if failures:
        print("\nValidation failed:")
        for failure in failures:
            print(f" - {failure}")
        return 1
    print("\nAll validation checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
