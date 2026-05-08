# flywheel-te36 canary secret scan evidence

Task: `flywheel-te36`
Verdict: `APPROVE_CLOSE`
Evidence date: 2026-05-08

## Source Checks

- Read bead body with `br show flywheel-te36`.
- Read `feedback_agent_mail_token_echo.md`: Agent Mail registration tokens are credential material and must not appear in pane commands, dispatch packets, callbacks, reports, or copied evidence.
- `feedback_secret_emission_discipline.md` was not present under the flywheel memory directory.
- Read `secret-emission-discipline` skill: once a secret value reaches stdout, it is transcript-resident; use presence/metadata checks rather than value emission.
- Read `mcp-secret-scanner` skill: scanner output should classify findings by file and token class; real secrets require rotation and human approval, not auto-rotation.
- Read `user_joshua_lens_judgment_depth.md`: Joshua lens must cite operator-grade durability, team-fit, company-building leverage, or turnover resilience.

## Implemented

1. Added scanner: `.flywheel/scripts/canary-secret-scan.sh`.
   - Input: one or more explicit paths, directories, or quoted globs.
   - Output schema: `canary-secret-scan/v1`.
   - JSON fields include `leaks_found`, `paths`, `patterns_matched`, and `findings`.
   - Findings name artifact path plus JSON field path or line/column.
   - Findings emit `[CANARY_REDACTED:<class>]` markers and do not echo matched canary values.
   - Exit `0` means clean, exit `1` means canary leak found, exit `2` means input/usage error.

2. Added synthetic canary corpus: `.flywheel/fixtures/canary-secret-scan/canary-corpus.json`.
   - Corpus is explicitly `synthetic_only=true`.
   - It covers six synthetic classes: AWS-key-shaped, Agent Mail registration-token-shaped, bearer-token-shaped, GitHub-PAT-shaped, OpenAI-key-shaped, and env-secret-shaped canaries.
   - It includes known false-positive examples that should not match.

3. Added canonical scan surface list: `.flywheel/fixtures/canary-secret-scan/canonical-paths.txt`.
   - Includes `.flywheel/receipts/**`, `.flywheel/dispatch-log.jsonl`, `.flywheel/reports/**`, `.flywheel/runtime/**`, `.flywheel/validation-receipts/**`, and `/tmp/flywheel-*-evidence.md`.

4. Added fixtures and test: `tests/canary-secret-scan.sh` plus `tests/fixtures/canary-secret-scan/`.
   - Leaky fixtures cover callback evidence markdown, dispatch-log JSONL, doctor JSON, and daily-report markdown.
   - Clean fixture covers secret-class names, redaction markers, and placeholder false positives.

## Test Evidence

Commands:

```bash
bash -n .flywheel/scripts/canary-secret-scan.sh
bash -n tests/canary-secret-scan.sh
TMPDIR=/var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/te36.XXXXXX.bBanJt8h5x bash tests/canary-secret-scan.sh
.flywheel/scripts/canary-secret-scan.sh --list-patterns --json | jq '{synthetic_only, patterns_count:(.patterns|length), patterns}'
set +e
out="$(.flywheel/scripts/canary-secret-scan.sh --json tests/fixtures/canary-secret-scan/leaky)"
rc=$?
set -e
printf 'rc=%s\n' "$rc"
printf '%s\n' "$out" | jq '{leaks_found, paths, patterns_matched, echoed_canary:(tostring|test("CANARY_TEST_"))}'
.flywheel/scripts/canary-secret-scan.sh --json tests/fixtures/canary-secret-scan/clean | jq '{leaks_found, paths, patterns_matched}'
```

Results:

- Syntax checks: PASS.
- `tests/canary-secret-scan.sh`: `PASS canary-secret-scan synthetic_leak_caught=true clean_evidence_passes=true`.
- Pattern list: `synthetic_only=true`, `patterns_count=6`.
- Synthetic leaky fixture: exit `1`, `leaks_found=7`, `paths` names four artifact files, `patterns_matched` names all six classes, and `echoed_canary=false`.
- Clean fixture: `leaks_found=0`, `paths=[]`, `patterns_matched=[]`.

## Acceptance Gates

1. Callback evidence fixtures include canary secrets in command args, env-shaped fields, JSON bodies, and markdown evidence: PASS.
2. Validator rejects persisted artifacts that contain unredacted canaries: PASS for the new scanner gate; hook-in to pane-2 validator was intentionally avoided because `.flywheel/scripts/validate-callback-before-close.sh` is concurrent pane-2 scope.
3. Tests cover callback evidence, dispatch logs, doctor JSON, and daily reports: PASS.
4. Failure output identifies field path and artifact path without echoing the secret: PASS (`echoed_canary=false`).
5. `canonical-paths.txt` documents the redaction validation surface: PASS.

## Joshua 25-Year Ops Lens

Secret leakage is the silent ops disaster: every credential in a transcript is tomorrow's incident, and a tired team cannot reliably grep scrollback by hand under pressure. Joshua's 25-year operations-management lens grades this as operator-grade durability: canary scans at evidence-write time turn a silent class into a noisy one before the leak ships, give the next operator a path and field to fix, and preserve turnover resilience because the scanner enforces the rule even when the original author is gone.

## Notes

- The corpus is synthetic only. No real secrets were read, generated, printed, or stored.
- `.beads/issues.jsonl` had an active Agent Mail reservation conflict from `LavenderHarbor`, so this dispatch commits the artifact receipt and reports the bead-state collision rather than racing the bead database.
