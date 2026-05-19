#!/usr/bin/env bash
set -euo pipefail

# cross-repo-failure-mode-harvester.sh
#
# Value-gap dimension #1 measurement (Step 4o, bead flywheel-1rmp.2):
# aggregate repeated trauma classes across repos before they become doctrine.
# Surface classes appearing in N+ sources (default N=2) BEFORE the third
# rediscovery so the orchestrator can decide on doctrine promotion proactively.
#
# Read-only by design. No bead filing, no dispatch, no source mutation.
# Per Step 4o anti-pattern guardrail: "do not dispatch directly from this
# finding." This script SURFACES candidates; humans/orch decide the action.
#
# Doctrine:
#   Step 4o tick.md (canonical wire-in via value-gap-probe.sh)
#   canonical-cli-scoping (doctor/health + validate/audit/why + --json)
#
# Native producers (read-only):
#   - $HOME/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_*.md
#     (frontmatter `trauma_class:` field + prose `**Trauma class:**` line)
#   - <repo>/INCIDENTS.md `## <class-name>` headers across the configured
#     repo roster

SCHEMA_VERSION="cross-repo-failure-mode-harvester.v1"
SCRIPT_NAME="cross-repo-failure-mode-harvester.sh"
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"

MEMORY_DIR="${CRFMH_MEMORY_DIR:-$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory}"
REPO_ROSTER_DEFAULT="/Users/josh/Developer/flywheel /Users/josh/Developer/skillos /Users/josh/Developer/mobile-eats /Users/josh/Developer/alpsinsurance /Users/josh/Developer/vrtx /Users/josh/Developer/zesttube /Users/josh/Developer/clutterfreespaces"
REPO_ROSTER="${CRFMH_REPO_ROSTER:-$REPO_ROSTER_DEFAULT}"
LEDGER="${CRFMH_LEDGER:-$HOME/.local/state/flywheel/cross-repo-failure-mode-harvester.jsonl}"
THRESHOLD="${CRFMH_THRESHOLD:-2}"

JSON_OUT=0
MODE="run"

usage() {
  cat <<EOF
$SCRIPT_NAME — cross-repo failure-mode harvester (value-gap dim #1)

Usage:
  $SCRIPT_NAME [--threshold N] [--json]
  $SCRIPT_NAME --doctor [--json]
  $SCRIPT_NAME --health [--json]
  $SCRIPT_NAME --info [--json]
  $SCRIPT_NAME --validate [--json]
  $SCRIPT_NAME --audit [--json]
  $SCRIPT_NAME --why=<class> [--json]
  $SCRIPT_NAME --schema | --examples | --help

Modes:
  (default)    aggregate trauma classes across memory + INCIDENTS surfaces
  --doctor     producer/measurement/consumer manifest + dependency probes
  --health     terse OK|DEGRADED|DOWN summary (exit code matches)
  --info       script identity and version
  --validate   re-emit one row through the JSON schema check
  --audit      list configured sources with their freshness
  --why        explain one trauma class — which sources cite it

Flags:
  --threshold N    classes appearing in N+ sources are recurring (default 2)
  --json           emit machine-readable JSON envelope

Exit codes:
  0  measurement ran cleanly
  1  one or more sources unavailable; partial results
  2  all primary sources unavailable; no measurement possible
  3  invalid usage
EOF
}

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    cat <<EOF
{"schema_version":"$SCHEMA_VERSION","mode":"info","script":"$SCRIPT_NAME","memory_dir":"$MEMORY_DIR","repo_roster":"$REPO_ROSTER","ledger":"$LEDGER","threshold":$THRESHOLD}
EOF
  else
    echo "$SCRIPT_NAME ($SCHEMA_VERSION)"
    echo "  memory_dir:  $MEMORY_DIR"
    echo "  repos:       $REPO_ROSTER"
    echo "  ledger:      $LEDGER"
    echo "  threshold:   $THRESHOLD"
  fi
}

