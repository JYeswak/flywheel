#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat >&2 <<'EOF'
usage: render.sh TEMPLATE < substitutions.env > rendered

Substitution input format:
  key=value starts or replaces a value.
  Non-key lines append to the current key, preserving newlines.
  Empty values are allowed.

Markers use {{key}}. Any marker left after substitution is an error.
EOF
}

if [[ $# -ne 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    [[ $# -eq 1 ]] && exit 0 || exit 64
fi

template="$1"
[[ -r "$template" ]] || { echo "ERR: template not readable: $template" >&2; exit 66; }

declare -A values
current_key=""

while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
        current_key="${BASH_REMATCH[1]}"
        values["$current_key"]="${BASH_REMATCH[2]}"
    elif [[ -n "$current_key" ]]; then
        values["$current_key"]+=$'\n'"$line"
    elif [[ -n "$line" ]]; then
        echo "ERR: substitution line before key=value: $line" >&2
        exit 65
    fi
done

for optional_key in resume_context; do
    [[ -n "${values[$optional_key]+set}" ]] || values["$optional_key"]=""
done

output="$(<"$template")"
for key in "${!values[@]}"; do
    output="${output//\{\{$key\}\}/${values[$key]}}"
done

if grep -q '{{[^}][^}]*}}' <<<"$output"; then
    echo "ERR: unsubstituted template marker(s):" >&2
    grep -o '{{[^}][^}]*}}' <<<"$output" | sort -u >&2
    exit 65
fi

printf '%s\n' "$output"
