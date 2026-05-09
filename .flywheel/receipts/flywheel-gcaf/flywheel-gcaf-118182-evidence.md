# flywheel-gcaf-118182 evidence receipt

Bead: `flywheel-gcaf`
Status before close evidence: `open`
Evidence redacted: `yes`

## Result

Routed decision loop evidence was verified. Current JSM structural validation for the two updated skills does not pass due executable-script policy, so this receipt records the caveat instead of claiming a clean validator pass.

## Commands Run

```bash
br show flywheel-gcaf --json
br dep tree flywheel-gcaf
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-gcaf-118182.md
br show flywheel-mdry --json
br show flywheel-vd2c --json
br show flywheel-a2eo --json
jq -c 'select((.original_row_ref=="line:4:sha256:85717547fcbc4b1a") or (.original_row_ref=="line:5:sha256:1342593f3bc1917f")) | {ts,event,task_id,original_row_ref,target_skill_id,candidate_domain,notification_status}' ~/.local/state/flywheel/skillos-routed.jsonl
rg -n 'Social Actions|SaaS Posting Through Nango|Nango on Railway|SELF-HOSTED|Railway' ~/.claude/skills/nango-integrations ~/.claude/skills/railway-api -g 'SKILL.md' -g '*.md'
timeout 20 jsm validate ~/.claude/skills/nango-integrations --json
timeout 20 jsm validate ~/.claude/skills/railway-api --json
bash .flywheel/receipts/flywheel-gcaf/l112-probe.sh
```

## Redacted Facts

- `flywheel-mdry` is closed.
- `flywheel-vd2c` and `flywheel-a2eo` are priority-3 closed update beads with routed-decision close reasons.
- Routed source rows `line:4:sha256:85717547fcbc4b1a` and `line:5:sha256:1342593f3bc1917f` exist with notified update rows.
- `nango-integrations` contains Nango action and self-hosted Railway handoff coverage.
- `railway-api` contains a Nango-on-Railway runbook.
- Current `jsm validate` fails on executable-script policy for both updated skills.
- Follow-up bead `flywheel-ovp71` tracks the JSM validation caveat.

## Acceptance

- AG1: pass
- AG2: pass with JSM validation caveat
- AG3: pass

## Notes

No token values, token fragments, registration tokens, or token hashes are copied into this receipt.
