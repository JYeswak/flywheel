# Installer Design — `curl | bash` without making you nervous

> *The design contract for the flywheel one-line installer. Not yet shipped; this is the specification.*

The standard "curl-pipe-bash" install pattern has a reputation problem. People look at `curl -sSL https://example.com/install.sh | bash` and (correctly) wonder: what does this thing do, why should I trust it, and how do I undo it if I don't like the result?

This document is the answer. It specifies what flywheel's installer is allowed to do, what it isn't, and what every user gets in return.

---

## What you'll run

```sh
curl -sSL https://flywheel.zeststream.ai/install.sh | bash
```

That URL serves a versioned shell script. The script is short, readable, signed, and reproduces a byte-identical local state given the same input.

## What the installer is allowed to do

### Read-only inspection of your environment

The installer inspects (does not modify):

- `git --version` — confirm git is installed
- `claude --version` (if Claude Code is installed) — confirm available agent
- `jq --version`, `python3 --version` — required dependencies for safety hooks
- `~/.claude/settings.json` — to verify it's well-formed JSON before any edit
- `~/.flywheel/` directory — to detect any existing installation

If a required dependency is missing, the installer prints what's needed and a recommended install command for the user's OS. It does not auto-install dependencies. You make the call.

### File creation in user-owned, non-system paths

The installer creates files in these specific locations:

```
~/.flywheel/                           ← user-owned runtime state
├── engine/                            ← versioned engine, cloned from public repo
├── config.yaml                        ← composition config (defaults; user-editable)
├── cross-repo-authorized-writes.json  ← empty authorize-list scaffold
└── private/                           ← empty; user-owned overlay home

~/.claude/hooks/                       ← Claude Code hooks (additive)
├── pretooluse-bash-cross-repo-guard.sh
├── pretooluse-write-edit-cross-repo-guard.sh
└── posttooluse-bash-secret-redact.sh
```

It does not touch `~/`, `/etc/`, `/usr/`, `/opt/`, `/Applications/`, or any path outside the directories listed above.

### One additive edit to `~/.claude/settings.json`

If `~/.claude/settings.json` exists, the installer adds (does not replace) entries to the `hooks.PreToolUse` and `hooks.PostToolUse` arrays for the flywheel safety hooks. The pre-edit state is preserved at `~/.claude/settings.json.flywheel-backup-<timestamp>` for byte-equality recovery.

The diff is:

```diff
   "hooks": {
     "PreToolUse": [
       { /* your existing hooks */ },
+      {
+        "matcher": "Bash",
+        "hooks": [
+          { "type": "command", "command": "$HOME/.flywheel/engine/hooks/pretooluse-bash-cross-repo-guard.sh" }
+        ]
+      },
+      {
+        "matcher": "Write|Edit|NotebookEdit",
+        "hooks": [
+          { "type": "command", "command": "$HOME/.flywheel/engine/hooks/pretooluse-write-edit-cross-repo-guard.sh" }
+        ]
+      }
     ],
     "PostToolUse": [
       { /* your existing hooks */ },
+      {
+        "matcher": "Bash",
+        "hooks": [
+          { "type": "command", "command": "$HOME/.flywheel/engine/hooks/posttooluse-bash-secret-redact.sh" }
+        ]
+      }
     ]
   }
```

If your `settings.json` already has matchers with these names, the installer prints the conflict and asks you what to do. It does not silently overwrite.

If `~/.claude/settings.json` does not exist, the installer creates a minimal one with just the flywheel hooks. You can edit freely afterward.

## What the installer is NOT allowed to do

