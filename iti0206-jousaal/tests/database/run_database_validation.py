#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

import psycopg2
from psycopg2 import sql
from psycopg2.extensions import connection as PgConnection


ROOT = Path(__file__).resolve().parents[2]
SCHEMA_SQL = ROOT / "jousaali_skript.sql"
SUBMISSION_SQL = ROOT / "submission_files" / "skript.sql"
APP_SEED_SQL = ROOT / "rakendus" / "test_data.sql"
APP_PY = ROOT / "rakendus" / "app.py"
SAFE_DB_PREFIX = "jousaali_db_validation_"
UNSAFE_DATABASE_NAMES = {
    "postgres",
    "template0",
    "template1",
    "production",
    "prod",
    "staging",
    "stage",
    "live",
    "main",
    "default",
    "app",
    "jousaali",
    "jousaali_prod",
    "jousaali_production",
}

APP_MUTATING_FUNCTIONS = (
    "fn_planeeri_treeningukord",
    "fn_ava_treeningukord",
    "fn_sulge_treeningukord",
    "fn_lopeta_treeningukord",
    "fn_registreeri_klient_treeningukorrale",
    "fn_tyhista_registreering",
    "fn_marki_osalemine",
    "fn_tyhista_treeningukord",
)

INTERNAL_MUTATING_FUNCTIONS = ("fn_edenda_ootejarjekorrast",)

MUTATING_FUNCTIONS = (*APP_MUTATING_FUNCTIONS, *INTERNAL_MUTATING_FUNCTIONS)

APP_WORKFLOW_FUNCTIONS = {
    "on_kasutajal_roll",
    "fn_tuvasta_kasutaja_e_meili_jargi",
    "on_juhataja",
    "on_treener",
    *APP_MUTATING_FUNCTIONS,
}

CORE_WRITE_TABLES = ("treeningukord", "registreering", "osalemine", "treeninguliik")
SAFE_SECURITY_DEFINER_SEARCH_PATH = "search_path=public, pg_temp"

EXPECTED_TRIGGER_METADATA = {
    "trg_isik_viimase_muutmise_aeg": ("isik", "fn_uuenda_viimase_muutmise_aeg", {"UPDATE"}),
    "trg_treeninguliik_viimase_muutmise_aeg": ("treeninguliik", "fn_uuenda_viimase_muutmise_aeg", {"UPDATE"}),
    "trg_treeningukord_viimase_muutmise_aeg": ("treeningukord", "fn_uuenda_viimase_muutmise_aeg", {"UPDATE"}),
    "trg_treeneri_padevus_roll": ("treeneri_padevus", "fn_kontrolli_treeneri_padevust", {"INSERT", "UPDATE"}),
    "trg_treeningukord_algseisund": ("treeningukord", "fn_treeningukord_algseisund", {"INSERT"}),
    "trg_treeningukord_seisundisiire": ("treeningukord", "fn_treeningukord_seisundisiire", {"UPDATE"}),
    "trg_treeningukord_invariandid": ("treeningukord", "fn_kontrolli_treeningukorra_invariandid", {"INSERT", "UPDATE"}),
    "trg_registreering_seisundisiire": ("registreering", "fn_registreering_seisundisiire", {"INSERT", "UPDATE"}),
    "trg_osalemine_kontroll": ("osalemine", "fn_kontrolli_osalemine", {"INSERT", "UPDATE"}),
}

EXPECTED_COLUMNS = {
    "riik": ["riigi_kood", "nimetus", "on_aktiivne"],
    "isiku_seisundi_liik": ["isiku_seisundi_liigi_kood", "nimetus", "on_aktiivne"],
    "tootaja_seisundi_liik": ["tootaja_seisundi_liigi_kood", "nimetus", "on_aktiivne"],
    "tootaja_roll": ["tootaja_rolli_kood", "nimetus", "on_aktiivne", "kirjeldus"],
    "treeninguliigi_seisundi_liik": ["treeninguliigi_seisundi_kood", "nimetus", "on_aktiivne"],
    "treeningukorra_seisundi_liik": ["treeningukorra_seisundi_kood", "nimetus", "on_aktiivne", "kirjeldus"],
    "registreeringu_seisundi_liik": ["registreeringu_seisundi_kood", "nimetus", "on_aktiivne", "kirjeldus"],
    "treeningu_kategooria_tyyp": ["treeningu_kategooria_tyybi_kood", "nimetus", "on_aktiivne"],
    "treeningu_kategooria": ["treeningu_kategooria_kood", "treeningu_kategooria_tyybi_kood", "nimetus", "on_aktiivne"],
    "isik": [
        "e_meil",
        "isikukood",
        "riigi_kood",
        "isiku_seisundi_liigi_kood",
        "synni_kp",
        "registreerimise_aeg",
        "viimase_muutmise_aeg",
        "eesnimi",
        "perenimi",
        "elukoht",
    ],
    "kasutajakonto": ["e_meil", "parool", "on_aktiivne"],
    "klient": ["e_meil", "registreerimise_aeg", "on_aktiivne"],
    "tootaja": ["e_meil", "tootaja_seisundi_liigi_kood"],
    "tootaja_rolli_omamine": ["tootaja_e_meil", "tootaja_rolli_kood", "alguse_aeg", "kehtivuse_lopu_aeg"],
    "treeninguliik": [
        "treeninguliigi_id",
        "nimetus",
        "kirjeldus",
        "kestus_minutites",
        "vajalik_varustus",
        "treeninguliigi_seisundi_kood",
        "registreerija_e_meil",
        "viimase_muutja_e_meil",
        "registreerimise_aeg",
        "viimase_muutmise_aeg",
    ],
    "treeninguliigi_kategooria_omamine": ["treeninguliigi_id", "treeningu_kategooria_kood"],
    "varustus": ["varustuse_kood", "nimetus", "kirjeldus", "on_aktiivne"],
    "treeninguliigi_varustuse_noue": [
        "treeninguliigi_id",
        "varustuse_kood",
        "minimaalne_kogus",
        "on_kohustuslik",
        "markus",
    ],
    "ruum": ["ruumi_kood", "nimetus", "asukoht", "mahutavus", "on_aktiivne"],
    "ruumi_varustuse_omamine": ["ruumi_kood", "varustuse_kood", "kogus", "markus"],
    "treeneri_padevus": ["tootaja_e_meil", "treeninguliigi_id", "alates", "kuni"],
    "treeningukord": [
        "treeningukorra_id",
        "treeninguliigi_id",
        "treener_e_meil",
        "ruumi_kood",
        "alguse_aeg",
        "lopu_aeg",
        "registreerimise_lopp",
        "tyhistamise_lopp",
        "maksimaalne_osalejate_arv",
        "treeningukorra_seisundi_kood",
        "looja_e_meil",
        "viimase_muutja_e_meil",
        "loomise_aeg",
        "viimase_muutmise_aeg",
        "tyhistamise_pohjus",
    ],
    "registreering": [
        "registreeringu_id",
        "treeningukorra_id",
        "klient_e_meil",
        "registreeringu_seisundi_kood",
        "registreerimise_aeg",
        "tyhistamise_aeg",
        "edendamise_aeg",
        "tyhistamise_pohjus",
    ],
    "ootejarjekorra_koht": ["registreeringu_id", "treeningukorra_id", "ootejarjekorra_nr"],
    "osalemine": ["registreeringu_id", "klient_e_meil", "treener_e_meil", "on_osalenud", "markija_e_meil", "markimise_aeg", "markus"],
}

CRITICAL_COLUMN_TYPES = {
    ("isik", "e_meil"): ("character varying", "e_meil_aadress", "NO"),
    ("kasutajakonto", "e_meil"): ("character varying", "e_meil_aadress", "NO"),
    ("treeninguliik", "treeninguliigi_id"): ("integer", None, "NO"),
    ("treeninguliik", "treeninguliigi_seisundi_kood"): ("character varying", "kood_10", "NO"),
    ("treeningukord", "alguse_aeg"): ("timestamp with time zone", "ajakava_ajahetk", "NO"),
    ("treeningukord", "lopu_aeg"): ("timestamp with time zone", "ajakava_ajahetk", "NO"),
    ("treeningukord", "treeningukorra_seisundi_kood"): ("character varying", "kood_10", "NO"),
    ("registreering", "registreeringu_seisundi_kood"): ("character varying", "kood_10", "NO"),
    ("ootejarjekorra_koht", "ootejarjekorra_nr"): ("integer", None, "NO"),
    ("osalemine", "klient_e_meil"): ("character varying", "e_meil_aadress", "NO"),
    ("osalemine", "treener_e_meil"): ("character varying", "e_meil_aadress", "NO"),
    ("osalemine", "on_osalenud"): ("boolean", None, "NO"),
}

CRITICAL_QUERIES = [
    (
        "client active registrations use client index",
        "uq_registreering_aktiivne_klient_kord",
        """
        SELECT treeningukorra_id, registreeringu_id
        FROM registreering
        WHERE klient_e_meil = 'klient@jousaal.ee'
          AND registreeringu_seisundi_kood IN ('KINNIT', 'OOTEJRK')
        """,
    ),
    (
        "trainer schedule lookup uses trainer/time index",
        "ix_treeningukord_treener_aeg",
        """
        SELECT *
        FROM treeningukord
        WHERE treener_e_meil = 'treener@jousaal.ee'
        ORDER BY alguse_aeg DESC
        """,
    ),
    (
        "session roster lookup uses session registration index",
        "ix_registreering_treeningukord_seisund_aeg",
        """
        SELECT r.*
        FROM registreering r
        LEFT JOIN ootejarjekorra_koht ok ON ok.registreeringu_id = r.registreeringu_id
        WHERE r.treeningukorra_id = 2002
        ORDER BY ok.ootejarjekorra_nr NULLS LAST, r.registreerimise_aeg
        """,
    ),
    (
        "public schedule state filter uses state index",
        "ix_treeningukord_seisundi_liik",
        """
        SELECT treeningukorra_id, alguse_aeg
        FROM treeningukord
        WHERE treeningukorra_seisundi_kood = 'AVATUD'
          AND registreerimise_lopp >= CURRENT_TIMESTAMP(0)
        ORDER BY alguse_aeg
        """,
    ),
]


@dataclass
class Finding:
    severity: str
    area: str
    test: str
    evidence: str
    why: str
    recommendation: str


class ValidationReport:
    def __init__(self) -> None:
        self.passed: list[str] = []
        self.failed: list[Finding] = []
        self.warnings: list[Finding] = []
        self.skipped: list[str] = []
        self.commands: list[str] = []
        self.created_files: list[str] = [
            "tests/database/run_database_validation.py",
            "tests/database/README.md",
        ]

    def pass_(self, message: str) -> None:
        self.passed.append(message)

    def fail(
        self,
        test: str,
        evidence: str,
        area: str = "database",
        severity: str = "High",
        why: str = "The database does not enforce or expose the expected behavior.",
        recommendation: str = "Adjust the schema, migration, constraint, or DB routine and rerun this suite.",
    ) -> None:
        self.failed.append(Finding(severity, area, test, evidence, why, recommendation))

    def warn(
        self,
        test: str,
        evidence: str,
        area: str = "database",
        severity: str = "Low",
        why: str = "This is a maintainability, performance, or security risk rather than a direct correctness failure.",
        recommendation: str = "Review whether the current design is intentional; add documentation or adjust the schema if needed.",
    ) -> None:
        self.warnings.append(Finding(severity, area, test, evidence, why, recommendation))

    def skip(self, message: str) -> None:
        self.skipped.append(message)

    def command(self, command: str) -> None:
        self.commands.append(command)

    def print_summary(self, dbname: str, server_version: str) -> None:
        print("# Database Validation Result")
        print(f"- Test database: {dbname}")
        print(f"- PostgreSQL version: {server_version}")
        print(f"- Passed checks: {len(self.passed)}")
        print(f"- Failed checks: {len(self.failed)}")
        print(f"- Warnings: {len(self.warnings)}")
        print(f"- Skipped/not applicable: {len(self.skipped)}")
        print()
        for message in self.passed:
            print(f"PASS: {message}")
        for message in self.skipped:
            print(f"SKIP: {message}")
        for finding in self.warnings:
            print(f"WARN [{finding.area}] {finding.test}: {finding.evidence}")
        for finding in self.failed:
            print(f"FAIL [{finding.area}] {finding.test}: {finding.evidence}")

        if self.failed or self.warnings:
            print("\n## Findings")
            for finding in [*self.failed, *self.warnings]:
                print(f"- Severity: {finding.severity}")
                print(f"  Area: {finding.area}")
                print(f"  Failing test: {finding.test}")
                print(f"  Evidence: {finding.evidence}")
                print(f"  Why it matters: {finding.why}")
                print(f"  Recommended fix: {finding.recommendation}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run disposable PostgreSQL database validation checks.")
    parser.add_argument(
        "--admin-dsn",
        default=os.environ.get("DB_VALIDATION_ADMIN_DSN", "dbname=postgres"),
        help="Administrative DSN used only to create/drop disposable validation databases.",
    )
    parser.add_argument(
        "--keep-db",
        action="store_true",
        help="Keep the disposable databases for manual inspection. Cleanup is the default.",
    )
    parser.add_argument(
        "--allow-nonlocal",
        action="store_true",
        help="Allow admin DSNs that do not resolve to a local PostgreSQL server.",
    )
    parser.add_argument(
        "--schema-sql",
        default=str(SCHEMA_SQL),
        help="Project SQL file to apply to fresh validation databases.",
    )
    return parser.parse_args()


def connect(dsn: str | None = None, dbname: str | None = None) -> PgConnection:
    kwargs: dict[str, Any] = {}
    if dbname:
        kwargs["dbname"] = dbname
    return psycopg2.connect(dsn or "", **kwargs)


def fetchone(cur: Any, query: str, params: tuple[Any, ...] = ()) -> tuple[Any, ...]:
    cur.execute(query, params)
    row = cur.fetchone()
    if row is None:
        raise AssertionError(f"Query returned no rows: {query}")
    return row


def fetchall(cur: Any, query: str, params: tuple[Any, ...] = ()) -> list[tuple[Any, ...]]:
    cur.execute(query, params)
    return list(cur.fetchall())


def is_local_admin_connection(conn: PgConnection) -> tuple[bool, str, str]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT
                current_database(),
                current_user,
                COALESCE(inet_server_addr()::text, 'local-socket'),
                COALESCE(inet_server_port()::text, 'local-socket'),
                current_setting('server_version')
            """
        )
        database, user, server_addr, server_port, server_version = cur.fetchone()
    local = server_addr == "local-socket" or server_addr.startswith("127.") or server_addr == "::1"
    return local, f"database={database} user={user} server={server_addr}:{server_port}", server_version


def role_exists(conn: PgConnection, role_name: str) -> bool:
    with conn.cursor() as cur:
        cur.execute("SELECT to_regrole(%s) IS NOT NULL", (role_name,))
        return bool(cur.fetchone()[0])


def assert_safe_disposable_db_name(dbname: str) -> None:
    lowered = dbname.lower()
    if not lowered.startswith(SAFE_DB_PREFIX):
        raise ValueError(f"Refusing unsafe database name without {SAFE_DB_PREFIX!r} prefix: {dbname}")
    if lowered in UNSAFE_DATABASE_NAMES or any(token in lowered for token in ("prod", "staging", "stage", "shared", "cloud")):
        raise ValueError(f"Refusing production-looking database name: {dbname}")


def create_database(admin_dsn: str, dbname: str) -> None:
    assert_safe_disposable_db_name(dbname)
    conn = connect(admin_dsn)
    try:
        conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(dbname)))
    finally:
        conn.close()


def drop_database(admin_dsn: str, dbname: str) -> None:
    assert_safe_disposable_db_name(dbname)
    conn = connect(admin_dsn)
    try:
        conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT pg_terminate_backend(pid)
                FROM pg_stat_activity
                WHERE datname = %s
                  AND pid <> pg_backend_pid()
                """,
                (dbname,),
            )
            cur.execute(sql.SQL("DROP DATABASE IF EXISTS {}").format(sql.Identifier(dbname)))
    finally:
        conn.close()


def drop_created_roles(admin_dsn: str, preexisting_roles: dict[str, bool]) -> None:
    conn = connect(admin_dsn)
    try:
        conn.autocommit = True
        with conn.cursor() as cur:
            for role_name, existed in preexisting_roles.items():
                if not existed:
                    cur.execute(sql.SQL("DROP ROLE IF EXISTS {}").format(sql.Identifier(role_name)))
    finally:
        conn.close()


