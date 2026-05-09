#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/.flywheel/security/v1/container-isolation.md"
README="$ROOT/README.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  grep -Eq -- "$pattern" "$file" || fail "$file missing pattern: $pattern"
}

rejects_command() {
  local name="$1"
  local command="$2"
  local reason
  reason="$(isolation_reason "$command")"
  [[ "$reason" == "$name" ]] || fail "expected $name rejection, got ${reason:-pass}"
}

passes_command() {
  local name="$1"
  local command="$2"
  local reason
  reason="$(isolation_reason "$command")"
  [[ -z "$reason" ]] || fail "expected $name pass, got $reason"
}

isolation_reason() {
  local command="$1"

  case "$command" in
    *"--privileged"* )
      printf 'privileged'
      return
      ;;
    *"--network=host"* | *"--net=host"* | *"--network host"* | *"--net host"* )
      printf 'host_network'
      return
      ;;
    *"/var/run/docker.sock"* )
      printf 'docker_socket'
      return
      ;;
    *"--env-file .env"* | *"--env-file=.env"* | *"src=.env"* | *"source=.env"* | *"dst=/workspace/.env"* | *"target=/workspace/.env"* )
      printf 'env_mount'
      return
      ;;
  esac

  if [[ "$command" =~ (^|[[:space:]])-e[[:space:]]+([A-Za-z_][A-Za-z0-9_]*) ]]; then
    local env_name="${BASH_REMATCH[2]}"
    case "$env_name" in
      HOME|PATH|TMPDIR|SSL_CERT_FILE|REQUESTS_CA_BUNDLE|GIT_CONFIG_NOSYSTEM|CI) ;;
      *)
        printf 'env_not_allowlisted'
        return
        ;;
    esac
  fi

  [[ "$command" == *"--read-only"* ]] || { printf 'missing_read_only_root'; return; }
  [[ "$command" == *"--security-opt=no-new-privileges"* ]] || { printf 'missing_no_new_privileges'; return; }
  [[ "$command" == *"--cap-drop=ALL"* ]] || { printf 'missing_cap_drop_all'; return; }
  [[ "$command" == *"--mount type=bind"* && "$command" == *"dst=/workspace"* ]] || { printf 'missing_workspace_mount'; return; }
}

[[ -f "$PROFILE" ]] || fail "missing $PROFILE"

assert_contains "$PROFILE" '^schema_version: container-isolation/v1$'
assert_contains "$PROFILE" '^  forbid_privileged: true$'
assert_contains "$PROFILE" '^  forbid_host_network: true$'
assert_contains "$PROFILE" '^  forbid_docker_socket: true$'
assert_contains "$PROFILE" '^  forbid_env_file: true$'
assert_contains "$PROFILE" '^  read_only_root: true$'
assert_contains "$PROFILE" '^  env_mode: allowlist$'
assert_contains "$PROFILE" '^  status: recommendation$'
assert_contains "$PROFILE" '^  blanket_failure: false$'

rejects_command privileged 'docker run --rm --privileged image:tag'
rejects_command host_network 'docker run --rm --network=host image:tag'
rejects_command docker_socket 'docker run --rm --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock image:tag'
rejects_command env_mount 'docker run --rm --env-file .env image:tag'
rejects_command env_mount 'docker run --rm --mount type=bind,src=.env,dst=/workspace/.env image:tag'
rejects_command env_not_allowlisted 'docker run --rm --read-only --security-opt=no-new-privileges --cap-drop=ALL --network=none --mount type=bind,src=/tmp/work,dst=/workspace -e AWS_ACCESS_KEY_ID image:tag'

passes_command env_allowlist 'docker run --rm --read-only --security-opt=no-new-privileges --cap-drop=ALL --network=none --mount type=bind,src=/tmp/work,dst=/workspace -e HOME image:tag'
passes_command hardened_fixture 'docker run --rm --read-only --security-opt=no-new-privileges --cap-drop=ALL --network=none --tmpfs /tmp:rw,noexec,nosuid,nodev,size=64m --mount type=bind,src=/tmp/work,dst=/workspace -w /workspace -e HOME image:tag'

assert_contains "$README" 'container-isolation\.md'
assert_contains "$README" 'production credentials|prod credentials'

printf 'PASS security-container-isolation\n'