- ❌ Modify any file outside `~/.flywheel/`, `~/.claude/hooks/`, or `~/.claude/settings.json`
- ❌ Install global packages (no `npm install -g`, no `pip install --system`, no `brew install`)
- ❌ Use `sudo` (the installer is fully user-space; if it can't run user-space, it tells you and exits)
- ❌ Touch any `.env`, `.netrc`, `~/.ssh/`, `~/.aws/`, or any other credential location
- ❌ Phone home (no telemetry in v0.1; v0.2 may add opt-in)
- ❌ Add anything to your `PATH`, `~/.bashrc`, `~/.zshrc`, or shell init files without explicit prompt
- ❌ Modify any existing git repository

## How you uninstall

```sh
curl -sSL https://flywheel.zeststream.ai/uninstall.sh | bash
```

The uninstaller:

1. Removes `~/.flywheel/engine/` (the versioned engine)
2. Removes the hook files from `~/.claude/hooks/` (those it installed; leaves your own alone)
3. Reverts `~/.claude/settings.json` to the byte-identical pre-install state from the timestamped backup
4. Leaves `~/.flywheel/private/`, `~/.flywheel/config.yaml`, and `~/.flywheel/cross-repo-authorized-writes.json` intact — these are your data
5. Prints a one-line summary of what was removed and what was preserved

If you want to remove everything including your data:

```sh
flywheel uninstall --remove-overlay
```

(Asks for confirmation; cannot be reversed without backups.)

## What you get to verify before running

The install URL serves a script that begins with:

```sh
#!/usr/bin/env bash
# flywheel install.sh — version <X.Y.Z>
# Released: <date>
# SHA-256: <self-hash>
# Verify: curl -sSL https://flywheel.zeststream.ai/install.sh.sha256
# Inspect: curl -sSL https://flywheel.zeststream.ai/install.sh | less
# Source: https://github.com/JYeswak/flywheel/blob/v<X.Y.Z>/install.sh
```

You can inspect before running:

```sh
curl -sSL https://flywheel.zeststream.ai/install.sh | less
```

You can verify the hash:

```sh
EXPECTED=$(curl -sSL https://flywheel.zeststream.ai/install.sh.sha256)
ACTUAL=$(curl -sSL https://flywheel.zeststream.ai/install.sh | shasum -a 256 | awk '{print $1}')
[ "$EXPECTED" = "$ACTUAL" ] && echo "ok" || echo "MISMATCH"
```

The hash file is generated at release time and published alongside the script.

## What happens on a failed install

The installer is **atomic at the visible-state layer**: either the install completes cleanly and reports success, or it aborts and leaves your system byte-identical to its pre-install state.

If anything fails partway through:

1. The installer reverts every file it created
2. The installer reverts the `settings.json` edit using the timestamped backup
3. It prints what failed, why, and a remediation hint
4. Exits non-zero

You can re-run safely after addressing the cause.

## Post-install verification

After install, the installer runs:

```sh
~/.flywheel/engine/bin/flywheel doctor --post-install
```

This checks:

- All expected files exist with correct permissions
- `~/.claude/settings.json` is well-formed JSON with the expected hooks
- The hooks are executable
- The hooks pass a self-test (mock inputs return expected blocks/passes)
- The optional dependencies (NTM, beads, Claude Code) are detected or noted absent

If `doctor --post-install` fails, the installer offers to run `doctor --repair` (which is itself reversible) or to uninstall.

## Reversibility receipt

Every install produces an explicit reversibility receipt at `~/.flywheel/install-receipt-<timestamp>.json`:

```json
{
  "schema_version": "flywheel.install_receipt/v1",
  "installed_at": "2026-05-12T15:30:00Z",
  "version": "0.2.0",
  "files_created": [
    "~/.flywheel/engine/...",
    "~/.claude/hooks/pretooluse-bash-cross-repo-guard.sh",
    ...
  ],
  "files_modified": [
    "~/.claude/settings.json"
  ],
  "backups": {
    "~/.claude/settings.json": "~/.claude/settings.json.flywheel-backup-20260512T153000Z"
  },
  "uninstall_command": "~/.flywheel/engine/bin/uninstall.sh"
}
```

This receipt is the authoritative record of what was installed and how to undo it.

## Versioning and updates

The installer supports pinned versions:

```sh
curl -sSL https://flywheel.zeststream.ai/install.sh | bash -s -- --version 0.2.0
```

Versions are semantic. Major version changes (1.x → 2.x) are not backward-compatible and require explicit opt-in. Minor versions (0.2 → 0.3) add features without breaking existing setups. Patch versions are bug fixes.

To update:

```sh
flywheel update           # to latest minor in current major
flywheel update --major   # to latest, including major (asks confirmation)
```

The update command:

1. Snapshots current state (backup receipt)
2. Diffs new engine against current
3. Shows you the changes
4. Applies if you confirm
5. Runs `doctor --post-update` to verify

## What this isn't

- **Not a package manager replacement.** Flywheel is one project, installed in one location. If you want to manage multiple AI tooling projects, use a package manager or dotfiles framework.
- **Not auto-updating.** No background daemons. Updates happen when you run `flywheel update`.
- **Not network-dependent at runtime.** Once installed, flywheel runs entirely locally. It only touches the network for explicit updates or your own AI provider calls.

## Implementation status

| Component | Status |
|---|---|
| Installer specification | This document (v0.1) |
| Installer implementation | ⏳ Wave 2 |
| Hosting at `flywheel.zeststream.ai` | ⏳ Wave 2 |
| SHA-256 signing pipeline | ⏳ Wave 2 |
| Versioned releases | ⏳ Wave 2 |
| `doctor --post-install` | ⏳ Wave 2 |
| Uninstaller | ⏳ Wave 2 |

This is the specification. The implementation lands in Wave 2 of the public-share-readiness rollout.

---

*This document is part of the flywheel ecosystem. The installer is the front door for new users; it is held to a higher standard than internal code precisely because it is the first thing every adopter encounters.*