def list_disposable_databases(admin_dsn: str) -> list[str]:
    conn = connect(admin_dsn)
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT datname
                FROM pg_database
                WHERE datname LIKE %s
                ORDER BY datname
                """,
                (SAFE_DB_PREFIX + "%",),
            )
            return [row[0] for row in cur.fetchall()]
    finally:
        conn.close()


def execute_sql_file(dbname: str, path: Path) -> None:
    assert_safe_disposable_db_name(dbname)
    with connect(dbname=dbname) as conn:
        with conn.cursor() as cur:
            cur.execute(path.read_text(encoding="utf-8"))
        conn.commit()


def validate_generated_sql_consistency(schema_path: Path, report: ValidationReport) -> None:
    if schema_path != SCHEMA_SQL.resolve():
        report.skip("schema SQL generator consistency check skipped for non-default --schema-sql path")
        return
    try:
        sys.path.insert(0, str(ROOT / "tools"))
        from sql_ddl import SQL_DDL  # noqa: PLC0415
    except Exception as exc:  # noqa: BLE001
        report.fail(
            "generated SQL source import",
            f"Could not import tools.sql_ddl.SQL_DDL: {exc!r}",
            area="migrations",
            severity="High",
        )
        return

    expected = SQL_DDL.strip() + "\n"
    actual = schema_path.read_text(encoding="utf-8")
    if actual == expected:
        report.pass_("jousaali_skript.sql matches tools/sql_ddl.py SQL_DDL source")
    else:
        report.fail(
            "generated SQL consistency",
            "jousaali_skript.sql differs from tools/sql_ddl.py SQL_DDL.",
            area="migrations",
            severity="High",
            why="The generated SQL artifact and source generator have drifted.",
            recommendation="Regenerate with .venv/bin/python -c 'from tools.sql_ddl import SQL_DDL; print(SQL_DDL.strip())' > jousaali_skript.sql",
        )


def strip_line_comments(sql_text: str) -> str:
    return "\n".join(line.split("--", 1)[0] for line in sql_text.splitlines())


def validate_sql_artifacts(schema_path: Path, report: ValidationReport) -> None:
    if schema_path == SCHEMA_SQL.resolve() and SUBMISSION_SQL.exists():
        main_sql = schema_path.read_text(encoding="utf-8")
        submission_sql = SUBMISSION_SQL.read_text(encoding="utf-8")
        if main_sql == submission_sql:
            report.pass_("submission_files/skript.sql matches jousaali_skript.sql exactly")
        else:
            report.fail(
                "submission SQL consistency",
                "submission_files/skript.sql differs from jousaali_skript.sql.",
                area="migrations",
                severity="High",
                why="The submitted SQL copy can drift from the generated SQL artifact that validation uses.",
                recommendation="Copy the regenerated jousaali_skript.sql to submission_files/skript.sql.",
            )
    elif schema_path == SCHEMA_SQL.resolve():
        report.skip("submission_files/skript.sql is not present; submission SQL sync check skipped")
    else:
        report.skip("submission SQL sync check skipped for non-default --schema-sql path")

    for path in [schema_path, SUBMISSION_SQL if SUBMISSION_SQL.exists() else None]:
        if path is None:
            continue
        text = path.read_text(encoding="utf-8")
        active_sql = strip_line_comments(text)
        suspicious_patterns = {
            "unresolved TODO/FIXME marker": r"\b(?:TODO|FIXME|XXX|CHANGE_ME|YOUR_[A-Z0-9_]+)\b",
            "template placeholder": r"(\$\{[^}]+\}|\{\{[^}]+\}\}|<[A-Z][A-Z0-9_ -]{2,}>)",
            "inline password assignment": r"(?i)\bpassword\s*=",
            "absolute local path": r"(?i)(?:^|['\"\s])/(?:Users|home|var|tmp)/[A-Za-z0-9_./ -]+",
        }
        for label, pattern in suspicious_patterns.items():
            match = re.search(pattern, active_sql)
            if match:
                report.fail(
                    f"{path.name} {label}",
                    f"Suspicious SQL text: {match.group(0)[:120]!r}",
                    area="migrations",
                    severity="High",
                    why="Generated submission SQL should not contain unresolved placeholders, local-only paths, or inline secrets.",
                    recommendation="Remove the placeholder/secret/path from the SQL generator and regenerate artifacts.",
                )
            else:
                report.pass_(f"{path.name} contains no {label}")

        destructive_sql = re.sub(
            r"\bDROP\s+SCHEMA\s+IF\s+EXISTS\s+public\s+CASCADE\s*;",
            "",
            active_sql,
            count=1,
            flags=re.IGNORECASE,
        )
        if re.search(r"\b(?:DROP|TRUNCATE)\b|\bDELETE\s+FROM\b", destructive_sql, flags=re.IGNORECASE):
            report.warn(
                f"{path.name} destructive SQL scan",
                "Active DROP/TRUNCATE/DELETE statement found in generated SQL.",
                area="migrations",
                severity="Medium",
                why="Final creation scripts should not remove data outside clearly disposable setup contexts.",
                recommendation="Review the active destructive statement and move it to disposable setup tooling if needed.",
            )
        else:
            report.pass_(f"{path.name} has no unexpected active DROP/TRUNCATE/DELETE statements")

        if re.search(r"\bDISABLE\s+TRIGGER\b", active_sql, flags=re.IGNORECASE):
            report.fail(
                f"{path.name} disabled trigger scan",
                "Generated SQL contains DISABLE TRIGGER.",
                area="migrations",
                severity="High",
                why="Validation and seed scripts must not bypass database invariants by disabling triggers.",
                recommendation="Remove DISABLE TRIGGER usage and make seed/import logic satisfy the constraints.",
            )
        else:
            report.pass_(f"{path.name} does not disable triggers")


def validate_database_name_guards(report: ValidationReport) -> None:
    unsafe_samples = sorted(UNSAFE_DATABASE_NAMES | {"jousaali_db_validation_prod", "jousaali_db_validation_staging"})
    rejected = []
    accepted = []
    for name in unsafe_samples:
        try:
            assert_safe_disposable_db_name(name)
        except ValueError:
            rejected.append(name)
        else:
            accepted.append(name)
    if accepted:
        report.fail(
            "disposable database name guard",
            f"Unsafe database names were accepted: {accepted}",
            area="safety",
            severity="Critical",
            why="The harness must not be able to drop or create production-looking targets.",
            recommendation="Tighten assert_safe_disposable_db_name before running destructive validation.",
        )
    else:
        report.pass_(f"unsafe database name guard rejects production-looking names ({len(rejected)})")

    try:
        assert_safe_disposable_db_name(f"{SAFE_DB_PREFIX}unit_test")
    except ValueError as exc:
        report.fail(
            "disposable database name prefix guard",
            f"Safe disposable sample was rejected: {exc}",
            area="safety",
            severity="High",
        )
    else:
        report.pass_("disposable database name guard accepts the required validation prefix")


def expected_objects_from_sql(sql_text: str) -> dict[str, list[str]]:
    patterns = {
        "domains": r"^CREATE\s+DOMAIN\s+([a-z_][a-z0-9_]*)\b",
        "sequences": r"^CREATE\s+SEQUENCE\s+([a-z_][a-z0-9_]*)\b",
        "tables": r"^CREATE\s+TABLE\s+([a-z_][a-z0-9_]*)\b",
        "views": r"^CREATE\s+VIEW\s+([a-z_][a-z0-9_]*)\b",
        "functions": r"^CREATE\s+OR\s+REPLACE\s+FUNCTION\s+([a-z_][a-z0-9_]*)\b",
        "triggers": r"^CREATE\s+TRIGGER\s+([a-z_][a-z0-9_]*)\b",
        "indexes": r"^CREATE\s+(?:UNIQUE\s+)?INDEX\s+([a-z_][a-z0-9_]*)\b",
    }
    return {
        kind: sorted(set(re.findall(pattern, sql_text, flags=re.IGNORECASE | re.MULTILINE)))
        for kind, pattern in patterns.items()
    }


def schema_fingerprint(dbname: str) -> dict[str, Any]:
    with connect(dbname=dbname) as conn, conn.cursor() as cur:
        snapshot: dict[str, Any] = {}
        queries = {
            "columns": """
                SELECT table_name, ordinal_position, column_name, data_type, domain_name,
                       is_nullable, column_default, character_maximum_length, numeric_precision, numeric_scale
                FROM information_schema.columns
                WHERE table_schema = 'public'
                ORDER BY table_name, ordinal_position
            """,
            "constraints": """
                SELECT c.conname, c.contype, c.conrelid::regclass::text, pg_get_constraintdef(c.oid, true)
                FROM pg_constraint c
                JOIN pg_namespace n ON n.oid = c.connamespace
                WHERE n.nspname = 'public'
                ORDER BY c.conrelid::regclass::text, c.conname
            """,
            "indexes": """
                SELECT tablename, indexname, indexdef
                FROM pg_indexes
                WHERE schemaname = 'public'
                ORDER BY tablename, indexname
            """,
            "triggers": """
                SELECT tgrelid::regclass::text, tgname, pg_get_triggerdef(oid, true)
                FROM pg_trigger
                WHERE NOT tgisinternal
                ORDER BY tgrelid::regclass::text, tgname
            """,
            "functions": """
                SELECT p.proname, pg_get_function_arguments(p.oid), pg_get_function_result(p.oid), p.provolatile
                FROM pg_proc p
                JOIN pg_namespace n ON n.oid = p.pronamespace
                WHERE n.nspname = 'public'
                ORDER BY p.proname, pg_get_function_arguments(p.oid)
            """,
            "views": """
                SELECT viewname, definition
                FROM pg_views
                WHERE schemaname = 'public'
                ORDER BY viewname
            """,
            "comments": """
                SELECT objoid::regclass::text, description
                FROM pg_description
                WHERE objsubid = 0
                  AND objoid IN (
                    SELECT c.oid
                    FROM pg_class c
                    JOIN pg_namespace n ON n.oid = c.relnamespace
                    WHERE n.nspname = 'public'
                  )
                ORDER BY objoid::regclass::text
            """,
        }
        for key, query in queries.items():
            cur.execute(query)
            snapshot[key] = [tuple(str(value) for value in row) for row in cur.fetchall()]
        return snapshot


def expect_error(
    report: ValidationReport,
    cur: Any,
    label: str,
    statement: str,
    params: tuple[Any, ...] = (),
    contains: str | None = None,
    sqlstate: str | None = None,
) -> None:
    cur.execute("SAVEPOINT expected_error")
    try:
        cur.execute(statement, params)
    except psycopg2.Error as exc:
        cur.execute("ROLLBACK TO SAVEPOINT expected_error")
        cur.execute("RELEASE SAVEPOINT expected_error")
        message = str(exc)
        if contains and contains not in message:
            report.fail(label, f"Expected error containing {contains!r}, got {message!r}")
            return
        if sqlstate and exc.pgcode != sqlstate:
            report.fail(label, f"Expected SQLSTATE {sqlstate}, got {exc.pgcode}: {message!r}")
            return
        report.pass_(label)
        return
    cur.execute("ROLLBACK TO SAVEPOINT expected_error")
    cur.execute("RELEASE SAVEPOINT expected_error")
    report.fail(label, f"Statement unexpectedly succeeded: {statement.strip()}")


def run_rolled_back(dbname: str, report: ValidationReport, name: str, func: Callable[[Any], None]) -> None:
    try:
        with connect(dbname=dbname) as conn:
            with conn.cursor() as cur:
                func(cur)
            conn.rollback()
    except Exception as exc:  # noqa: BLE001 - test harness must report every unexpected DB issue.
        report.fail(name, f"Unexpected exception: {exc!r}")


class DatabaseValidator:
    def __init__(
        self,
        dbname: str,
        compare_dbname: str,
        schema_path: Path,
        expected: dict[str, list[str]],
        report: ValidationReport,
    ) -> None:
        self.dbname = dbname
        self.compare_dbname = compare_dbname
        self.schema_path = schema_path
        self.expected = expected
        self.report = report

    def run(self) -> None:
        self.run_safe("schema determinism", self.test_schema_determinism)
        self.run_safe("repeated schema attempt", self.test_repeated_schema_attempt)
        self.run_safe("catalog object existence", self.test_catalog_object_existence)
        self.run_safe("column shape", self.test_column_shape)
        self.run_safe("primary keys", self.test_primary_keys)
        self.run_safe("foreign keys and orphans", self.test_foreign_keys_and_orphans)
        self.run_safe("indexes", self.test_indexes)
        self.run_safe("validated constraints", self.test_constraints_are_validated)
        self.run_safe("catalog health", self.test_catalog_health)
        run_rolled_back(self.dbname, self.report, "constraint negative tests", self.test_constraint_negative_cases)
        run_rolled_back(self.dbname, self.report, "default and type tests", self.test_defaults_and_types)
        run_rolled_back(self.dbname, self.report, "trigger and function tests", self.test_triggers_and_functions)
        run_rolled_back(self.dbname, self.report, "view tests", self.test_views)
        run_rolled_back(self.dbname, self.report, "seed idempotency tests", self.test_seed_idempotency)
        self.run_safe("existing data integrity", self.test_existing_data_integrity)
        self.run_safe("query plans", self.test_query_plans)
        self.run_safe("transactions", self.test_transactions)
        self.run_safe("permissions and RLS", self.test_permissions_and_rls)
        self.run_safe("advanced feature detection", self.test_advanced_feature_detection)
        self.run_safe("application SQL integration", self.test_app_sql_integration)
        self.run_safe("compatibility lints", self.test_compatibility_lints)

    def run_safe(self, name: str, func: Callable[[], None]) -> None:
        try:
            func()
        except Exception as exc:  # noqa: BLE001 - report harness/DB errors without aborting cleanup/reporting.
            self.report.fail(
                name,
                f"Unexpected exception: {exc!r}",
                area="test harness",
                severity="High",
                why="A validation section did not complete, so coverage for that area is incomplete.",
                recommendation="Fix the validation harness or the underlying database error and rerun the suite.",
            )

    def test_schema_determinism(self) -> None:
        left = schema_fingerprint(self.dbname)
        right = schema_fingerprint(self.compare_dbname)
        if left == right:
            self.report.pass_("fresh schema is deterministic across two disposable database builds")
        else:
            self.report.fail(
                "fresh schema determinism",
                "Catalog snapshots from two fresh database builds differ.",
                area="migrations",
                severity="High",
                why="A non-deterministic migration can hide drift between environments.",
                recommendation="Remove environment-dependent DDL/defaults or commit a generated schema snapshot and compare it.",
            )

    def test_repeated_schema_attempt(self) -> None:
        before = schema_fingerprint(self.dbname)
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            cur.execute("SAVEPOINT rerun_schema")
            try:
                cur.execute(self.schema_path.read_text(encoding="utf-8"))
            except psycopg2.Error:
                cur.execute("ROLLBACK TO SAVEPOINT rerun_schema")
                cur.execute("RELEASE SAVEPOINT rerun_schema")
                self.report.pass_("repeated schema execution fails cleanly and is rolled back")
            else:
                cur.execute("ROLLBACK TO SAVEPOINT rerun_schema")
                cur.execute("RELEASE SAVEPOINT rerun_schema")
                self.report.pass_("repeated schema execution rebuilds cleanly inside a rollback scope")
            conn.rollback()
        after = schema_fingerprint(self.dbname)
        if before == after:
            self.report.pass_("repeated schema rollback does not mutate committed schema")
        else:
            self.report.fail(
                "repeated schema attempt mutation",
                "Catalog fingerprint changed after a failed repeated schema execution.",
                area="migrations",
                severity="High",
                why="A failed repeated migration attempt left the database in a different state.",
                recommendation="Wrap schema application in a transaction or make repeated execution fully idempotent.",
            )

    def test_catalog_object_existence(self) -> None:
        queries = {
            "domains": "SELECT typname FROM pg_type WHERE typtype = 'd' ORDER BY typname",
            "sequences": """
                SELECT sequence_name FROM information_schema.sequences
                WHERE sequence_schema = 'public'
                ORDER BY sequence_name
            """,
            "tables": """
                SELECT table_name FROM information_schema.tables
                WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
                ORDER BY table_name
            """,
            "views": """
                SELECT table_name FROM information_schema.views
                WHERE table_schema = 'public'
                ORDER BY table_name
            """,
            "functions": """
                SELECT p.proname
                FROM pg_proc p
                JOIN pg_namespace n ON n.oid = p.pronamespace
                WHERE n.nspname = 'public'
                ORDER BY p.proname
            """,
            "triggers": "SELECT tgname FROM pg_trigger WHERE NOT tgisinternal ORDER BY tgname",
            "indexes": "SELECT indexname FROM pg_indexes WHERE schemaname = 'public' ORDER BY indexname",
        }
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            for kind, query in queries.items():
                cur.execute(query)
                actual = {row[0] for row in cur.fetchall()}
                missing = sorted(set(self.expected[kind]) - actual)
                if missing:
                    self.report.fail(
                        f"{kind} existence",
                        f"Missing expected {kind}: {missing}",
                        area="schema",
                        severity="Critical",
                    )
                else:
                    self.report.pass_(f"all expected {kind} exist ({len(self.expected[kind])})")

        if not self.expected["tables"]:
            self.report.fail("migration discovery", "No CREATE TABLE statements were detected in the SQL script.")

    def test_column_shape(self) -> None:
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            for table_name, expected_columns in EXPECTED_COLUMNS.items():
                cur.execute(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = %s
                    ORDER BY ordinal_position
                    """,
                    (table_name,),
                )
                actual = [row[0] for row in cur.fetchall()]
                if actual == expected_columns:
                    self.report.pass_(f"{table_name} columns match expected order and names")
                else:
                    self.report.fail(
                        f"{table_name} column shape",
                        f"Expected {expected_columns}, got {actual}",
                        area="schema",
                        severity="High",
                    )

            for (table_name, column_name), (data_type, domain_name, nullable) in CRITICAL_COLUMN_TYPES.items():
                cur.execute(
                    """
                    SELECT data_type, domain_name, is_nullable
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = %s
                      AND column_name = %s
                    """,
                    (table_name, column_name),
                )
                row = cur.fetchone()
                expected = (data_type, domain_name, nullable)
                if row == expected:
                    self.report.pass_(f"{table_name}.{column_name} has expected type/domain/nullability")
                else:
                    self.report.fail(
                        f"{table_name}.{column_name} type",
                        f"Expected {expected}, got {row}",
                        area="schema",
                        severity="High",
                    )

    def test_primary_keys(self) -> None:
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                  AND table_type = 'BASE TABLE'
                ORDER BY table_name
                """
            )
            tables = [row[0] for row in cur.fetchall()]
            for table_name in tables:
                cur.execute(
                    """
                    SELECT kcu.column_name, c.is_nullable
                    FROM information_schema.table_constraints tc
                    JOIN information_schema.key_column_usage kcu
                      ON kcu.constraint_schema = tc.constraint_schema
                     AND kcu.constraint_name = tc.constraint_name
                    JOIN information_schema.columns c
                      ON c.table_schema = kcu.table_schema
                     AND c.table_name = kcu.table_name
                     AND c.column_name = kcu.column_name
                    WHERE tc.table_schema = 'public'
                      AND tc.table_name = %s
                      AND tc.constraint_type = 'PRIMARY KEY'
                    ORDER BY kcu.ordinal_position
                    """,
                    (table_name,),
                )
                rows = cur.fetchall()
                if not rows:
                    self.report.fail(
                        f"{table_name} primary key",
                        "Table has no primary key.",
                        area="primary keys",
                        severity="High",
                    )
                    continue
                nullable = [column for column, is_nullable in rows if is_nullable != "NO"]
                if nullable:
                    self.report.fail(
                        f"{table_name} primary key nullability",
                        f"Primary key columns are nullable: {nullable}",
                        area="primary keys",
                        severity="Critical",
                    )
                else:
                    self.report.pass_(f"{table_name} has a non-null primary key: {[row[0] for row in rows]}")

    def test_foreign_keys_and_orphans(self) -> None:
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    c.conname,
                    c.conrelid::regclass::text AS child_table,
                    c.confrelid::regclass::text AS parent_table,
                    c.confdeltype,
                    c.confupdtype,
                    ARRAY(
                        SELECT a.attname
                        FROM unnest(c.conkey) WITH ORDINALITY AS cols(attnum, ord)
                        JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = cols.attnum
                        ORDER BY cols.ord
                    ) AS child_columns,
                    ARRAY(
                        SELECT a.attname
                        FROM unnest(c.confkey) WITH ORDINALITY AS cols(attnum, ord)
                        JOIN pg_attribute a ON a.attrelid = c.confrelid AND a.attnum = cols.attnum
                        ORDER BY cols.ord
                    ) AS parent_columns
                FROM pg_constraint c
                JOIN pg_namespace n ON n.oid = c.connamespace
                WHERE n.nspname = 'public'
                  AND c.contype = 'f'
                ORDER BY c.conrelid::regclass::text, c.conname
                """
            )
            fks = cur.fetchall()
            if not fks:
                self.report.fail("foreign key discovery", "No foreign keys found.", area="foreign keys", severity="Critical")
                return
            for conname, child, parent, deltype, updtype, child_cols, parent_cols in fks:
                if deltype == "a" and updtype == "a":
                    self.report.pass_(f"{conname} references {parent} with default NO ACTION update/delete behavior")
                else:
                    self.report.warn(
                        f"{conname} referential action",
                        f"Delete action={deltype}, update action={updtype}",
                        area="foreign keys",
                    )

                child_conditions = [
                    sql.SQL("c.{} IS NOT NULL").format(sql.Identifier(col))
                    for col in child_cols
                ]
                join_conditions = [
                    sql.SQL("p.{} = c.{}").format(sql.Identifier(parent_col), sql.Identifier(child_col))
                    for child_col, parent_col in zip(child_cols, parent_cols, strict=True)
                ]
                orphan_query = sql.SQL("SELECT COUNT(*) FROM {} c WHERE {} AND NOT EXISTS (SELECT 1 FROM {} p WHERE {})").format(
                    sql.Identifier(child),
                    sql.SQL(" AND ").join(child_conditions),
                    sql.Identifier(parent),
                    sql.SQL(" AND ").join(join_conditions),
                )
                cur.execute(orphan_query)
                orphan_count = cur.fetchone()[0]
                if orphan_count == 0:
                    self.report.pass_(f"{conname} has no orphan rows")
                else:
                    self.report.fail(
                        f"{conname} orphan scan",
                        f"Found {orphan_count} orphan rows in {child}.",
                        area="data integrity",
                        severity="Critical",
                    )

    def test_indexes(self) -> None:
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            cur.execute("SELECT indexname FROM pg_indexes WHERE schemaname = 'public'")
            actual_indexes = {row[0] for row in cur.fetchall()}
            for index_name in self.expected["indexes"]:
                if index_name in actual_indexes:
                    self.report.pass_(f"index exists: {index_name}")
                else:
                    self.report.fail(
                        f"index exists: {index_name}",
                        "Index is missing from pg_indexes.",
                        area="indexes",
                        severity="High",
                    )

            cur.execute(
                """
                WITH index_columns AS (
                    SELECT
                        i.indrelid::regclass::text AS table_name,
                        ic.relname AS index_name,
                        ARRAY(
                            SELECT a.attname
                            FROM unnest(i.indkey) WITH ORDINALITY AS k(attnum, ord)
                            JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
                            WHERE k.attnum > 0
                            ORDER BY k.ord
                        ) AS columns
                    FROM pg_index i
                    JOIN pg_class ic ON ic.oid = i.indexrelid
                    JOIN pg_namespace n ON n.oid = ic.relnamespace
                    WHERE n.nspname = 'public'
                ),
                foreign_keys AS (
                    SELECT
                        c.conname,
                        c.conrelid::regclass::text AS table_name,
                        ARRAY(
                            SELECT a.attname
                            FROM unnest(c.conkey) WITH ORDINALITY AS cols(attnum, ord)
                            JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = cols.attnum
                            ORDER BY cols.ord
                        ) AS columns
                    FROM pg_constraint c
                    JOIN pg_namespace n ON n.oid = c.connamespace
                    WHERE n.nspname = 'public'
                      AND c.contype = 'f'
                )
                SELECT fk.conname, fk.table_name, fk.columns
                FROM foreign_keys fk
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM index_columns ic
                    WHERE ic.table_name = fk.table_name
                      AND ic.columns[1:array_length(fk.columns, 1)] = fk.columns
                )
                ORDER BY fk.table_name, fk.conname
                """
            )
            missing_fk_indexes = cur.fetchall()
            if not missing_fk_indexes:
                self.report.pass_("all foreign key columns have a supporting leading index")
            else:
                for conname, table_name, columns in missing_fk_indexes:
                    self.report.warn(
                        f"{conname} supporting index",
                        f"{table_name}{tuple(columns)} is not covered by a leading-column index.",
                        area="indexes",
                        severity="Low",
                        why="Deletes, updates, and joins through this foreign key can become slow as data grows.",
                        recommendation="Add a btree index on the foreign key columns unless the relationship is intentionally low-volume.",
                    )

            cur.execute(
                """
                SELECT a.indexname, b.indexname, a.tablename
                FROM pg_indexes a
                JOIN pg_indexes b
                  ON a.schemaname = b.schemaname
                 AND a.tablename = b.tablename
                 AND a.indexname < b.indexname
                 AND regexp_replace(a.indexdef, '^CREATE (UNIQUE )?INDEX [^ ]+ ', '') =
                     regexp_replace(b.indexdef, '^CREATE (UNIQUE )?INDEX [^ ]+ ', '')
                WHERE a.schemaname = 'public'
                ORDER BY a.tablename, a.indexname, b.indexname
                """
            )
            duplicates = cur.fetchall()
            if duplicates:
                self.report.warn("duplicate index scan", f"Potential duplicate indexes: {duplicates}", area="indexes")
            else:
                self.report.pass_("no exactly duplicated indexes detected")

    def test_constraints_are_validated(self) -> None:
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT conname, conrelid::regclass::text
                FROM pg_constraint
                WHERE connamespace = 'public'::regnamespace
                  AND NOT convalidated
                ORDER BY conrelid::regclass::text, conname
                """
            )
            unvalidated = cur.fetchall()
            if unvalidated:
                self.report.fail(
                    "validated constraints",
                    f"Unvalidated constraints found: {unvalidated}",
                    area="constraints",
                    severity="High",
                )
            else:
                self.report.pass_("all catalog constraints are validated")

    def test_catalog_health(self) -> None:
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            zero_row_checks = [
                (
                    "no disabled user triggers",
                    """
                    SELECT tgrelid::regclass::text, tgname, tgenabled
                    FROM pg_trigger
                    WHERE NOT tgisinternal
                      AND tgenabled <> 'O'
                    ORDER BY tgrelid::regclass::text, tgname
                    """,
                    "triggers",
                    "Disabled triggers can silently bypass business rules and seed validation.",
                ),
                (
                    "no invalid or not-ready indexes",
                    """
                    SELECT i.indrelid::regclass::text, c.relname, i.indisvalid, i.indisready
                    FROM pg_index i
                    JOIN pg_class c ON c.oid = i.indexrelid
                    JOIN pg_namespace n ON n.oid = c.relnamespace
                    WHERE n.nspname = 'public'
                      AND (NOT i.indisvalid OR NOT i.indisready)
                    ORDER BY i.indrelid::regclass::text, c.relname
                    """,
                    "indexes",
                    "Invalid indexes can make constraints or query plans unreliable.",
                ),
                (
                    "no unlogged user tables",
                    """
                    SELECT relname
                    FROM pg_class c
                    JOIN pg_namespace n ON n.oid = c.relnamespace
                    WHERE n.nspname = 'public'
                      AND c.relkind = 'r'
                      AND c.relpersistence = 'u'
                    ORDER BY relname
                    """,
                    "schema",
                    "Unlogged tables lose data after crashes and are not appropriate for durable application data.",
                ),
                (
                    "no unexpected non-system schemas",
                    """
                    SELECT nspname
                    FROM pg_namespace
                    WHERE nspname <> 'public'
                      AND nspname <> 'information_schema'
                      AND nspname NOT LIKE 'pg_%'
                    ORDER BY nspname
                    """,
                    "schema",
                    "The one-shot script is expected to build objects in the public schema only.",
                ),
                (
                    "no duplicate constraint names in public schema",
                    """
                    SELECT conname, COUNT(*)
                    FROM pg_constraint c
                    JOIN pg_namespace n ON n.oid = c.connamespace
                    WHERE n.nspname = 'public'
                    GROUP BY conname
                    HAVING COUNT(*) > 1
                    ORDER BY conname
                    """,
                    "constraints",
                    "Duplicate names make diagnostics and migrations harder to reason about.",
                ),
                (
                    "no duplicate index names in public schema",
                    """
                    SELECT relname, COUNT(*)
                    FROM pg_class c
                    JOIN pg_namespace n ON n.oid = c.relnamespace
                    WHERE n.nspname = 'public'
                      AND c.relkind = 'i'
                    GROUP BY relname
                    HAVING COUNT(*) > 1
                    ORDER BY relname
                    """,
                    "indexes",
                    "Duplicate index names would indicate namespace drift or identifier truncation issues.",
                ),
                (
                    "no object or column names at PostgreSQL identifier limit",
                    """
                    SELECT object_name
                    FROM (
                        SELECT c.relname AS object_name
                        FROM pg_class c
                        JOIN pg_namespace n ON n.oid = c.relnamespace
                        WHERE n.nspname = 'public'
                        UNION ALL
                        SELECT c.relname || '.' || a.attname
                        FROM pg_class c
                        JOIN pg_namespace n ON n.oid = c.relnamespace
                        JOIN pg_attribute a ON a.attrelid = c.oid
                        WHERE n.nspname = 'public'
                          AND c.relkind IN ('r', 'v', 'm')
                          AND a.attnum > 0
                          AND NOT a.attisdropped
                        UNION ALL
                        SELECT conname
                        FROM pg_constraint c
                        JOIN pg_namespace n ON n.oid = c.connamespace
                        WHERE n.nspname = 'public'
                    ) names
                    WHERE octet_length(object_name) >= 63
                    ORDER BY object_name
                    """,
                    "compatibility",
                    "PostgreSQL truncates identifiers to 63 bytes; near-limit names can collide.",
                ),
                (
                    "no case-folded duplicate column names",
                    """
                    SELECT table_name, lower(column_name), COUNT(*)
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                    GROUP BY table_name, lower(column_name)
                    HAVING COUNT(*) > 1
                    ORDER BY table_name, lower(column_name)
                    """,
                    "schema",
                    "Quoted/case-variant duplicate names make application SQL fragile.",
                ),
                (
                    "no duplicate function signatures",
                    """
                    SELECT p.proname, pg_get_function_identity_arguments(p.oid), COUNT(*)
                    FROM pg_proc p
                    JOIN pg_namespace n ON n.oid = p.pronamespace
                    WHERE n.nspname = 'public'
                    GROUP BY p.proname, pg_get_function_identity_arguments(p.oid)
                    HAVING COUNT(*) > 1
                    ORDER BY p.proname
                    """,
                    "functions",
                    "Duplicate signatures would indicate catalog corruption or generation drift.",
                ),
                (
                    "status/type columns are constrained by FK or CHECK",
                    """
                    SELECT c.table_name, c.column_name
                    FROM information_schema.columns c
                    JOIN information_schema.tables t
                      ON t.table_schema = c.table_schema
                     AND t.table_name = c.table_name
                    WHERE c.table_schema = 'public'
                      AND t.table_type = 'BASE TABLE'
                      AND c.column_name ~ ('(seisundi|status|olek|tyyp|roll).*ko' || 'od')
                      AND NOT EXISTS (
                          SELECT 1
                          FROM pg_constraint pc
                          JOIN pg_class r ON r.oid = pc.conrelid
                          JOIN pg_namespace n ON n.oid = pc.connamespace
                          JOIN pg_attribute a ON a.attrelid = pc.conrelid AND a.attnum = ANY(pc.conkey)
                          WHERE n.nspname = 'public'
                            AND r.relname = c.table_name
                            AND a.attname = c.column_name
                            AND pc.contype = 'p'
                      )
                      AND NOT EXISTS (
                          SELECT 1
                          FROM pg_constraint pc
                          JOIN pg_class r ON r.oid = pc.conrelid
                          JOIN pg_namespace n ON n.oid = pc.connamespace
                          JOIN pg_attribute a ON a.attrelid = pc.conrelid AND a.attnum = ANY(pc.conkey)
                          WHERE n.nspname = 'public'
                            AND r.relname = c.table_name
                            AND a.attname = c.column_name
                            AND pc.contype IN ('f', 'c')
                      )
                    ORDER BY c.table_name, c.column_name
                    """,
                    "constraints",
                    "Status/type code columns should be constrained to known values.",
                ),
                (
                    "official-style audit: no view prefix names",
                    """
                    SELECT table_name
                    FROM information_schema.views
                    WHERE table_schema = 'public'
                      AND table_name LIKE 'v\\_%' ESCAPE '\\'
                    ORDER BY table_name
                    """,
                    "naming",
                    "Derived-table names should describe the relation itself rather than use v_/vw_ prefixes.",
                ),
                (
                    "official-style audit: no generic routine naming fragments",
                    """
                    SELECT routine_name
                    FROM information_schema.routines
                    WHERE routine_schema = 'public'
                      AND routine_name ~ '(andmed|info|data)'
                    ORDER BY routine_name
                    """,
                    "naming",
                    "Routine names should describe their result or predicate without generic data/info words.",
                ),
                (
                    "official-style audit: no base column named only kood",
                    """
                    SELECT c.table_name, c.column_name
                    FROM information_schema.columns c
                    JOIN information_schema.tables t
                      ON t.table_schema = c.table_schema
                     AND t.table_name = c.table_name
                    WHERE c.table_schema = 'public'
                      AND t.table_type = 'BASE TABLE'
                      AND c.column_name = 'kood'
                    ORDER BY c.table_name
                    """,
                    "naming",
                    "Classifier key columns should include the entity concept, not only kood.",
                ),
                (
                    "official-style audit: no generated-looking domain check names",
                    """
                    SELECT domain_name, constraint_name
                    FROM information_schema.domain_constraints
                    WHERE domain_schema = 'public'
                      AND constraint_name LIKE '%\\_check' ESCAPE '\\'
                    ORDER BY domain_name, constraint_name
                    """,
                    "naming",
                    "Domain CHECK constraints should be explicitly named for the actual rule.",
                ),
                (
                    "official-style audit: occupancy statistic has specific total column",
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = 'treeningute_taituvuse_statistika'
                      AND column_name = 'treeningukordade_arv'
                    """,
                    "naming",
                    "The total session count column should not be less specific than sibling count columns.",
                ),
                (
                    "official-style audit: table check names include table name",
                    """
                    SELECT rel.relname, con.conname
                    FROM pg_constraint con
                    JOIN pg_class rel ON rel.oid = con.conrelid
                    JOIN pg_namespace ns ON ns.oid = rel.relnamespace
                    WHERE ns.nspname = 'public'
                      AND con.contype = 'c'
                      AND position(rel.relname in con.conname) = 0
                    ORDER BY rel.relname, con.conname
                    """,
                    "naming",
                    "Base-table CHECK names should include the exact table name and checked concept.",
                ),
                (
                    "official-style audit: index names include table name",
                    """
                    SELECT rel.relname, ix.relname
                    FROM pg_index idx
                    JOIN pg_class ix ON ix.oid = idx.indexrelid
                    JOIN pg_class rel ON rel.oid = idx.indrelid
                    JOIN pg_namespace ns ON ns.oid = rel.relnamespace
                    WHERE ns.nspname = 'public'
                      AND NOT idx.indisprimary
                      AND position(rel.relname in ix.relname) = 0
                    ORDER BY rel.relname, ix.relname
                    """,
                    "naming",
                    "Index names should identify their base table and indexed concept.",
                ),
                (
                    "official-style audit: boolean columns use predicate prefix",
                    """
                    SELECT c.table_name, c.column_name
                    FROM information_schema.columns c
                    JOIN information_schema.tables t
                      ON t.table_schema = c.table_schema
                     AND t.table_name = c.table_name
                    WHERE c.table_schema = 'public'
                      AND t.table_type IN ('BASE TABLE', 'VIEW')
                      AND c.data_type = 'boolean'
                      AND c.column_name !~ '^on_'
                    ORDER BY c.table_name, c.column_name
                    """,
                    "naming",
                    "Boolean columns should read as predicates.",
                ),
                (
                    "official-style audit: boolean routines use predicate names",
                    """
                    SELECT p.proname
                    FROM pg_proc p
                    JOIN pg_namespace n ON n.oid = p.pronamespace
                    JOIN pg_type rt ON rt.oid = p.prorettype
                    WHERE n.nspname = 'public'
                      AND p.prokind = 'f'
                      AND rt.typname = 'bool'
                      AND p.proname !~ '^(on|is|has|can|saab)_'
                    ORDER BY p.proname
                    """,
                    "naming",
                    "Boolean-returning routines should start with a predicate verb.",
                ),
                (
                    "official-style audit: no staatus synonym remains",
                    """
                    SELECT name
                    FROM (
                        SELECT table_name AS name
                        FROM information_schema.tables
                        WHERE table_schema = 'public'
                          AND table_name LIKE '%staatus%'
                        UNION ALL
                        SELECT column_name
                        FROM information_schema.columns
                        WHERE table_schema = 'public'
                          AND column_name LIKE '%staatus%'
                        UNION ALL
                        SELECT routine_name
                        FROM information_schema.routines
                        WHERE routine_schema = 'public'
                          AND routine_name LIKE '%staatus%'
                    ) names
                    ORDER BY name
                    """,
                    "naming",
                    "Lifecycle/state naming is standardized on seisund.",
                ),
                (
                    "official-style audit: no SERIAL-style nextval defaults",
                    """
                    SELECT table_name, column_name, column_default
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND column_default LIKE 'nextval%'
                    ORDER BY table_name, column_name
                    """,
                    "schema",
                    "Surrogate keys should use SQL-standard identity columns rather than SERIAL/nextval defaults.",
                ),
                (
                    "official-style audit: no table CHECK IN value lists",
                    """
                    SELECT rel.relname, con.conname
                    FROM pg_constraint con
                    JOIN pg_class rel ON rel.oid = con.conrelid
                    JOIN pg_namespace ns ON ns.oid = rel.relnamespace
                    WHERE ns.nspname = 'public'
                      AND con.contype = 'c'
                      AND pg_get_constraintdef(con.oid) ~* '\\mIN\\s*\\('
                    ORDER BY rel.relname, con.conname
                    """,
                    "schema",
                    "Enumerated lifecycle values should be represented through classifier tables and FKs.",
                ),
                (
                    "official-style audit: SQL routines use modern bodies",
                    """
                    SELECT p.proname
                    FROM pg_proc p
                    JOIN pg_namespace n ON n.oid = p.pronamespace
                    JOIN pg_language l ON l.oid = p.prolang
                    WHERE n.nspname = 'public'
                      AND p.prokind = 'f'
                      AND l.lanname = 'sql'
                      AND pg_get_functiondef(p.oid) NOT ILIKE '%BEGIN ATOMIC%'
                    ORDER BY p.proname
                    """,
                    "functions",
                    "SQL-language routines should avoid old string-literal bodies when the target PostgreSQL supports standard bodies.",
                ),
                (
                    "official-style audit: routines avoid SELECT star",
                    """
                    SELECT p.proname
                    FROM pg_proc p
                    JOIN pg_namespace n ON n.oid = p.pronamespace
                    WHERE n.nspname = 'public'
                      AND p.prokind = 'f'
                      AND pg_get_functiondef(p.oid) ~* 'SELECT\\s+\\*'
                    ORDER BY p.proname
                    """,
                    "functions",
                    "Routine result shape should be explicit.",
                ),
                (
                    "official-style audit: views use security barrier",
                    """
                    SELECT c.relname
                    FROM pg_class c
                    JOIN pg_namespace n ON n.oid = c.relnamespace
                    WHERE n.nspname = 'public'
                      AND c.relkind = 'v'
                      AND NOT COALESCE(c.reloptions @> ARRAY['security_barrier=true'], false)
                    ORDER BY c.relname
                    """,
                    "views",
                    "Views, especially filtered views, should declare security_barrier where appropriate.",
                ),
                (
                    "official-style audit: views are not layered on views",
                    """
                    SELECT DISTINCT v.relname
                    FROM pg_rewrite rw
                    JOIN pg_class v ON v.oid = rw.ev_class
                    JOIN pg_namespace vn ON vn.oid = v.relnamespace
                    JOIN pg_depend d ON d.objid = rw.oid
                    JOIN pg_class dep ON dep.oid = d.refobjid
                    JOIN pg_namespace dn ON dn.oid = dep.relnamespace
                    WHERE vn.nspname = 'public'
                      AND dn.nspname = 'public'
                      AND v.relkind = 'v'
                      AND dep.relkind = 'v'
                      AND dep.oid <> v.oid
                    ORDER BY v.relname
                    """,
                    "views",
                    "Layered derived tables can hide dependencies and widen derived data unnecessarily.",
                ),
            ]
            for label, query, area, why in zero_row_checks:
                cur.execute(query)
                rows = cur.fetchall()
                if rows:
                    self.report.fail(
                        label,
                        f"Unexpected rows: {rows[:10]}",
                        area=area,
                        severity="High" if area in {"constraints", "triggers", "indexes"} else "Medium",
                        why=why,
                        recommendation="Adjust the generator/source SQL so this catalog invariant holds.",
                    )
                else:
                    self.report.pass_(label)

            cur.execute(
                """
                SELECT seq.relname, tbl.relname, attr.attname
                FROM pg_class seq
                JOIN pg_namespace seq_ns ON seq_ns.oid = seq.relnamespace
                JOIN pg_depend dep
                  ON dep.objid = seq.oid
                 AND dep.deptype IN ('a', 'i')
                JOIN pg_class tbl ON tbl.oid = dep.refobjid
                JOIN pg_attribute attr
                  ON attr.attrelid = tbl.oid
                 AND attr.attnum = dep.refobjsubid
                JOIN pg_namespace tbl_ns ON tbl_ns.oid = tbl.relnamespace
                WHERE seq_ns.nspname = 'public'
                  AND tbl_ns.nspname = 'public'
                  AND seq.relkind = 'S'
                ORDER BY seq.relname
                """
            )
            owned_sequences = cur.fetchall()
            if owned_sequences:
                self.report.pass_(f"all discovered sequences are owned by table columns: {owned_sequences}")
            else:
                self.report.fail("sequence ownership", "No owned public sequences were discovered.", area="schema", severity="High")

            for seq_name, table_name, column_name in owned_sequences:
                cur.execute(sql.SQL("SELECT last_value FROM {}").format(sql.Identifier(seq_name)))
                last_value = cur.fetchone()[0]
                cur.execute(
                    sql.SQL("SELECT COALESCE(MAX({}), 0) FROM {}").format(
                        sql.Identifier(column_name),
                        sql.Identifier(table_name),
                    )
                )
                max_value = cur.fetchone()[0]
                if last_value >= max_value:
                    self.report.pass_(f"{seq_name} is aligned with max({table_name}.{column_name})")
                else:
                    self.report.fail(
                        f"{seq_name} sequence alignment",
                        f"last_value={last_value}, max({table_name}.{column_name})={max_value}",
                        area="seed data",
                        severity="High",
                        why="A sequence behind seeded fixed IDs can cause the next generated insert to collide.",
                        recommendation="Run setval after fixed-ID seed inserts and regenerate the SQL artifact.",
                    )

    def test_constraint_negative_cases(self, cur: Any) -> None:
        expect_error(
            self.report,
            cur,
            "primary key duplicate is rejected",
            "INSERT INTO riik (riigi_kood, nimetus) VALUES ('EE', 'Duplicate country')",
            sqlstate="23505",
        )
        expect_error(
            self.report,
            cur,
            "unique constraint duplicate is rejected",
            "INSERT INTO varustus (varustuse_kood, nimetus) VALUES ('MATX', 'Treeningmatid')",
            sqlstate="23505",
        )
        expect_error(
            self.report,
            cur,
            "composite unique constraint duplicate is rejected",
            """
            INSERT INTO treeningu_kategooria (treeningu_kategooria_kood, treeningu_kategooria_tyybi_kood, nimetus)
            VALUES ('JOO2', 'GRUPP', 'Jooga')
            """,
            sqlstate="23505",
        )
        expect_error(
            self.report,
            cur,
            "foreign key invalid reference is rejected",
            """
            INSERT INTO isik (isikukood, riigi_kood, isiku_seisundi_liigi_kood, synni_kp, eesnimi, perenimi, e_meil)
            VALUES ('49901010001', 'NOPE', 'KLIENT', DATE '1999-01-01', 'Test', 'Kasutaja', 'fk-test@example.test')
            """,
            sqlstate="23503",
        )
        expect_error(
            self.report,
            cur,
            "parent delete with children is rejected",
            "DELETE FROM riik WHERE riigi_kood = 'EE'",
            sqlstate="23503",
        )
        cur.execute("SAVEPOINT cascade_update")
        cur.execute("UPDATE riik SET riigi_kood = 'EE2' WHERE riigi_kood = 'EE'")
        cur.execute("SELECT COUNT(*) FROM isik WHERE riigi_kood = 'EE2'")
        if cur.fetchone()[0] > 0:
            self.report.pass_("parent update cascades to child rows")
        else:
            self.report.fail(
                "parent update cascade",
                "Updating riik.riigi_kood did not cascade to child isik rows.",
                area="constraints",
            )
        cur.execute("ROLLBACK TO SAVEPOINT cascade_update")
        cur.execute("RELEASE SAVEPOINT cascade_update")
        expect_error(
            self.report,
            cur,
            "NOT NULL violation is rejected",
            "INSERT INTO riik (riigi_kood, nimetus) VALUES ('NN', NULL)",
            sqlstate="23502",
        )
        expect_error(
            self.report,
            cur,
            "CHECK constraint negative capacity is rejected",
            "INSERT INTO ruum (ruumi_kood, nimetus, mahutavus) VALUES ('BADMAHT', 'Bad room', 0)",
            sqlstate="23514",
        )
        expect_error(
            self.report,
            cur,
            "CHECK constraint duration lower bound is rejected",
            """
            INSERT INTO treeninguliik (nimetus, kestus_minutites, treeninguliigi_seisundi_kood)
            VALUES ('Too short validation class', 14, 'AKTIIVNE')
            """,
            sqlstate="23514",
        )
        expect_error(
            self.report,
            cur,
            "CHECK constraint date ordering is rejected",
            """
            INSERT INTO tootaja_rolli_omamine (tootaja_e_meil, tootaja_rolli_kood, alguse_aeg, kehtivuse_lopu_aeg)
            VALUES ('treener@jousaal.ee', 'TREENER', CURRENT_TIMESTAMP(0), CURRENT_TIMESTAMP(0) - INTERVAL '1 day')
            """,
            sqlstate="23514",
        )
        expect_error(
            self.report,
            cur,
            "email domain requires an at sign",
            "SELECT 'not-an-email'::e_meil_aadress",
            sqlstate="23514",
        )
        expect_error(
            self.report,
            cur,
            "domain blank code is rejected",
            "INSERT INTO riik (riigi_kood, nimetus) VALUES ('', 'Blank code')",
            sqlstate="23514",
        )
        cur.execute(
            """
            INSERT INTO isik (isikukood, riigi_kood, isiku_seisundi_liigi_kood, synni_kp, eesnimi, perenimi, e_meil)
            VALUES ('49901010008', 'EE', 'KLIENT', DATE '1999-01-01', 'Legal', 'Email', 'legal.email+tag@example.test')
            """
        )
        self.report.pass_("email domain accepts common legal local-part characters")
        cur.execute(
            """
            INSERT INTO isik (isikukood, riigi_kood, isiku_seisundi_liigi_kood, synni_kp, eesnimi, perenimi, e_meil)
            VALUES ('49901010009', 'EE', 'KLIENT', DATE '1999-01-01', 'Mononym', NULL, 'mononym@example.test')
            """
        )
        self.report.pass_("person can be registered with one name component")
        expect_error(
            self.report,
            cur,
            "person without any name component is rejected",
            """
            INSERT INTO isik (isikukood, riigi_kood, isiku_seisundi_liigi_kood, synni_kp, eesnimi, perenimi, e_meil)
            VALUES ('49901010010', 'EE', 'KLIENT', DATE '1999-01-01', NULL, NULL, 'noname@example.test')
            """,
            sqlstate="23514",
        )
        expect_error(
            self.report,
            cur,
            "partial active registration uniqueness is enforced",
            """
            INSERT INTO registreering (treeningukorra_id, klient_e_meil, registreeringu_seisundi_kood)
            VALUES (2002, 'klient2@jousaal.ee', 'KINNIT')
            """,
            sqlstate="23505",
        )
        expect_error(
            self.report,
            cur,
            "partial waitlist position uniqueness is enforced",
            """
            WITH uus_registreering AS (
                INSERT INTO registreering (treeningukorra_id, klient_e_meil, registreeringu_seisundi_kood)
                VALUES (2002, 'klient4@jousaal.ee', 'OOTEJRK')
                RETURNING registreeringu_id
            )
            INSERT INTO ootejarjekorra_koht (registreeringu_id, treeningukorra_id, ootejarjekorra_nr)
            SELECT registreeringu_id, 2002, 1
            FROM uus_registreering
            """,
            sqlstate="23505",
        )

        cur.execute(
            """
            INSERT INTO riik (riigi_kood, nimetus) VALUES ('VT', 'Valid Testland');
            INSERT INTO isik (isikukood, riigi_kood, isiku_seisundi_liigi_kood, synni_kp, eesnimi, perenimi, e_meil)
            VALUES ('49901010003', 'VT', 'KLIENT', DATE '1999-01-01', 'Valid', 'Kasutaja', 'valid.constraint@example.test');
            """
        )
        self.report.pass_("valid referenced rows can be inserted")

    def test_defaults_and_types(self, cur: Any) -> None:
        cur.execute("INSERT INTO riik (riigi_kood, nimetus) VALUES ('DF', 'Defaultland') RETURNING on_aktiivne")
        if cur.fetchone()[0] is True:
            self.report.pass_("boolean default on riik.on_aktiivne is applied")
        else:
            self.report.fail("riik.on_aktiivne default", "Default was not TRUE.", area="defaults")

        cur.execute(
            """
            INSERT INTO treeninguliik (nimetus, kirjeldus, kestus_minutites)
            VALUES ('Default validation class', 'Default status/sequence validation.', 30)
            RETURNING treeninguliigi_id, treeninguliigi_seisundi_kood, registreerimise_aeg
            """
        )
        code, status, created_at = cur.fetchone()
        if code and code > 0 and status == "KOOST" and created_at is not None:
            self.report.pass_("treeninguliik sequence, status default, and timestamp default are applied")
        else:
            self.report.fail(
                "treeninguliik defaults",
                f"Unexpected defaults: code={code}, status={status}, created_at={created_at}",
                area="defaults",
            )

        cur.execute(
            """
            INSERT INTO ruum (ruumi_kood, nimetus, mahutavus)
            VALUES ('UNICODE', 'Quotes '' and unicode value', 1)
            RETURNING nimetus
            """
        )
        if "unicode value" in cur.fetchone()[0]:
            self.report.pass_("strings with quotes and special characters are accepted when valid")
        else:
            self.report.fail("string literal handling", "Inserted special-character string was not returned.")

        cur.execute(
            """
            INSERT INTO varustus (varustuse_kood, nimetus, kirjeldus)
            VALUES ('OVERRIDE', 'Override default active flag', 'Explicit default override test')
            RETURNING on_aktiivne
            """
        )
        if cur.fetchone()[0] is True:
            self.report.pass_("varustus.on_aktiivne default is applied")
        else:
            self.report.fail("varustus.on_aktiivne default", "Default was not TRUE.", area="defaults")

    def test_triggers_and_functions(self, cur: Any) -> None:
        cur.execute(
            """
            SELECT
                t.tgname,
                t.tgrelid::regclass::text AS table_name,
                p.proname AS function_name,
                t.tgenabled,
                CASE WHEN (t.tgtype & 2) <> 0 THEN 'BEFORE'
                     WHEN (t.tgtype & 64) <> 0 THEN 'INSTEAD OF'
                     ELSE 'AFTER'
                END AS timing,
                ARRAY_REMOVE(ARRAY[
                    CASE WHEN (t.tgtype & 4) <> 0 THEN 'INSERT' END,
                    CASE WHEN (t.tgtype & 8) <> 0 THEN 'DELETE' END,
                    CASE WHEN (t.tgtype & 16) <> 0 THEN 'UPDATE' END,
                    CASE WHEN (t.tgtype & 32) <> 0 THEN 'TRUNCATE' END
                ], NULL) AS events
            FROM pg_trigger t
            JOIN pg_proc p ON p.oid = t.tgfoid
            WHERE NOT t.tgisinternal
            ORDER BY t.tgname
            """
        )
        trigger_rows = {row[0]: row[1:] for row in cur.fetchall()}
        for trigger_name, (expected_table, expected_function, expected_events) in EXPECTED_TRIGGER_METADATA.items():
            row = trigger_rows.get(trigger_name)
            if row is None:
                self.report.fail(trigger_name, "Expected trigger is missing.", area="triggers", severity="High")
                continue
            table_name, function_name, enabled, timing, events = row
            if (
                table_name == expected_table
                and function_name == expected_function
                and enabled == "O"
                and timing == "BEFORE"
                and set(events) == expected_events
            ):
                self.report.pass_(f"{trigger_name} metadata matches expected table/event/function")
            else:
                self.report.fail(
                    f"{trigger_name} metadata",
                    (
                        f"table={table_name}, function={function_name}, enabled={enabled}, "
                        f"timing={timing}, events={events}"
                    ),
                    area="triggers",
                    severity="High",
                )

        cur.execute(
            """
            SELECT p.proname, pg_get_function_arguments(p.oid), pg_get_function_result(p.oid), p.prosecdef
            FROM pg_proc p
            JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname = 'public'
              AND p.proname = ANY(%s)
            ORDER BY p.proname
            """,
            (list(APP_WORKFLOW_FUNCTIONS),),
        )
        function_rows = cur.fetchall()
        found_functions = {row[0] for row in function_rows}
        missing_functions = sorted(APP_WORKFLOW_FUNCTIONS - found_functions)
        if missing_functions:
            self.report.fail(
                "application workflow function signatures",
                f"Missing functions used by the app/validation workflow: {missing_functions}",
                area="functions",
                severity="High",
            )
        else:
            self.report.pass_("all application workflow functions exist in public schema")

        cur.execute(
            """
            SELECT
                p.proname,
                p.prosecdef,
                COALESCE(p.proconfig, ARRAY[]::text[]) AS proconfig,
                pg_get_userbyid(p.proowner) AS owner_name,
                pg_get_functiondef(p.oid) AS function_definition
            FROM pg_proc p
            JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname = 'public'
              AND p.proname = ANY(%s)
            ORDER BY p.proname
            """,
            (list(MUTATING_FUNCTIONS),),
        )
        mutating_rows = cur.fetchall()
        mutating_found = {row[0] for row in mutating_rows}
        missing_mutating = sorted(set(MUTATING_FUNCTIONS) - mutating_found)
        if missing_mutating:
            self.report.fail(
                "mutating function discovery",
                f"Missing mutating functions: {missing_mutating}",
                area="security",
                severity="High",
            )
        else:
            self.report.pass_("all mutating workflow functions exist for security-definer checks")

        unsafe_security = []
        unsafe_owner = []
        dynamic_sql = []
        for name, prosecdef, proconfig, owner_name, function_definition in mutating_rows:
            if not prosecdef or SAFE_SECURITY_DEFINER_SEARCH_PATH not in proconfig:
                unsafe_security.append((name, prosecdef, proconfig))
            if owner_name in {"jousaali_rakendus", "jousaali_vaatleja"}:
                unsafe_owner.append((name, owner_name))
            if re.search(r"\bEXECUTE\b", function_definition):
                dynamic_sql.append(name)
        if unsafe_security:
            self.report.fail(
                "mutating function SECURITY DEFINER search_path",
                f"Unsafe security-definer settings: {unsafe_security}",
                area="security",
                severity="Critical",
                why="Mutating SECURITY DEFINER functions must fix search_path to trusted schemas.",
                recommendation="Add SECURITY DEFINER SET search_path = public, pg_temp to every mutating workflow function.",
            )
        else:
            self.report.pass_("all mutating workflow functions are SECURITY DEFINER with fixed public, pg_temp search_path")

        if unsafe_owner:
            self.report.fail(
                "mutating function ownership",
                f"Low-privilege roles own SECURITY DEFINER functions: {unsafe_owner}",
                area="security",
                severity="Critical",
                why="A low-privilege owner could alter SECURITY DEFINER behavior or fail to provide needed table privileges.",
                recommendation="Create SECURITY DEFINER functions as the schema owner, not the application or observer role.",
            )
        else:
            self.report.pass_("mutating SECURITY DEFINER functions are not owned by app or observer roles")

        if dynamic_sql:
            self.report.fail(
                "mutating function dynamic SQL scan",
                f"SECURITY DEFINER functions contain dynamic EXECUTE: {dynamic_sql}",
                area="security",
                severity="High",
                why="Dynamic SQL in SECURITY DEFINER functions requires identifier/value quoting review.",
                recommendation="Remove dynamic SQL or verify identifiers use %I and values use USING/%L.",
            )
        else:
            self.report.pass_("mutating SECURITY DEFINER functions contain no dynamic SQL EXECUTE")

        cur.execute("SELECT on_juhataja('juhataja@jousaal.ee'), on_treener('treener@jousaal.ee')")
        if cur.fetchone() == (True, True):
            self.report.pass_("role helper functions return expected seeded role memberships")
        else:
            self.report.fail("role helper functions", "Seeded manager/trainer roles were not recognized.", area="functions")

        cur.execute("SELECT rollid FROM fn_tuvasta_kasutaja_e_meili_jargi('juhataja@jousaal.ee')")
        if "JUHATAJA" in cur.fetchone()[0]:
            self.report.pass_("authentication function returns seeded manager role")
        else:
            self.report.fail("authentication function", "Manager role missing from auth function result.", area="functions")

        expect_error(
            self.report,
            cur,
            "trainer competence trigger rejects non-trainer",
            """
            INSERT INTO treeneri_padevus (tootaja_e_meil, treeninguliigi_id)
            VALUES ('juhataja@jousaal.ee', 1000)
            """,
            contains="aktiivse TREENER",
        )
        expect_error(
            self.report,
            cur,
            "session initial-status trigger rejects non-draft insert",
            """
            INSERT INTO treeningukord (
                treeninguliigi_id, treener_e_meil, ruumi_kood, alguse_aeg, lopu_aeg,
                registreerimise_lopp, tyhistamise_lopp, maksimaalne_osalejate_arv, treeningukorra_seisundi_kood
            )
            VALUES (
                1000, 'treener@jousaal.ee', 'SAAL_B',
                CURRENT_TIMESTAMP(0) + INTERVAL '120 days',
                CURRENT_TIMESTAMP(0) + INTERVAL '120 days 60 minutes',
                CURRENT_TIMESTAMP(0) + INTERVAL '119 days',
                CURRENT_TIMESTAMP(0) + INTERVAL '119 days',
                8, 'AVATUD'
            )
            """,
            contains="KAVAND",
        )
        expect_error(
            self.report,
            cur,
            "capacity trigger rejects over-room capacity",
            """
            SELECT fn_planeeri_treeningukord(
                p_treeninguliigi_id => 1001,
                p_treener_e_meil => 'treener@jousaal.ee',
                p_ruumi_kood => 'SAAL_A',
                p_alguse_aeg => CURRENT_TIMESTAMP(0) + INTERVAL '121 days',
                p_lopu_aeg => CURRENT_TIMESTAMP(0) + INTERVAL '121 days 45 minutes',
                p_registreerimise_lopp => CURRENT_TIMESTAMP(0) + INTERVAL '120 days',
                p_tyhistamise_lopp => CURRENT_TIMESTAMP(0) + INTERVAL '120 days',
                p_maksimaalne_osalejate_arv => 99,
                p_juhataja_e_meil => 'juhataja@jousaal.ee'
            )
            """,
            contains="ületab ruumi mahutavuse",
        )
        expect_error(
            self.report,
            cur,
            "equipment trigger rejects incompatible room",
            """
            SELECT fn_planeeri_treeningukord(
                p_treeninguliigi_id => 1002,
                p_treener_e_meil => 'treener2@jousaal.ee',
                p_ruumi_kood => 'SAAL_A',
                p_alguse_aeg => CURRENT_TIMESTAMP(0) + INTERVAL '122 days',
                p_lopu_aeg => CURRENT_TIMESTAMP(0) + INTERVAL '122 days 75 minutes',
                p_registreerimise_lopp => CURRENT_TIMESTAMP(0) + INTERVAL '121 days',
                p_tyhistamise_lopp => CURRENT_TIMESTAMP(0) + INTERVAL '121 days',
                p_maksimaalne_osalejate_arv => 2,
                p_juhataja_e_meil => 'juhataja@jousaal.ee'
            )
            """,
            contains="Ruumis puudub",
        )
        expect_error(
            self.report,
            cur,
            "session overlap trigger rejects overlapping trainer/room",
            """
            SELECT fn_planeeri_treeningukord(
                p_treeninguliigi_id => 1000,
                p_treener_e_meil => 'treener@jousaal.ee',
                p_ruumi_kood => 'SAAL_B',
                p_alguse_aeg => CURRENT_TIMESTAMP(0) + INTERVAL '7 days 15 minutes',
                p_lopu_aeg => CURRENT_TIMESTAMP(0) + INTERVAL '7 days 75 minutes',
                p_registreerimise_lopp => CURRENT_TIMESTAMP(0) + INTERVAL '6 days',
                p_tyhistamise_lopp => CURRENT_TIMESTAMP(0) + INTERVAL '6 days',
                p_maksimaalne_osalejate_arv => 8,
                p_juhataja_e_meil => 'juhataja@jousaal.ee'
            )
            """,
            contains="samal ajal",
        )
        expect_error(
            self.report,
            cur,
            "registration status trigger rejects invalid insert status",
            """
            INSERT INTO registreering (treeningukorra_id, klient_e_meil, registreeringu_seisundi_kood, tyhistamise_aeg)
            VALUES (2002, 'klient4@jousaal.ee', 'TYH_KL', CURRENT_TIMESTAMP(0))
            """,
            contains="KINNIT või OOTEJRK",
        )

        cur.execute(
            """
            SELECT fn_planeeri_treeningukord(
                p_treeninguliigi_id => 1002,
                p_treener_e_meil => 'treener2@jousaal.ee',
                p_ruumi_kood => 'SAAL_B',
                p_alguse_aeg => CURRENT_TIMESTAMP(0) + INTERVAL '130 days',
                p_lopu_aeg => CURRENT_TIMESTAMP(0) + INTERVAL '130 days 75 minutes',
                p_registreerimise_lopp => CURRENT_TIMESTAMP(0) + INTERVAL '129 days',
                p_tyhistamise_lopp => CURRENT_TIMESTAMP(0) + INTERVAL '129 days',
                p_maksimaalne_osalejate_arv => 1,
                p_juhataja_e_meil => 'juhataja@jousaal.ee'
            )
            """
        )
        cur.execute("SELECT currval('seq_treeningukorra_id')::integer")
        session_id = cur.fetchone()[0]
        cur.execute("SELECT fn_ava_treeningukord(%s, 'juhataja@jousaal.ee')", (session_id,))
        cur.execute("SELECT fn_registreeri_klient_treeningukorrale(%s, 'klient@jousaal.ee')", (session_id,))
        cur.execute("SELECT currval('seq_registreeringu_id')::integer")
        confirmed_id = cur.fetchone()[0]
        cur.execute(
            """
            SELECT r.registreeringu_id, r.registreeringu_seisundi_kood, ok.ootejarjekorra_nr
            FROM registreering r
            LEFT JOIN ootejarjekorra_koht ok ON ok.registreeringu_id = r.registreeringu_id
            WHERE r.registreeringu_id = %s
            """,
            (confirmed_id,),
        )
        confirmed = cur.fetchone()
        cur.execute("SELECT fn_registreeri_klient_treeningukorrale(%s, 'klient2@jousaal.ee')", (session_id,))
        cur.execute("SELECT currval('seq_registreeringu_id')::integer")
        waitlisted_id = cur.fetchone()[0]
        cur.execute(
            """
            SELECT r.registreeringu_id, r.registreeringu_seisundi_kood, ok.ootejarjekorra_nr
            FROM registreering r
            LEFT JOIN ootejarjekorra_koht ok ON ok.registreeringu_id = r.registreeringu_id
            WHERE r.registreeringu_id = %s
            """,
            (waitlisted_id,),
        )
        waitlisted = cur.fetchone()
        if confirmed[1] == "KINNIT" and waitlisted[1] == "OOTEJRK" and waitlisted[2] == 1:
            self.report.pass_("registration function confirms seats and waitlists overflow clients")
        else:
            self.report.fail(
                "registration function capacity behavior",
                f"confirmed={confirmed}, waitlisted={waitlisted}",
                area="functions",
            )

        expect_error(
            self.report,
            cur,
            "duplicate active registration is rejected through DB uniqueness",
            "SELECT fn_registreeri_klient_treeningukorrale(%s, 'klient@jousaal.ee')",
            (session_id,),
            contains="uq_registreering_aktiivne_klient_kord",
        )

        cur.execute(
            "SELECT fn_tyhista_registreering(%s, 'klient@jousaal.ee', 'validation cancellation')",
            (confirmed_id,),
        )
        cur.execute(
            """
            SELECT registreeringu_seisundi_kood
            FROM registreering
            WHERE registreeringu_id = %s
            """,
            (confirmed_id,),
        )
        cancellation = cur.fetchone()
        cur.execute(
            """
            SELECT r.registreeringu_seisundi_kood, ok.ootejarjekorra_nr, r.edendamise_aeg
            FROM registreering r
            LEFT JOIN ootejarjekorra_koht ok ON ok.registreeringu_id = r.registreeringu_id
            WHERE r.registreeringu_id = %s
            """,
            (waitlisted_id,),
        )
        promoted = cur.fetchone()
        if cancellation[0] == "TYH_KL" and promoted[0] == "KINNIT" and promoted[1] is None and promoted[2] is not None:
            self.report.pass_("waitlist promotion works after client cancellation")
        else:
            self.report.fail(
                "waitlist promotion",
                f"cancellation={cancellation}, promoted={promoted}",
                area="functions",
            )

        cur.execute("SELECT fn_tyhista_treeningukord(%s, 'juhataja@jousaal.ee', 'validation cancel')", (session_id,))
        cur.execute(
            """
            SELECT COUNT(*)
            FROM registreering
            WHERE treeningukorra_id = %s
              AND registreeringu_seisundi_kood = 'TYH_SYS'
            """,
            (session_id,),
        )
        if cur.fetchone()[0] == 1:
            self.report.pass_("session cancellation system-cancels remaining active registrations")
        else:
            self.report.fail("session cancellation", "Unexpected affected registration count.", area="functions")

        cur.execute("SELECT fn_marki_osalemine(3003, 'treener@jousaal.ee', TRUE, 'validation update')")
        cur.execute("""
            SELECT klient_e_meil, treener_e_meil, on_osalenud, markija_e_meil, markus
            FROM osalemine
            WHERE registreeringu_id = 3003
        """)
        if cur.fetchone() == ("klient@jousaal.ee", "treener@jousaal.ee", True, "treener@jousaal.ee", "validation update"):
            self.report.pass_("attendance function upserts attendance for completed session")
        else:
            self.report.fail("attendance function", "Attendance row did not update as expected.", area="functions")

        expect_error(
            self.report,
            cur,
            "attendance trigger rejects future/open session attendance",
            "SELECT fn_marki_osalemine(3001, 'treener@jousaal.ee', TRUE, 'too early')",
            contains="suletud või toimunud",
        )

    def test_views(self, cur: Any) -> None:
        cur.execute(
            """
            SELECT v.table_name, COUNT(c.column_name)
            FROM information_schema.views v
            LEFT JOIN information_schema.columns c
              ON c.table_schema = v.table_schema
             AND c.table_name = v.table_name
            WHERE v.table_schema = 'public'
            GROUP BY v.table_name
            ORDER BY v.table_name
            """
        )
        empty_views = [name for name, column_count in cur.fetchall() if column_count == 0]
        if empty_views:
            self.report.fail("view columns", f"Views without visible columns: {empty_views}", area="views", severity="High")
        else:
            self.report.pass_("all user views expose column metadata")

        view_equivalence_checks = [
            (
                "public schedule view row count matches manager overview filter",
                """
                SELECT
                    (SELECT COUNT(*) FROM avalikud_treeningukorrad),
                    (
                        SELECT COUNT(*)
                        FROM juhataja_treeningukordade_ulevaade
                        WHERE korra_seisundi_kood = 'AVATUD'
                          AND registreerimise_lopp >= CURRENT_TIMESTAMP(0)
                    )
                """,
            ),
            (
                "trainer schedule view row count matches base sessions",
                """
                SELECT
                    (SELECT COUNT(*) FROM treeneri_tunniplaan),
                    (SELECT COUNT(*) FROM treeningukord)
                """,
            ),
            (
                "roster view row count matches registrations",
                """
                SELECT
                    (SELECT COUNT(*) FROM treeningukorra_osalejad),
                    (SELECT COUNT(*) FROM registreering)
                """,
            ),
            (
                "client registration view row count matches registrations",
                """
                SELECT
                    (SELECT COUNT(*) FROM kliendi_registreeringud),
                    (SELECT COUNT(*) FROM registreering)
                """,
            ),
        ]
        for label, query in view_equivalence_checks:
            cur.execute(query)
            actual, expected = cur.fetchone()
            if actual == expected:
                self.report.pass_(label)
            else:
                self.report.fail(label, f"actual={actual}, expected={expected}", area="views", severity="High")

        cur.execute(
            """
            SELECT COUNT(*)
            FROM avalikud_treeningukorrad
            WHERE treeningukorra_id IN (2001, 2002)
            """
        )
        if cur.fetchone()[0] == 2:
            self.report.pass_("public schedule view exposes seeded open sessions")
        else:
            self.report.fail("avalikud_treeningukorrad", "Expected seeded open sessions 2001 and 2002.", area="views")

        cur.execute(
            """
            SELECT kinnitatud_osalejate_arv, ootel_registreeringute_arv, vabu_kohti
            FROM juhataja_treeningukordade_ulevaade
            WHERE treeningukorra_id = 2002
            """
        )
        if cur.fetchone() == (2, 1, 0):
            self.report.pass_("manager overview view computes occupancy and waitlist counts")
        else:
            self.report.fail("juhataja_treeningukordade_ulevaade", "Unexpected counts for session 2002.", area="views")

        cur.execute(
            """
            SELECT COUNT(*)
            FROM treeningukorra_osalejad
            WHERE treeningukorra_id = 2003
              AND on_osalenud IS NOT NULL
            """
        )
        if cur.fetchone()[0] == 2:
            self.report.pass_("roster view joins attendance rows for completed sessions")
        else:
            self.report.fail("treeningukorra_osalejad", "Expected two attendance rows for session 2003.", area="views")

        cur.execute(
            """
            SELECT kinnitatud_osalejate_arv, ootel_registreeringute_arv
            FROM treeningute_taituvuse_statistika
            WHERE treeninguliigi_id = 1001
            """
        )
        if cur.fetchone() == (2, 1):
            self.report.pass_("occupancy statistics view aggregates confirmed and waitlisted registrations")
        else:
            self.report.fail("treeningute_taituvuse_statistika", "Unexpected aggregate for HIIT training type.", area="views")

    def test_seed_idempotency(self, cur: Any) -> None:
        tables_to_track = ["isik", "treeningukord", "registreering", "osalemine"]
        before_counts = {table: fetchone(cur, f"SELECT COUNT(*) FROM {table}")[0] for table in tables_to_track}
        cur.execute("SAVEPOINT app_seed_idempotency")
        try:
            cur.execute(APP_SEED_SQL.read_text(encoding="utf-8"))
        except psycopg2.Error as exc:
            cur.execute("ROLLBACK TO SAVEPOINT app_seed_idempotency")
            cur.execute("RELEASE SAVEPOINT app_seed_idempotency")
            self.report.fail(
                "rakendus/test_data.sql idempotency",
                str(exc).strip(),
                area="seed data",
                severity="Medium",
                why="The README says this seed file can be run after schema import to ensure demo data, but rerunning it fires BEFORE INSERT triggers before ON CONFLICT can skip duplicate training sessions.",
                recommendation="Change the seed file to avoid re-inserting existing treeningukord rows, for example with INSERT ... SELECT ... WHERE NOT EXISTS or an upsert path that does not trip overlap triggers.",
            )
        else:
            cur.execute("RELEASE SAVEPOINT app_seed_idempotency")
            after_counts = {table: fetchone(cur, f"SELECT COUNT(*) FROM {table}")[0] for table in tables_to_track}
            if after_counts == before_counts:
                self.report.pass_("rakendus/test_data.sql rerun does not duplicate demo people, sessions, registrations, or attendance")
            else:
                self.report.fail(
                    "seed idempotency",
                    f"Counts changed from {before_counts} to {after_counts}",
                    area="seed data",
                    severity="Medium",
                )

            duplicate_checks = [
                (
                    "no duplicate demo treeningukord natural identities after seed rerun",
                    """
                    SELECT treener_e_meil, treeninguliigi_id, ruumi_kood, alguse_aeg, lopu_aeg, COUNT(*)
                    FROM treeningukord
                    WHERE treeningukorra_id BETWEEN 2000 AND 2999
                    GROUP BY treener_e_meil, treeninguliigi_id, ruumi_kood, alguse_aeg, lopu_aeg
                    HAVING COUNT(*) > 1
                    """,
                ),
                (
                    "no duplicate demo registration logical identities after seed rerun",
                    """
                    SELECT treeningukorra_id, klient_e_meil, registreeringu_seisundi_kood, COUNT(*)
                    FROM registreering
                    WHERE registreeringu_id BETWEEN 3000 AND 3999
                    GROUP BY treeningukorra_id, klient_e_meil, registreeringu_seisundi_kood
                    HAVING COUNT(*) > 1
                    """,
                ),
                (
                    "no duplicate demo attendance rows after seed rerun",
                    """
                    SELECT registreeringu_id, COUNT(*)
                    FROM osalemine
                    GROUP BY registreeringu_id
                    HAVING COUNT(*) > 1
                    """,
                ),
            ]
            for label, query in duplicate_checks:
                cur.execute(query)
                duplicates = cur.fetchall()
                if duplicates:
                    self.report.fail(label, f"Duplicate rows: {duplicates}", area="seed data", severity="Medium")
                else:
                    self.report.pass_(label)

        expected_reference_counts = {
            "riik": 3,
            "treeningukorra_seisundi_liik": 5,
            "registreeringu_seisundi_liik": 4,
            "treeninguliik": 3,
            "ruum": 3,
            "varustus": 6,
        }
        for table_name, expected_count in expected_reference_counts.items():
            actual_count = fetchone(cur, f"SELECT COUNT(*) FROM {table_name}")[0]
            if actual_count >= expected_count:
                self.report.pass_(f"seed data contains expected reference rows for {table_name}")
            else:
                self.report.fail(
                    f"{table_name} seed count",
                    f"Expected at least {expected_count}, got {actual_count}.",
                    area="seed data",
                    severity="High",
                )

    def test_existing_data_integrity(self) -> None:
        checks = [
            (
                "no active session exceeds configured capacity",
                """
                SELECT tk.treeningukorra_id
                FROM treeningukord tk
                LEFT JOIN registreering r
                  ON r.treeningukorra_id = tk.treeningukorra_id
                 AND r.registreeringu_seisundi_kood = 'KINNIT'
                GROUP BY tk.treeningukorra_id, tk.maksimaalne_osalejate_arv
                HAVING COUNT(r.registreeringu_id) > tk.maksimaalne_osalejate_arv
                """,
            ),
            (
                "no active registrations exist for cancelled sessions",
                """
                SELECT r.registreeringu_id
                FROM registreering r
                JOIN treeningukord tk ON tk.treeningukorra_id = r.treeningukorra_id
                WHERE tk.treeningukorra_seisundi_kood = 'TYHIST'
                  AND r.registreeringu_seisundi_kood IN ('KINNIT', 'OOTEJRK')
                """,
            ),
            (
                "no waitlist row has missing/invalid position",
                """
                SELECT r.registreeringu_id
                FROM registreering r
                LEFT JOIN ootejarjekorra_koht ok ON ok.registreeringu_id = r.registreeringu_id
                WHERE r.registreeringu_seisundi_kood = 'OOTEJRK'
                  AND (ok.ootejarjekorra_nr IS NULL OR ok.ootejarjekorra_nr <= 0)
                """,
            ),
            (
                "no impossible registration cancellation timestamp",
                """
                SELECT registreeringu_id
                FROM registreering
                WHERE tyhistamise_aeg IS NOT NULL
                  AND tyhistamise_aeg < registreerimise_aeg
                """,
            ),
            (
                "no impossible session update timestamp",
                """
                SELECT treeningukorra_id
                FROM treeningukord
                WHERE viimase_muutmise_aeg IS NOT NULL
                  AND viimase_muutmise_aeg < loomise_aeg
                """,
            ),
            (
                "attendance only points at confirmed registrations",
                """
                SELECT os.registreeringu_id
                FROM osalemine os
                JOIN registreering r ON r.registreeringu_id = os.registreeringu_id
                WHERE r.registreeringu_seisundi_kood <> 'KINNIT'
                """,
            ),
            (
                "attendance only exists for closed/completed sessions",
                """
                SELECT os.registreeringu_id
                FROM osalemine os
                JOIN registreering r ON r.registreeringu_id = os.registreeringu_id
                JOIN treeningukord tk ON tk.treeningukorra_id = r.treeningukorra_id
                WHERE tk.treeningukorra_seisundi_kood NOT IN ('SULETUD', 'TOIMUNUD')
                """,
            ),
            (
                "attendance client reference matches registration",
                """
                SELECT os.registreeringu_id
                FROM osalemine os
                JOIN registreering r ON r.registreeringu_id = os.registreeringu_id
                WHERE os.klient_e_meil <> r.klient_e_meil
                """,
            ),
            (
                "attendance trainer reference matches session trainer",
                """
                SELECT os.registreeringu_id
                FROM osalemine os
                JOIN registreering r ON r.registreeringu_id = os.registreeringu_id
                JOIN treeningukord tk ON tk.treeningukorra_id = r.treeningukorra_id
                WHERE os.treener_e_meil <> tk.treener_e_meil
                """,
            ),
            (
                "no duplicate lower-cased person emails",
                """
                SELECT lower(e_meil)
                FROM isik
                GROUP BY lower(e_meil)
                HAVING COUNT(*) > 1
                """,
            ),
            (
                "no duplicate non-cancelled session natural identities",
                """
                SELECT treener_e_meil, ruumi_kood, alguse_aeg, lopu_aeg
                FROM treeningukord
                WHERE treeningukorra_seisundi_kood <> 'TYHIST'
                GROUP BY treener_e_meil, ruumi_kood, alguse_aeg, lopu_aeg
                HAVING COUNT(*) > 1
                """,
            ),
            (
                "no duplicate active registrations per client/session",
                """
                SELECT treeningukorra_id, klient_e_meil
                FROM registreering
                WHERE registreeringu_seisundi_kood IN ('KINNIT', 'OOTEJRK')
                GROUP BY treeningukorra_id, klient_e_meil
                HAVING COUNT(*) > 1
                """,
            ),
            (
                "no duplicate waitlist positions per session",
                """
                SELECT ok.treeningukorra_id, ok.ootejarjekorra_nr
                FROM ootejarjekorra_koht ok
                JOIN registreering r ON r.registreeringu_id = ok.registreeringu_id
                WHERE r.registreeringu_seisundi_kood = 'OOTEJRK'
                GROUP BY ok.treeningukorra_id, ok.ootejarjekorra_nr
                HAVING COUNT(*) > 1
                """,
            ),
            (
                "waitlist positions are contiguous per session",
                """
                SELECT treeningukorra_id, ootejarjekorra_nr, expected_nr
                FROM (
                    SELECT
                        ok.treeningukorra_id,
                        ok.ootejarjekorra_nr,
                        ROW_NUMBER() OVER (
                            PARTITION BY ok.treeningukorra_id
                            ORDER BY ok.ootejarjekorra_nr
                        ) AS expected_nr
                    FROM ootejarjekorra_koht ok
                    JOIN registreering r ON r.registreeringu_id = ok.registreeringu_id
                    WHERE r.registreeringu_seisundi_kood = 'OOTEJRK'
                ) ranked
                WHERE ootejarjekorra_nr <> expected_nr
                """,
            ),
            (
                "sessions have strictly positive capacity and valid time window",
                """
                SELECT treeningukorra_id
                FROM treeningukord
                WHERE maksimaalne_osalejate_arv <= 0
                   OR lopu_aeg <= alguse_aeg
                """,
            ),
            (
                "session trainers have active trainer role at session start",
                """
                SELECT tk.treeningukorra_id, tk.treener_e_meil
                FROM treeningukord tk
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM tootaja_rolli_omamine tro
                    WHERE tro.tootaja_e_meil = tk.treener_e_meil
                      AND tro.tootaja_rolli_kood = 'TREENER'
                      AND tro.alguse_aeg <= tk.alguse_aeg
                      AND tro.kehtivuse_lopu_aeg >= tk.alguse_aeg
                )
                """,
            ),
            (
                "closed or completed sessions do not have open registration deadline in future",
                """
                SELECT treeningukorra_id
                FROM treeningukord
                WHERE treeningukorra_seisundi_kood IN ('SULETUD', 'TOIMUNUD', 'TYHIST')
                  AND registreerimise_lopp > CURRENT_TIMESTAMP(0)
                """,
            ),
        ]
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            for label, query in checks:
                cur.execute(query)
                rows = cur.fetchall()
                if rows:
                    self.report.fail(label, f"Invalid rows: {rows[:10]}", area="data integrity", severity="High")
                else:
                    self.report.pass_(label)

    def test_query_plans(self) -> None:
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            cur.execute("SET LOCAL enable_seqscan = off")
            for label, expected_index, query in CRITICAL_QUERIES:
                cur.execute("EXPLAIN " + query)
                plan_text = "\n".join(row[0] for row in cur.fetchall())
                if expected_index in plan_text:
                    self.report.pass_(f"query plan smoke: {label}")
                else:
                    self.report.warn(
                        f"query plan smoke: {label}",
                        f"Expected index {expected_index} was not visible in plan:\n{plan_text}",
                        area="performance",
                        severity="Medium",
                        why="A critical application lookup may not be using the intended access path.",
                        recommendation="Review predicates, index column order, and view definitions with EXPLAIN ANALYZE on realistic data.",
                    )

    def test_transactions(self) -> None:
        with connect(dbname=self.dbname) as conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO riik (riigi_kood, nimetus) VALUES ('RB', 'Rollbackland')")
                conn.rollback()
                cur.execute("SELECT COUNT(*) FROM riik WHERE riigi_kood = 'RB'")
                if cur.fetchone()[0] == 0:
                    self.report.pass_("transaction rollback discards inserted data")
                else:
                    self.report.fail("transaction rollback", "Rolled-back country row is still visible.", area="transactions")

        with connect(dbname=self.dbname) as conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO riik (riigi_kood, nimetus) VALUES ('CM', 'Commitland')")
            conn.commit()
        with connect(dbname=self.dbname) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT COUNT(*) FROM riik WHERE riigi_kood = 'CM'")
                committed = cur.fetchone()[0]
                cur.execute("DELETE FROM riik WHERE riigi_kood = 'CM'")
            conn.commit()
        if committed == 1:
            self.report.pass_("transaction commit persists data")
        else:
            self.report.fail("transaction commit", "Committed country row was not visible.", area="transactions")

        def savepoint_test(cur: Any) -> None:
            cur.execute("SAVEPOINT before_failure")
            try:
                cur.execute("INSERT INTO riik (riigi_kood, nimetus) VALUES ('EE', 'Duplicate')")
            except psycopg2.Error:
                cur.execute("ROLLBACK TO SAVEPOINT before_failure")
            cur.execute("INSERT INTO riik (riigi_kood, nimetus) VALUES ('SV', 'Savepointland')")
            cur.execute("SELECT COUNT(*) FROM riik WHERE riigi_kood = 'SV'")
            if cur.fetchone()[0] == 1:
                self.report.pass_("savepoint rollback recovers after a failed statement")
            else:
                self.report.fail("savepoint recovery", "Valid insert after savepoint rollback failed.", area="transactions")

        run_rolled_back(self.dbname, self.report, "savepoint recovery", savepoint_test)

        with connect(dbname=self.dbname) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT COUNT(*)
                    FROM registreering
                    WHERE treeningukorra_id = 2001
                      AND klient_e_meil = 'klient4@jousaal.ee'
                    """
                )
                before = cur.fetchone()[0]
                cur.execute("SELECT fn_registreeri_klient_treeningukorrale(2001, 'klient4@jousaal.ee')")
                conn.rollback()
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT COUNT(*)
                FROM registreering
                WHERE treeningukorra_id = 2001
                  AND klient_e_meil = 'klient4@jousaal.ee'
                """
            )
            after = cur.fetchone()[0]
        if after == before:
            self.report.pass_("function side effects roll back with transaction rollback")
        else:
            self.report.fail(
                "function transaction rollback",
                f"Registration count changed from {before} to {after} after rollback.",
                area="transactions",
                severity="High",
            )

    def test_permissions_and_rls(self) -> None:
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            cur.execute("SELECT to_regrole('jousaali_vaatleja') IS NOT NULL, to_regrole('jousaali_rakendus') IS NOT NULL")
            viewer_exists, app_exists = cur.fetchone()

            if viewer_exists:
                cur.execute("SET ROLE jousaali_vaatleja")
                cur.execute("SELECT COUNT(*) FROM riik")
                self.report.pass_("read-only viewer role can read tables")
                expect_error(
                    self.report,
                    cur,
                    "read-only viewer role cannot write",
                    "INSERT INTO riik (riigi_kood, nimetus) VALUES ('VW', 'Viewer write')",
                    sqlstate="42501",
                )
                expect_error(
                    self.report,
                    cur,
                    "read-only viewer role cannot execute mutating workflow functions",
                    "SELECT fn_tyhista_treeningukord(2001, 'juhataja@jousaal.ee', 'viewer should not mutate')",
                    sqlstate="42501",
                )
                cur.execute("RESET ROLE")
                cur.execute(
                    """
                    SELECT p.proname
                    FROM pg_proc p
                    JOIN pg_namespace n ON n.oid = p.pronamespace
                    WHERE n.nspname = 'public'
                      AND p.proname = ANY(%s)
                      AND has_function_privilege('jousaali_vaatleja', p.oid, 'EXECUTE')
                    ORDER BY p.proname
                    """,
                    (list(MUTATING_FUNCTIONS),),
                )
                viewer_mutating_executes = cur.fetchall()
                if viewer_mutating_executes:
                    self.report.fail(
                        "observer mutating function EXECUTE grants",
                        f"jousaali_vaatleja can execute mutating functions: {viewer_mutating_executes}",
                        area="security",
                        severity="High",
                    )
                else:
                    self.report.pass_("observer role has no EXECUTE grant on mutating workflow functions")
            else:
                self.report.skip("jousaali_vaatleja role was not created by this PostgreSQL user; viewer permission tests skipped")

            if app_exists:
                cur.execute(
                    """
                    SELECT p.proname
                    FROM pg_proc p
                    JOIN pg_namespace n ON n.oid = p.pronamespace
                    WHERE n.nspname = 'public'
                      AND p.proname = ANY(%s)
                      AND NOT has_function_privilege('jousaali_rakendus', p.oid, 'EXECUTE')
                    ORDER BY p.proname
                    """,
                    (list(APP_WORKFLOW_FUNCTIONS),),
                )
                missing_execute = cur.fetchall()
                if missing_execute:
                    self.report.fail(
                        "application function EXECUTE grants",
                        f"jousaali_rakendus lacks EXECUTE on: {missing_execute}",
                        area="security",
                        severity="High",
                    )
                else:
                    self.report.pass_("application role has EXECUTE on workflow functions")

                cur.execute(
                    """
                    SELECT p.proname
                    FROM pg_proc p
                    JOIN pg_namespace n ON n.oid = p.pronamespace
                    WHERE n.nspname = 'public'
                      AND p.proname = ANY(%s)
                      AND has_function_privilege('jousaali_rakendus', p.oid, 'EXECUTE')
                    ORDER BY p.proname
                    """,
                    (list(INTERNAL_MUTATING_FUNCTIONS),),
                )
                app_internal_executes = cur.fetchall()
                if app_internal_executes:
                    self.report.fail(
                        "application internal mutating function EXECUTE grants",
                        f"jousaali_rakendus can execute internal mutating functions: {app_internal_executes}",
                        area="security",
                        severity="Medium",
                        why="The application role should call public workflow entrypoints, not internal mutation helpers directly.",
                        recommendation="Revoke EXECUTE on internal mutating helper functions from jousaali_rakendus.",
                    )
                else:
                    self.report.pass_("application role cannot execute internal mutating helper functions directly")

                cur.execute("SET ROLE jousaali_rakendus")
                cur.execute("SELECT COUNT(*) FROM avalikud_treeningukorrad")
                cur.execute("SELECT COUNT(*) FROM fn_tuvasta_kasutaja_e_meili_jargi('juhataja@jousaal.ee')")
                cur.execute("SAVEPOINT app_role_workflow")
                app_registration = None
                app_waitlisted = None
                app_registration_cancel = None
                app_cancelled = None
                try:
                    cur.execute("CREATE TEMP TABLE treeningukord (treeningukorra_id INTEGER, marker TEXT)")
                    cur.execute(
                        """
                        SELECT fn_planeeri_treeningukord(
                            p_treeninguliigi_id => 1002,
                            p_treener_e_meil => 'treener2@jousaal.ee',
                            p_ruumi_kood => 'SAAL_B',
                            p_alguse_aeg => CURRENT_TIMESTAMP(0) + INTERVAL '190 days',
                            p_lopu_aeg => CURRENT_TIMESTAMP(0) + INTERVAL '190 days 75 minutes',
                            p_registreerimise_lopp => CURRENT_TIMESTAMP(0) + INTERVAL '189 days',
                            p_tyhistamise_lopp => CURRENT_TIMESTAMP(0) + INTERVAL '189 days',
                            p_maksimaalne_osalejate_arv => 1,
                            p_juhataja_e_meil => 'juhataja@jousaal.ee'
                        )
                        """
                    )
                    cur.execute("SELECT max(treeningukorra_id) FROM public.treeningukord")
                    app_session_id = cur.fetchone()[0]
                    cur.execute("SELECT fn_ava_treeningukord(%s, 'juhataja@jousaal.ee')", (app_session_id,))
                    cur.execute("SELECT fn_registreeri_klient_treeningukorrale(%s, 'klient4@jousaal.ee')", (app_session_id,))
                    cur.execute(
                        """
                        SELECT max(registreeringu_id)
                        FROM public.registreering
                        WHERE treeningukorra_id = %s
                          AND klient_e_meil = 'klient4@jousaal.ee'
                        """,
                        (app_session_id,),
                    )
                    app_registration_id = cur.fetchone()[0]
                    cur.execute(
                        """
                        SELECT r.registreeringu_id, r.registreeringu_seisundi_kood, ok.ootejarjekorra_nr
                        FROM registreering r
                        LEFT JOIN ootejarjekorra_koht ok ON ok.registreeringu_id = r.registreeringu_id
                        WHERE r.registreeringu_id = %s
                        """,
                        (app_registration_id,),
                    )
                    app_registration = cur.fetchone()
                    cur.execute("SELECT fn_registreeri_klient_treeningukorrale(%s, 'klient2@jousaal.ee')", (app_session_id,))
                    cur.execute(
                        """
                        SELECT max(registreeringu_id)
                        FROM public.registreering
                        WHERE treeningukorra_id = %s
                          AND klient_e_meil = 'klient2@jousaal.ee'
                        """,
                        (app_session_id,),
                    )
                    app_waitlisted_id = cur.fetchone()[0]
                    cur.execute(
                        """
                        SELECT r.registreeringu_id, r.registreeringu_seisundi_kood, ok.ootejarjekorra_nr
                        FROM registreering r
                        LEFT JOIN ootejarjekorra_koht ok ON ok.registreeringu_id = r.registreeringu_id
                        WHERE r.registreeringu_id = %s
                        """,
                        (app_waitlisted_id,),
                    )
                    app_waitlisted = cur.fetchone()
                    cur.execute(
                        "SELECT fn_tyhista_registreering(%s, 'klient4@jousaal.ee', 'app role hardening validation')",
                        (app_registration_id,),
                    )
                    cur.execute(
                        """
                        SELECT registreeringu_seisundi_kood
                        FROM registreering
                        WHERE registreeringu_id = %s
                        """,
                        (app_registration_id,),
                    )
                    app_registration_cancel = cur.fetchone()
                    cur.execute("SELECT fn_tyhista_treeningukord(%s, 'juhataja@jousaal.ee', 'app role hardening validation')", (app_session_id,))
                    cur.execute(
                        """
                        SELECT COUNT(*)
                        FROM registreering
                        WHERE treeningukorra_id = %s
                          AND registreeringu_seisundi_kood = 'TYH_SYS'
                        """,
                        (app_session_id,),
                    )
                    app_cancelled = cur.fetchone()[0]
                finally:
                    cur.execute("ROLLBACK TO SAVEPOINT app_role_workflow")
                    cur.execute("RELEASE SAVEPOINT app_role_workflow")
                if (
                    app_registration
                    and app_registration[1] == "KINNIT"
                    and app_waitlisted
                    and app_waitlisted[1] == "OOTEJRK"
                    and app_registration_cancel
                    and app_registration_cancel[0] == "TYH_KL"
                    and app_cancelled == 1
                ):
                    self.report.pass_("application role can run planning, opening, registration, and cancellation through hardened functions")
                    self.report.pass_("SECURITY DEFINER search_path resists temp-table hijack for treeningukord")
                else:
                    self.report.fail(
                        "application role workflow",
                        (
                            "Unexpected workflow result under jousaali_rakendus: "
                            f"registration={app_registration}, waitlisted={app_waitlisted}, "
                            f"registration_cancel={app_registration_cancel}, cancelled={app_cancelled}"
                        ),
                        area="security",
                        severity="High",
                        why="The configured application role cannot perform a normal app write workflow.",
                        recommendation="Grant the required table/function privileges or adjust function security mode safely.",
                    )

                expect_error(
                    self.report,
                    cur,
                    "application role cannot directly INSERT treeningukord",
                    """
                    INSERT INTO treeningukord (
                        treeninguliigi_id, treener_e_meil, ruumi_kood, alguse_aeg, lopu_aeg,
                        registreerimise_lopp, tyhistamise_lopp, maksimaalne_osalejate_arv, treeningukorra_seisundi_kood
                    )
                    VALUES (
                        1000, 'treener@jousaal.ee', 'SAAL_B',
                        CURRENT_TIMESTAMP(0) + INTERVAL '210 days',
                        CURRENT_TIMESTAMP(0) + INTERVAL '210 days 60 minutes',
                        CURRENT_TIMESTAMP(0) + INTERVAL '209 days',
                        CURRENT_TIMESTAMP(0) + INTERVAL '209 days',
                        8, 'KAVAND'
                    )
                    """,
                    sqlstate="42501",
                )
                expect_error(
                    self.report,
                    cur,
                    "application role cannot directly UPDATE treeningukord",
                    "UPDATE treeningukord SET treeningukorra_seisundi_kood = treeningukorra_seisundi_kood WHERE treeningukorra_id = 2001",
                    sqlstate="42501",
                )
                expect_error(
                    self.report,
                    cur,
                    "application role cannot directly DELETE registrations",
                    "DELETE FROM registreering WHERE registreeringu_id = -1",
                    sqlstate="42501",
                )
                cur.execute("RESET ROLE")

                cur.execute(
                    """
                    SELECT t.table_name, p.privilege_type
                    FROM information_schema.tables t
                    CROSS JOIN (VALUES ('INSERT'), ('UPDATE'), ('DELETE')) AS p(privilege_type)
                    WHERE t.table_schema = 'public'
                      AND t.table_type = 'BASE TABLE'
                      AND has_table_privilege(
                          'jousaali_rakendus',
                          format('%I.%I', t.table_schema, t.table_name),
                          p.privilege_type
                      )
                    ORDER BY t.table_name, p.privilege_type
                    """
                )
                app_table_writes = cur.fetchall()
                if app_table_writes:
                    self.report.fail(
                        "application role direct table writes",
                        f"jousaali_rakendus still has base-table write privileges: {app_table_writes}",
                        area="security",
                        severity="High",
                        why="The app should write through hardened SECURITY DEFINER workflow functions.",
                        recommendation="Revoke INSERT/UPDATE/DELETE on base tables from jousaali_rakendus and keep function EXECUTE grants.",
                    )
                else:
                    self.report.pass_("application role has no direct base-table INSERT/UPDATE/DELETE privileges")
            else:
                self.report.skip("jousaali_rakendus role was not created by this PostgreSQL user; application role test skipped")

            cur.execute(
                """
                SELECT p.proname
                FROM pg_proc p
                JOIN pg_namespace n ON n.oid = p.pronamespace
                CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) acl
                WHERE n.nspname = 'public'
                  AND p.proname = ANY(%s)
                  AND acl.grantee = 0
                  AND acl.privilege_type = 'EXECUTE'
                ORDER BY p.proname
                """,
                (list(MUTATING_FUNCTIONS),),
            )
            public_mutating_executes = cur.fetchall()
            if public_mutating_executes:
                self.report.fail(
                    "PUBLIC mutating function EXECUTE grants",
                    f"PUBLIC can execute mutating functions: {public_mutating_executes}",
                    area="security",
                    severity="High",
                    why="PUBLIC function EXECUTE grants make write workflows callable by any role that later gains table privileges.",
                    recommendation="REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC and explicitly grant intended roles.",
                )
            else:
                self.report.pass_("PUBLIC cannot execute mutating workflow functions")

            cur.execute("SAVEPOINT default_function_privilege_probe")
            try:
                cur.execute(
                    """
                    CREATE FUNCTION fn_validation_default_privilege_probe()
                    RETURNS INTEGER
                    LANGUAGE sql
                    AS $probe$ SELECT 1 $probe$
                    """
                )
                cur.execute(
                    """
                    SELECT EXISTS (
                        SELECT 1
                        FROM pg_proc p
                        JOIN pg_namespace n ON n.oid = p.pronamespace
                        CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) acl
                        WHERE n.nspname = 'public'
                          AND p.proname = 'fn_validation_default_privilege_probe'
                          AND acl.grantee = 0
                          AND acl.privilege_type = 'EXECUTE'
                    )
                    """
                )
                public_default_execute = cur.fetchone()[0]
            finally:
                cur.execute("ROLLBACK TO SAVEPOINT default_function_privilege_probe")
                cur.execute("RELEASE SAVEPOINT default_function_privilege_probe")
            if public_default_execute:
                self.report.fail(
                    "default function EXECUTE privileges",
                    "A newly-created public function would be executable by PUBLIC.",
                    area="security",
                    severity="High",
                    why="Future functions can accidentally become publicly executable if default privileges are not hardened.",
                    recommendation="Apply ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC for the schema owner role.",
                )
            else:
                self.report.pass_("default privileges prevent PUBLIC EXECUTE on future functions")

            cur.execute(
                """
                SELECT c.relname, acl.privilege_type
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                CROSS JOIN LATERAL aclexplode(COALESCE(c.relacl, acldefault('r', c.relowner))) acl
                WHERE n.nspname = 'public'
                  AND c.relkind IN ('r', 'v', 'm')
                  AND acl.grantee = 0
                  AND acl.privilege_type IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')
                ORDER BY c.relname, acl.privilege_type
                """
            )
            public_table_writes = cur.fetchall()
            if public_table_writes:
                self.report.fail(
                    "PUBLIC table write privileges",
                    f"PUBLIC has table write privileges: {public_table_writes}",
                    area="security",
                    severity="Critical",
                    why="PUBLIC table writes would allow unintended data mutation outside workflow functions.",
                    recommendation="Revoke table write privileges from PUBLIC.",
                )
            else:
                self.report.pass_("PUBLIC has no table write privileges on public relations")

            cur.execute(
                """
                SELECT EXISTS (
                    SELECT 1
                    FROM pg_namespace n
                    CROSS JOIN LATERAL aclexplode(COALESCE(n.nspacl, acldefault('n', n.nspowner))) acl
                    WHERE n.nspname = 'public'
                      AND acl.grantee = 0
                      AND acl.privilege_type = 'CREATE'
                )
                """
            )
            if cur.fetchone()[0]:
                self.report.warn(
                    "public schema CREATE privilege",
                    "PUBLIC can create objects in schema public.",
                    area="security",
                    severity="Medium",
                    why="Broad schema CREATE grants allow unrelated roles to create objects in the application schema.",
                    recommendation="Keep REVOKE CREATE ON SCHEMA public FROM PUBLIC effective in deployment databases.",
                )
            else:
                self.report.pass_("PUBLIC cannot create objects in schema public")

            cur.execute("SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public'")
            policy_count = cur.fetchone()[0]
            if policy_count == 0:
                self.report.skip("row-level security is not configured and no tenant/account key exists in the schema")
            else:
                self.report.pass_(f"row-level security policies exist ({policy_count})")

            cur.execute("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND column_name ~ '(tenant|organization|workspace|account)_id'")
            if cur.fetchone()[0] == 0:
                self.report.skip("multi-tenancy tests are not applicable: no tenant/account/workspace key columns detected")
            else:
                self.report.warn("multi-tenancy detection", "Tenant-like columns exist; add scoped FK/RLS tests.", area="security")

    def test_advanced_feature_detection(self) -> None:
        feature_queries = [
            (
                "JSON/JSONB",
                """
                SELECT table_name || '.' || column_name
                FROM information_schema.columns
                WHERE table_schema = 'public'
                  AND udt_name IN ('json', 'jsonb')
                ORDER BY table_name, column_name
                """,
                "JSON/JSONB tests are not applicable: no JSON columns detected",
            ),
            (
                "materialized views",
                """
                SELECT matviewname
                FROM pg_matviews
                WHERE schemaname = 'public'
                ORDER BY matviewname
                """,
                "materialized view tests are not applicable: none detected",
            ),
            (
                "generated columns",
                """
                SELECT table_name || '.' || column_name
                FROM information_schema.columns
                WHERE table_schema = 'public'
                  AND is_generated <> 'NEVER'
                ORDER BY table_name, column_name
                """,
                "generated column tests are not applicable: none detected",
            ),
            (
                "partitioned tables",
                """
                SELECT relname
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = 'public'
                  AND c.relkind = 'p'
                ORDER BY relname
                """,
                "partitioning tests are not applicable: no partitioned tables detected",
            ),
            (
                "exclusion constraints",
                """
                SELECT conname
                FROM pg_constraint
                WHERE connamespace = 'public'::regnamespace
                  AND contype = 'x'
                ORDER BY conname
                """,
                "exclusion constraint tests are not applicable: none detected",
            ),
            (
                "deferrable constraints",
                """
                SELECT conname
                FROM pg_constraint
                WHERE connamespace = 'public'::regnamespace
                  AND condeferrable
                ORDER BY conname
                """,
                "deferrable constraint tests are not applicable: none detected",
            ),
            (
                "expression indexes",
                """
                SELECT c.relname
                FROM pg_index i
                JOIN pg_class c ON c.oid = i.indexrelid
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = 'public'
                  AND indexprs IS NOT NULL
                ORDER BY c.relname
                """,
                "expression index tests are not applicable: none detected",
            ),
            (
                "partial indexes",
                """
                SELECT c.relname
                FROM pg_index i
                JOIN pg_class c ON c.oid = i.indexrelid
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = 'public'
                  AND indpred IS NOT NULL
                ORDER BY c.relname
                """,
                "partial index tests are not applicable: none detected",
            ),
            (
                "custom domains",
                """
                SELECT typname
                FROM pg_type
                WHERE typtype = 'd'
                  AND typnamespace = 'public'::regnamespace
                ORDER BY typname
                """,
                "domain tests are not applicable: no custom domains detected",
            ),
            (
                "PostGIS/geospatial",
                """
                SELECT extname
                FROM pg_extension
                WHERE extname IN ('postgis', 'postgis_topology')
                ORDER BY extname
                """,
                "geospatial tests are not applicable: PostGIS extension not detected",
            ),
            (
                "full-text indexes",
                """
                SELECT c.relname
                FROM pg_index i
                JOIN pg_class c ON c.oid = i.indexrelid
                JOIN pg_namespace n ON n.oid = c.relnamespace
                JOIN pg_am am ON am.oid = c.relam
                WHERE n.nspname = 'public'
                  AND am.amname = 'gin'
                ORDER BY c.relname
                """,
                "full-text/search index tests are not applicable: no public GIN indexes detected",
            ),
        ]
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            for feature_name, query, skip_message in feature_queries:
                cur.execute(query)
                rows = cur.fetchall()
                if rows:
                    self.report.pass_(f"{feature_name} feature detected and cataloged: {rows}")
                else:
                    self.report.skip(skip_message)

    def test_app_sql_integration(self) -> None:
        app_source = APP_PY.read_text(encoding="utf-8")
        called_functions = set(re.findall(r"call_session_function\(\s*\"([a-z_][a-z0-9_]*)\"", app_source))
        unknown_functions = sorted(called_functions - APP_WORKFLOW_FUNCTIONS)
        if unknown_functions:
            self.report.fail(
                "Flask app function calls",
                f"Unexpected function names passed to call_session_function: {unknown_functions}",
                area="application integration",
                severity="High",
                why="Dynamic function dispatch is only safe if names are fixed and expected.",
                recommendation="Keep function names allowlisted or route each workflow to a static SQL call.",
            )
        else:
            self.report.pass_("Flask app workflow function names are fixed and expected")

        suspicious_sql_fstrings = []
        for line_no, line in enumerate(app_source.splitlines(), start=1):
            stripped = line.strip()
            if not stripped.startswith(("f\"", "f'", "cur.execute(f\"", "cur.execute(f'")) and "cur.execute(f" not in stripped and "cur.execute(f'" not in stripped:
                continue
            if "SELECT {function_name}({placeholders})" in stripped:
                continue
            suspicious_sql_fstrings.append((line_no, stripped[:140]))
        if suspicious_sql_fstrings:
            self.report.warn(
                "Flask dynamic SQL scan",
                f"Review f-string SQL usage: {suspicious_sql_fstrings}",
                area="application integration",
                severity="Medium",
                why="User-controlled string interpolation into SQL can bypass psycopg2 parameterization.",
                recommendation="Keep SQL values parameterized and allowlist dynamic identifiers.",
            )
        else:
            self.report.pass_("Flask SQL scan found no suspicious f-string SQL beyond allowlisted function dispatch")

        referenced_relations = sorted(set(re.findall(r"\b(?:FROM|JOIN|INTO|UPDATE)\s+([a-z_][a-z0-9_]*)", app_source)))
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT relname
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = 'public'
                  AND c.relkind IN ('r', 'v', 'm')
                """
            )
            existing_relations = {row[0] for row in cur.fetchall()}
            cur.execute(
                """
                SELECT p.proname
                FROM pg_proc p
                JOIN pg_namespace n ON n.oid = p.pronamespace
                WHERE n.nspname = 'public'
                """
            )
            existing_functions = {row[0] for row in cur.fetchall()}
            missing_relations = [
                name for name in referenced_relations
                if name not in existing_relations and name not in existing_functions
            ]
            if missing_relations:
                self.report.fail(
                    "Flask SQL referenced relations",
                    f"Missing relations/functions referenced by app.py FROM/JOIN/UPDATE clauses: {missing_relations}",
                    area="application integration",
                    severity="High",
                )
            else:
                self.report.pass_(f"Flask SQL referenced relations/table-valued functions exist: {referenced_relations}")

            missing_called_functions = sorted(called_functions - existing_functions)
            if missing_called_functions:
                self.report.fail(
                    "Flask SQL function references",
                    f"Missing functions referenced by app.py: {missing_called_functions}",
                    area="application integration",
                    severity="High",
                )
            else:
                self.report.pass_("Flask app referenced workflow functions exist")

    def test_compatibility_lints(self) -> None:
        with connect(dbname=self.dbname) as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT names.object_name, names.word
                FROM (
                    SELECT table_name AS object_name, table_name AS word
                    FROM information_schema.tables
                    WHERE table_schema = 'public'
                    UNION ALL
                    SELECT table_name || '.' || column_name, column_name
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                ) names
                JOIN pg_get_keywords() kw ON kw.word = names.word
                WHERE kw.catcode IN ('R', 'T')
                ORDER BY object_name
                """
            )
            keyword_hits = cur.fetchall()
            if keyword_hits:
                self.report.warn("reserved keyword names", f"Potential keyword conflicts: {keyword_hits}", area="compatibility")
            else:
                self.report.pass_("no table or column names use reserved/type PostgreSQL keywords")

            cur.execute(
                """
                SELECT table_name, column_name
                FROM information_schema.columns
                WHERE table_schema = 'public'
                  AND data_type = 'text'
                  AND table_name NOT LIKE 'v_%'
                ORDER BY table_name, column_name
                """
            )
            text_columns = cur.fetchall()
            if text_columns:
                self.report.pass_(f"text columns are intentional descriptive fields: {text_columns}")
            else:
                self.report.pass_("no broad text columns detected")

            cur.execute(
                """
                SELECT extname
                FROM pg_extension
                WHERE extname = 'pgtap'
                """
            )
            if cur.fetchone():
                self.report.pass_("pgTAP is installed, though this harness uses psycopg2 assertions")
            else:
                self.report.skip("pgTAP is not installed; using standalone psycopg2 assertions instead")


