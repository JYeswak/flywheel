# Public-Share Publisher Auth Path OK

From: flywheel:1 / Codex
To: skillos:1
Filed: 2026-05-17T02:26Z
Topic: public-share publisher auth

## Result

The current public-share publisher blocker is no longer Cloudflare Access auth.

Flywheel found the 403 was Cloudflare `error code: 1010` against Python's default `urllib` request shape. The same POST with a normal automation/browser-style User-Agent reached n8n and returned machine-readable JSON.

## Changes Landed In SkillOS

- `scripts/skillos_weekly_publish_via_zesttube.py`
  - Adds an explicit `User-Agent: skillos-public-share-publisher/1.0 (+https://zeststream.ai)`.
- `mcp/skillos-mcp-server/lib/doctor_checks/public_share_publisher_auth.py`
  - Treats machine-readable webhook JSON as auth path reached, even for non-2xx webhook/workflow responses.
- `mcp/skillos-mcp-server/tests/test_doctor_new_v2_scopes.py`
  - Adds regression coverage for non-auth webhook JSON.

Receipt:

`/Users/josh/Developer/skillos/state/public-share-publisher-auth-owner-lane-20260517T0218Z.json`

## Validation

```bash
python3 -m pytest mcp/skillos-mcp-server/tests/test_doctor_new_v2_scopes.py -k public_share_publisher_auth -q
# 5 passed, 87 deselected

python3 -m py_compile scripts/skillos_weekly_publish_via_zesttube.py mcp/skillos-mcp-server/lib/doctor_checks/public_share_publisher_auth.py
# pass
```

Fresh dry-run:

```json
{
  "receipt": "state/public-share/2026-05-17/linkedin-001-weekly-system-sharpening-publish-receipt-2026-05-17T022240Z.json",
  "http_status": 404,
  "webhook_payload_present": true,
  "webhook_message": "The requested webhook \"POST gap-voice-gated-publisher\" is not registered.",
  "force_publish": false,
  "mode": "dry_run"
}
```

Scoped doctor:

```json
{
  "status": "OK",
  "http_status": 404,
  "webhook_payload_present": true
}
```

## Next Owner

Route remaining work to the n8n workflow owner: activate/register the production webhook `gap-voice-gated-publisher` or update SkillOS to the active production webhook path.

Live distribution remains gated on Joshua ratification.

No live publish, token rotation, auth mutation, or secret recording occurred.

