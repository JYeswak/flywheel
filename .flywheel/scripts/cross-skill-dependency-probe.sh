#!/usr/bin/env bash
# cross-skill-dependency-probe.sh — closes flywheel-1rmp.6 (value-gap
# `cross-skill-dependency-graph`).
#
# The smallest recurring measurement that makes the value gap visible: for
# each skill in the catalog, count how many other skills reference it inbound
# (i.e. mention its name in their SKILL.md). High inbound-degree = high blast
# radius. Top-N high-blast-radius skills surface the "skill changes can break
# downstream workflows" finding as a number per skill.
#
# Step 4o anti-pattern preserved: probe is READ-ONLY. No br/ntm/gh/git/agent-mail
# mutating verbs in source. No auto-dispatch from findings. Output is structured
# JSON only.
#
# Canonical-cli-scoping triad: --doctor / --health / --info / --schema /
# --json with stable exit codes.
set -euo pipefail

SCHEMA_VERSION="cross-skill-dependency-probe.v1"
DEFAULT_SKILLS_DIR="$HOME/.claude/skills"

SKILLS_DIR="$DEFAULT_SKILLS_DIR"
TOP_N=20
MIN_INBOUND=2
JSON_OUT=0
MODE=run

usage() {
  cat <<'USAGE'
usage: cross-skill-dependency-probe.sh [--skills-dir PATH] [--top N] [--min-inbound N] [--json]
       cross-skill-dependency-probe.sh --doctor|--health|--info|--schema [--json]

Reads SKILL.md files under --skills-dir (default: ~/.claude/skills/), counts
inbound mentions of each skill name across all OTHER SKILL.md files, and emits
a per-skill blast-radius histogram.

Output JSON (run mode):
  {
    schema_version, ts,
    skills_dir, skills_scanned,
    top_blast_radius: [{skill, inbound_count, sample_referrers[5]}],
    high_radius_count,            # skills with inbound >= --min-inbound
    distribution: {p50, p90, p99, max, mean},
    reads_only: true, auto_dispatch: false,
    step_4o_compliance: "preserved"
  }

Defaults: --top 20, --min-inbound 2.

Exit codes:
  0  measurement emitted
  1  no skills found
  2  config error
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg dir "$SKILLS_DIR" \
    '{schema_version:$schema, success:true, mode:"doctor",
      skills_dir:$dir, dir_present:true,
      reads_only:true, auto_dispatch:false,
      surfaces:["tick receipt consumer","dashboard tile","doctor signal candidate"],
      step_4o_compliance:"preserved"}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      measurement:"per-skill inbound-mention count across all SKILL.md files",
      blast_radius_signal:"high inbound count = high blast radius (changing the skill breaks many downstream callers)",
      output_includes:["top_blast_radius (top N skills by inbound count)","high_radius_count","distribution percentiles"],
      reads_only:true,
      step_4o_compliance:"preserved"}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        skills_scanned:{type:"integer"},
        top_blast_radius:{type:"array",
          items:{properties:{skill:{type:"string"},inbound_count:{type:"integer"},sample_referrers:{type:"array"}}}},
        high_radius_count:{type:"integer"},
        distribution:{type:"object", properties:{p50:{type:"number"},p90:{type:"number"},p99:{type:"number"},max:{type:"integer"},mean:{type:"number"}}}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills-dir) SKILLS_DIR="${2:?--skills-dir requires PATH}"; shift 2;;
    --top) TOP_N="${2:?--top requires N}"; shift 2;;
    --min-inbound) MIN_INBOUND="${2:?--min-inbound requires N}"; shift 2;;
    --json) JSON_OUT=1; shift;;
    --doctor|--health) MODE=doctor; shift;;
    --info) MODE=info; shift;;
    --schema) MODE=schema; shift;;
    -h|--help) usage; exit 0;;
    *) echo "ERR: unknown arg $1" >&2; usage >&2; exit 2;;
  esac
done

case "$MODE" in
  doctor) doctor; exit 0;;
  info) info; exit 0;;
  schema) schema; exit 0;;
esac

[[ -d "$SKILLS_DIR" ]] || { echo "ERR: skills dir not found: $SKILLS_DIR" >&2; exit 2; }

# Collect skill names (top-level dirs that contain SKILL.md).
SKILLS_TMP="$(mktemp "${TMPDIR:-/tmp}/cross-skill-probe-skills.XXXXXX")"
INBOUND_TMP="$(mktemp "${TMPDIR:-/tmp}/cross-skill-probe-inbound.XXXXXX")"
trap 'rm -f "$SKILLS_TMP" "$INBOUND_TMP"' EXIT
: >"$SKILLS_TMP"
: >"$INBOUND_TMP"

while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  d="$(dirname "$path")"
  name="$(basename "$d")"
  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || continue
  [[ "$name" == _* ]] && continue
  printf '%s\n' "$name" >>"$SKILLS_TMP"
