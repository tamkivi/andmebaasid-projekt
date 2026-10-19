#!/usr/bin/env python3
"""Render portrait-A4 Ü2 register diagrams from local PostgreSQL."""
from __future__ import annotations

import html
import os
import subprocess
from collections import defaultdict
from pathlib import Path

DB = os.environ.get("ITI0207_U2_DB")
if not DB:
    raise SystemExit("Set ITI0207_U2_DB to the local database whose schema should be exported")
OUT = Path(__file__).resolve().parents[1] / "docs" / "diagrams"

# Exactly one detailed appearance per table. Large registers span several pages.
REGISTERS = {
    "01a-klassifikaatorid-isikuseisundid": [
        "isiku_seisundi_liik", "tootaja_seisundi_liik", "kliendi_seisundi_liik",
    ],
    "01b-klassifikaatorid-yldised": [
        "kauba_seisundi_liik", "tootaja_roll", "riik",
    ],
    "01c-klassifikaatorid-ekraan": [
        "diagonaal", "ekraani_resolutsioon", "kaamera",
    ],
    "01d-klassifikaatorid-tehnika": ["protsessor", "sisemalu", "brand"],
    "01e-klassifikaatorid-kategooriad": [
        "varv", "kauba_kategooria_tyyp", "kauba_kategooria",
    ],
    "02-isikud": ["isik", "kasutajakonto"],
    "03-tootajad": ["tootaja", "tootaja_rolli_omamine"],
    "04-kliendid": ["klient"],
    "05a-kaubad": ["kaup"],
    "05b-nutitelefon": ["nutitelefon"],
    "05c-kauba-seosed": ["kauba_variant", "kauba_kategooria_omamine"],
}

TITLES = {
    "01a-klassifikaatorid-isikuseisundid": "Klassifikaatorid: isikute seisundid",
    "01b-klassifikaatorid-yldised": "Klassifikaatorid: kauba seisund, roll, riik",
    "01c-klassifikaatorid-ekraan": "Klassifikaatorid: ekraan ja kaamera",
    "01d-klassifikaatorid-tehnika": "Klassifikaatorid: tehnika ja bränd",
    "01e-klassifikaatorid-kategooriad": "Klassifikaatorid: värv ja kategooriad",
    "02-isikud": "Isikute register",
    "03-tootajad": "Töötajate register",
    "04-kliendid": "Klientide register",
    "05a-kaubad": "Kaupade register: kaup",
    "05b-nutitelefon": "Kaupade register: nutitelefon",
    "05c-kauba-seosed": "Kaupade register: variandid ja kategooriad",
}
ACTION = {"a": "NO ACTION", "r": "RESTRICT", "c": "CASCADE", "n": "SET NULL", "d": "SET DEFAULT"}


def psql(sql: str) -> list[tuple[str, ...]]:
    raw = subprocess.check_output(
        ["psql", "-X", "-d", DB, "-At", "-F", "\t", "-c", sql], text=True
    )
    return [tuple(line.split("\t")) for line in raw.splitlines() if line.strip()]


def display_type(value: str) -> str:
    return (value.replace("character varying", "varchar")
                 .replace("timestamp(0) with time zone", "timestamptz(0)")
                 .replace("character(", "char("))


def load_schema():
    cols = defaultdict(list)
    for table, column, typ, nullable, identity, default in psql("""
        SELECT t.relname, a.attname, format_type(a.atttypid, a.atttypmod),
               CASE WHEN a.attnotnull THEN 'NOT NULL' ELSE 'NULL' END,
               CASE WHEN a.attidentity <> '' THEN 'IDENTITY' ELSE '' END,
               COALESCE(pg_get_expr(d.adbin, d.adrelid), '')
        FROM pg_class t JOIN pg_namespace n ON n.oid = t.relnamespace
        JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped
        LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum
        WHERE n.nspname = 'public' AND t.relkind = 'r'
        ORDER BY t.relname, a.attnum
    """):
        cols[table].append((column, display_type(typ), nullable, identity, default))

    constraints = defaultdict(dict)
    flags = defaultdict(lambda: defaultdict(set))
    for table, name, kind, column, definition, target, delete, update in psql("""
        SELECT t.relname, c.conname, c.contype, a.attname,
               pg_get_constraintdef(c.oid), COALESCE(ref.relname, ''),
               c.confdeltype, c.confupdtype
        FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        JOIN LATERAL unnest(c.conkey) AS k(attnum) ON true
        JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = k.attnum
        LEFT JOIN pg_class ref ON ref.oid = c.confrelid
        WHERE n.nspname = 'public' AND c.contype IN ('p', 'u', 'f')
        ORDER BY t.relname, c.contype, c.conname, a.attnum
    """):
        constraints[table][name] = (kind, definition, target, delete, update)
        flags[table][column].add({"p": "PK", "u": "UK", "f": "FK"}[kind])

    fks = []
    for table, column, target, name in psql("""
        SELECT t.relname, a.attname, ref.relname, c.conname
        FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        JOIN pg_class ref ON ref.oid = c.confrelid
        JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = c.conkey[1]
        WHERE n.nspname = 'public' AND c.contype = 'f'
        ORDER BY t.relname, c.conname
    """):
        fks.append((table, column, target, name))
    return cols, constraints, flags, fks


