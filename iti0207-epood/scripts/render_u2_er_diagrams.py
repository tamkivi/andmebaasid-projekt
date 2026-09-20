#!/usr/bin/env python3
"""Render Ü2 register ER diagrams from local Postgres (DBeaver path alternative / export)."""
from __future__ import annotations

import subprocess
from collections import defaultdict
from pathlib import Path

DB = "iti0207_epood_u2"
OUT = Path(__file__).resolve().parents[1] / "docs" / "diagrams"

# Primary ownership: each table detailed on exactly one diagram.
REGISTERS: dict[str, list[str]] = {
    "01-klassifikaatorid": [
        "riik",
        "isiku_seisundi_liik",
        "tootaja_seisundi_liik",
        "kliendi_seisundi_liik",
        "tootaja_roll",
        "kauba_seisundi_liik",
        "brand",
        "diagonaal",
        "ekraani_resolutsioon",
        "kaamera",
        "protsessor",
        "sisemalu",
        "varv",
        "kauba_kategooria_tyyp",
        "kauba_kategooria",
    ],
    "02-isikud": ["isik", "kasutajakonto"],
    "03-tootajad": ["tootaja", "tootaja_rolli_omamine"],
    "04-kliendid": ["klient"],
    "05-kaubad": ["kaup", "nutitelefon", "kauba_variant", "kauba_kategooria_omamine"],
}

TITLES = {
    "01-klassifikaatorid": "Klassifikaatorite register",
    "02-isikud": "Isikute register",
    "03-tootajad": "Töötajate register",
    "04-kliendid": "Klientide register",
    "05-kaubad": "Kaupade register",
}


def psql(sql: str) -> list[tuple[str, ...]]:
    raw = subprocess.check_output(
        ["psql", "-d", DB, "-At", "-F", "\t", "-c", sql],
        text=True,
    )
    rows = []
    for line in raw.splitlines():
        if not line.strip():
            continue
        rows.append(tuple(line.split("\t")))
    return rows


def load_schema():
    cols = defaultdict(list)
    for table, column, data_type, udt, nullable, identity in psql(
        """
        SELECT c.table_name, c.column_name, c.data_type, c.udt_name,
               c.is_nullable, COALESCE(c.is_identity, 'NO')
        FROM information_schema.columns c
        WHERE c.table_schema = 'public'
        ORDER BY c.table_name, c.ordinal_position
        """
    ):
        typ = data_type
        if data_type == "USER-DEFINED":
            typ = udt
        elif data_type == "timestamp with time zone":
            typ = "timestamptz"
        elif data_type == "character varying":
            typ = "varchar"
        elif data_type == "character":
            typ = "char"
        null = "NULL" if nullable == "YES" else "NOT NULL"
        ident = " IDENTITY" if identity == "YES" else ""
        cols[table].append((column, f"{typ}{ident}", null))

    pks = defaultdict(set)
    for table, column in psql(
        """
        SELECT tc.table_name, kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
         AND tc.table_schema = kcu.table_schema
        WHERE tc.table_schema = 'public' AND tc.constraint_type = 'PRIMARY KEY'
        """
    ):
        pks[table].add(column)

    fks = []
    for src_t, src_c, dst_t, dst_c, cname in psql(
        """
        SELECT kcu.table_name, kcu.column_name,
               ccu.table_name, ccu.column_name, tc.constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
         AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage ccu
          ON ccu.constraint_name = tc.constraint_name
         AND ccu.table_schema = tc.table_schema
        WHERE tc.table_schema = 'public' AND tc.constraint_type = 'FOREIGN KEY'
        ORDER BY 1, 2
        """
    ):
        fks.append((src_t, src_c, dst_t, dst_c, cname))

    return cols, pks, fks


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("<", "\\<").replace(">", "\\>")


