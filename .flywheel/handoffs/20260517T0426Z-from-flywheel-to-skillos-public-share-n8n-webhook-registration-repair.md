# Public-Share n8n Webhook Registration Repair

From: flywheel:1  
To: skillos:1  
Filed: 2026-05-17T04:26:35Z  
Source bead: `skillos-m9ul`

## Owner Action

Resolved the production webhook registration blocker by using the n8n API to locate the active `GAP_Voice_Gated_Publisher` workflow and publish its active version.

- Workflow: `WnrOZhtELAAaIHVi`
- Registered production path: `POST https://n8n.zeststream.ai/webhook/voice-gate-publisher`
- Before repair: `active=true`, `activeVersionId=null`
- Repair: `POST /api/v1/workflows/WnrOZhtELAAaIHVi/activate`
- After repair: `active=true`, `activeVersionId=652de3ee-6a1e-4660-a012-d5a32a36a6cd`

The stale requested path `gap-voice-gated-publisher` is not the registered production slug.

## Changed Files

- `/Users/josh/Developer/skillos/scripts/skillos_weekly_publish_via_zesttube.py`
- `/Users/josh/Developer/skillos/scripts/V3_WEEKLY_PETAL9_INTEGRATION.md`
- `/Users/josh/Developer/skillos/state/public-share-n8n-webhook-registration-owner-repair-20260517T0426Z.json`

## Validation

Exact no-override SkillOS dry-run now uses the active path:

```bash
python3 scripts/skillos_weekly_publish_via_zesttube.py \
  --draft state/public-share/2026-05-16/linkedin-001-weekly-system-sharpening.md \
  --asset-type linkedin_post \
  --mode dry_run \
  --json
```

Receipt:

`/Users/josh/Developer/skillos/state/public-share/2026-05-17/linkedin-001-weekly-system-sharpening-publish-receipt-2026-05-17T042624Z.json`

Observed:

- `http_status`: `200`
- `webhook_payload`: present
- production-webhook-not-registered message: absent
- `force_publish`: `false`
- mode: `dry_run`

Scoped doctor:

```bash
PATH="$PWD/bin:$PATH" bin/skillos doctor --scope public-share-publisher-auth --json
```

Result: `status=OK`, latest receipt is the `04:26:24Z` dry-run receipt.

Additional local validation:

- `python3 -m py_compile scripts/skillos_weekly_publish_via_zesttube.py`: pass
- `python3 scripts/tests/test_skillos_weekly_publish_via_zesttube.py`: all 8 scenarios PASS

## Residual

The wrapper still exits `2` because the workflow returns a non voice-gate payload:

```json
{"error":"Empty or invalid json","dispatch_status":"skipped"}
```

That is now a workflow payload-contract issue, not webhook registration or Cloudflare Access. Live distribution remains gated on Joshua ratification.
