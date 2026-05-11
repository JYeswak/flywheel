# ntm queued chevron stuck after caam_rotate fail

When the caam_rotate sequence fails, the queued chevron in pane 3 stays
stuck even after the auto-recover daemon fires.

Repro: ...

## Expected behavior

ntm should detect the stuck state and surface it via doctor.