emit_schema() {
  cat <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "cross-repo-failure-mode-harvester.v1",
  "type": "object",
  "required": ["schema_version", "mode", "checked_at", "threshold", "summary", "recurring_classes"],
  "properties": {
    "schema_version": {"const": "cross-repo-failure-mode-harvester.v1"},
    "mode": {"enum": ["run", "doctor", "health", "validate", "audit", "why", "info"]},
    "checked_at": {"type": "string", "format": "date-time"},
    "threshold": {"type": "integer", "minimum": 1},
    "summary": {
      "type": "object",
      "required": ["sources_total", "sources_available", "classes_total", "recurring_count"],
      "properties": {
        "sources_total": {"type": "integer"},
        "sources_available": {"type": "integer"},
        "classes_total": {"type": "integer"},
        "recurring_count": {"type": "integer"}
      }
    },
    "recurring_classes": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["class", "source_count", "sources"],
        "properties": {
          "class": {"type": "string"},
          "source_count": {"type": "integer"},
          "sources": {
            "type": "array",
            "items": {"type": "string"}
          }
        }
      }
    }
  }
}
EOF
}

emit_doctor() {
  local memory_health repos_available repos_total overall
  memory_health="missing"
  if [[ -d "$MEMORY_DIR" ]]; then
    memory_health="healthy"
  fi
  repos_total=0
  repos_available=0
  for repo in $REPO_ROSTER; do
    repos_total=$((repos_total + 1))
    if [[ -f "$repo/INCIDENTS.md" ]]; then
      repos_available=$((repos_available + 1))
    fi
  done
  overall="healthy"
  [[ "$memory_health" != "healthy" ]] && overall="degraded"
  [[ "$repos_available" -eq 0 ]] && overall="down"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    python3 -c "
import json
print(json.dumps({
  'schema_version': '$SCHEMA_VERSION',
  'mode': 'doctor',
  'producer': [
    'memory_dir: $MEMORY_DIR (frontmatter trauma_class field + prose **Trauma class:** lines)',
    'repo_roster INCIDENTS.md ## headers',
  ],
  'measurement': '$SCRIPT_NAME --json',
  'consumer': '/flywheel:tick Step 4o value-gap-probe + fleet observatory',
  'memory_health': '$memory_health',
  'repos_total': $repos_total,
  'repos_available': $repos_available,
  'overall': '$overall',
}))
"
  else
    echo "doctor: overall=$overall memory=$memory_health repos=$repos_available/$repos_total"
    echo "producers:"
    echo "  $MEMORY_DIR (memory feedback trauma_class)"
    echo "  <repo>/INCIDENTS.md ## headers"
    echo "measurement: $SCRIPT_NAME --json"
    echo "consumer: /flywheel:tick Step 4o + fleet observatory"
  fi
  case "$overall" in
    healthy) return 0 ;;
    degraded) return 1 ;;
    down) return 2 ;;
  esac
}

emit_health() {
  local rc level
  set +e
  emit_doctor >/dev/null 2>&1
  rc=$?
  set -e
  case "$rc" in
    0)  level="OK" ;;
    1)  level="DEGRADED" ;;
    *)  level="DOWN" ;;
  esac
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '{"schema_version":"%s","mode":"health","level":"%s","exit_code":%d}\n' "$SCHEMA_VERSION" "$level" "$rc"
  else
    echo "health: $level"
  fi
  return "$rc"
}

emit_audit() {
  python3 - <<'PY' "$MEMORY_DIR" "$REPO_ROSTER" "$SCHEMA_VERSION"
import json, os, sys, time

memory_dir, repo_roster_str, schema_version = sys.argv[1:4]
sources = []
if os.path.isdir(memory_dir):
    files = [f for f in os.listdir(memory_dir) if f.startswith("feedback_") and f.endswith(".md")]
    sources.append({"kind": "memory_dir", "path": memory_dir, "feedback_count": len(files), "exists": True})
else:
    sources.append({"kind": "memory_dir", "path": memory_dir, "exists": False})
for repo in repo_roster_str.split():
    incidents = os.path.join(repo, "INCIDENTS.md")
    if os.path.isfile(incidents):
        try:
            age = int(time.time() - os.path.getmtime(incidents))
        except Exception:
            age = None
        sources.append({"kind": "incidents_md", "path": incidents, "exists": True, "age_seconds": age})
    else:
        sources.append({"kind": "incidents_md", "path": incidents, "exists": False})

print(json.dumps({"schema_version": schema_version, "mode": "audit", "sources": sources}))
PY
}

