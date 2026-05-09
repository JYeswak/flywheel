# flywheel-mzvd0 Compliance Report

The dispatch created the `container-isolation/v1` profile for high-risk
prod-credential work and pinned it with a shell conformance test.

Primary proof:

```bash
bash tests/security-container-isolation.sh
```

Expected output:

```text
PASS security-container-isolation
```

The profile rejects privileged mode, host networking, Docker socket mounts,
`.env` injection surfaces, and non-allowlisted env. It passes the hardened
read-only-root fixture with an explicit `/workspace` mount. README now states
when prod-credential sandboxing is required and when synthetic fixture work is
outside the requirement.
