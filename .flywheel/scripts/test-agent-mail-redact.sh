#!/usr/bin/env bash
# Synthetic regression test for agent-mail-send-redacted.sh.
set -euo pipefail

ROOT="/Users/josh/Developer/flywheel"
WRAPPER="$ROOT/.flywheel/scripts/agent-mail-send-redacted.sh"
FAKE_TOKEN="FAKE_AGENT_MAIL_TOKEN_1234567890"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/agent-mail-redact-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

VAULT="$TMP/vault"
CAPTURE="$TMP/capture"
REGISTER_CAPTURE="$TMP/register-capture"
STDOUT="$TMP/stdout.txt"
STDERR="$TMP/stderr.txt"

mkdir -p "$VAULT"
chmod 700 "$VAULT"
printf '%s' "$FAKE_TOKEN" >"$VAULT/SyntheticAgent.token"
chmod 600 "$VAULT/SyntheticAgent.token"

AGENT_MAIL_TOKEN_VAULT_DIR="$VAULT" "$WRAPPER" send_message \
  --project-key "/tmp/synthetic-agent-mail-project" \
  --sender-name "SyntheticAgent" \
  --to "SyntheticRecipient" \
  --subject "Synthetic redaction test" \
  --body "Synthetic body with no credential material" \
  --sender-token-handle "vault:SyntheticAgent" \
  --capture-dir "$CAPTURE" \
  --dry-run >"$STDOUT" 2>"$STDERR"

for file in "$CAPTURE/dispatch.txt" "$CAPTURE/wrapper.log" "$CAPTURE/pane-visible-tool-call-args.json" "$STDOUT" "$STDERR"; do
  if [[ ! -f "$file" ]]; then
    printf 'FAIL: missing capture file: %s\n' "$file" >&2
    exit 1
  fi
  if grep -Fq "$FAKE_TOKEN" "$file"; then
    printf 'FAIL: synthetic token appeared in %s\n' "$file" >&2
    exit 1
  fi
done

if ! grep -Fq '[REDACTED]' "$CAPTURE/pane-visible-tool-call-args.json"; then
  printf 'FAIL: pane-visible args did not include redacted token marker\n' >&2
  exit 1
fi

AGENT_MAIL_TOKEN_VAULT_DIR="$VAULT" "$WRAPPER" register_agent \
  --project-key "/tmp/synthetic-agent-mail-project" \
  --agent-name "SyntheticAgent" \
  --program "synthetic" \
  --model "synthetic-model" \
  --task-description "Synthetic registration redaction test" \
  --registration-token-handle "vault:SyntheticAgent" \
  --capture-dir "$REGISTER_CAPTURE" \
  --dry-run >"$TMP/register-stdout.txt" 2>"$TMP/register-stderr.txt"

for file in "$REGISTER_CAPTURE/dispatch.txt" "$REGISTER_CAPTURE/wrapper.log" "$REGISTER_CAPTURE/pane-visible-tool-call-args.json" "$TMP/register-stdout.txt" "$TMP/register-stderr.txt"; do
  if [[ ! -f "$file" ]]; then
    printf 'FAIL: missing register capture file: %s\n' "$file" >&2
    exit 1
  fi
  if grep -Fq "$FAKE_TOKEN" "$file"; then
    printf 'FAIL: synthetic token appeared in %s\n' "$file" >&2
    exit 1
  fi
done

if ! grep -Fq '[REDACTED]' "$REGISTER_CAPTURE/pane-visible-tool-call-args.json"; then
  printf 'FAIL: register pane-visible args did not include redacted token marker\n' >&2
  exit 1
fi

if ! "$WRAPPER" send_message \
  --project-key "/tmp/synthetic-agent-mail-project" \
  --sender-name "SyntheticAgent" \
  --to "SyntheticRecipient" \
  --subject "Synthetic direct literal rejection test" \
  --body "Synthetic body" \
  --sender-token-handle "$FAKE_TOKEN" \
  --dry-run >"$TMP/reject-stdout.txt" 2>"$TMP/reject-stderr.txt"; then
  if grep -Fq "$FAKE_TOKEN" "$TMP/reject-stdout.txt" "$TMP/reject-stderr.txt"; then
    printf 'FAIL: literal-token rejection echoed the synthetic token\n' >&2
    exit 1
  fi
  printf 'PASS: synthetic token absent from dispatch text, wrapper logs, and pane-visible args\n'
  exit 0
fi

  printf 'FAIL: wrapper accepted a literal token-shaped handle\n' >&2
exit 1
