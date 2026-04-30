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
[[ -x "$RENDER" ]] || fail "render.sh is not executable"
[[ -x "$FLYWHEEL_LOOP_BIN" ]] || fail "flywheel-loop not executable: $FLYWHEEL_LOOP_BIN"
[[ -r "$FRONTMATTER_SH" ]] || fail "frontmatter helper not readable: $FRONTMATTER_SH"

# shellcheck source=/dev/null
source "$FRONTMATTER_SH"
declare -f frontmatter_status >/dev/null 2>&1 || fail "frontmatter_status not available"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git -C "$tmp" init -q
mkdir -p "$tmp/.flywheel" "$tmp/tests"
cat >"$tmp/tests/test_smoke.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

now="2026-04-30T00:00:00Z"
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
mission_source=Mission source line one.
Mission source line two.
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
    "$RENDER" "$ROOT/$template" <"$tmp/substitutions.env" >"$out"
    ! grep -q '{{[^}][^}]*}}' "$out" || fail "unsubstituted marker in $out"
    [[ "$template" == "loop.json.tmpl" ]] || stamp_lock_hash "$out"
done

[[ "$(frontmatter_status "$tmp/.flywheel/MISSION.md")" == "locked" ]] || fail "MISSION frontmatter status is not locked"
[[ "$(frontmatter_status "$tmp/.flywheel/GOAL.md")" == "locked" ]] || fail "GOAL frontmatter status is not locked"
[[ "$(frontmatter_status "$tmp/.flywheel/STATE.md")" == "locked" ]] || fail "STATE frontmatter status is not locked"

jq -e '.schema_version == 1 and .template_version == "0.1.0" and .docs.mission == ".flywheel/MISSION.md"' "$tmp/.flywheel/loop.json" >/dev/null \
    || fail "loop.json render does not satisfy expected shape"

doctor_json="$("$FLYWHEEL_LOOP_BIN" doctor --strict --repo "$tmp" --json)"
jq -e '.status == "ok" and .repo_docs_state == "ready" and .loop_config_present == true' <<<"$doctor_json" >/dev/null \
    || fail "strict doctor did not return ok: $doctor_json"

empty_render="$("$RENDER" "$ROOT/MISSION.md.tmpl" 2>"$tmp/missing.err" <<EOF
schema_version=1
doc_type=
EOF
)" && fail "renderer should reject missing substitutions, got: $empty_render"
grep -q '{{repo_name}}' "$tmp/missing.err" || fail "missing substitution error did not name an unresolved marker"

multiline="$("$RENDER" "$ROOT/MISSION.md.tmpl" <"$tmp/substitutions.env")"
grep -q 'Mission source line two.' <<<"$multiline" || fail "multiline substitution was not preserved"

for template in MISSION.md.tmpl GOAL.md.tmpl STATE.md.tmpl loop.json.tmpl; do
    hash="$(tmpl_hash "$ROOT/$template")"
    [[ -n "$hash" && "${#hash}" -eq 64 ]] || fail "template hash failed for $template"
done

echo "PASS: render templates, frontmatter, and strict doctor smoke"
