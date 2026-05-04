#!/usr/bin/env bash
set -euo pipefail

repo="${PWD}"
json=0
remote_name="${1:-}"
remote_url="${2:-}"

usage() {
    printf '%s\n' \
        "zeststream-public-prepublish-hook.sh [remote-name remote-url] [--repo PATH] [--json]" \
        "" \
        "Git pre-push compatible gate for public ZestStream repos. It blocks pushes to a" \
        "remote named public when publishability brand-voice readiness fails."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            repo="$2"
            shift 2
            ;;
        --repo=*)
            repo="${1#*=}"
            shift
            ;;
        --json)
            json=1
            shift
            ;;
        --help|-h|help)
            usage
            exit 0
            ;;
        *)
            if [[ -z "$remote_name" ]]; then
                remote_name="$1"
            elif [[ -z "$remote_url" ]]; then
                remote_url="$1"
            fi
            shift
            ;;
    esac
done

repo="$(cd "$repo" 2>/dev/null && pwd -P || printf '%s' "$repo")"
probe="$repo/.flywheel/scripts/publishability-bar.sh"
if [[ ! -x "$probe" ]]; then
    jq -nc --arg probe "$probe" '{status:"fail",gate:"zeststream_public_prepublish",errors:[{code:"publishability_probe_missing",path:$probe}]}'
    exit 1
fi

target_public=false
if [[ "$remote_name" == "public" || "$remote_url" == *"public"* ]]; then
    target_public=true
fi

if [[ "$target_public" != "true" ]]; then
    out="$(jq -nc --arg remote_name "$remote_name" --arg remote_url "$remote_url" '{status:"pass",gate:"zeststream_public_prepublish",target_public:false,remote_name:$remote_name,remote_url:$remote_url,skipped:true}')"
    [[ "$json" -eq 1 ]] && printf '%s\n' "$out" || jq -r '"status=\(.status) skipped=\(.skipped)"' <<<"$out"
    exit 0
fi

probe_out="$("$probe" --doctor --json --repo "$repo" 2>/dev/null)" || true
if ! jq -e . >/dev/null 2>&1 <<<"$probe_out"; then
    jq -nc '{status:"fail",gate:"zeststream_public_prepublish",errors:[{code:"publishability_probe_invalid_json"}]}'
    exit 1
fi

status="$(jq -r '.status // "fail"' <<<"$probe_out")"
out="$(jq -c --argjson publishability "$probe_out" --arg remote_name "$remote_name" --arg remote_url "$remote_url" '
  ($publishability.brand_voice.public_repo // false) as $declared_public
  | (($publishability.errors // []) + (if $declared_public then [] else [{code:"public_push_without_public_voice_gate", message:"target remote is public but PUBLISHABILITY-AUDIT.md does not mark Public repo: yes"}] end)) as $errors
  | {
  status:(if $publishability.status == "pass" and $declared_public then "pass" else "fail" end),
  gate:"zeststream_public_prepublish",
  target_public:true,
  remote_name:$remote_name,
  remote_url:$remote_url,
  publishability_bar_score:$publishability.publishability_bar_score,
  brand_voice:$publishability.brand_voice,
  errors:$errors,
  warnings:($publishability.warnings // [])
}' <<<"{}")"
[[ "$json" -eq 1 ]] && printf '%s\n' "$out" || jq -r '"status=\(.status) score=\(.publishability_bar_score.score) brand_voice=\(.publishability_bar_score.brand_voice_composite)"' <<<"$out"
jq -e '.status == "pass"' >/dev/null <<<"$out" && exit 0
exit 1