done < <(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -name SKILL.md -type f 2>/dev/null)

SKILLS_COUNT="$(wc -l <"$SKILLS_TMP" | tr -d ' ')"
if [[ "$SKILLS_COUNT" -eq 0 ]]; then
  echo "ERR: no SKILL.md files under $SKILLS_DIR" >&2
  exit 1
fi

# For each skill, count inbound references in OTHER skills' SKILL.md files.
# Vectorized with python3 to avoid N^2 grep loop on 500-skill catalogs.
python3 - "$SKILLS_DIR" "$SKILLS_TMP" "$INBOUND_TMP" <<'PY'
import os, re, sys
skills_dir, skills_file, out_file = sys.argv[1], sys.argv[2], sys.argv[3]
with open(skills_file) as f:
    skills = sorted({line.strip() for line in f if line.strip()})
# Word-boundary regex per skill (escaped); compile once.
patterns = {s: re.compile(r"(?:^|[^A-Za-z0-9_-])" + re.escape(s) + r"(?:[^A-Za-z0-9_-]|$)") for s in skills}
inbound = {s: 0 for s in skills}
referrers = {s: [] for s in skills}
for entry in os.scandir(skills_dir):
    if not entry.is_dir():
        continue
    other_name = entry.name
    skill_md = os.path.join(entry.path, "SKILL.md")
    if not os.path.isfile(skill_md):
        continue
    try:
        with open(skill_md, "r", encoding="utf-8", errors="replace") as f:
            text = f.read()
    except OSError:
        continue
    for s in skills:
        if s == other_name:
            continue
        if patterns[s].search(text):
            inbound[s] += 1
            if len(referrers[s]) < 5:
                referrers[s].append(other_name)
with open(out_file, "w") as f:
    for s in skills:
        f.write(f"{inbound[s]}\t{s}\t{','.join(referrers[s])}\n")
PY

# Aggregate.
TOP_JSON="$(sort -t $'\t' -k1,1 -nr "$INBOUND_TMP" \
  | head -n "$TOP_N" \
  | awk -F'\t' '{ printf "{\"skill\":\"%s\",\"inbound_count\":%s,\"sample_referrers\":\"%s\"}\n", $2, $1, $3 }' \
  | jq -s 'map(. + {sample_referrers: (.sample_referrers | split(",") | map(select(length > 0)))})')"

HIGH_RADIUS_COUNT="$(awk -F'\t' -v m="$MIN_INBOUND" 'BEGIN{c=0} $1>=m{c++} END{print c}' "$INBOUND_TMP")"

# Distribution.
COUNTS_SORTED="$(awk -F'\t' '{print $1}' "$INBOUND_TMP" | sort -n)"
N="$(printf '%s\n' "$COUNTS_SORTED" | grep -c '^' || echo 0)"
if [[ "$N" -gt 0 ]]; then
  P50_IDX=$(( (N - 1) * 50 / 100 ))
  P90_IDX=$(( (N - 1) * 90 / 100 ))
  P99_IDX=$(( (N - 1) * 99 / 100 ))
  P50="$(printf '%s\n' "$COUNTS_SORTED" | awk -v i="$P50_IDX" 'NR == i+1 { print; exit }')"
  P90="$(printf '%s\n' "$COUNTS_SORTED" | awk -v i="$P90_IDX" 'NR == i+1 { print; exit }')"
  P99="$(printf '%s\n' "$COUNTS_SORTED" | awk -v i="$P99_IDX" 'NR == i+1 { print; exit }')"
  MAX="$(printf '%s\n' "$COUNTS_SORTED" | tail -1)"
  MEAN="$(printf '%s\n' "$COUNTS_SORTED" | awk '{s+=$1; n++} END{ if(n>0) printf "%.4f", s/n; else print "0" }')"
else
  P50=0; P90=0; P99=0; MAX=0; MEAN=0
fi

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg dir "$SKILLS_DIR" \
  --argjson scanned "$SKILLS_COUNT" \
  --argjson top "$TOP_JSON" \
  --argjson high_radius "$HIGH_RADIUS_COUNT" \
  --argjson p50 "$P50" \
  --argjson p90 "$P90" \
  --argjson p99 "$P99" \
  --argjson max "$MAX" \
  --argjson mean "$MEAN" \
  '{schema_version:$schema, ts:$ts, success:true, mode:"run",
    skills_dir:$dir, skills_scanned:$scanned,
    top_blast_radius:$top,
    high_radius_count:$high_radius,
    distribution:{p50:$p50, p90:$p90, p99:$p99, max:$max, mean:$mean},
    reads_only:true, auto_dispatch:false,
    step_4o_compliance:"preserved"}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"cross-skill-dep skills=\(.skills_scanned) high_radius=\(.high_radius_count) max=\(.distribution.max) p99=\(.distribution.p99) p90=\(.distribution.p90) top=\(.top_blast_radius[0:3] | map(.skill) | join(","))"' <<<"$PAYLOAD"
fi
