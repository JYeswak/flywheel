#!/usr/bin/env python3
"""Schema-stem entry point for the holding-company runway receipt validator."""

from __future__ import annotations

import runpy
from pathlib import Path


if __name__ == "__main__":
    runpy.run_path(str(Path(__file__).with_name("holding-company-runway-validate.py")), run_name="__main__")
