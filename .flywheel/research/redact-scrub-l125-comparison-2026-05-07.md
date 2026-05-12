# Redact/Scrub vs Flywheel Secret Fixtures + L125

Date: 2026-05-07
Task: `flywheel-nybur`
Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
NTM live version: `ntm version v1.14.0-290-g99c67b31`
NTM live commit: `99c67b310485d6ba9ca5d2823dc7b3fec99c39c3`
NTM repo note: no `Cargo.toml` exists in `/Users/josh/Developer/ntm`; this is the Go-built NTM repo, so the binary version and git HEAD are the audit anchors.

## Executive Decision

Do not delete `.flywheel/scripts/ntm-scrub-secret-scan-wrapper.sh` yet.

Native `ntm redact preview` and `ntm scrub` are strong enough to become the scan engine for ordinary provider/cloud/auth secret detection. They are not yet a drop-in replacement for W2S because flywheel's wrapper owns callback-time policy and flywheel-specific classes:

- Output contract is `[SCRUBBED:<class>]`; native emits `[REDACTED:<CATEGORY>:<hash>]`.
- Wrapper classes include `agent_mail_registration_token`, `infisical_secret_value`, `xai_key`, `slack_token`, `contextual_base64_secret`, and `contextual_hex_secret`; native does not expose these as first-class categories today.
- Wrapper fails closed for callback preflight with stable exit codes: pass `0`, findings `1`, usage `2`.
- Wrapper exposes the canonical CLI triads: `doctor`, `health`, `repair`, `validate`, `audit`, `why`, `schema`, and `completion`.
- L125 needs a transcript/artifact leak detector profile. Native `scrub` scans any path read-only, but its default roots are the NTM config dir and `~/.ntm`, not Claude/Codex transcripts, flywheel dispatch artifacts, Agent Mail archives, or mobile-eats rotation proof roots.

Decision: keep W2S as the flywheel policy wrapper. File a Jeff/NTM issue for a SEC-class extension or profile bundle, then delete W2S only after the deletion criteria below pass.

## Research Grounding

Socraticode: 10 queries completed, 100 indexed chunks observed.

Queries covered:

- `ntm scrub secret scan wrapper flywheel SEC secret fixtures redact scrub`
- `SEC-001 SEC-002 SEC-003 SEC-004 SEC-005 SEC-006 secret values mission lock security negative invariants`
- `L125 ENV-FILE-IS-SEALED-SUBSTRATE env file sealed substrate Read tool transcript leak`
- `infisical-safe dcg secret leak env file Bash guards L125 tests`
- `josh-request-schema secret scrub contract aws github anthropic openai jwt bearer google slack token classes`
- `ntm-scrub-secret-scan-wrapper fixtures tests secret taxonomy native scrub compare`
- `mobile-eats rotation gate clean leak proof L125 scrub transcript detector`
- `redact scrub built-in redaction engine secret patterns github openai anthropic jwt bearer slack aws google`
- `scrub command implementation path since format json findings redact file scanner`
- `redact preview command implementation JSON output findings categories`

Live commands and fixtures:

- `ntm redact preview --help`
- `ntm scrub --help`
- `ntm scrub --path .flywheel/tests/fixtures/ntm-scrub-secret-scan --format json`
- `.flywheel/scripts/ntm-scrub-secret-scan-wrapper.sh --file .flywheel/tests/fixtures/ntm-scrub-secret-scan/secret-bank.txt --json`
- synthetic-only probe outputs:
  - `/private/tmp/nybur-ntm-scrub-synthetic.json`
  - `/private/tmp/nybur-ntm-redact-preview-synthetic.json`
  - `/private/tmp/nybur-ntm-scrub-flywheel-fixture.json`
  - `/private/tmp/nybur-wrapper-secret-bank.json`

Canonical CLI scoping gates:

- Doctor/health/repair triad: W2S wrapper covers these; native `redact`/`scrub` do not expose a dedicated repair surface because they are read-only utilities.
- Validate/audit/why triad: W2S wrapper covers these; native covers detection but not flywheel policy receipts.
- JSON/schema/exit behavior: native supports `--json` output; W2S adds explicit `schema` and stable exit-code contract.
- Dry-run/apply discipline: native scan is read-only; W2S `repair --apply` requires `--idempotency-key` and is a no-op.
- File-length threshold: no edited script in this research bead; W2S itself stays below the threshold target from the W2S migration bead.

