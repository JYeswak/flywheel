# Branch protection revert receipt

- Reason: n2228 misapply 2026-05-20T02:46Z + Joshua data-decided directive
- Command: bash ~/Developer/flywheel/.flywheel/scripts/branch-protection-revert.sh
- Started: 2026-05-20T07:09:42Z

```text
=== revert branch protection (idempotent) ===
  JYeswak/flywheel                         :master ... ✓ removed
  JYeswak/zesttube                         :main ... ✓ removed
  JYeswak/mobile-eats                      :main ... ✓ removed
  JYeswak/ClutterFreeSpaces                :main ... ✓ removed

=== verify all 4 unprotected ===
  JYeswak/flywheel                         :master ✓ unprotected
  JYeswak/zesttube                         :main ✓ unprotected
  JYeswak/mobile-eats                      :main ✓ unprotected
  JYeswak/ClutterFreeSpaces                :main ✓ unprotected
zsh:11: read-only variable: status
```

- Wrapper note: receipt footer write hit zsh read-only `status`; revert script output above completed and verified all 4 repos unprotected.
- Wrapper exit status: 0 (script completed before wrapper footer failure)
- Finished: 2026-05-20T07:10:13Z
