#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RENDER="$ROOT/render.sh"
FLYWHEEL_LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
FRONTMATTER_SH="$HOME/.claude/hooks/_shared/frontmatter.sh"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

need() {
    command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

need git
need jq
need python3
[[ -x "$RENDER" ]] || fail "render.sh is not executable"
[[ -x "$FLYWHEEL_LOOP_BIN" ]] || fail "flywheel-loop not executable: $FLYWHEEL_LOOP_BIN"
[[ -r "$FRONTMATTER_SH" ]] || fail "frontmatter helper not readable: $FRONTMATTER_SH"

# shellcheck source=/dev/null
source "$FRONTMATTER_SH"
declare -f frontmatter_status >/dev/null 2>&1 || fail "frontmatter_status not available"

find_bash4() {
    local candidate version
    for candidate in /opt/homebrew/bin/bash /usr/local/bin/bash bash; do
        command -v "$candidate" >/dev/null 2>&1 || continue
        version="$("$candidate" -c 'printf "%s\n" "${BASH_VERSINFO[0]}"' 2>/dev/null || true)"
        [[ "$version" -ge 4 ]] 2>/dev/null && { printf '%s\n' "$candidate"; return 0; }
    done
    return 1
}

BASH4="$(find_bash4)" || fail "render.sh requires bash >=4"

render_template() {
    "$BASH4" "$RENDER" "$@"
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git -C "$tmp" init -q
mkdir -p "$tmp/.flywheel" "$tmp/tests"
cat >"$tmp/tests/test_smoke.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

now="<timestamp>"
repo_realpath="$(cd "$tmp" && pwd -P)"
tmpl_hash() {
    shasum -a 256 "$1" | awk '{print $1}'
}

body_hash() {
    awk '
      BEGIN { in_yaml=0; in_kv=0; body=0 }
      NR==1 && /^---[[:space:]]*$/ { in_yaml=1; next }
      in_yaml && /^---[[:space:]]*$/ { body=1; next }
      in_yaml { next }
      !in_kv && !body && /^#[[:space:]]/ { next }
      !in_kv && !body && /^[[:space:]]*$/ { next }
      !in_kv && !body && /^[[:alpha:]_][[:alnum:]_-]*[[:space:]]*:/ { in_kv=1; next }
      in_kv && /^[[:alpha:]_][[:alnum:]_-]*[[:space:]]*:/ { next }
      in_kv && /^[[:space:]]*$/ { body=1; next }
      in_kv { body=1 }
      body { print }
    ' "$1" | shasum -a 256 | awk '{print $1}'
}

stamp_lock_hash() {
    local file="$1" hash tmp_file
    hash="$(body_hash "$file")"
    tmp_file="$(mktemp "$tmp/.lock.XXXXXX")"
    awk -v hash="$hash" '
      !done && /^lock_hash:/ { print "lock_hash: " hash; done=1; next }
      { print }
    ' "$file" >"$tmp_file"
    mv "$tmp_file" "$file"
}

cat >"$tmp/substitutions.env" <<EOF
schema_version=1
status=locked
repo=$tmp
repo_realpath=$repo_realpath
git_root=$repo_realpath
repo_name=render-fixture
installed_from=$ROOT
template_hash=synthetic-template-hash
rendered_at=$now
rendered_by=test_render.sh
lock_hash=synthetic-lock-hash
locked_at=$now
locked_by=test_render.sh
source_path=/tmp/source.md
source_sha256=synthetic-source-sha256
source_section=synthetic section
provenance_note=render smoke
why_now=Render smoke verifies the 14-section mission-lock template.
mission_source=Mission source line one.
Mission source line two.
mission_anchor=Template-backed portable loop install.
success_metrics=Strict doctor returns ok; rendered docs preserve lock hashes.
client_stakeholders=Repo maintainers and flywheel workers.
frontend_stack=No frontend stack in render fixture.
backend_stack=Shell templates plus flywheel-loop doctor.
middleware_requirements=None for render fixture.
auth_model=None for render fixture.
data_model_governance=Repo-local .flywheel docs only.
infrastructure_deployment=Local template render smoke in a temp repo.
flywheel_loop_policy=Run strict doctor before source mutation.
doctrine_compliance=Consult skills-best-practices before mission pivots.
stakeholder_escalation_map=Owner review required before mission changes.
north_star_outcome=One durable repo-local flywheel install path.
primary_beneficiary=Agents running portable loop ticks.
explicit_non_goals=No application source edits.
safety_privacy_boundaries=Do not mutate source files during doctor or render.
mission_change_evidence=Owner override or failed validation evidence.
owner_review_cadence=Review when mission or ownership changes.
current_goal=Render template-backed install artifacts.
measured_acceptance_criteria=Strict doctor returns ok.
validation_commands=bash templates/flywheel-install/tests/test_render.sh
current_blockers=
safe_next_action=Wire init to consume templates.
out_of_scope=Changing the live flywheel-loop binary in this step.
mission_anchor=Template-backed portable loop install.
success_definition=Rendered docs pass frontmatter and doctor checks.
resume_context=Continue from template render validation.
active_work_in_flight=bd-cwfs2 Step 4 templates upstream.
confirmed_failure_modes=Inline heredoc init stubs drift from doctor contract.
current_decisions=Use locked frontmatter for strict doctor readiness.
next_actions=Integrate templates in a later step.
key_files=templates/flywheel-install
lock_receipt=Locked by synthetic test fixture.
doctor_strict_command=flywheel-loop doctor --strict --repo . --json
source_mutation_allowed_when=Only after strict doctor returns ok and a loop tick selects a bounded patch.
EOF

for template in MISSION.md.tmpl GOAL.md.tmpl STATE.md.tmpl loop.json.tmpl; do
    out="$tmp/.flywheel/${template%.tmpl}"
    if [[ "$template" == "loop.json.tmpl" ]]; then
        out="$tmp/.flywheel/loop.json"
    fi
    render_template "$ROOT/$template" <"$tmp/substitutions.env" >"$out"
    ! grep -q '{{[^}][^}]*}}' "$out" || fail "unsubstituted marker in $out"
    [[ "$template" == "loop.json.tmpl" ]] || stamp_lock_hash "$out"
done

mkdir -p "$tmp/.flywheel/scripts"
cp "$ROOT/validate-callback-before-close.sh.tmpl" "$tmp/.flywheel/scripts/validate-callback-before-close.sh"
chmod 0755 "$tmp/.flywheel/scripts/validate-callback-before-close.sh"
[[ -x "$tmp/.flywheel/scripts/validate-callback-before-close.sh" ]] || fail "four-lens close validator did not render executable"
"$tmp/.flywheel/scripts/validate-callback-before-close.sh" --help >/dev/null \
    || fail "four-lens close validator help failed"
! grep -q '{{[^}][^}]*}}' "$tmp/.flywheel/scripts/validate-callback-before-close.sh" \
    || fail "unsubstituted marker in four-lens close validator"
if [[ -x "$ROOT/.flywheel/scripts/publishability-bar.sh" ]]; then
    cp "$ROOT/.flywheel/scripts/publishability-bar.sh" "$tmp/.flywheel/scripts/publishability-bar.sh"
    chmod 0755 "$tmp/.flywheel/scripts/publishability-bar.sh"
    cat >"$tmp/.flywheel/PUBLISHABILITY-AUDIT.md" <<'EOF'
Public repo: no

| id | facet | verdict | evidence |
|---|---|---|---|
| F1 | mission clarity | YES | render fixture |
| F2 | executable proof | YES | render smoke |
| F3 | documentation | YES | template README |
| F4 | operator safety | YES | dry-run fixture |
| F5 | doctrine fit | YES | AGENTS canonical |
| F6 | public shape | YES | internal exemption |
| F7 | maintenance path | YES | render test |
EOF
fi

cp "$ROOT/../../AGENTS.md" "$tmp/AGENTS.md"
cp "$tmp/AGENTS.md" "$tmp/.flywheel/AGENTS-CANONICAL.md"
mkdir -p "$tmp/.flywheel/reports"
printf '# daily\n' >"$tmp/.flywheel/reports/daily-2026-04-30.md"
storage_fixture="$tmp/storage-healthy.json"
jq -nc '{
  disk_total_gb:926,
  disk_free_gb:400,
  disk_free_pct:43,
  developer_dir_gb:0,
  local_state_gb:0,
  stale_baks_count:0,
  stale_baks_size_mb:0,
  qdrant_volumes_size_mb:0,
  tmp_dispatch_artifacts_count:0
}' >"$storage_fixture"
topology_fixture="$tmp/session-topology.jsonl"
josh_requests_fixture="$tmp/josh-requests.jsonl"
: >"$topology_fixture"
: >"$josh_requests_fixture"

[[ "$(frontmatter_status "$tmp/.flywheel/MISSION.md")" == "locked" ]] || fail "MISSION frontmatter status is not locked"
[[ "$(frontmatter_status "$tmp/.flywheel/GOAL.md")" == "locked" ]] || fail "GOAL frontmatter status is not locked"
[[ "$(frontmatter_status "$tmp/.flywheel/STATE.md")" == "locked" ]] || fail "STATE frontmatter status is not locked"

jq -e '.schema_version == 1 and .template_version == "0.1.0" and .docs.mission == ".flywheel/MISSION.md"' "$tmp/.flywheel/loop.json" >/dev/null \
    || fail "loop.json render does not satisfy expected shape"
jq -e '.polish_gate.version == "1" and .polish_gate.mode == "bootstrap" and .polish_gate.scope == "repo_local_flywheel" and (.polish_gate.blocking_when | index("expired_waiver"))' "$tmp/.flywheel/loop.json" >/dev/null \
    || fail "loop.json polish_gate object missing expected defaults"
python3 -c 'import json, sys; import jsonschema; from jsonschema import Draft202012Validator; loop=json.load(open(sys.argv[1], encoding="utf-8")); schema=json.load(open(sys.argv[2], encoding="utf-8")); Draft202012Validator.check_schema(schema); Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(loop["polish_gate"])' "$tmp/.flywheel/loop.json" "$ROOT/polish-gate/v1/manifest.schema.json" \
    || fail "rendered loop.json polish_gate object does not validate against manifest schema"

grep -q '## Polish Gate' "$tmp/.flywheel/MISSION.md" \
    || fail "MISSION template missing Polish Gate section"
grep -q 'polish_gate_mode: bootstrap' "$tmp/.flywheel/MISSION.md" \
    || fail "MISSION template missing polish_gate_mode"
grep -q 'polish_gate_latest_summary: .flywheel/polish-gate/latest.json' "$tmp/.flywheel/MISSION.md" \
    || fail "MISSION template missing polish_gate_latest_summary"
grep -q '## Polish Gate runtime' "$tmp/.flywheel/STATE.md" \
    || fail "STATE template missing Polish Gate runtime section"
grep -q 'polish_gate_surfaces_graded_count: 0' "$tmp/.flywheel/STATE.md" \
    || fail "STATE template missing polish_gate_surfaces_graded_count"
grep -q 'polish_gate_min_composite_surface: null' "$tmp/.flywheel/STATE.md" \
    || fail "STATE template missing polish_gate_min_composite_surface"

set +e
doctor_json="$(FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" FLYWHEEL_SESSION_TOPOLOGY="$topology_fixture" FLYWHEEL_JOSH_REQUESTS_LOG="$josh_requests_fixture" FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 FLYWHEEL_CANONICAL_DOCTRINE_PATH="$repo_realpath/AGENTS.md" "$FLYWHEEL_LOOP_BIN" doctor --strict --repo "$tmp" --json)"
doctor_rc=$?
set -e
[[ "$doctor_rc" -le 1 ]] || fail "strict doctor command failed unexpectedly rc=$doctor_rc: $doctor_json"
jq -e '.repo_docs_state == "ready" and .loop_config_present == true and .repo_local_clis_below_canonical_floor == 0 and .publishability_bar.status == "pass"' <<<"$doctor_json" >/dev/null \
    || fail "strict doctor did not return ready docs with repo-local CLI floor clean: $doctor_json"

