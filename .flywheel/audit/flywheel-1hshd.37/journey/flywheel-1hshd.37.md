# Journey: flywheel-1hshd.37

PARTIAL-BYPASS. Native has rich --info AND --examples envelopes (idempotency-replay-guard.info/v1 with statuses+output_schema; idempotency-replay-guard.examples/v1 with examples array). Scaffold yields both flags; owns --schema (native lacked) + verbs.

Discovery: bash =~ doesn't support {N,M} repetition. Initial `^[A-Za-z0-9._/#:-]{4,256}$` failed at runtime with "invalid repetition count(s)". Pivot to `(( len >= 4 && len <= 256 )) && [[ pattern_without_repetition ]]` works. 1st explicit application of this fix this session.

19/19 PASS, commit, close, callback.
