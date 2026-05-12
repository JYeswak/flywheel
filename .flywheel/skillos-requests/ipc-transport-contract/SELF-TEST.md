# SELF-TEST

This skillos request includes an executable self-test:

```bash
bash .flywheel/skillos-requests/ipc-transport-contract/scripts/self_test.sh .flywheel/skillos-requests/ipc-transport-contract
```

Expected result:

```json
{"status":"pass","skill":"ipc-transport-contract","triggers":13,"hard_rules":12,"anti_patterns":7}
```

The test is intentionally structural. It checks that the draft has enough trigger phrases, the required contract sections, Jeff/flywheel evidence, a narrative anti-pattern table, and the envelope fields needed for delivery verification and durable audit rows.

Publication remains staged. This request does not mutate `~/.claude/skills`.