def main() -> int:
    args = parse_args()
    schema_path = Path(args.schema_sql).resolve()
    if not schema_path.exists():
        print(f"Schema SQL file does not exist: {schema_path}", file=sys.stderr)
        return 2

    report = ValidationReport()
    report.command(f"{sys.executable} tests/database/run_database_validation.py")
    validate_database_name_guards(report)
    validate_generated_sql_consistency(schema_path, report)
    validate_sql_artifacts(schema_path, report)

    with connect(args.admin_dsn) as admin_conn:
        local, target, server_version = is_local_admin_connection(admin_conn)
        preexisting_roles = {
            "jousaali_rakendus": role_exists(admin_conn, "jousaali_rakendus"),
            "jousaali_vaatleja": role_exists(admin_conn, "jousaali_vaatleja"),
        }

    if not local and not args.allow_nonlocal:
        print(f"Refusing to create a validation database on non-local PostgreSQL target: {target}", file=sys.stderr)
        print("Use --allow-nonlocal only for a verified disposable server.", file=sys.stderr)
        return 2
    if local:
        report.pass_(f"admin connection is local and disposable validation is allowed: {target}")

    stamp = f"{int(time.time())}_{os.getpid()}"
    dbname = f"{SAFE_DB_PREFIX}{stamp}_a"
    compare_dbname = f"{SAFE_DB_PREFIX}{stamp}_b"
    expected = expected_objects_from_sql(schema_path.read_text(encoding="utf-8"))

    print(f"Creating disposable PostgreSQL databases on {target}")
    print(f"Primary database: {dbname}")
    print(f"Comparison database: {compare_dbname}")

    created = [dbname, compare_dbname]
    try:
        for database in created:
            create_database(args.admin_dsn, database)
            execute_sql_file(database, schema_path)
            report.pass_(f"fresh migration/schema SQL applied to {database}")

        validator = DatabaseValidator(dbname, compare_dbname, schema_path, expected, report)
        validator.run()
    finally:
        if args.keep_db:
            print(f"Keeping disposable databases: {', '.join(created)}")
        else:
            for database in created:
                try:
                    drop_database(args.admin_dsn, database)
                except Exception as exc:  # noqa: BLE001
                    report.warn("database cleanup", f"Could not drop {database}: {exc!r}", area="cleanup")
            try:
                drop_created_roles(args.admin_dsn, preexisting_roles)
            except Exception as exc:  # noqa: BLE001
                report.warn("role cleanup", f"Could not drop roles created by validation run: {exc!r}", area="cleanup")
            try:
                leftovers = list_disposable_databases(args.admin_dsn)
                if leftovers:
                    report.fail(
                        "disposable database cleanup",
                        f"Leftover validation databases remain: {leftovers}",
                        area="cleanup",
                        severity="High",
                        why="Disposable validation databases should be removed after successful and failing runs unless --keep-db is used.",
                        recommendation="Drop the leftover jousaali_db_validation_% databases and investigate cleanup errors.",
                    )
                else:
                    report.pass_("no leftover disposable validation databases remain after cleanup")
            except Exception as exc:  # noqa: BLE001
                report.warn("database cleanup verification", f"Could not verify leftover validation databases: {exc!r}", area="cleanup")

    report.print_summary(dbname, server_version)
    return 1 if report.failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
