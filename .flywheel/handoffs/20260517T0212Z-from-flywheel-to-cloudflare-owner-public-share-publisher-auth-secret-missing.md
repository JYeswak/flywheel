# Public-Share Publisher Auth Secret Missing Owner Packet

From: flywheel:1 / Codex
To: Cloudflare Access + Infisical owner lane
Filed: 2026-05-17T02:12Z
Topic: gap-voice-gated-publisher Cloudflare Access service token

## Current State

SkillOS public-share publisher auth still fails at the Cloudflare Access boundary.

The approved `cf-secret` helper itself probes successfully, but the two expected runtime keys are absent:

- `CF_AT_GAP_VOICE_GATED_PUBLISHER_CLIENT_ID`
- `CF_AT_GAP_VOICE_GATED_PUBLISHER_CLIENT_SECRET`

Because the keys are absent, `scripts/skillos_weekly_publish_via_zesttube.py` attaches no `CF-Access-Client-Id` or `CF-Access-Client-Secret` headers. The dry-run therefore still receives HTTP 403 with no n8n JSON payload.

## Fresh Evidence

Dry-run command:

```bash
cd /Users/josh/Developer/skillos
python3 scripts/skillos_weekly_publish_via_zesttube.py \
  --draft state/public-share/2026-05-16/linkedin-001-weekly-system-sharpening.md \
  --asset-type linkedin_post \
  --mode dry_run \
  --json
```

Fresh receipt:

`/Users/josh/Developer/skillos/state/public-share/2026-05-17/linkedin-001-weekly-system-sharpening-publish-receipt-2026-05-17T021107Z.json`

Observed:

```json
{
  "http_status": 403,
  "webhook_payload_present": false,
  "force_publish": false,
  "mode": "dry_run"
}
```

Scoped doctor remains `WARN` against that receipt.

## Required Owner Action

Use the approved Cloudflare Access and Infisical workflow to either:

1. Provision a service token accepted by the Access app/policy for `https://n8n.zeststream.ai/webhook/gap-voice-gated-publisher`, then store the client id and client secret under the two expected key names; or
2. Confirm the keys exist elsewhere and update the approved runtime secret path so `cf-secret` resolves them; or
3. Return a bounded deferral naming the missing authority or policy blocker.

After the keys resolve, rerun:

```bash
cd /Users/josh/Developer/skillos
python3 scripts/skillos_weekly_publish_via_zesttube.py \
  --draft state/public-share/2026-05-16/linkedin-001-weekly-system-sharpening.md \
  --asset-type linkedin_post \
  --mode dry_run \
  --json

bin/skillos doctor --scope public-share-publisher-auth --json
```

## Safety

- No live publish attempted.
- No token rotation attempted.
- No auth mutation attempted.
- No secret material printed or recorded.
- Do not paste client secret material into panes, commits, or handoff files.

