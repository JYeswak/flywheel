# Audit pack: flywheel-fqsmx

**Bead:** flywheel-fqsmx — [session-start-hook activation] joshua-gated wire-in to `~/.claude/settings.json` SessionStart
**Labels:** `joshua-gated`, `session-hook`, `skillos-cohort`
**Task ID:** flywheel-fqsmx-8493db
**Worker:** MistyCliff (flywheel:0.4)
**UTC:** 2026-05-10T02:55:30Z
**Disposition:** BLOCKED — preconditions met, Joshua sign-off required for the live `~/.claude/settings.json` edit.

## Why BLOCKED, not DONE

The bead title literally calls this a "joshua-gated wire-in to
`~/.claude/settings.json` SessionStart." Labels include `joshua-gated`.
The risk note in the bead body — "every Claude Code session start
will run the hook ... surface area for unexpected systemMessage
injection grows" — names the exact reason: the wire-in target is the
top-level Claude Code settings file, with system-wide blast radius
on every future session.

Worker scope here is *verify preconditions + prepare patch*, not
*apply the gated edit*. This is consistent with the
`feedback_caam_activate_is_flywheel_decided_not_joshua_gated` carve-out
— that rule applies to *false* Joshua-gates (vault profile selectors,
per-bead workflow signoffs). This bead is the *real* class: a global
config edit that can break or surprise every Claude session if the
consumer hook misbehaves.

The patch artifact at
`.flywheel/audit/flywheel-fqsmx/proposed-settings-patch.json` carries
the exact one-line jq operation Joshua can apply.

## Cohort policy: preconditions verified met

The bead body sets two cohort preconditions before activation:

1. "the skillos producer side is on a per-session emit cadence"
2. "the canonical sessions-root path has visible packets in production"

Both met:

### 1. Producer active

```
$ ls ~/Developer/skillos/scripts/skillos_session_start_hook.sh
-rwxr-xr-x  21994 May  8 23:39 .../skillos_session_start_hook.sh
```

Producer file present, executable, recent.

### 2. Packets visible, all schema-conformant, fresh

```
$ for p in ~/.local/state/flywheel/sessions/*/context_upgrade_packet.json; do
    printf '%s mtime=%s schema=%s\n' "$(basename $(dirname "$p"))" \
      "$(stat -f %Sm "$p")" "$(jq -r '.schema_version // "?"' "$p")"
  done
alpsinsurance mtime=May  9 20:44:55 2026 schema=skillos.context_upgrade_packet.session_start.v1
mobile-eats   mtime=May  9 20:44:55 2026 schema=skillos.context_upgrade_packet.session_start.v1
skillos       mtime=May  9 20:44:56 2026 schema=skillos.context_upgrade_packet.session_start.v1
test          mtime=May  9 20:44:56 2026 schema=skillos.context_upgrade_packet.session_start.v1
vrtx          mtime=May  9 20:44:56 2026 schema=skillos.context_upgrade_packet.session_start.v1
```

5 packets, all conform to `skillos.context_upgrade_packet.session_start.v1`,
all generated 2026-05-10T02:44:56Z (~10 minutes pre-dispatch).

Caveat: packets are project-keyed (e.g. `sessions/skillos/`), not
session-id-keyed. The bead body's path template `<id>` is satisfied
by project name today; if Joshua wants strict per-session-id keying
before activation, that's a sub-bead, not a blocker for this one.

## Consumer health: smoke 7/7 PASS

```
$ bash tests/session-start-hook-smoke.sh
PASS hook exists and is executable
PASS --info exposes schema + mission lock hash
PASS --examples cites --session and --dry-run
PASS unknown flag returns exit 1
PASS missing packet => silent no-op (exit 0, empty stdout)
PASS --json envelope conforms to flywheel.session_start_hook.status.v1 (noop)
PASS SKILLOS_DISABLED=1 silent no-op exit 0
SUMMARY pass=7 fail=0
```

Backwards-compat is silent no-op (exit 0, empty stdout) on missing
packet — the consumer cannot break a session even if the producer
goes dark.

## Current settings.json state

```
$ jq '.hooks // {} | keys[]?' ~/.claude/settings.json
PostToolUse
PreToolUse
Stop

$ jq '.hooks.SessionStart // null' ~/.claude/settings.json
null
```

`SessionStart` key is absent — confirms the bead's "wired-but-cold"
claim. The patch adds a single SessionStart entry; existing
PreToolUse/PostToolUse/Stop hooks are untouched.

## Proposed patch

See `proposed-settings-patch.json` in this audit pack. Summary:

```jq
.hooks.SessionStart = [
  { "matcher": "*",
    "hooks": [
      { "type": "command",
        "command": "$HOME/.claude/skills/.flywheel/hooks/session-start.sh --session=$CLAUDE_SESSION_ID"
      }
    ]
  }
]
```

Format mirrors the existing PreToolUse entry shape (matcher + hooks
array of `{type, command}` objects). Apply command and post-apply
verification commands are in the patch JSON.

## What Joshua needs to decide

1. Apply the patch as-is, accepting the every-session blast radius
   (consumer is silent-no-op-safe per smoke Test 5).
2. Defer until session-id-keyed packets land (currently project-keyed
   only — file a sub-bead, hold this one open).
3. Reject — keep the consumer cold; close `flywheel-fqsmx` as
   intentionally-deferred.

The worker has no honest way to make this call without Joshua —
hence BLOCKED, not DONE.

## Files

- `.flywheel/audit/flywheel-fqsmx/evidence.md` (this file)
- `.flywheel/audit/flywheel-fqsmx/proposed-settings-patch.json`
- `.flywheel/audit/flywheel-fqsmx/smoke-results.txt`

## No edits performed

This audit pack contains only read-only inspection results and a
proposed patch artifact. No mutation of `~/.claude/settings.json`,
`~/.claude/skills/.flywheel/hooks/session-start.sh`, or any
production file occurred.
