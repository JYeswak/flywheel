# Extended Callback Envelope And Tiered Close Bar

Source beads: `flywheel-9w12h`, `flywheel-9sg6i`
Status: active

## Why This Exists

The 2026-05-20 worker-discipline traumas share one root: callback rows did not
carry enough evidence to distinguish real completion from local artifact writes,
push blocks, stale worktrees, lingering branches, or runtime work with no
receipt.

The mobile-eats joint deep-dive named the extended callback envelope as a P1
need: `worktree_removed`, `branch_local_deleted`, `stash_dropped`, and
`main_ff_status` must become explicit callback evidence rather than prose.

CFS:1 supplied the paired semantic pattern in the 2026-05-20T04:00Z iOS-app
mission lock: substrate-class work closes on code-path evidence; runtime-class
work closes only with a concrete runtime receipt.

## Close Classes

`substrate_class` means the bead changes source, doctrine, scripts, schemas, or
other inspectable code-path substrate. Close requires:

- a commit field (`commit_sha` or `commit`);
- `tests=PASS`.

`runtime_class` means the bead claims a live runtime result. Close requires:

- `runtime_receipt_path`;
- populated `runtime_artifacts`;
- a receipt file that exists before the worker sends the callback.

Runtime artifacts must name real runtime facts for that bead. Examples:
TestFlight build number, device model, iOS version, timestamp, API endpoint,
HTTP status, latency, payload hash, or equivalent domain-specific evidence.

## Post-Callback Cleanup Fields

The v3 callback envelope records:

- `post_callback_worktree_removed`
- `post_callback_branch_local_deleted`
- `post_callback_stash_dropped`
- `post_callback_main_ff_status`
- `post_callback_auto_push_status`

The worker pre-callback gate treats explicit `false` cleanup fields as
unfinished work. `post_callback_auto_push_status=blocked` blocks callback send;
`ok` and `swept` are acceptable.

## Cross-Links

- `flywheel-ozfou`: false-idle-after-silent-artifact-write trauma class this
  discipline prevents.
- `flywheel-ge03h`: repo hygiene tick, because stale worktrees, stashes, and
  branches become measured cleanup evidence.
- `flywheel-8ont6`: runtime/doctrine separation, because runtime-class closes
  require receipts while doctrine substrate remains code-path evidence.
- `.flywheel/doctrine/dispatch-log-schema-v3.md`: field-level schema contract.
