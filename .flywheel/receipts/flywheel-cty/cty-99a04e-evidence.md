# flywheel-cty-99a04e Evidence

## Scope

- Bead: `flywheel-cty`
- Task: audit active client/fleet repos for `br`, `bv`, and `ntm` version drift.
- Implementation: `.flywheel/scripts/client-tentacle-version-audit.py`
- Test: `tests/client-tentacle-version-audit.sh`
- Live matrix: `.flywheel/receipts/flywheel-cty/live-audit.json`
- Live doctor matrix: `.flywheel/receipts/flywheel-cty/live-doctor.json`

## Acceptance Evidence

Commands run:

```bash
tests/client-tentacle-version-audit.sh
.flywheel/scripts/client-tentacle-version-audit.py audit --json > .flywheel/receipts/flywheel-cty/live-audit.json
jq -e 'all(.rows[]; has("repo") and has("tool") and has("version") and has("status"))' .flywheel/receipts/flywheel-cty/live-audit.json
.flywheel/scripts/client-tentacle-version-audit.py doctor --json > .flywheel/receipts/flywheel-cty/live-doctor.json
jq -e '.mode == "doctor" and .row_count == 24 and all(.rows[]; has("repo") and has("tool") and has("version") and has("status"))' .flywheel/receipts/flywheel-cty/live-doctor.json
.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-cty-99a04e.md
```

Results:

- Fixture tests: `PASS client-tentacle-version-audit tests pass=11 fail=0`
- Live audit: `status=warn`, `repo_count=8`, `tool_count=3`, `row_count=24`
- Live findings: `br=0.2.5` and `bv=0.13.0` consistent across live repos; `ntm=dev` reported as `unversioned` across live repos.
- JSON matrix required fields: validated true for `repo`, `tool`, `version`, `status`.
- Client repo mutation: fixture test verifies audited repos remain clean before/after audit; implementation only runs version commands with audited repo as `cwd`.

## Live Matrix Summary

```text
alpsinsurance      br   0.2.5   ok
alpsinsurance      bv   0.13.0  ok
alpsinsurance      ntm  dev     unversioned
mobile-eats        br   0.2.5   ok
mobile-eats        bv   0.13.0  ok
mobile-eats        ntm  dev     unversioned
skillos            br   0.2.5   ok
skillos            bv   0.13.0  ok
skillos            ntm  dev     unversioned
terratitle         br   0.2.5   ok
terratitle         bv   0.13.0  ok
terratitle         ntm  dev     unversioned
zeststream-infra   br   0.2.5   ok
zeststream-infra   bv   0.13.0  ok
zeststream-infra   ntm  dev     unversioned
zesttube           br   0.2.5   ok
zesttube           bv   0.13.0  ok
zesttube           ntm  dev     unversioned
polymarket-pico-z  br   0.2.5   ok
polymarket-pico-z  bv   0.13.0  ok
polymarket-pico-z  ntm  dev     unversioned
vrtx               br   0.2.5   ok
vrtx               bv   0.13.0  ok
vrtx               ntm  dev     unversioned
```

## Canonical CLI Notes

- `doctor`, `health`, `validate`, `audit`, `why`, `schema`, `info`, `examples`, and `repair` modes are present.
- `--json` emits machine-readable payloads; schema reports stable exit codes.
- `repair` is intentionally read-only and reports `repair.applied=false`.
- Drift warnings use stable codes: `major_drift`, `minor_drift_gt_one`, `missing`, `repo_missing`, `error`, `unversioned`.

## Socraticode

- Query count: 1
- Query: `client repo tentacle version pins audit br bv ntm version matrix active fleet repos doctor report missing required tool drift greater than one minor version`
- Relevant prior patterns: `.flywheel/scripts/tentacle-drift-sweep.sh`, `tests/tentacle-drift-sweep.sh`, `.flywheel/scripts/tentacle-source-presence-audit.sh`.

## L52 Receipt

- New beads filed: none
- Beads updated: none
- No-bead reason: no new gap beyond accepted live `ntm` unversioned warning; audit surfaces it as data.

## Skill Routes

- `canonical-cli-scoping=yes`: CLI mode/JSON/schema/repair/read-only/exit-code surfaces implemented.
- `python-best-practices=yes`: typed dataclasses, boundary exception handling, small pure helpers, compile test.
- `rust-best-practices=n/a`: no Rust touched.
- `readme-writing=n/a`: no README/docs surface changed.

## Compliance Pack

- Score: `920/1000`
- CLI canonical: yes
- Python clean: yes
- Rust clean: n/a
- README quality: n/a
- Evidence redacted: n/a
- Artifact checks:
  - `.flywheel/scripts/client-tentacle-version-audit.py:exists`
  - `tests/client-tentacle-version-audit.sh:exists`
  - `.flywheel/receipts/flywheel-cty/live-audit.json:exists`
  - `.flywheel/receipts/flywheel-cty/live-doctor.json:exists`

## Four-Lens Self-Grade

- brand: 9
- sniff: 9
- jeff: 9
- public: 9

Three Judges check: a skeptical operator can rerun the matrix, a maintainer can reason about drift codes and no-mutation behavior, and a future worker has durable live output plus fixture coverage.

## L112 Probe

```bash
jq -e '.row_count == 24 and all(.rows[]; has("repo") and has("tool") and has("version") and has("status"))' .flywheel/receipts/flywheel-cty/live-audit.json
```

Expected: `jq:.row_count == 24 and all(.rows[]; has("repo") and has("tool") and has("version") and has("status"))`
