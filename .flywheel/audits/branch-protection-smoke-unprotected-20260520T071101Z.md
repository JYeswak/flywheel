# Branch protection smoke verification

- Command: gh api repos/<repo>/branches/<branch>/protection
- Expected: Branch not protected for all 4 reverted repos
- Started: 2026-05-20T07:11:01Z

| Repo | Branch | Result |
|---|---|---|
| `JYeswak/flywheel` | `master` | PASS: Branch not protected |
| `JYeswak/zesttube` | `main` | PASS: Branch not protected |
| `JYeswak/mobile-eats` | `main` | PASS: Branch not protected |
| `JYeswak/ClutterFreeSpaces` | `main` | PASS: Branch not protected |

- pass=4 fail=0
- Finished: 2026-05-20T07:11:03Z
