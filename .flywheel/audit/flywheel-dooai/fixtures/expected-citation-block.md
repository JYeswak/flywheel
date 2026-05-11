## Corpus-aware citations (cross-collection-fanout)

### Prior Art (1)
- (prior art) Dicklesworthstone/beads_rust: src/db.rs:78: shape: prior art for stuck-state detection in beads-db

### Shape Precedent (2)
- (matches the pattern in) Dicklesworthstone/ntm: src/recover.rs:142: // pattern for caam_rotate retry; jeff convention: use exponential backoff
- (matches the pattern in) Dicklesworthstone/frankensqlite: src/wal.rs:312: convention: signal stuck via dedicated probe surface

### Anti Pattern (1)
- (anti-pattern in) Dicklesworthstone/ntm: src/recover.rs:205: // jeff explicitly rejected synchronous wait here; previously deadlocked

### Same Issue Already Filed (1)
- (already filed) Dicklesworthstone/ntm: issues/#114:0: already filed: queued chevron stuck after caam_rotate
