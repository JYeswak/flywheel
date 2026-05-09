#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../../.."

rg -n 'RU-backed multi-repo systems must also inspect `~/.config/ru/config` and `~/.config/ru/repos.d/\*\.txt`' INCIDENTS.md >/dev/null
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-i18f-02f015.md >/dev/null

printf '%s\n' 'OK_ru_config_inventory_checklist'
