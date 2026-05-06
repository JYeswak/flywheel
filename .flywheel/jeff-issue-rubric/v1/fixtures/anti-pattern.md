# URGENT: please merge this runtime_handoff patch

This is unacceptable and should be easy to fix. Please apply this patch and add
a migration that recreates the table exactly as follows. We can submit PR if
that is faster.

```sql
ALTER TABLE runtime_handoff ADD COLUMN working_dir TEXT NOT NULL DEFAULT '';
```

The token is sk-testtoken1234567890 and the local API key is ghp_deadbeef12345.

Thanks for the amazing work.
