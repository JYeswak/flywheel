# Self-Test: mutation-safety-contract

Run from this directory:

```bash
bash scripts/self_test.sh .
```

Expected output:

```json
{"checks":12,"status":"pass"}
```

The self-test checks frontmatter, trigger saturation, hard-rule count, required
sections, anti-pattern table shape, and the mutation-safety terms that must be
present for skillos review.
