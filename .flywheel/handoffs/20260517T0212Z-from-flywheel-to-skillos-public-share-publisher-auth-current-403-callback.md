# Public-Share Publisher Auth Current 403 Callback

From: flywheel:1 / Codex
To: skillos:1
Filed: 2026-05-17T02:12Z
Topic: public-share publisher Cloudflare Access service-token verification

## Result

The runtime secret path is healthy in general, but the two required public-share publisher Cloudflare Access service-token keys are not currently available through the approved `cf-secret` path.

Checked keys by presence only:

- `CF_AT_GAP_VOICE_GATED_PUBLISHER_CLIENT_ID`: not present from environment and not present from `cf-secret`
- `CF_AT_GAP_VOICE_GATED_PUBLISHER_CLIENT_SECRET`: not present from environment and not present from `cf-secret`

The wrapper's `_load_cf_access_headers()` returned zero Access headers:

```json
{
  "header_count": 0,
  "has_client_id": false,
  "has_client_secret": false
}
```

No secret values were printed.

## Fresh Dry-Run

Command run from `/Users/josh/Developer/skillos`:

```bash
python3 scripts/skillos_weekly_publish_via_zesttube.py \
  --draft state/public-share/2026-05-16/linkedin-001-weekly-system-sharpening.md \
  --asset-type linkedin_post \
  --mode dry_run \
  --json
```

Result:

- exit code: `2`
- receipt: `/Users/josh/Developer/skillos/state/public-share/2026-05-17/linkedin-001-weekly-system-sharpening-publish-receipt-2026-05-17T021107Z.json`
- `http_status`: `403`
- `webhook_payload`: `null`
- `force_publish`: `false`
- mode: `dry_run`

## Scoped Doctor

Command:

```bash
bin/skillos doctor --scope public-share-publisher-auth --json
```

Result after the fresh dry-run:

- status: `WARN`
- latest receipt: `/Users/josh/Developer/skillos/state/public-share/2026-05-17/linkedin-001-weekly-system-sharpening-publish-receipt-2026-05-17T021107Z.json`
- `http_status`: `403`
- `webhook_payload_present`: `false`

## Owner-Lane Packet

Updated owner-lane packet:

`/Users/josh/Developer/flywheel/.flywheel/handoffs/20260517T0212Z-from-flywheel-to-cloudflare-owner-public-share-publisher-auth-secret-missing.md`

The required next action remains provisioning or verifying the Cloudflare Access service token through the approved Infisical path. This lane did not mutate auth, rotate tokens, or attempt live publish.

