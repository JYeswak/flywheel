#!/usr/bin/env bash
# tests/caam-auto-rotate-on-usage-limit-canonical-cli.sh
# flywheel-0pkcf calibration: this surface is a Python script; the canonical
# test is the py-scaffolder-generated companion at
# tests/caam-auto-rotate-on-usage-limit.sh-canonical-cli-py.sh
# (note the .sh-canonical-cli-py.sh suffix, distinguishing it from the
# bash-scaffold-style test name this file once held).
#
# This file is preserved as a thin pointer to the canonical py test so any
# fleet tooling that searches for "canonical-cli.sh" by name still finds a
# runnable test. It defers entirely to the py test.
set -uo pipefail
exec bash "$(dirname "${BASH_SOURCE[0]}")/caam-auto-rotate-on-usage-limit.sh-canonical-cli-py.sh" "$@"
