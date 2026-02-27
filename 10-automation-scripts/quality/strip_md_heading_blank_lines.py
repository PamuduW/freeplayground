#!/usr/bin/env python3
"""Remove blank lines after ATX headings when followed by paragraph text."""

from __future__ import annotations

import re
import sys
from pathlib import Path

HEADING_RE = re.compile(r"^[ \t]{0,3}#{1,6}[ \t]+\S")
FENCE_RE = re.compile(r"^[ \t]{0,3}(```|~~~)")


def _normalize_markdown(text: str) -> tuple[str, bool]:
    lines = text.splitlines(keepends=True)
    out: list[str] = []
    i = 0
    changed = False
    in_fence = False

    while i < len(lines):
        line = lines[i]

        if FENCE_RE.match(line):
            in_fence = not in_fence
            out.append(line)
            i += 1
            continue

        if not in_fence and HEADING_RE.match(line.rstrip("\r\n")):
            out.append(line)
            i += 1

            # Collapse accidental adjacent duplicate headings (with optional blank lines between).
            while True:
                k = i
                while k < len(lines) and lines[k].strip() == "":
                    k += 1
                if (
                    k < len(lines)
                    and lines[k].rstrip("\r\n") == line.rstrip("\r\n")
                    and HEADING_RE.match(lines[k].rstrip("\r\n"))
                ):
                    changed = True
                    i = k + 1
                    continue
                break

            j = i
            while j < len(lines) and lines[j].strip() == "":
                j += 1

            if j > i:
                changed = True
                i = j

            continue

        out.append(line)
        i += 1

    return "".join(out), changed


def main(argv: list[str]) -> int:
    changed_files: list[str] = []

    for name in argv:
        path = Path(name)
        if not path.exists() or path.suffix.lower() != ".md":
            continue

        original = path.read_text(encoding="utf-8")
        updated, changed = _normalize_markdown(original)
        if changed and updated != original:
            path.write_text(updated, encoding="utf-8")
            changed_files.append(name)

    if changed_files:
        print("Removed blank lines after headings in:")
        for name in changed_files:
            print(f"- {name}")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
