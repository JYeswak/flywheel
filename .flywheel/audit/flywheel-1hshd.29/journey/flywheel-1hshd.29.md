# Journey: flywheel-1hshd.29

NO-BYPASS variant. flywheel-adopt has rich native flag set (--reconcile, --first-run-audit, --apply-fs-rag, --idempotency-key, --apply, --start-loop, --repo) but no canonical verbs that would collide with scaffold.

Recipe-parity scaffold + 18-TODO fillin. Doctor probes flywheel-install templates (load-bearing for adoption installer) and fs-rag substrate (load-bearing for --apply-fs-rag). Validate cross-sources native flag contracts (adoption-mode enum collapses --reconcile/--first-run-audit/--apply-fs-rag).

19/19 PASS, lint clean, commit + close + callback.