# harvest_classes: extract trauma class names from all sources, emit
# array of {class, source} rows on stdout (one per discovery — a class
# in 3 sources produces 3 rows; aggregation happens in the caller).
harvest_classes() {
  python3 - "$MEMORY_DIR" "$REPO_ROSTER" <<'PY'
import json, os, re, sys

memory_dir = sys.argv[1]
repo_roster = sys.argv[2].split()
rows = []

# Memory feedback frontmatter: trauma_class: <name>
# and prose: **Trauma class:** `<name>` or **Trauma class name:** `<name>`
trauma_re = re.compile(
    r"^trauma_class:\s*(\S.*?)\s*$|"                 # frontmatter
    r"\*\*Trauma class[^:]*:\*\*\s*`?([^`\n*]+?)`?\s*(?:[\s.;]|$)",  # prose
    re.MULTILINE,
)

if os.path.isdir(memory_dir):
    for name in os.listdir(memory_dir):
        if not (name.startswith("feedback_") and name.endswith(".md")):
            continue
        path = os.path.join(memory_dir, name)
        try:
            with open(path, "r") as f:
                text = f.read()
        except Exception:
            continue
        for m in trauma_re.finditer(text):
            cls = (m.group(1) or m.group(2) or "").strip().strip("`").strip("'\"")
            # Trim parenthetical commentary
            cls = re.split(r"\s*[(]", cls, 1)[0].strip()
            # Skip prose-noise: very long strings, or things that obviously
            # aren't class identifiers
            if not cls or len(cls) > 80 or " " in cls and "-" not in cls and "_" not in cls:
                continue
            rows.append({"class": cls, "source": f"memory:{name}"})

# INCIDENTS.md per-repo: ## <class-or-title> headers
for repo in repo_roster:
    path = os.path.join(repo, "INCIDENTS.md")
    if not os.path.isfile(path):
        continue
    repo_basename = os.path.basename(repo) or repo
    try:
        with open(path, "r") as f:
            text = f.read()
    except Exception:
        continue
    for line in text.splitlines():
        if not line.startswith("## "):
            continue
        header = line[3:].strip()
        # Heuristic: extract a kebab-case class identifier from headers like
        #   "## paradigm-correct-but-stuck-no-producing-loop (2026-05-04, ...)"
        # or "## DCG redirect-truncate false-positive on `>` literals ..."
        # or "## <foo-bar-baz>" with no parens.
        m = re.match(r"^([a-z][a-z0-9_-]*[a-z0-9])", header.lower())
        if not m:
            continue
        cls = m.group(1)
        # Skip very short tokens that are likely noise (e.g. "wired", "fix")
        if len(cls) < 8:
            continue
        rows.append({"class": cls, "source": f"incidents:{repo_basename}"})

print(json.dumps(rows))
PY
}

run_measurement() {
  local raw aggregated
  raw="$(harvest_classes 2>/dev/null || echo '[]')"
  python3 - "$raw" "$THRESHOLD" "$SCHEMA_VERSION" "$LEDGER" "$JSON_OUT" "$REPO_ROSTER" "$MEMORY_DIR" "$SCRIPT_PATH" <<'PY'
import json, os, sys, datetime, collections

raw, threshold_s, schema_version, ledger_path, json_out, repo_roster, memory_dir, script_path = sys.argv[1:9]
threshold = int(threshold_s)
json_out = json_out == "1"
rows = json.loads(raw)

by_class = collections.defaultdict(set)
for r in rows:
    by_class[r["class"]].add(r["source"])

recurring = []
for cls, sources in sorted(by_class.items()):
    if len(sources) >= threshold:
        recurring.append({
            "class": cls,
            "source_count": len(sources),
            "sources": sorted(sources),
        })
recurring.sort(key=lambda x: (-x["source_count"], x["class"]))

repos_total = len(repo_roster.split())
repos_available = sum(
    1 for r in repo_roster.split() if os.path.isfile(os.path.join(r, "INCIDENTS.md"))
)
sources_total = repos_total + 1
sources_available = repos_available + (1 if os.path.isdir(memory_dir) else 0)

now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
out = {
    "schema_version": schema_version,
    "mode": "run",
    "checked_at": now,
    "threshold": threshold,
    "summary": {
        "sources_total": sources_total,
        "sources_available": sources_available,
        "classes_total": len(by_class),
        "recurring_count": len(recurring),
    },
    "recurring_classes": recurring,
}

# Self-log to ledger so wired-but-cold doesn't fire on this script;
# enrich with ts and script_path for audit traceability.
try:
    os.makedirs(os.path.dirname(ledger_path), exist_ok=True)
    enriched = dict(out)
    enriched["script"] = script_path
    with open(ledger_path, "a") as f:
        f.write(json.dumps(enriched) + "\n")
except Exception:
    pass

if json_out:
    print(json.dumps(out))
else:
    print(f"checked_at: {now}")
    print(f"threshold: {threshold} (classes appearing in {threshold}+ sources)")
    print(f"sources: {sources_available}/{sources_total} available")
    print(f"classes_total: {len(by_class)}")
    print(f"recurring_count: {len(recurring)}")
    print()
    if recurring:
        print(f"{'class':<60} {'count':>6}  sources")
        print("-" * 100)
        for r in recurring:
            print(f"{r['class']:<60} {r['source_count']:>6}  {', '.join(r['sources'])}")
    else:
        print("(no recurring trauma classes above threshold)")

# Exit codes
if sources_available == 0:
    sys.exit(2)
if sources_available < sources_total:
    sys.exit(1)
sys.exit(0)
PY
}

