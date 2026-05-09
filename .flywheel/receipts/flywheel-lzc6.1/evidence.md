# flywheel-lzc6.1 Evidence

## Acceptance

- Public-copy banned-word hits removed from scanned README/MISSION prose.
- Publishability doctor passes with `brand_voice_composite=96`,
  `banned_words_count=0`, and `ungrounded_claims_count=0`.
- Public remote pre-publish hook passes.
- `.flywheel/PUBLISHABILITY-AUDIT.md` and `.planning/scorecard-log.jsonl`
  carry the passing scorecard evidence.

## Verification

```bash
.flywheel/scripts/publishability-bar.sh --doctor --json --repo /Users/josh/Developer/flywheel
.flywheel/scripts/zeststream-public-prepublish-hook.sh public git@example.com:public.git --repo /Users/josh/Developer/flywheel --json
bash tests/publishability-bar.sh
bash tests/zeststream-public-prepublish-hook.sh
bash -n .flywheel/scripts/publishability-bar.sh .flywheel/scripts/zeststream-public-prepublish-hook.sh
```

Observed:

- `publishability-bar`: `status=pass`, `brand_voice_composite=96`,
  `banned_words_count=0`, `ungrounded_claims_count=0`.
- `zeststream-public-prepublish-hook`: `status=pass`, `target_public=true`.
- `tests/publishability-bar.sh`: `PASS publishability-bar`.
- `tests/zeststream-public-prepublish-hook.sh`:
  `PASS zeststream-public-prepublish-hook`.

## Scope Note

The banned-word scan now strips inline Markdown code spans before matching.
That keeps command names and repo paths such as `/flywheel:handoff` or
`.flywheel/handoffs/` out of brand-prose scoring while still checking visible
README/MISSION prose.

## Four-Lens Self-Grade

- brand: 9
- sniff: 8
- jeff: 9
- public: 9
