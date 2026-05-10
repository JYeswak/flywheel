#!/usr/bin/env bash
# tests/fleet-rotate-on-caam-swap-canonical-cli.sh
# flywheel-ou656 calibration: this surface is a Python script; the canonical
# test is the py-scaffolder-generated companion at
# tests/fleet-rotate-on-caam-swap.sh-canonical-cli-py.sh
# (note the .sh-canonical-cli-py.sh suffix).
#
# This file is preserved as a thin pointer to the canonical py test so any
# fleet tooling that searches for "canonical-cli.sh" by name still finds a
# runnable test. Sister precedent: flywheel-0pkcf for caam-auto-rotate.
set -uo pipefail
exec bash "$(dirname "${BASH_SOURCE[0]}")/fleet-rotate-on-caam-swap.sh-canonical-cli-py.sh" "$@"