grep -q 'canonical-cli-scoping/SKILL.md' "$tmp/.flywheel/MISSION.md" \
    || fail "MISSION template did not mention canonical-cli-scoping skill"
grep -q 'repo_local_clis_below_canonical_floor' "$tmp/.flywheel/MISSION.md" \
    || fail "MISSION template did not document repo_local_clis_below_canonical_floor"

empty_render="$(render_template "$ROOT/MISSION.md.tmpl" 2>"$tmp/missing.err" <<EOF
schema_version=1
doc_type=
EOF
)" && fail "renderer should reject missing substitutions, got: $empty_render"
grep -q '{{repo_name}}' "$tmp/missing.err" || fail "missing substitution error did not name an unresolved marker"

multiline="$(render_template "$ROOT/MISSION.md.tmpl" <"$tmp/substitutions.env")"
grep -q 'Mission source line two.' <<<"$multiline" || fail "multiline substitution was not preserved"

for template in MISSION.md.tmpl GOAL.md.tmpl STATE.md.tmpl loop.json.tmpl validate-callback-before-close.sh.tmpl; do
    hash="$(tmpl_hash "$ROOT/$template")"
    [[ -n "$hash" && "${#hash}" -eq 64 ]] || fail "template hash failed for $template"
done

echo "PASS: render templates, frontmatter, and strict doctor smoke"
