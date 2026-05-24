#!/usr/bin/env python3
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DIAGRAM_SRC = ROOT / "diagrams"
DIAGRAM_DST = ROOT / "work" / "generated_diagrams"


DIAGRAMS = [
    "01_system_context",
    "02_use_cases",
    "03_core_er",
    "04_registration_activity",
    "05_session_state",
    "06_registration_state",
    "07_waitlist_sequence",
    "08_permission_flow",
    "09_app_db_architecture",
    "10_attendance_activity",
]


def renderer_command() -> list[str] | None:
    mmdc = shutil.which("mmdc")
    if mmdc:
        return [mmdc]
    npx = shutil.which("npx")
    if npx:
        return [npx, "-y", "@mermaid-js/mermaid-cli"]
    return None


def is_stale(source: Path, target: Path) -> bool:
    return not target.exists() or target.stat().st_mtime < source.stat().st_mtime


def render_one(command: list[str], source: Path, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    args = [
        *command,
        "-i",
        str(source),
        "-o",
        str(target),
        "--backgroundColor",
        "white",
        "--scale",
        "2",
    ]
    subprocess.run(args, cwd=ROOT, check=True)


def main() -> int:
    missing = [name for name in DIAGRAMS if not (DIAGRAM_SRC / f"{name}.mmd").exists()]
    if missing:
        print(f"Missing Mermaid source files: {', '.join(missing)}", file=sys.stderr)
        return 1

    command = renderer_command()
    stale = [
        name
        for name in DIAGRAMS
        if is_stale(DIAGRAM_SRC / f"{name}.mmd", DIAGRAM_DST / f"{name}.png")
    ]
    if not stale:
        print("Mermaid diagrams are up to date.")
        return 0

    if command is None:
        targets = [str(DIAGRAM_DST / f"{name}.png") for name in stale]
        print(
            "Mermaid renderer not found. Install mermaid-cli (`npm install -g @mermaid-js/mermaid-cli`) "
            "or make npx available. Missing/stale PNGs: " + ", ".join(targets),
            file=sys.stderr,
        )
        return 1

    for name in stale:
        source = DIAGRAM_SRC / f"{name}.mmd"
        target = DIAGRAM_DST / f"{name}.png"
        print(f"Rendering {source.relative_to(ROOT)} -> {target.relative_to(ROOT)}")
        render_one(command, source, target)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
