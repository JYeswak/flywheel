---
title: "JSM Canonical Auth Contract: Always Use the Skillos Process"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# JSM Canonical Auth Contract: Always Use the Skillos Process

Version: `jsm-canonical-auth-contract/v1`
Owner: skillos (canonical auth contract owner) + flywheel workers (consumer)
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.118 (memory-without-cross-link wire-in)

## TL;DR

JSM authentication has a canonical 4-invariant contract built by skillos.
**NEVER manually `jsm login`** without `JSM_DISABLE_KEYRING=1` — that re-creates
the keychain path and re-introduces GUI password prompts in agent shells.
Always use the file-based encrypted credentials path skillos provisioned.

Joshua's 2026-05-08T~23:30Z directive: *"skillos built a process so that jsm
would source a password on my machine. every time I've come back to my machine
recently there has been jsm password input requests. we need to ensure we're
using the processes skillos built to connect to jsm reliably."*

## Canonical memory source

This doctrine summarizes
`feedback_jsm_canonical_auth_contract_use_skillos_process.md` — the META-RULE
memory documenting the contract. Read the memory for the full setup recipe +
recovery troubleshooting. **Canonical contract source itself lives at
`/Users/josh/Developer/skillos/docs/jsm-auth-contract.md`** (skillos-owned
truth).

## The contract (two layers)

- **Layer A (jsm itself):**
  - OAuth-keychain path → GUI prompt (the failure mode)
  - **File-based encrypted credentials path → no prompt** (the canonical path)
- **Layer B (skillos guarded runner):** `scripts/jsm_guarded_runner.py` gates
  skillos's mutating commands behind sandbox-auth-ok proof

## The 4 invariants — all must be true

| # | Invariant | Check |
|---|---|---|
| 1 | `credentials_enc_populated` | `~/Library/Application Support/jsm/credentials.enc` size > 0 |
| 2 | `passphrase_file_present` | `~/.local/state/jsm/jsm-passphrase.env` exists |
| 3 | `JSM_ALLOW_ENV_PASSPHRASE_set` | env var `=1` in shell |
| 4 | `JSM_CREDENTIALS_PASSPHRASE_set` | env var non-empty in shell |

Probe:
```bash
skillos doctor --scope jsm --json | jq .subsystems.jsm.invariants
```

All 4 must report true. Any false = troubleshoot before invoking `jsm`.

## When jsm-managed-skill discipline applies

Flywheel workers regularly check `jsm list` / `jsm show <skill>` to determine
mutator path (see
`.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md`). Those reads
require auth-contract invariants to be true; otherwise jsm prompts for password
mid-worker-tick and silently stalls.

## Anti-pattern

**NEVER manually `jsm login` without `JSM_DISABLE_KEYRING=1`.**

The default `jsm login` writes to macOS Keychain, which:
- Re-introduces GUI password prompts in agent shells
- Breaks every subsequent `jsm list`/`jsm show` call
- Joshua's 2026-05-08 incident: returned to machine after agent runs to find
  jsm password input requests waiting

## Recovery procedure

When jsm prompts despite invariants checking true:

1. **Process context** — likely launchd job started before `.zshenv` was
   sourced, OR raw bash invocation that didn't pick up the env block.
   Fix by ensuring caller sources `~/.zshenv` or sets the env vars
   explicitly.
2. **Keychain item exists alongside file-based** — jsm may prefer keychain.
   Either delete the keychain item, OR set `JSM_DISABLE_KEYRING=1` globally
   in shell init.
3. **Run `skillos doctor --scope jsm --json`** — emits invariant status +
   per-invariant remediation guidance.

## Setup recipe (canonical, from skillos docs)

```bash
PASSPHRASE="$(openssl rand -hex 12)"
mkdir -p ~/.local/state/jsm
printf 'JSM_CREDENTIALS_PASSPHRASE=%s\n' "$PASSPHRASE" > ~/.local/state/jsm/jsm-passphrase.env
chmod 600 ~/.local/state/jsm/jsm-passphrase.env

# Add canonical load block to ~/.zshenv (idempotent; usually already present
# per Joshua's 2026-05-08 setup)

JSM_DISABLE_KEYRING=1 jsm login
# Browser opens → callback URL → at "Set a passphrase": enter same value as
# the one written to jsm-passphrase.env

skillos doctor --scope jsm --json  # verify all 4 invariants now report true
```

## Cross-references (skillos-canonical)

- Contract doc: `/Users/josh/Developer/skillos/docs/jsm-auth-contract.md`
- Guarded runner: `/Users/josh/Developer/skillos/scripts/jsm_guarded_runner.py`
- Recovery state log: `/Users/josh/Developer/skillos/state/jsm-auth-gate-recovery-options-2026-05-08.md`
- Tests: `/Users/josh/Developer/skillos/tests/test_jsm_guarded_runner.py`,
  `/Users/josh/Developer/skillos/tests/unit/test_jsm_auth_set_key.py`

## Sister doctrine

- `.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md` — consumers
  of jsm (reads) and mutators (skill pushes) both depend on the auth contract
- Memory `feedback_jsm_canonical_auth_contract_use_skillos_process.md` (the
  canonical memory source for this doctrine)

## Conformance

A flywheel worker that invokes `jsm` proves conformance via:
- Pre-call: `skillos doctor --scope jsm --json` returns all 4 invariants true
- Auth failure response: re-run skillos doctor; trust its remediation, don't
  manually `jsm login`
- Worker callback notes if jsm prompts blocked progress (so orch can re-route)

## Lifecycle

This is a HARD RULE. Bypassing the skillos process re-introduces the GUI-prompt
failure mode Joshua flagged on 2026-05-08. The canonical recovery is always
"run skillos doctor; fix what it surfaces; verify all 4 invariants; re-try."