def table_html(name: str, cols, pks, detailed: bool) -> str:
    rows = []
    for col, typ, null in cols[name]:
        mark = "PK" if col in pks[name] else ""
        if detailed:
            rows.append(
                f'<TR><TD ALIGN="LEFT"><B>{esc(col)}</B></TD>'
                f'<TD ALIGN="LEFT">{esc(typ)}</TD>'
                f'<TD ALIGN="LEFT">{esc(null)}</TD>'
                f'<TD ALIGN="LEFT">{mark}</TD></TR>'
            )
        else:
            if col in pks[name]:
                rows.append(
                    f'<TR><TD ALIGN="LEFT"><B>{esc(col)}</B></TD>'
                    f'<TD ALIGN="LEFT">PK</TD></TR>'
                )
    if not detailed and not rows:
        rows.append('<TR><TD ALIGN="LEFT">…</TD></TR>')
    body = "".join(rows)
    header = (
        f'<TR><TD COLSPAN="4" BGCOLOR="#1f4e79"><FONT COLOR="white"><B>{esc(name)}</B></FONT></TD></TR>'
        if detailed
        else f'<TR><TD COLSPAN="2" BGCOLOR="#6c757d"><FONT COLOR="white"><B>{esc(name)}</B> (kontekst)</FONT></TD></TR>'
    )
    return f'<<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="4">{header}{body}</TABLE>>'


def render_register(key: str, primary: list[str], cols, pks, fks) -> Path:
    primary_set = set(primary)
    context = set()
    edges = []
    for src_t, src_c, dst_t, dst_c, _ in fks:
        if src_t in primary_set or dst_t in primary_set:
            if src_t not in primary_set:
                context.add(src_t)
            if dst_t not in primary_set:
                context.add(dst_t)
            edges.append((src_t, dst_t, src_c))

    # Keep context limited to direct FK neighbors of primary tables.
    context = {t for t in context if t not in primary_set}

    lines = [
        "digraph G {",
        "  graph [rankdir=TB, bgcolor=white, pad=0.3, nodesep=0.35, ranksep=0.55, fontname=Helvetica];",
        "  node [shape=plaintext, fontname=Helvetica, fontsize=9];",
        "  edge [color=\"#444444\", arrowsize=0.7, fontsize=8, fontname=Helvetica];",
        f'  labelloc="t";',
        f'  label="ITI0207 Ü2 — {TITLES[key]}\\n(local iti0207_epood_u2)";',
    ]

    for t in primary:
        lines.append(f'  "{t}" [label={table_html(t, cols, pks, True)}];')
    for t in sorted(context):
        lines.append(f'  "{t}" [label={table_html(t, cols, pks, False)}];')

    seen = set()
    for src_t, dst_t, src_c in edges:
        if src_t not in primary_set and dst_t not in primary_set:
            continue
        ekey = (src_t, dst_t, src_c)
        if ekey in seen:
            continue
        seen.add(ekey)
        lines.append(f'  "{src_t}" -> "{dst_t}" [label="{esc(src_c)}"];')

    lines.append("}")
    OUT.mkdir(parents=True, exist_ok=True)
    dot_path = OUT / f"u2-{key}.dot"
    png_path = OUT / f"u2-{key}.png"
    pdf_path = OUT / f"u2-{key}.pdf"
    dot_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    subprocess.check_call(["dot", "-Tpng", "-Gdpi=150", "-o", str(png_path), str(dot_path)])
    subprocess.check_call(["dot", "-Tpdf", "-o", str(pdf_path), str(dot_path)])
    return png_path


def main() -> None:
    cols, pks, fks = load_schema()
    missing = [t for tables in REGISTERS.values() for t in tables if t not in cols]
    if missing:
        raise SystemExit(f"Missing tables in DB: {missing}")
    all_owned = [t for tables in REGISTERS.values() for t in tables]
    if len(all_owned) != len(set(all_owned)):
        raise SystemExit("Duplicate table ownership")
    extras = set(cols) - set(all_owned)
    if extras:
        raise SystemExit(f"Unowned tables: {sorted(extras)}")

    written = []
    for key, tables in REGISTERS.items():
        written.append(render_register(key, tables, cols, pks, fks))
    print("Wrote:")
    for p in written:
        print(" ", p)


if __name__ == "__main__":
    main()
