#!/usr/bin/env python3
"""Schema-stem entry point for the holding-company runway receipt validator."""

from __future__ import annotations

import runpy
from pathlib import Path


if __name__ == "__main__":
    runpy.run_path(str(Path(__file__).with_name("holding-company-runway-validate.py")), run_name="__main__")

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