## Native NTM Coverage

Native implementations checked:

- `/Users/josh/Developer/ntm/internal/cli/redact.go`
- `/Users/josh/Developer/ntm/internal/cli/scrub.go`
- `/Users/josh/Developer/ntm/internal/redaction/types.go`
- `/Users/josh/Developer/ntm/internal/redaction/patterns.go`
- `/Users/josh/Developer/ntm/docs/REDACTION_SPEC.md`
- `/Users/josh/Developer/ntm/testdata/redaction_fixtures.json`

Native `redact preview`:

- Requires `--text` or `--file`.
- Supports `--json`.
- Always computes safe redacted output, even if global redaction mode is warn/off.
- JSON findings include category, redacted placeholder, offsets, line, and column; they never include the raw match.

Native `scrub`:

- Scans files/directories read-only.
- Defaults to the active config directory plus `~/.ntm`.
- Supports repeated `--path`, `--since`, `--format text|json`, and `--json`.
- Skips `.git`, symlinks, and binary files.
- JSON findings include path, category, offsets, line, column, and safe preview.

Native category set observed in source:

```text
OPENAI_KEY
ANTHROPIC_KEY
GITHUB_TOKEN
AWS_ACCESS_KEY
AWS_SECRET_KEY
JWT
GOOGLE_API_KEY
PRIVATE_KEY
DATABASE_URL
PASSWORD
GENERIC_API_KEY
GENERIC_SECRET
BEARER_TOKEN
```

Native synthetic probe result:

```text
scrub_categories=ANTHROPIC_KEY,AWS_ACCESS_KEY,AWS_SECRET_KEY,BEARER_TOKEN,DATABASE_URL,GENERIC_SECRET,GITHUB_TOKEN,GOOGLE_API_KEY,JWT,OPENAI_KEY,PASSWORD,PRIVATE_KEY
preview_categories=ANTHROPIC_KEY,AWS_ACCESS_KEY,AWS_SECRET_KEY,BEARER_TOKEN,DATABASE_URL,GENERIC_SECRET,GITHUB_TOKEN,GOOGLE_API_KEY,JWT,OPENAI_KEY,PASSWORD,PRIVATE_KEY
scrub_findings=15
preview_findings=15
```

Flywheel W2S fixture comparison:

```text
ntm_fixture_categories=AWS_ACCESS_KEY,BEARER_TOKEN,GENERIC_SECRET,GOOGLE_API_KEY,JWT,PRIVATE_KEY
ntm_fixture_findings=6
wrapper_classes=agent_mail_registration_token,anthropic_key,aws_access_key,bearer_token,github_token,google_api_key,infisical_secret_value,jwt,openai_key,private_key,slack_token,xai_key
wrapper_findings=12
```

Interpretation: native caught the classes whose fixture strings met NTM's stricter length/shape rules. The W2S fixture deliberately uses additional flywheel classes and shorter sentinel-style synthetic values, so native is not equivalent for W2S policy verification.

## Taxonomy Comparison

The dispatch prompt says "9-class taxonomy", but the current canonical `templates/josh-request-schema.md` lists 12 required classes. The v1 archive lists 10 legacy classes. This audit uses the current 12-class schema and calls out legacy deltas.

