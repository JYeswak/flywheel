Both sub-asks are real, and the cost framing is right.

Sub-ask (1) — strict-JSON-on-stdout — is the one we need first. The blocker today is exactly what you described: stdout has INFO log lines mixed with the JSON payload, so `ntm review-queue <session> --format json | jq` fails on the first non-JSON line. Wrappers can't replace bespoke pane-classification with the native call until that's clean. Routing INFO to stderr (or silencing under robot-mode detection) unblocks wrapper retirement on its own — sub-ask (1) shipping standalone is the higher-ROI move.

Sub-ask (2) — L85-compatible idle-state schema — is feature work to consume after (1) ships. Coordinating field names across the wrapper-parity epic is exactly right; `task_id` from #127/#128/#129 and `capture_provenance` matching #128's `prompt_packet` provenance both make sense. The L85 envelope wanting the same `(session, pane, task-id)` correlation triple means a fleet-wide doctor view can join `review-queue` rows against `assign` rows trivially.

One small ask if it fits naturally: when sub-ask (1) ships, the strict-JSON contract should expose a `schema_version` field on the envelope (e.g. `"ntm.review-queue.v1"`) so wrappers can gate parsing on it. Cleaner than a fragile shape probe.

Tracking the split as you proposed: (1) bug fix landing on its own, (2) feature work in the wrapper-parity epic with #126–#129. Holding for either.
