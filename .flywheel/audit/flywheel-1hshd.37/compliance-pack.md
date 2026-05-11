# Compliance Pack: flywheel-1hshd.37 — score 960/1000

PARTIAL-BYPASS. 19/19 PASS. Lint clean. 17 smoke captures.

Skill discoveries:
- pattern-recurrence: native-flags-to-enum N=8 (status + input-mode); META-RULE promoted at N=3
- pattern-emerged: bash-regex-{N,M}-fix (split length-range from char-class because bash =~ doesn't support {N,M} repetition; pivot to (( len >= N && len <= M )) && [[ char-class-only ]])
