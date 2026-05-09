# flywheel-cmov compliance pack

Task: `flywheel-cmov-a68084`
Bead: `flywheel-cmov`
Identity: `CloudyMill`
Date: 2026-05-09

## Scope

Evidence-only close for `[skillos-v2-tick-1] FoggyBear vault wired + 5 routed decisions notified`.

No runtime source, doctrine, skills, AGENTS, or README surfaces were changed. The closeout records already-completed FoggyBear vault/routing work and provides a re-runnable redacted probe.

## Evidence

| Claim | Evidence |
|---|---|
| Dispatch packet is valid | `bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-cmov-a68084.md` returned `valid=true`. |
| Bead had no dependency blocker | `br dep tree flywheel-cmov` showed only `flywheel-cmov` open. |
| AG3 held before artifact write | `br show flywheel-cmov --json` showed `status=open` before this pack was created. |
| FoggyBear vault file exists with 0600 mode | `stat -f '%Lp %N' ~/.local/state/flywheel/fleet-mail-tokens/FoggyBear.token` returned mode `600`. |
| LavenderGlen vault file exists with 0600 mode | `stat -f '%Lp %N' ~/.local/state/flywheel/fleet-mail-tokens/LavenderGlen.token` returned mode `600`. |
| Vault doctor passes for current topology identities | `bash .flywheel/scripts/fleet-mail-vault-doctor.sh` returned `PASS: all fleet_mail_identity values have tokens`. The doctor currently checks topology identities, so explicit mode checks above cover FoggyBear/LavenderGlen. |
| Smoke message exists | Local Agent Mail DB message `41` in project `/Users/josh/.local/state/flywheel/fleet-mail-project` has sender `FoggyBear`, recipient `LavenderGlen`, topic `foggybear-vault-wire`, and a non-null `read_ts`. |
| Routed decision message exists | Local Agent Mail DB message `42` has sender `FoggyBear`, recipient `LavenderGlen`, topic `skillos-routed-decisions`, `importance=high`, `ack_required=1`, and non-null `read_ts`/`ack_ts`. |
| Five routed notification rows exist | `jq -s '[.[] | select(.event=="notification_status_update" and .task_id=="foggybear-vault-wire-2026_05_03")] | length' ~/.local/state/flywheel/skillos-routed.jsonl` returned `5`. |
| Routed skills match dispatch claim | Target skills: `meta-graph-publishing`, `x-api-saas-posting`, `google-youtube-workspace-oauth`, `nango-integrations`, `railway-api+nango-integrations`. |
| Token hygiene preserved in artifacts | This pack and receipt name token paths and modes only; no token values, token fragments, or token hashes are included. |

## Acceptance Gates

AG1: Pass. Close evidence is recorded in `.flywheel/audit/flywheel-cmov/compliance-pack.md` and `.flywheel/receipts/flywheel-cmov/flywheel-cmov-a68084-evidence.md`.

AG2: Pass. Targeted validators are named and the re-runnable L112 probe is `.flywheel/receipts/flywheel-cmov/l112-probe.sh`.

AG3: Pass. `br show flywheel-cmov --json` remained `open` until this artifact existed.

## Verification Commands

```bash
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-cmov-a68084.md
bash .flywheel/scripts/fleet-mail-vault-doctor.sh
stat -f '%Lp %N' ~/.local/state/flywheel/fleet-mail-tokens/FoggyBear.token ~/.local/state/flywheel/fleet-mail-tokens/LavenderGlen.token
jq -s '[.[] | select(.event=="notification_status_update" and .task_id=="foggybear-vault-wire-2026_05_03")] | length == 5' ~/.local/state/flywheel/skillos-routed.jsonl
bash .flywheel/receipts/flywheel-cmov/l112-probe.sh
```

## Skill Auto-Routes

`canonical-cli-scoping=n/a`: no CLI source changed; existing validation commands already expose `--json` where applicable.

`rust-best-practices=n/a`: no Rust files changed.

`python-best-practices=n/a`: no Python files changed.

`readme-writing=n/a`: no README or public docs changed.

## L61 Surface

No doctrine, canonical L-rule, or skill surface was modified. `agents_md_updated=not_applicable`, `readme_updated=not_applicable`, `no_touch_reason=evidence_only_no_doctrine_or_public_readme_surface`.

## L52 / L53

No new bead was filed. No new gap was discovered; the only nuance was measurement wording around the topology-scoped vault doctor, handled by pairing the doctor result with explicit FoggyBear/LavenderGlen mode checks.

No fuckup row was logged because the task completed without blocker or trauma-class incident.

## Four-Lens Self-Grade

`four_lens=brand:8,sniff:8,jeff:8,public:8`

Brand: concise evidence-only pack with no secret leakage.

Sniff: claims are backed by commands or local database rows, not prose alone.

Jeff: structured closure, pathspec-ready artifacts, and re-runnable probe.

Public: a skeptical operator, maintainer, and future worker can verify the named facts without reading token material.

## Compliance Score

`820/1000`

The pack meets dispatch, L112, L120, L126, and token hygiene requirements. Minor deduction: the original dispatch phrasing says the vault doctor passes "for FoggyBear and LavenderGlen", while the current doctor implementation checks topology identities; this closeout records that nuance and adds explicit mode checks.
