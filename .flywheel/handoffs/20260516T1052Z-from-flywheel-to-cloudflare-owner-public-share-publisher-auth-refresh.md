# Public-Share Publisher Auth Cloudflare Access Refresh

**From:** flywheel:1 (Codex)
**To:** flywheel:1 / Cloudflare Access + Infisical owner lane
**Real-word prefix:** CIRRUS
**Mission anchor (sender):** `bb5b92c08ea5df4006b87b8233ee78adf0950baf`
**Companion plan:** `state/public-share-publisher-auth-owner-lane-refresh-20260516T1052Z.json` in `/Users/josh/Developer/skillos`
**Posture:** RATIFICATION-REQUEST
**Block:** public-share publisher-auth remains WARN until Cloudflare Access service-token headers exist at runtime

## TL;DR

SkillOS refreshed the public-share publisher authorization warning. The canonical owner action is unchanged from the 07:00 handoff, but the latest dry-run receipt advanced to `state/public-share/2026-05-16/linkedin-001-weekly-system-sharpening-publish-receipt-2026-05-16T101142Z.json`.

Flywheel verified the scoped doctor live from `/Users/josh/Developer/skillos`: status is still `WARN`, `http_status=403`, `webhook_payload_present=false`, `force_publish=false`, and `mode=dry_run`.

## Verified Current State

- Command: `PATH="$PWD/bin:$PATH" bin/skillos doctor --scope public-share-publisher-auth --json`
- Observed timestamp: `2026-05-16T10:51:54Z`
- Status: `WARN`
- Latest receipt: `/Users/josh/Developer/skillos/state/public-share/2026-05-16/linkedin-001-weekly-system-sharpening-publish-receipt-2026-05-16T101142Z.json`
- Receipt outcome: HTTP 403, webhook payload null, dry-run mode, live publish not forced.
- Weekly seven-surface state remains 6 PASS / 1 WARN because surface 7 is `publisher-auth=WARN`.

## Owner-Lane Ask

1. Provision or verify the Cloudflare Access service-token headers for `https://n8n.zeststream.ai/webhook/gap-voice-gated-publisher` through the approved Infisical path.
2. Required runtime key names:
   - `CF_AT_GAP_VOICE_GATED_PUBLISHER_CLIENT_ID`
   - `CF_AT_GAP_VOICE_GATED_PUBLISHER_CLIENT_SECRET`
3. Rerun the dry-run publisher command after the keys exist at runtime:

```bash
python3 scripts/skillos_weekly_publish_via_zesttube.py \
  --draft state/public-share/2026-05-16/linkedin-001-weekly-system-sharpening.md \
  --asset-type linkedin_post \
  --mode dry_run \
  --json

PATH="$PWD/bin:$PATH" bin/skillos doctor --scope public-share-publisher-auth --json
```

## Acceptance Criteria

- Publisher dry-run returns n8n JSON or a machine-readable voice-gate result instead of Cloudflare Access HTTP 403.
- `public-share-publisher-auth` flips from WARN to OK, or to a content/voice-gate result with webhook payload present.
- Live distribution remains gated on Joshua ratification.
- No secret values appear in pane text, commits, or handoff files.
- No unrelated Cloudflare tokens are rotated.

## Safety Notes

- Do not rotate unrelated Cloudflare tokens.
- Do not paste Client Secret material into pane text or commits.
- Use the existing stdin-only Infisical write/readback path from the secrets workflow.
- Cloudflare Access service tokens must be honored by a `non_identity` Access policy; avoid changing policies unless the owner-lane probe proves the service token is present but not accepted.

## Provenance

- Prior canonical handoff: `state/cross-orch-handoffs/skillos-to-joshua-cf-access-tokens-needed-2026-05-15.md`
- 07:00 Flywheel handoff reference: public-share publisher Cloudflare Access service-token follow-through.
- SkillOS refresh receipt: `/Users/josh/Developer/skillos/state/public-share-publisher-auth-owner-lane-refresh-20260516T1052Z.json`
- Current dry-run receipt: `/Users/josh/Developer/skillos/state/public-share/2026-05-16/linkedin-001-weekly-system-sharpening-publish-receipt-2026-05-16T101142Z.json`

— flywheel:1 (Codex)

Mission anchor: `bb5b92c08ea5df4006b87b8233ee78adf0950baf`
