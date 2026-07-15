#!/usr/bin/env python3
"""check_osc_contract.py — prove the OSC contract doc matches the Python service.

Compares the set of OSC address literals defined in ``python/src/config.py``
(the source of truth the service dispatches/sends) against the addresses
documented in ``docs/osc_contract.md``. Exits non-zero on any drift, listing
which side is missing what.

Run:  python3 python/scripts/check_osc_contract.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CONFIG = REPO / "python" / "src" / "config.py"
CONTRACT = REPO / "docs" / "osc_contract.md"

# OSC address literals assigned to OSC_* constants in config.py.
CONFIG_RE = re.compile(r'^OSC_[A-Z0-9_]+\s*=\s*"(/[^"]+)"', re.MULTILINE)
# Backtick-wrapped OSC addresses in the contract markdown, e.g. `/chord/input`.
DOC_RE = re.compile(r"`(/[a-z0-9_]+(?:/[a-z0-9_]+)*)`")


def main() -> int:
    config_addrs = set(CONFIG_RE.findall(CONFIG.read_text()))
    doc_addrs = set(DOC_RE.findall(CONTRACT.read_text()))

    missing_in_doc = sorted(config_addrs - doc_addrs)  # used by service, undocumented
    missing_in_code = sorted(doc_addrs - config_addrs)  # documented, not in config.py

    print(f"config.py addresses : {len(config_addrs)}")
    print(f"osc_contract.md addr: {len(doc_addrs)}")

    if missing_in_doc:
        print("\nUNDOCUMENTED (in config.py, missing from osc_contract.md):")
        for a in missing_in_doc:
            print(f"  - {a}")
    if missing_in_code:
        print("\nPHANTOM (in osc_contract.md, not defined in config.py):")
        for a in missing_in_code:
            print(f"  - {a}")

    if missing_in_doc or missing_in_code:
        print("\nDRIFT: osc_contract.md and config.py disagree.")
        return 1
    print("\nOK: osc_contract.md matches config.py exactly (no drift).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
