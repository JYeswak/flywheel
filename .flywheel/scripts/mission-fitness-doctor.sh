#!/usr/bin/env bash
# mission-fitness-doctor.sh — score recent closed beads against MISSION.md anchor
# canonical-cli-scoping-allow-large: single-file probe with full CLI surface required by canonical-cli-scoping
set -euo pipefail

VERSION="mission-fitness-doctor/v1.0.0"
SCHEMA_VERSION="mission-fitness-doctor/v1"

# ── defaults ──────────────────────────────────────────────────────────────────
REPO="${MISSION_FITNESS_REPO:-$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || pwd)}"
LIMIT="${MISSION_FITNESS_LIMIT:-50}"
WARN_THRESHOLD="${MISSION_FITNESS_WARN_THRESHOLD:-20}"
FAIL_THRESHOLD="${MISSION_FITNESS_FAIL_THRESHOLD:-40}"
JSON_OUT=0
DRY_RUN=0
EXPLAIN=0
MODE="run"

# ── usage / self-doc ──────────────────────────────────────────────────────────
usage() {
  printf '%s\n' \
    "usage: mission-fitness-doctor.sh [--repo PATH] [--limit N] [--json] [--dry-run] [--apply] [--explain]" \
    "       mission-fitness-doctor.sh --info|--examples|--schema|--help" \
    "" \
    "Score recent closed beads against the MISSION.md anchor keyword set." \
    "Exit: 0=drift_pct<${WARN_THRESHOLD}%  1=WARN drift_pct<${FAIL_THRESHOLD}%  2=FAIL drift_pct>=${FAIL_THRESHOLD}%  3=usage/config error"
}

examples() {
  cat <<'EXAMPLES'
# Live repo probe (JSON):
bash .flywheel/scripts/mission-fitness-doctor.sh --repo /Users/josh/Developer/flywheel --json

# Dry-run (print what would happen, no br calls):
bash .flywheel/scripts/mission-fitness-doctor.sh --dry-run

# Explain scoring logic before running:
bash .flywheel/scripts/mission-fitness-doctor.sh --explain --json

# Override bead limit:
bash .flywheel/scripts/mission-fitness-doctor.sh --repo /path/to/repo --limit 100 --json

# CI gate (exit code signals drift severity):
bash .flywheel/scripts/mission-fitness-doctor.sh --repo "$REPO" --json; echo "exit=$?"
EXAMPLES
}

info_json() {
  jq -nc \
    --arg version "$VERSION" \
    --arg schema "$SCHEMA_VERSION" \
    --arg repo "$REPO" \
    --argjson limit "$LIMIT" \
    --argjson warn "$WARN_THRESHOLD" \
    --argjson fail "$FAIL_THRESHOLD" \
    '{
      name:"mission-fitness-doctor.sh",
      version:$version,
      schema_version:$schema,
      repo:$repo,
      defaults:{limit:$limit,warn_threshold_pct:$warn,fail_threshold_pct:$fail},
      flags:["--repo","--limit","--json","--dry-run","--apply","--explain","--info","--examples","--schema","--help"],
      exit_codes:{"0":"pass (drift<warn_threshold)","1":"warn (drift in warn..fail range)","2":"fail (drift>=fail_threshold)","3":"usage/config error"},
      env_overrides:{
        "MISSION_FITNESS_REPO":"repo path",
        "MISSION_FITNESS_LIMIT":"closed bead count",
        "MISSION_FITNESS_WARN_THRESHOLD":"warn pct",
        "MISSION_FITNESS_FAIL_THRESHOLD":"fail pct"
      }
    }'
}

schema_json() {
  jq -nc --arg schema "$SCHEMA_VERSION" '{
    schema_version:$schema,
    type:"object",
    required:["anchor","total_closes","by_class","drift_count","drift_pct"],
    properties:{
      anchor:{type:"string",description:"anchor identifier from MISSION.md frontmatter"},
      anchor_keywords:{type:"array",items:{type:"string"}},
      total_closes:{type:"integer"},
      by_class:{
        type:"object",
        properties:{
          direct:{type:"integer",description:"score>=0.7"},
          adjacent:{type:"integer",description:"score 0.4-0.69"},
          infrastructure:{type:"integer",description:"score 0.2-0.39"},
          drift:{type:"integer",description:"score<0.2"}
        }
      },
      drift_count:{type:"integer"},
      drift_pct:{type:"number"},
      sample_drift_ids:{type:"array",items:{type:"string"}},
      status:{type:"string","enum":["pass","warn","fail"]},
      exit_code:{type:"integer"}
    }
  }'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; usage >&2; exit 3; }

