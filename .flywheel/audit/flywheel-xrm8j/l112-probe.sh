#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
bash .flywheel/validation-schema/v1/parse.sh .flywheel/audit/flywheel-xrm8j/validation-receipt.json