def esc(value: str) -> str:
    return html.escape(value, quote=True)


def table_html(name: str, cols, constraints, flags, detailed: bool) -> str:
    if not detailed:
        return ('<<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="5">'
                f'<TR><TD BGCOLOR="#e8edf2"><B>{esc(name)}</B></TD></TR></TABLE>>')
    rows = [f'<TR><TD COLSPAN="3" BGCOLOR="#1f4e79"><FONT COLOR="white"><B>{esc(name)}</B></FONT></TD></TR>']
    for column, typ, nullable, identity, default in cols[name]:
        props = [nullable] + sorted(flags[name][column])
        if identity:
            props.append(identity)
        if default:
            props.append(f"DEFAULT {default}")
        rows.append(
            f'<TR><TD ALIGN="LEFT">{esc(column)}</TD>'
            f'<TD ALIGN="LEFT">{esc(typ)}</TD>'
            f'<TD ALIGN="LEFT">{esc("; ".join(props))}</TD></TR>'
        )
    for constraint, (kind, definition, target, delete, update) in constraints[name].items():
        columns = definition.split("(", 1)[1].split(")", 1)[0]
        if kind == "f":
            detail = (f"FK {constraint} -> {target} "
                      f"[D {ACTION[delete]}; U {ACTION[update]}]")
        else:
            detail = f"{'PK' if kind == 'p' else 'UK'} {constraint}: ({columns})"
        rows.append(
            '<TR><TD COLSPAN="3" ALIGN="LEFT" BGCOLOR="#f2f5f8">'
            f'<FONT POINT-SIZE="9">{esc(detail)}</FONT></TD></TR>'
        )
    return ('<<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="3">'
            + ''.join(rows) + '</TABLE>>')


def render_register(key: str, primary: list[str], cols, constraints, flags, fks) -> Path:
    owned = set(primary)
    # Include direct FK targets for owned tables; unrelated incoming FKs stay on their page.
    context = {target for source, _, target, _ in fks if source in owned and target not in owned}
    edges = [(source, column, target) for source, column, target, _ in fks
             if source in owned and target in owned | context]
    lines = [
        'digraph G {',
        '  graph [rankdir=TB, bgcolor=white, pad=0.1, nodesep=0.18, ranksep=0.15,',
        '         fontname=Helvetica, fontsize=12, size="7.3,10.5", page="8.27,11.69", margin=0.2];',
        '  node [shape=plaintext, fontname=Helvetica, fontsize=9];',
        '  edge [color="#667788", dir=none, fontsize=8, fontname=Helvetica];',
        '  labelloc="t";',
        f'  label="ITI0207 Ü2 - {TITLES[key]}";',
    ]
    for table in primary:
        lines.append(f'  "{table}" [label={table_html(table, cols, constraints, flags, True)}];')
    for table in sorted(context):
        lines.append(f'  "{table}" [label={table_html(table, cols, constraints, flags, False)}];')
    for source, column, target in edges:
        lines.append(f'  "{target}" -> "{source}";')
    # A reading-order chain prevents wide landscape rows.
    ordered = sorted(context) + primary
    for before, after in zip(ordered, ordered[1:]):
        lines.append(f'  "{before}" -> "{after}" [style=invis, weight=100];')
    lines.append('}')
    OUT.mkdir(parents=True, exist_ok=True)
    stem = OUT / f"u2-{key}"
    dot_path, png_path, pdf_path = (stem.with_suffix(ext) for ext in (".dot", ".png", ".pdf"))
    dot_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    subprocess.check_call(["dot", "-Tpng", "-Gdpi=150", "-o", str(png_path), str(dot_path)])
    subprocess.check_call(["dot", "-Tpdf", "-o", str(pdf_path), str(dot_path)])
    return pdf_path


def main() -> None:
    cols, constraints, flags, fks = load_schema()
    all_owned = [table for group in REGISTERS.values() for table in group]
    if len(all_owned) != len(set(all_owned)):
        raise SystemExit("Duplicate table ownership")
    missing, extras = set(all_owned) - set(cols), set(cols) - set(all_owned)
    if missing or extras:
        raise SystemExit(f"Missing tables: {sorted(missing)}; unowned tables: {sorted(extras)}")
    for key, tables in REGISTERS.items():
        print(render_register(key, tables, cols, constraints, flags, fks))


if __name__ == "__main__":
    main()