| Flywheel class | Native coverage | Verdict | Note |
|---|---|---|---|
| `aws_access_key` | `AWS_ACCESS_KEY` | covered | Native catches `AKIA` and `ASIA` access key IDs with exact length. |
| `github_token` | `GITHUB_TOKEN` | covered | Native catches `gh[pousr]_` and `github_pat_`; W2S fixture uses shorter synthetic strings, so fixture must be updated before replacement. |
| `anthropic_key` | `ANTHROPIC_KEY` | covered | Native requires a longer `sk-ant-` body than the current W2S fixture. |
| `openai_key` | `OPENAI_KEY` | covered | Native catches legacy and project-style keys with stricter lengths. |
| `jwt` | `JWT` | covered | Native catches standard three-part `eyJ...` JWTs. |
| `bearer_token` | `BEARER_TOKEN` | covered | Native catches bearer tokens with 20+ token chars. |
| `google_api_key` | `GOOGLE_API_KEY` | covered | Native catches exact `AIza` plus 35-char body. |
| `slack_token` | generic only | gap | Native robot sensitivity tests mention Slack-like tokens, but the canonical redaction engine has no `SLACK_TOKEN` category. In the W2S fixture native reports this as `GENERIC_SECRET`, not Slack. |
| `private_key_block` | `PRIVATE_KEY` | covered | Category name differs; mapping is straightforward. |
| `agent_mail_token_field` | `GENERIC_SECRET` sometimes | gap | Native does not expose an Agent Mail token category and may miss field variants. |
| `contextual_base64_secret` | no exact category | gap | Native `GENERIC_SECRET` is assignment-based; it does not implement flywheel's contextual base64 class. |
| `contextual_hex_secret` | no exact category | gap | Native lacks a dedicated contextual hex class. |

Legacy v1 deltas:

| Legacy class | Native coverage | Decision |
|---|---|---|
| `xai_key` | no exact native category | keep W2S or file extension; current W2S still detects it. |
| `github_pat` / `github_fine_grained_pat` | `GITHUB_TOKEN` | covered under one category. |
| `base64_blob` | no exact native category | superseded by `contextual_base64_secret`; still not native. |
| `near_secret_keyword` | partial via `GENERIC_SECRET`, `GENERIC_API_KEY`, `PASSWORD` | partial; native is assignment-focused, not proximity-focused. |

Native extra useful categories:

- `AWS_SECRET_KEY`
- `DATABASE_URL`
- `PASSWORD`
- `GENERIC_API_KEY`
- `GENERIC_SECRET`

These are useful for L125 and rotation-gate proof, but they do not remove the wrapper-specific classes above.

## W2S Deletion Criteria

Delete W2S only when all of these pass:

1. Native NTM exposes or can be configured to expose every current flywheel schema class, including `slack_token`, `agent_mail_token_field`, `contextual_base64_secret`, and `contextual_hex_secret`.
2. Native NTM either exposes `xai_key` or flywheel records a no-fit decision removing that legacy class from W2S obligations.
3. Native JSON has a stable schema suitable for callback gates: category counts, safe previews, no raw matches, scanned file count, warnings, and version/schema identifier.
4. Native scan supports a fail-on-findings mode or flywheel has a 5-line caller that converts findings to the existing fail-closed exit contract.
5. Native supports a named path profile or config bundle for L125 transcript/artifact scanning roots.
6. Native fixture suite passes against:
   - `templates/josh-request-schema.md` current 12 classes
   - `.flywheel/tests/fixtures/ntm-scrub-secret-scan/secret-bank.txt`
   - an L125 synthetic Read-tool transcript leak fixture
   - clean negative fixtures that mention class names without values
7. Replacement preserves the flywheel callback marker format or the consuming hooks are migrated from `[SCRUBBED:<class>]` to native `[REDACTED:<CATEGORY>:<hash>]`.
8. Canonical CLI gates remain covered after deletion: doctor/health/repair marked n/a for read-only native surfaces, validate/audit/why covered by native or by a tiny flywheel caller, and stable exit codes documented.

Until those are true, W2S should stay as a wrapper around policy and evidence, not as a competing secret scanner.

## L125 Gap Inventory

L125 states that `.env*` files are sealed substrate. Reading them through Read/Edit/Write/cat/MCP file tools creates a transcript leak. Bash-surface guards do not cover file-read tools by design.

Current preventive coverage:

- `tests/dcg-secret-leak-overrides.sh` blocks raw Infisical list/get/run/export commands, JWT literals, and Supabase URL literals. It allows key-only safe-wrapper enumeration.
- `tests/infisical-safe.sh` blocks table/plain list, non-silent get, and `infisical run`; it allows key-only JSON list, silent redirected gets, and login. It asserts no `secretValue`, `FAKE_`, or JWT-like markers leak in dry-run output.

Coverage gaps:

