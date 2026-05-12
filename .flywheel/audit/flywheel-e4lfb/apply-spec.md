---
title: scaffold-canonical-cli.sh — detect + skip Python scripts (.sh extension misnomer guard)
type: apply-spec
created: 2026-05-10
bead: flywheel-e4lfb
parent: flywheel-ac4fy (closed; discovered the gap)
chain: doctor-mode-tooling
---

# scaffolder shebang-aware guard

CloudyMill discovered during ac4fy: scaffold-canonical-cli.sh is bash-only
but corrupted 2 .sh files that had python shebangs. Fleet-wide, 3 known
.sh files have python shebangs:
- `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh`
- `.flywheel/scripts/fleet-rotate-on-caam-swap.sh`
- `.flywheel/scripts/jeff-issue.sh`

12 more .sh files use python-heredoc-wrap pattern (bash on outside,
python in heredoc) — those are SAFE for the bash scaffolder. Only the
3 with `#!/usr/bin/env python3` shebang are at risk.

## Goal

Make scaffold-canonical-cli.sh detect non-bash shebangs and refuse with
an explicit error class instead of silently corrupting files.

## Scope

### AG1: shebang detection in scaffolder

In `.flywheel/scripts/scaffold-canonical-cli.sh`, add a precondition
check after path validation:

```bash
shebang="$(head -1 "$target" 2>/dev/null)"
case "$shebang" in
  '#!/usr/bin/env bash'|'#!/bin/bash'|'#!/usr/bin/bash'|'#!/usr/bin/env sh'|'#!/bin/sh')
    : ;;
  '#!/usr/bin/env python'*|'#!/usr/bin/python'*|'#!/usr/bin/env node'*|'#!/usr/bin/env ruby'*|'#!/usr/bin/env zsh'*)
    echo "ERR: scaffolder is bash-only; target has shebang: $shebang" >&2
    echo "  → Use language-appropriate canonical-cli scaffolder, or refactor target to bash" >&2
    exit 67  # new exit code: language_mismatch
    ;;
  *)
    if [[ -n "$shebang" ]]; then
      echo "WARN: unrecognized shebang: $shebang — proceeding with bash scaffold" >&2
    fi
    ;;
esac
```

### AG2: regression test

Add a fixture script with python shebang to
`tests/scaffold-canonical-cli-e2e.sh`:

- Test: scaffolder refuses python-shebang target with exit 67
- Assert: target file unchanged after refusal
- Assert: error message names the language

### AG3: inventory annotation

Update `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` rows for
the 3 python-shebang scripts to add `python_shebang: true` flag. These
are out-of-scope for the bash scaffolder pipeline; they need a python
canonical-cli adapter (filed as separate followup if needed).

### AG4: doctrine note

Add note to `.flywheel/scripts/scaffold-canonical-cli.sh` header:
"Bash-only. Refuses python/node/ruby/zsh targets via shebang check
(exit 67)."

### AG5: receipt

Write `.flywheel/audit/flywheel-e4lfb/evidence.md`:
- Diff to scaffolder
- Test fixture
- 3 inventory rows annotated
- Refused-class smoke (exit 67 produced for fixture)

## Boundary

- DO NOT attempt to scaffold the 3 python-shebang scripts. They need
  a python adapter; that's a separate bead.
- DO NOT change the helper-lib API. Lib remains bash-only; scaffolder
  just refuses non-bash inputs.
- File a followup bead for python canonical-cli adapter if Joshua wants
  the 3 surfaces upgraded.

## Acceptance gate

- Fixture test passes (refused with exit 67)
- 3 inventory rows annotated
- bash -n clean
- canonical-cli-lint.sh clean on the modified scaffolder

## Estimated effort

~30-45 minutes.

## Goal

See body above.

## Acceptance gate

See AG-list above.