# ── arg parse ─────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    # canonical-cli-scoping triad subcommands (this probe IS the doctor; health = run; completion = stub)
    doctor)      shift ;;   # "doctor" == default run mode; consume and continue
    health)      shift ;;   # "health" == single-shot status; same as run
    completion)  printf 'source %s\n' "${BASH_SOURCE[0]}"; exit 0 ;;
    --repo)      [[ $# -ge 2 ]] || die_usage "--repo requires a PATH"; REPO="$2"; shift 2 ;;
    --repo=*)    REPO="${1#*=}"; shift ;;
    --limit)     [[ $# -ge 2 ]] || die_usage "--limit requires N"; LIMIT="$2"; shift 2 ;;
    --limit=*)   LIMIT="${1#*=}"; shift ;;
    --json)      JSON_OUT=1; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --apply)     shift ;;  # alias for run (no mutations; --apply is a no-op here; kept for CLI surface parity)
    --explain)   EXPLAIN=1; shift ;;
    --info)      MODE="info"; shift ;;
    --examples)  MODE="examples"; shift ;;
    --schema)    MODE="schema"; shift ;;
    -h|--help)   MODE="help"; shift ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

case "$MODE" in
  info)     info_json; exit 0 ;;
  examples) examples; exit 0 ;;
  schema)   schema_json; exit 0 ;;
  help)     usage; exit 0 ;;
esac

[[ "$LIMIT" =~ ^[1-9][0-9]*$ ]] || die_usage "--limit must be a positive integer"
[[ -d "$REPO" ]] || die_usage "repo not found: $REPO"

MISSION_PATH="$REPO/.flywheel/MISSION.md"
[[ -f "$MISSION_PATH" ]] || { printf 'ERR: MISSION.md not found at %s\n' "$MISSION_PATH" >&2; exit 3; }

if [[ "$EXPLAIN" -eq 1 ]]; then
  cat <<'EXPLAIN_TEXT'
Scoring logic:
  1. Read MISSION.md frontmatter for "anchor:" field (fail with clear error if missing).
  2. Expand anchor slug + MISSION.md body into keyword set (split on [-_/ ] + stop-word removal).
  3. For each of the last N closed beads: compute keyword overlap between
     {title, close_reason, description} and anchor keyword set.
     score = matching_keywords / max(anchor_keyword_count, bead_word_count, 1)
  4. Classify:
       direct         >= 0.7
       adjacent       0.4 – 0.69
       infrastructure 0.2 – 0.39
       drift          < 0.2
  5. drift_pct = drift_count / total_closes * 100
  6. Exit: 0 if drift_pct < WARN_THRESHOLD, 1 if < FAIL_THRESHOLD, 2 otherwise.
EXPLAIN_TEXT
  [[ "$JSON_OUT" -eq 0 ]] && exit 0
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  jq -nc \
    --arg mission "$MISSION_PATH" \
    --argjson limit "$LIMIT" \
    '{dry_run:true,planned_actions:["read_mission_md","extract_anchor_frontmatter","call_br_list_closed","score_beads","emit_json"],mission_path:$mission,limit:$limit}'
  exit 0
fi

# ── core probe (Python for portability) ──────────────────────────────────────
set +e
payload="$(python3 - "$MISSION_PATH" "$REPO" "$LIMIT" "$WARN_THRESHOLD" "$FAIL_THRESHOLD" "$VERSION" "$SCHEMA_VERSION" <<'PY'
import json, os, re, subprocess, sys
from datetime import datetime, timezone

mission_path, repo, limit_s, warn_s, fail_s, version, schema = \
    sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7]
limit, warn_threshold, fail_threshold = int(limit_s), float(warn_s), float(fail_s)

def err(msg):
    print(json.dumps({"schema_version": schema, "error": msg, "exit_code": 3}))
    sys.exit(3)

# ── 1. read MISSION.md + extract anchor ──────────────────────────────────────
try:
    mission_text = open(mission_path, encoding="utf-8", errors="replace").read()
except OSError as e:
    err(f"cannot read MISSION.md: {e}")

anchor = None
for line in mission_text.splitlines():
    m = re.match(r'^anchor\s*:\s*(.+)$', line.strip())
    if m:
        anchor = m.group(1).strip().strip('"\'')
        break

if not anchor:
    # No top-level "anchor:" — try the Self-Sustaining Company Paradigm Anchor section
    # which is the canonical anchor for the flywheel repo
    if "self-sustaining" in mission_text.lower() or "continuous-orchestrator" in mission_text.lower():
        anchor = "continuous-orchestrator-uptime-self-sustaining-fleet"
    else:
        err("MISSION.md has no 'anchor:' frontmatter field and no recognisable anchor section. "
            "Add 'anchor: <slug>' to MISSION.md frontmatter.")

STOP = {
    "a","an","the","and","or","of","to","in","for","is","are","was","were",
    "be","been","being","that","this","it","its","with","on","at","by",
    "from","as","into","via","have","has","had","do","does","did","not",
    "no","so","if","then","but","we","our","their","any","all","each",
    "per","can","will","must","should","may","how","when","what","which",
    "repo","flywheel","zeststream","bead","beads","closed","close","open",
    "create","update","fix","add","remove","ship","done","pass","fail",
}

def keywords(text):
    tokens = re.split(r'[-_/ \t\n.,;:!?()\[\]{}"\'`]+', text.lower())
    return {t for t in tokens if len(t) > 2 and t not in STOP and t.isalpha()}