1. Read/Edit/Write/MCP file tools can still read `.env*`, `.envrc`, `.secrets`, private keys, or credentials files unless the agent obeys L125. Bash guards do not intercept those tools.
2. Transcript leaks are post-fact artifacts. Preventive guards stop shell commands, but they do not scan Claude/Codex transcripts, NTM dispatch logs, Agent Mail messages, or flywheel state after a leak.
3. Native `ntm scrub` default roots do not include the likely leak surfaces:
   - Claude/Codex transcript stores
   - `/private/tmp/dispatch_*.md`
   - `.flywheel/dispatch-log.jsonl`
   - `.flywheel/research/`
   - `~/.local/state/flywheel/`
   - Agent Mail inbox/outbox archives
   - mobile-eats rotation evidence directories
4. Native `ntm scrub` can scan `.env` files if pointed there. For L125 clean-leak proof, it should scan transcripts and derived artifacts, not sealed env substrates.
5. Native category names do not yet align to SEC/L125 receipts. It can report `GENERIC_SECRET`; flywheel needs to know whether that means Agent Mail token, contextual base64, Infisical `secretValue`, or Slack.

Native NTM can cover these natively if it adds an L125 profile:

```yaml
l125_clean_leak_profile:
  command: ntm scrub
  mode: read_only_artifact_scan
  forbidden_roots:
    - "**/.env"
    - "**/.env.*"
    - "**/.secrets"
    - "**/*.pem"
    - "**/id_rsa*"
  scanned_roots:
    - "/private/tmp/dispatch_*.md"
    - ".flywheel/dispatch-log.jsonl"
    - ".flywheel/research"
    - "~/.local/state/flywheel"
    - "~/.claude/projects"
    - "~/.codex/sessions"
  flags:
    - "--since 24h"
    - "--format json"
  pass_condition:
    findings: 0
    warnings: []
  evidence:
    retain_redacted_json: true
    retain_raw_values: false
```

This would make `ntm scrub` a post-fact detector for Joshua's rotation-gate clean-leak proof. It complements L125 prevention; it does not replace L125.

## Jeff Issue Recommendation

File one upstream NTM issue for a SEC/L125 redaction profile, not several small scattered issues.

Proposed issue title:

```text
Add SEC/L125 scrub profile for flywheel transcript leak proof
```

Requested capabilities:

- Publish the canonical native category list and schema version from `ntm scrub --json`.
- Add `--fail-on-findings` or documented stable non-zero mode for CI/doctor use.
- Add profile/config support for artifact-root bundles, especially `l125-clean-leak`.
- Add first-class or configurable categories for:
  - `SLACK_TOKEN`
  - `XAI_KEY`
  - `AGENT_MAIL_TOKEN`
  - `INFISICAL_SECRET_VALUE`
  - contextual base64 near secret keywords
  - contextual hex near secret keywords
- Add a no-raw-match invariant test for `scrub` and `redact preview` JSON.
- Add fixtures equivalent to flywheel SEC-001..006 plus L125 transcript leak synthetic cases.
- Document whether `GENERIC_SECRET` is allowed to satisfy flywheel-specific categories, or require explicit categories.

## Rotation-Gate Use

For mobile-eats substrate rotation, use native `ntm scrub` as a daily post-fact detector:

```bash
ntm scrub --path /private/tmp --path ~/.local/state/flywheel --path ~/.claude/projects --path ~/.codex/sessions --since 24h --format json
```

Do not point the rotation proof at `.env*` files. Clean-leak proof should prove no secret values escaped into transcripts/artifacts, not re-read sealed substrates.

Store one redacted JSON receipt per day for seven days. Pass condition: zero findings in allowed artifact roots, no read warnings for expected roots, and no scan of forbidden sealed roots.

## Acceptance

Deliverables completed:

1. K=10 socraticode against NTM redact/scrub and flywheel SEC/L125 surfaces.
2. Native `ntm scrub` compared against the current 12-class `templates/josh-request-schema.md` taxonomy and legacy v1 classes.
3. W2S decision made: keep wrapper; file SEC/L125 native extension issue.
4. Research documented in this file.
5. L125 gaps in Bash-surface guards inventoried, with a native `ntm scrub` profile proposal.

Four-lens self-grade: `brand:9,sniff:9,jeff:9,public:9`.
