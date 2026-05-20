# flywheel-ic6td Compliance Pack

Task: `flywheel-ic6td-c4ceac`
Bead: `flywheel-ic6td`
Mission fitness: adjacent
Compliance score: 930/1000

## Acceptance Evidence

1. Act-first doctrine reference is wired in `.flywheel/CI-POLICY.json` and
   `.flywheel/state/workflow-classification.json`:
   `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/act-first-canonical-extension.md`.
2. Workflow classifier exists at `.flywheel/scripts/act-workflow-classify.sh`
   and writes `.flywheel/state/workflow-classification.json`.
3. PR-create hook exists at `.flywheel/hooks/gh-pr-create-act-gate.sh` and is
   wired in `.claude/settings.json` for `PreToolUse:Bash`.
4. Missing local act receipt blocks `gh pr create`; override requires
   `--skip-act-gate="<reason>"` and writes an audit JSONL row.
5. N=5 hosted failure receiver exists at
   `.flywheel/scripts/gha-auto-disable-on-local-green.sh`.
6. Cron surface exists at
   `.flywheel/launchd/ai.zeststream.gha-auto-disable-on-local-green.plist`.
7. Fleet audit evidence exists at
   `.flywheel/audit/flywheel-ic6td/fleet-workflow-audit.json`.
8. Local-actions runbook documents the act-first PR gate, receipt path,
   override, classifier artifact, and auto-disable receiver.

## Verification

- `bash tests/act-first-workflow-gate.sh`: PASS, 6/6.
- `bash tests/github-workflows.sh`: PASS, 124/0.
- `bash tests/local-ci-policy.sh`: PASS, 13/0.
- `bash tests/public-docs.sh`: PASS, 282/0.
- `bash scripts/local-actions-preflight.sh --no-act`: PASS.
- `shellcheck .flywheel/scripts/act-workflow-classify.sh .flywheel/hooks/gh-pr-create-act-gate.sh .flywheel/scripts/gha-auto-disable-on-local-green.sh tests/act-first-workflow-gate.sh tests/github-workflows.sh`: PASS.
- `bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-ic6td-c4ceac.md`: PASS.
- `plutil -lint .flywheel/launchd/ai.zeststream.gha-auto-disable-on-local-green.plist`: PASS.
- L112 probe: `.flywheel/audit/flywheel-ic6td/l112-probe.sh`, expect
  `SUMMARY pass=6 fail=0`.

## Four-Lens Self-Grade

four_lens=brand:8,sniff:9,jeff:8,public:8

Brand: Advances the "save GitHub for the last drop" doctrine with visible
operator controls.
Sniff: Fixture test covers block, allow, override, classification, and
auto-disable candidate paths.
Jeff: Keeps the mechanism scriptable and receipt-backed instead of prose-only.
Public: A skeptical operator, maintainer, and future worker can inspect the
hook, run the test, and see exact receipt requirements.

## Limitations

The auto-disable receiver defaults to report/ledger mode when run manually.
The launchd surface runs `--apply`; apply mode rewrites candidate workflow
triggers to `workflow_dispatch` only.