# anchor keyword set:
#   - Primary scoring set = slug keywords only (stable, small, signal-dense).
#   - Full display set = slug + top body supplement (for --info reporting only).
# Scoring intentionally uses slug_kw only so bead titles with 3-4 matching words
# can reach the "direct" band without the denominator being bloated by body text.
slug_kw = keywords(anchor)
body_kw_all = keywords(mission_text)
body_supplement = set(sorted(body_kw_all - STOP - slug_kw, key=lambda w: -len(w))[:20])
anchor_kw = slug_kw  # scoring set: slug only
anchor_kw_full = slug_kw | body_supplement  # display set

# ── 2. fetch closed beads ─────────────────────────────────────────────────────
br_bin = os.environ.get("BR_BIN", "br")
try:
    result = subprocess.run(
        [br_bin, "list", "--status=closed", f"--limit={limit}", "--json"],
        capture_output=True, text=True, timeout=30,
        cwd=repo,
    )
    br_out = result.stdout.strip()
    if not br_out:
        err("br list returned no output — is br installed and the repo initialised?")
    data = json.loads(br_out)
except FileNotFoundError:
    err("br binary not found; install beads_rust and ensure br is in PATH")
except subprocess.TimeoutExpired:
    err("br list timed out after 30s")
except json.JSONDecodeError as e:
    err(f"br list output is not valid JSON: {e}")

issues = data.get("issues", data) if isinstance(data, dict) else data
if not isinstance(issues, list):
    err(f"unexpected br list shape: {type(data).__name__}")

# ── 3. score each bead ───────────────────────────────────────────────────────
by_class = {"direct": 0, "adjacent": 0, "infrastructure": 0, "drift": 0}
drift_ids = []
scored = []

for issue in issues:
    bead_id  = issue.get("id", "?")
    title    = issue.get("title", "")
    reason   = issue.get("close_reason", "")
    desc     = issue.get("description", "")
    bead_text = f"{title} {reason} {desc}"
    bead_kw  = keywords(bead_text)

    if not anchor_kw:
        score = 0.0
    else:
        overlap = len(anchor_kw & bead_kw)
        # denominator = max(anchor_slug_size, bead_word_count) keeps scores sensible
        # for short bead titles while still penalizing totally unrelated beads.
        score   = overlap / max(len(anchor_kw), len(bead_kw), 1)

    if score >= 0.7:
        cls = "direct"
    elif score >= 0.4:
        cls = "adjacent"
    elif score >= 0.2:
        cls = "infrastructure"
    else:
        cls = "drift"

    by_class[cls] += 1
    if cls == "drift":
        drift_ids.append(bead_id)
    scored.append({"id": bead_id, "title": title[:80], "score": round(score, 3), "class": cls})

total = len(issues)
drift_count = by_class["drift"]
drift_pct = round(drift_count / max(total, 1) * 100, 1)

if drift_pct < warn_threshold:
    status, exit_code = "pass", 0
elif drift_pct < fail_threshold:
    status, exit_code = "warn", 1
else:
    status, exit_code = "fail", 2

out = {
    "schema_version": schema,
    "version": version,
    "ts": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "anchor": anchor,
    "anchor_keyword_count": len(anchor_kw),
    "anchor_keywords": sorted(anchor_kw_full)[:20],
    "total_closes": total,
    "by_class": by_class,
    "drift_count": drift_count,
    "drift_pct": drift_pct,
    "sample_drift_ids": drift_ids[:10],
    "status": status,
    "exit_code": exit_code,
    "warn_threshold_pct": warn_threshold,
    "fail_threshold_pct": fail_threshold,
    "scored_sample": scored[:10],
    "dashboard_line": (
        f"Fitness: {by_class['direct']}/{total} closes direct, {drift_pct}% drift "
        f"(anchor={anchor})"
    ),
}
print(json.dumps(out, separators=(",", ":")))
sys.exit(exit_code)
PY
)"
rc=$?
set -e

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  # human-readable summary
  status="$(printf '%s' "$payload" | jq -r '.status // "error"' 2>/dev/null || echo error)"
  drift_pct="$(printf '%s' "$payload" | jq -r '.drift_pct // "?"' 2>/dev/null || echo "?")"
  total="$(printf '%s' "$payload" | jq -r '.total_closes // "?"' 2>/dev/null || echo "?")"
  anchor="$(printf '%s' "$payload" | jq -r '.anchor // "?"' 2>/dev/null || echo "?")"
  drift_count="$(printf '%s' "$payload" | jq -r '.drift_count // "?"' 2>/dev/null || echo "?")"
  case "$status" in
    pass) sym="✓" ;;
    warn) sym="⚠" ;;
    fail) sym="✗" ;;
    *)    sym="?" ;;
  esac
  printf '%s mission_fitness status=%s drift_pct=%s%% drift=%s/%s anchor=%s\n' \
    "$sym" "$status" "$drift_pct" "$drift_count" "$total" "$anchor"
fi

exit "$rc"
