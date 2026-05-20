#!/usr/bin/env bash
set -euo pipefail

bash tests/act-first-workflow-gate.sh
printf 'L112_OK_act_first_gate\n'
