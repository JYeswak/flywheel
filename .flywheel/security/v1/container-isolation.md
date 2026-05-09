# Container Isolation Profile v1

This profile defines the required sandbox shape for agent work that touches
production credentials or credential-bearing runtime state. It is intentionally
stricter than normal fixture testing: the goal is to keep live credentials out
of the host namespace, the Docker control plane, and broad ambient env.

## Contract

```yaml
schema_version: container-isolation/v1
profile_name: prod-credential-high-risk
required_when:
  - production credentials are loaded from Infisical, 1Password, shell env, or a live .env file
  - admin tokens, service-role keys, Cloudflare tokens, billing keys, SSH keys, or Agent Mail bearer tokens are in scope
  - a worker must run untrusted code, package scripts, browser automation, provider clients, or repo-local tools while credentials are present
not_required_when:
  - tests use synthetic .env.test fixtures with CANARY_TEST_, FIXTURE_, SYNTHETIC_, or EXAMPLE_ values
  - evidence is redacted and contains no live secret material
  - offline docs, schema, or static scanner work does not load live credentials
required_controls:
  forbid_privileged: true
  forbid_host_network: true
  forbid_docker_socket: true
  forbid_env_file: true
  forbid_env_mounts:
    - .env
    - .env.*
  read_only_root: true
  no_new_privileges: true
  cap_drop: ALL
  network: none_or_explicit_allowlist
  workspace_mount: explicit
  workspace_target: /workspace
  credentials_mount: tmpfs_or_secret_store_only
  env_mode: allowlist
  env_allowlist:
    - HOME
    - PATH
    - TMPDIR
    - SSL_CERT_FILE
    - REQUESTS_CA_BUNDLE
    - GIT_CONFIG_NOSYSTEM
    - CI
doctor_signal:
  status: recommendation
  blanket_failure: false
  code: security_container_isolation_recommended
```

## Hardened Shape

Use this shape for high-risk credential work:

```bash
docker run --rm \
  --read-only \
  --security-opt=no-new-privileges \
  --cap-drop=ALL \
  --network=none \
  --tmpfs /tmp:rw,noexec,nosuid,nodev,size=64m \
  --mount type=bind,src="$PWD",dst=/workspace \
  -w /workspace \
  -e HOME=/tmp/home \
  -e PATH=/usr/local/bin:/usr/bin:/bin \
  -e TMPDIR=/tmp \
  image:tag command
```

Do not add `--privileged`, host networking, `/var/run/docker.sock`, `--env-file
.env`, or a bind mount for `.env` material. If a task needs one of those
surfaces, it is outside this profile and must be redesigned or explicitly
escalated with a probe ledger.

## Doctor Behavior

The doctor should recommend this profile when a task appears to touch live
credentials or production credential migration. It must not fail every repo or
every normal test run merely because the sandbox is absent. The expected signal
is advisory until a live credential path is actually in scope.
