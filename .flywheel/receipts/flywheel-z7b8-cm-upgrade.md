# flywheel-z7b8 cm upgrade receipt

Bead: `flywheel-z7b8`
Tool: `cm`
Repo: `Dicklesworthstone/coding_agent_session_search`
Decision: `pin`

## Version probes

- Pre-version: `0.2.3`
- Dispatch target: `0.4.1`
- Live latest release: `v0.4.2`, published `2026-05-06T07:16:32Z`
- Live latest source: `gh release view v0.4.2 --repo Dicklesworthstone/coding_agent_session_search`
- Installed post-version: `0.2.3`
- Installed path: `/Users/josh/.local/bin/cm`

## Install / pin method

I downloaded and verified both release candidates in isolated tmp:

- `v0.4.1` asset: `cass-darwin-arm64.tar.gz`
  - sha256: `f409da9db762035a9fe70a9e72b1cdbb0b04d4351f5cd3afc8382ee61200fce3`
  - extracted binary reported: `cass 0.4.1`
- `v0.4.2` asset: `cass-darwin-arm64.tar.gz`
  - sha256: `f31f7542170f4206b7381edf60739748ccffc6392255da37f4e55d99a3cc295c`
  - extracted binary reported: `cass 0.4.2`

I temporarily installed `v0.4.2`, confirmed the break below, then restored the
backup with:

```bash
install -m 0755 /Users/josh/.local/bin/cm.0.2.3.bak /Users/josh/.local/bin/cm
```

Post-restore hash:

```text
f310f7eb690c642575de4348f2b1871286caf9338eb5aa7ea00da73ffc6f1546  /Users/josh/.local/bin/cm
```

## Breaking behavior observed

Local `cass-memory` skill contract requires:

```bash
cm context "<task>" --workspace "$(pwd -P)" --json
```

`cm 0.2.3` accepts that command and returned:

```json
{"success":true,"code":null,"error":null,"relevantBullets":0,"antiPatterns":0}
```

Both `v0.4.1` and `v0.4.2` reject the same contract:

```text
error: unexpected argument '--workspace' found
Usage: cass context --source <SOURCE> <PATH>
```

That is breaking-incompatible for existing worker preflight prompts and the
local `cass-memory` skill. I therefore intentionally pinned `cm` at `0.2.3`
instead of shipping a silent CLI contract break.

## Watchtower confirmation

Command:

```bash
bash .flywheel/scripts/jeff-binary-version-watchtower.sh --json
```

Post-pin summary:

```json
{
  "schema_version": "jeff-binary-version-watchtower.v2",
  "status": "warn",
  "stale_count": 0,
  "unknown_count": 1,
  "cm_behind_count": 0,
  "cm_rows": []
}
```

The current watchtower script is read-only for this dispatch and currently emits
only the `ntm` row, so `cm` no longer reports `relation=behind` because no `cm`
row is emitted. That is a watchtower coverage limitation, not an upgrade proof.
The live `cm --version` and smoke tests above are the pin proof.

## Behavior-breaking follow-up

Filed follow-up bead: `flywheel-anqp1`

Title:
`[cm-upgrade-break] 0.4.x breaks cm context workspace contract`

The follow-up decides whether to keep the pin, add a compatibility wrapper, or
update all local CASS memory call sites to the new `cass 0.4.x` CLI.

## Joshua lens

Joshua's 25-year operations-manager lens supports the pin: version drift on
Jeffrey's substrate is the silent-bug class an experienced ops manager catches
via the watchtower, but the operating rule is upgrade-or-pin with a receipt, not
"latest at any cost." A memory preflight command that changes shape without the
team noticing would burn future worker time and break turnover-resilience. This
receipt keeps the current operator contract working while routing the upgrade
decision into a follow-up bead.