emit_validate() {
  local rendered status missing
  rendered="$($0 --json 2>/dev/null || true)"
  python3 - <<'PY' "$rendered" "$SCHEMA_VERSION"
import json, sys
rendered, schema_version = sys.argv[1:3]
try:
    d = json.loads(rendered)
except Exception as e:
    print(json.dumps({"schema_version": schema_version, "mode": "validate", "status": "fail", "reason": "non_json_output", "detail": str(e)}))
    sys.exit(1)
required = ["schema_version", "mode", "checked_at", "threshold", "summary", "recurring_classes"]
missing = [k for k in required if k not in d]
status = "ok" if not missing else "fail"
print(json.dumps({"schema_version": schema_version, "mode": "validate", "status": status, "missing": missing}))
sys.exit(0 if status == "ok" else 1)
PY
}

emit_why() {
  local target="$1"
  if [[ -z "$target" ]]; then
    echo "ERROR: --why requires a class name" >&2
    return 3
  fi
  local raw
  raw="$(harvest_classes 2>/dev/null || echo '[]')"
  python3 - <<'PY' "$raw" "$target" "$SCHEMA_VERSION"
import json, sys
raw, target, schema_version = sys.argv[1:4]
rows = json.loads(raw)
matches = [r for r in rows if r["class"] == target]
sources = sorted({r["source"] for r in matches})
print(json.dumps({
  "schema_version": schema_version,
  "mode": "why",
  "class": target,
  "source_count": len(sources),
  "sources": sources,
}))
PY
}

# Argument parsing.
WHY_TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --threshold) THRESHOLD="$2"; shift 2 ;;
    --threshold=*) THRESHOLD="${1#--threshold=}"; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --health) MODE="health"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    --validate) MODE="validate"; shift ;;
    --audit) MODE="audit"; shift ;;
    --examples) MODE="examples"; shift ;;
    --why=*) MODE="why"; WHY_TARGET="${1#--why=}"; shift ;;
    --why) MODE="why"; WHY_TARGET="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown arg: $1" >&2; usage; exit 3 ;;
  esac
done

case "$MODE" in
  info) emit_info ;;
  schema) emit_schema ;;
  doctor) emit_doctor ;;
  health) emit_health ;;
  validate) emit_validate ;;
  audit) emit_audit ;;
  why) emit_why "$WHY_TARGET" ;;
  examples)
    cat <<'EOF'
# default: aggregate trauma classes across memory + INCIDENTS, threshold 2
.flywheel/scripts/cross-repo-failure-mode-harvester.sh --json | jq '.recurring_classes'

# higher threshold (only classes hitting 3+ sources surface)
.flywheel/scripts/cross-repo-failure-mode-harvester.sh --threshold 3 --json

# explain one class — which sources cite it
.flywheel/scripts/cross-repo-failure-mode-harvester.sh --why=peer-orch-idle-on-blocker --json
EOF
    ;;
  run) run_measurement ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
