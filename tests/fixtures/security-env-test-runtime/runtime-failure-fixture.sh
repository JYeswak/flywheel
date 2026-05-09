#!/usr/bin/env bash
set -euo pipefail

env_file="${1:?env file required}"

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    ""|\#*) continue ;;
  esac
  key="${line%%=*}"
  case "$key" in
    OPENAI_API_KEY|AWS_ACCESS_KEY_ID|PRIVATE_KEY|SESSION_JWT|DATABASE_URL|AGENT_MAIL_TOKEN|BEARER_TOKEN)
      printf 'runtime config error: %s=[REDACTED:runtime_secret]\n' "$key" >&2
      ;;
  esac
done <"$env_file"

exit 1
