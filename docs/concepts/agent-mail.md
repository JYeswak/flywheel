# Agent Mail

Agent Mail is the coordination layer for agents that share a repo. Flywheel uses
it for messages, acknowledgement, and file reservations.

The public release does not ship private Agent Mail archives. It documents the
contract:

- reserve files before touching shared state;
- use targeted messages instead of broad broadcasts;
- acknowledge messages that request acknowledgement;
- release reservations after the work is complete.

Agent Mail is optional for reduced mode. When it is not present, Flywheel should
still run the local first loop and say that shared-agent coordination is not
active.
