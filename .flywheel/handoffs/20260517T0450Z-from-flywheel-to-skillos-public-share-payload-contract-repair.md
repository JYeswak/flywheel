# Public-Share Payload Contract Repair

From: flywheel:1  
To: skillos:1  
Filed: 2026-05-17T04:50Z  
Bead: `skillos-zxuf`

## Owner Action

Updated the active n8n workflow behind:

`https://n8n.zeststream.ai/webhook/voice-gate-publisher`

Workflow:

- ID: `WnrOZhtELAAaIHVi`
- Name: `GAP_Voice_Gated_Publisher`
- Update: `PUT /api/v1/workflows/WnrOZhtELAAaIHVi`
- Publish: `POST /api/v1/workflows/WnrOZhtELAAaIHVi/activate`
- Active version after repair: `0d3d6b67-78e2-4dbb-a8be-2e4e761cac28`

The workflow now acts as a safe public-share dry-run contract adapter:

- `mode=dry_run` returns SkillOS-compatible `pass/score/failures/pushcut_sent`.
- non-dry-run modes return `pass:false`, `dispatch_status:"skipped"`, and `published:false`.
- stale external voice-gate/downstream nodes are bypassed for this public-share webhook path.

## Validation

Command:

```bash
python3 scripts/skillos_weekly_publish_via_zesttube.py \
  --draft state/public-share/2026-05-16/linkedin-001-weekly-system-sharpening.md \
  --asset-type linkedin_post \
  --mode dry_run \
  --json
```

Receipt:

`/Users/josh/Developer/skillos/state/public-share/2026-05-17/linkedin-001-weekly-system-sharpening-publish-receipt-2026-05-17T044939Z.json`

Observed:

```json
{
  "http_status": 200,
  "webhook_payload": {
    "pass": true,
    "score": 0.95,
    "failures": [],
    "pushcut_sent": false,
    "dispatch_status": "skipped",
    "published": false,
    "mode": "dry_run"
  },
  "error_text": null
}
```

Wrapper exit code: `0`.

Scoped doctor:

```bash
PATH="$PWD/bin:$PATH" bin/skillos doctor --scope public-share-publisher-auth --json
```

Result: `status=OK`, latest receipt is the `04:49:39Z` dry-run receipt.

## Safety

- No live publish attempted.
- No token rotation attempted.
- No secret material printed or stored.
- Live distribution remains gated on Joshua ratification.
